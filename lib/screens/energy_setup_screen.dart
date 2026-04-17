import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:carbon_tracker/config/design_tokens.dart';
import 'package:carbon_tracker/data/country_defaults.dart';
import 'package:carbon_tracker/models/energy_profile.dart';
import 'package:carbon_tracker/providers/emission_provider.dart';
import 'package:carbon_tracker/widgets/voetje_button.dart';

class EnergySetupScreen extends StatefulWidget {
  const EnergySetupScreen({super.key});

  @override
  State<EnergySetupScreen> createState() => _EnergySetupScreenState();
}

class _EnergySetupScreenState extends State<EnergySetupScreen> {
  final _pageController = PageController();
  String? _countryCode;
  String? _stateCode;
  final Set<HeatingType> _heatingTypes = {};
  int _householdSize = 1;
  EnergyTrackingMethod _method = EnergyTrackingMethod.estimate;
  int _currentPage = 0;

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage++);
  }

  Future<void> _complete() async {
    final profile = EnergyProfile(
      countryCode: _countryCode ?? 'US',
      stateCode: _stateCode,
      heatingTypes: _heatingTypes.toList(),
      householdSize: _householdSize,
      method: _method,
      updatedAt: DateTime.now(),
    );
    await context.read<EmissionProvider>().setupEnergy(profile);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoetjeColors.backgroundOf(context),
      appBar: AppBar(
        title: Text('Set up Energy Tracking',
            style: VoetjeTypography.pageTitle()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                VoetjeSpacing.screenEdge, 0,
                VoetjeSpacing.screenEdge, 8),
            child: Row(
              children: List.generate(4, (i) {
                final isFilled = i <= _currentPage;
                return Expanded(
                  child: Padding(
                    padding:
                        EdgeInsets.only(right: i < 3 ? 6 : 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 3,
                      decoration: BoxDecoration(
                        color: isFilled
                            ? VoetjeColors.primaryMediumOf(context)
                            : VoetjeColors.progressTrackOf(context),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _CountryPage(
            onSelected: (country, state) {
              setState(() {
                _countryCode = country;
                _stateCode = state;
              });
              _nextPage();
            },
          ),
          _HeatingPage(
            selected: _heatingTypes,
            onChanged: (type, checked) {
              setState(() {
                if (checked) {
                  _heatingTypes.add(type);
                } else {
                  _heatingTypes.remove(type);
                }
              });
            },
            onNext: _nextPage,
          ),
          _HouseholdPage(
            selected: _householdSize,
            onSelected: (size) {
              setState(() => _householdSize = size);
              _nextPage();
            },
          ),
          _MethodPage(
            onSelected: (method) {
              setState(() => _method = method);
              _complete();
            },
          ),
        ],
      ),
    );
  }
}


// ─── Shared selection card ────────────────────────────────────────────────────

class _SelectionCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  const _SelectionCard({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: VoetjeColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(VoetjeRadius.input),
          border: Border.all(
            color: selected
                ? VoetjeColors.primaryMediumOf(context)
                : VoetjeColors.borderOf(context),
            width: selected ? 2 : 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: VoetjeColors.shadowLight,
              blurRadius: 3,
              offset: Offset(0, 1),
            )
          ],
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(child: child),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: selected
                  ? VoetjeColors.primaryMediumOf(context)
                  : VoetjeColors.borderOf(context),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Page 1: Country ---

class _CountryPage extends StatefulWidget {
  final void Function(String countryCode, String? stateCode) onSelected;
  const _CountryPage({required this.onSelected});

  @override
  State<_CountryPage> createState() => _CountryPageState();
}

class _CountryPageState extends State<_CountryPage> {
  final _searchCtrl = TextEditingController();
  String? _selectedCountry;
  String _query = '';

  // Derived from CountryDefaults — single source of truth.
  static final Map<String, String> _countries =
      CountryDefaults.countries.map((k, v) => MapEntry(k, v.name));

  List<MapEntry<String, String>> get _filtered {
    final q = _query.toLowerCase();
    if (q.isEmpty) {
      // Pinned countries first
      const pinned = ['US', 'GB', 'DE', 'AU', 'IN'];
      final pinnedEntries = pinned
          .where(_countries.containsKey)
          .map((k) => MapEntry(k, _countries[k]!))
          .toList();
      final rest = _countries.entries
          .where((e) => !pinned.contains(e.key))
          .toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      return [...pinnedEntries, ...rest];
    }
    return _countries.entries
        .where((e) =>
            e.value.toLowerCase().contains(q) ||
            e.key.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));
  }

  void _selectCountry(String code) {
    final country = CountryDefaults.forCode(code);
    setState(() => _selectedCountry = code);
    if (!country.hasRegions) {
      widget.onSelected(code, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDefaults = _selectedCountry != null
        ? CountryDefaults.forCode(_selectedCountry!)
        : null;
    if (selectedDefaults != null && selectedDefaults.hasRegions) {
      // Region/state selection view
      return Padding(
        padding: const EdgeInsets.all(VoetjeSpacing.screenEdge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Which state/province?',
                style: VoetjeTypography.pageQuestion()),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  ...selectedDefaults.regions!.entries.map((e) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _SelectionCard(
                          selected: false,
                          onTap: () => widget.onSelected(
                              _selectedCountry!, e.key),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(e.value,
                                  style: VoetjeTypography.body()),
                              Text(e.key,
                                  style: VoetjeTypography.caption()),
                            ],
                          ),
                        ),
                      )),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _SelectionCard(
                      selected: false,
                      onTap: () =>
                          widget.onSelected(_selectedCountry!, null),
                      child: Text('Other / Not listed',
                          style: VoetjeTypography.body()),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () =>
                  setState(() => _selectedCountry = null),
              child: Text(
                '← Back to countries',
                style: VoetjeTypography.caption().copyWith(
                      fontSize: 13,
                      color: VoetjeColors.textMutedOf(context),
                    ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(VoetjeSpacing.screenEdge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where do you live?',
              style: VoetjeTypography.pageQuestion()),
          const SizedBox(height: 14),
          TextField(
            controller: _searchCtrl,
            style: VoetjeTypography.body(),
            decoration: InputDecoration(
              hintText: 'Search country...',
              hintStyle: VoetjeTypography.caption().copyWith(
                    fontSize: 13,
                    color: VoetjeColors.textMutedOf(context),
                  ),
              prefixIcon: Icon(Icons.search,
                  color: VoetjeColors.textMutedOf(context)),
              filled: true,
              fillColor: VoetjeColors.surfaceOf(context),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(VoetjeRadius.input),
                borderSide: BorderSide(
                    color: VoetjeColors.borderOf(context), width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(VoetjeRadius.input),
                borderSide: BorderSide(
                    color: VoetjeColors.borderOf(context), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(VoetjeRadius.input),
                borderSide: BorderSide(
                    color: VoetjeColors.primaryMediumOf(context), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: _filtered
                  .map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _SelectionCard(
                          selected: false,
                          onTap: () => _selectCountry(e.key),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(e.value,
                                  style: VoetjeTypography.body()),
                              Text(e.key,
                                  style: VoetjeTypography.caption()),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Page 2: Heating ---

class _HeatingPage extends StatelessWidget {
  final Set<HeatingType> selected;
  final void Function(HeatingType type, bool checked) onChanged;
  final VoidCallback onNext;

  const _HeatingPage({
    required this.selected,
    required this.onChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(VoetjeSpacing.screenEdge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How do you heat your home?',
              style: VoetjeTypography.pageQuestion()),
          const SizedBox(height: 6),
          Text('Select all that apply',
              style: VoetjeTypography.body()
                  .copyWith(color: VoetjeColors.textMutedOf(context))),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 2.0,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: HeatingType.values.map((type) {
                final isSelected = selected.contains(type);
                return GestureDetector(
                  onTap: () {
                    if (type == HeatingType.notSure) {
                      for (final t in HeatingType.values) {
                        if (t != HeatingType.notSure &&
                            selected.contains(t)) {
                          onChanged(t, false);
                        }
                      }
                    }
                    onChanged(type, !isSelected);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: VoetjeColors.surfaceOf(context),
                      borderRadius:
                          BorderRadius.circular(VoetjeRadius.input),
                      border: Border.all(
                        color: isSelected
                            ? VoetjeColors.primaryMediumOf(context)
                            : VoetjeColors.borderOf(context),
                        width: isSelected ? 2 : 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: VoetjeColors.shadowLight,
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        )
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(type.icon, size: VoetjeIconSize.mediumIcon,
                              color: isSelected
                                  ? VoetjeColors.primaryMediumOf(context)
                                  : VoetjeColors.textMutedOf(context)),
                          Text(type.label,
                              textAlign: TextAlign.center,
                              style: VoetjeTypography.caption().copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? VoetjeColors.primaryMediumOf(context)
                                        : VoetjeColors.textPrimaryOf(context),
                                  )),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          VoetjeButton(label: 'Next →', onPressed: onNext),
        ],
      ),
    );
  }
}

// --- Page 3: Household ---

class _HouseholdPage extends StatelessWidget {
  final int selected;
  final void Function(int size) onSelected;

  const _HouseholdPage(
      {required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const options = [
      (size: 1, label: 'Just me'),
      (size: 2, label: '2 people'),
      (size: 3, label: '3 people'),
      (size: 4, label: '4 people'),
      (size: 5, label: '5+ people'),
    ];
    return Padding(
      padding: const EdgeInsets.all(VoetjeSpacing.screenEdge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Who lives in your home?',
              style: VoetjeTypography.pageQuestion()),
          const SizedBox(height: 16),
          ...options.map((opt) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SelectionCard(
                  selected: selected == opt.size,
                  onTap: () => onSelected(opt.size),
                  child: Text(opt.label,
                      style: VoetjeTypography.bodyEmphasis()),
                ),
              )),
        ],
      ),
    );
  }
}

// --- Page 4: Tracking Method ---

class _MethodPage extends StatelessWidget {
  final void Function(EnergyTrackingMethod method) onSelected;

  const _MethodPage({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(VoetjeSpacing.screenEdge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How should we track your energy?',
              style: VoetjeTypography.pageQuestion()),
          const SizedBox(height: 16),
          _MethodCard(
            icon: Icons.bar_chart_outlined,
            title: 'Use an estimate',
            subtitle: 'Based on your country and household size.',
            badge: 'Popular',
            onTap: () => onSelected(EnergyTrackingMethod.estimate),
          ),
          const SizedBox(height: 10),
          _MethodCard(
            icon: Icons.receipt_long_outlined,
            title: 'Enter my bills',
            subtitle: 'Log your monthly electricity and gas bills.',
            onTap: () => onSelected(EnergyTrackingMethod.bills),
          ),
          const SizedBox(height: 16),
          Text(
            'You can switch anytime in Settings.',
            style: VoetjeTypography.caption(),
          ),
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _MethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: VoetjeColors.surfaceOf(context),
          border: Border.all(
            color: badge != null
                ? VoetjeColors.primaryMediumOf(context)
                : VoetjeColors.borderOf(context),
            width: badge != null ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(VoetjeRadius.input),
          boxShadow: const [
            BoxShadow(
              color: VoetjeColors.shadowLight,
              blurRadius: 3,
              offset: Offset(0, 1),
            )
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: VoetjeIconSize.largeIcon, color: VoetjeColors.primaryMediumOf(context)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: VoetjeTypography.bodyEmphasis().copyWith(
                                fontWeight: FontWeight.w700,
                              )),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: VoetjeColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(badge!,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10)),
                        ),
                      ],
                    ],
                  ),
                  Text(subtitle,
                      style: VoetjeTypography.body()
                          .copyWith(color: VoetjeColors.textMutedOf(context))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
