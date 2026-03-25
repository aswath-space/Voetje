import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carbon_tracker/config/design_tokens.dart';
import 'package:carbon_tracker/providers/emission_provider.dart';
import 'package:carbon_tracker/screens/history_screen.dart';
import 'package:carbon_tracker/screens/settings_screen.dart';
import 'package:carbon_tracker/models/emission_entry.dart';
import 'package:carbon_tracker/widgets/budget_ring.dart';
import 'package:carbon_tracker/widgets/entry_tile.dart';
import 'package:carbon_tracker/widgets/section_header.dart';
import 'package:carbon_tracker/widgets/still_to_log_card.dart';
import 'package:carbon_tracker/widgets/category_picker_sheet.dart';
import 'package:carbon_tracker/services/nudge_message_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _DashboardTab(
            onSwitchToHistory: () => setState(() => _currentIndex = 1),
            onSwitchToSettings: () => setState(() => _currentIndex = 2),
          ),
          const HistoryScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        elevation: 0,
        backgroundColor: VoetjeColors.surfaceOf(context),
        selectedItemColor: VoetjeColors.primaryOf(context),
        unselectedItemColor: VoetjeColors.inactiveNavOf(context),
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: VoetjeTypography.caption().copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: VoetjeTypography.caption().copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time_outlined),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final VoidCallback onSwitchToHistory;
  final VoidCallback onSwitchToSettings;

  const _DashboardTab({required this.onSwitchToHistory, required this.onSwitchToSettings});

  @override
  Widget build(BuildContext context) {
    return Selector<EmissionProvider, ({bool isLoading, String? error, bool isEmpty})>(
      selector: (_, p) => (
        isLoading: p.isLoading,
        error: p.refreshError,
        isEmpty: p.recentEntries.isEmpty,
      ),
      builder: (context, state, _) {
        if (state.isLoading && state.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: VoetjeIconSize.xlargeIcon, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(state.error!, textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.read<EmissionProvider>().refreshData(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        return _DashboardContent(onSwitchToHistory: onSwitchToHistory, onSwitchToSettings: onSwitchToSettings);
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final VoidCallback onSwitchToHistory;
  final VoidCallback onSwitchToSettings;

  const _DashboardContent({required this.onSwitchToHistory, required this.onSwitchToSettings});

  @override
  Widget build(BuildContext context) {
    return Consumer<EmissionProvider>(
      builder: (context, provider, _) {
        final breakdown = provider.todayCategoryBreakdown;
        final loggedEntries = provider.todayLoggedEntries;
        final stillToLog = provider.todayStillToLog;
        final nudge = NudgeMessagePicker.pick(provider);

        return RefreshIndicator(
          onRefresh: provider.refreshData,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(height: MediaQuery.of(context).padding.top + 24),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: VoetjeSpacing.screenEdge),
                sliver: SliverList.list(
                  children: [
                    // Hero ring — 65% of screen width, centered with breathing room
                    const SizedBox(height: 8),
                    Center(
                      child: BudgetRing(
                        totalCO2: provider.todayCO2,
                        categoryBreakdown: breakdown,
                        size: MediaQuery.of(context).size.width * 0.65,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Category legend (small dots + labels)
                    _CategoryLegend(breakdown: breakdown),

                    const SizedBox(height: 8),

                    // "This week" pill
                    Center(
                      child: GestureDetector(
                        onTap: onSwitchToHistory,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: VoetjeColors.surfaceSubtleOf(context),
                            borderRadius: BorderRadius.circular(VoetjeRadius.chip),
                          ),
                          child: Text(
                            'This week: ${provider.weekCO2.toStringAsFixed(1)} kg \u2192',
                            style: VoetjeTypography.caption().copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: VoetjeColors.textSecondaryOf(context),
                                ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: VoetjeSpacing.sectionGap),

                    // Section header
                    SectionHeader(
                      label: 'TODAY',
                      actionLabel: '+ Add',
                      onAction: () => _showCategoryPicker(context),
                    ),

                    const SizedBox(height: VoetjeSpacing.cardGap),

                    // Still to log (if any) — shown first so users can act immediately
                    if (stillToLog.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: VoetjeSpacing.cardGap),
                        child: Row(
                          children: [
                            for (int i = 0; i < stillToLog.length; i++) ...[
                              if (i > 0) const SizedBox(width: VoetjeSpacing.cardGap),
                              Expanded(
                                child: StillToLogCard(
                                  label: stillToLog[i]['label'] as String,
                                  icon: Icons.restaurant,
                                  color: VoetjeColors.primaryMedium,
                                  onTap: () => _showCategoryPicker(context, initialCategory: 'food'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                    // Logged entries
                    ...loggedEntries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: VoetjeSpacing.cardGap),
                      child: EntryTile(
                        title: _titleForEntry(entry, provider),
                        subtitle: _subtitleForEntry(entry, provider),
                        kgValue: '${entry.co2Kg.toStringAsFixed(1)} kg',
                        category: entry.category.name,
                        icon: _iconForCategory(entry),
                      ),
                    )),

                    // Empty state
                    if (loggedEntries.isEmpty && stillToLog.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.eco_outlined, size: VoetjeIconSize.xlargeIcon, color: VoetjeColors.textMutedOf(context)),
                              const SizedBox(height: 8),
                              Text(
                                'Nothing logged yet today',
                                style: VoetjeTypography.body().copyWith(
                                      color: VoetjeColors.textMutedOf(context),
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap "+ Add" to start tracking',
                                style: VoetjeTypography.caption().copyWith(
                                  color: VoetjeColors.captionColorOf(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: VoetjeSpacing.sectionGap),

                    // Nudge card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: VoetjeColors.surfaceSubtleOf(context),
                        borderRadius: BorderRadius.circular(VoetjeRadius.input),
                        boxShadow: const [
                          BoxShadow(
                            color: VoetjeColors.shadowLight,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(nudge.icon, size: VoetjeIconSize.mediumIcon, color: VoetjeColors.primaryMediumOf(context)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              nudge.text,
                              style: VoetjeTypography.caption().copyWith(
                                    color: VoetjeColors.textSecondaryOf(context),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCategoryPicker(BuildContext context, {String? initialCategory}) {
    final provider = context.read<EmissionProvider>();

    // Transport-only: skip picker and open transport form directly inside sheet
    if (!provider.foodEnabled &&
        !provider.energyEnabled &&
        !provider.shoppingEnabled &&
        !provider.wasteEnabled) {
      showExpandingLogSheet(
        context,
        foodEnabled: false,
        energyEnabled: false,
        shoppingEnabled: false,
        wasteEnabled: false,
        initialCategory: 'transport',
      );
      return;
    }

    showExpandingLogSheet(
      context,
      foodEnabled: provider.foodEnabled,
      energyEnabled: provider.energyEnabled,
      shoppingEnabled: provider.shoppingEnabled,
      wasteEnabled: provider.wasteEnabled,
      initialCategory: initialCategory,
    );
  }

  String _titleForEntry(EmissionEntry entry, EmissionProvider provider) {
    switch (entry.category) {
      case EmissionCategory.food:
        final meal = entry.mealType;
        return meal?.label ?? entry.subCategory;
      case EmissionCategory.energy:
        return entry.note ?? entry.subCategory;
      case EmissionCategory.waste:
        final bin = entry.binType;
        return bin?.label ?? entry.subCategory;
      case EmissionCategory.shopping:
        final details = entry.shoppingDetails;
        return details != null ? details.$1 : entry.subCategory;
      default:
        final mode = entry.transportMode;
        return mode?.label ?? entry.subCategory;
    }
  }

  String? _subtitleForEntry(EmissionEntry entry, EmissionProvider provider) {
    switch (entry.category) {
      case EmissionCategory.food:
        return entry.note;
      case EmissionCategory.energy:
        return entry.subCategory;
      case EmissionCategory.waste:
        return '${entry.value.toStringAsFixed(1)} kg waste';
      case EmissionCategory.shopping:
        final details = entry.shoppingDetails;
        if (details != null) {
          return details.$2.name.replaceAllMapped(
            RegExp(r'[A-Z]'),
            (m) => ' ${m.group(0)!.toLowerCase()}',
          ).trim();
        }
        return entry.note;
      default:
        return '${provider.convertDistance(entry.value).toStringAsFixed(1)} ${provider.unitLabel}';
    }
  }

  IconData _iconForCategory(EmissionEntry entry) {
    switch (entry.category) {
      case EmissionCategory.transport:
        final mode = entry.transportMode;
        if (mode != null) return mode.icon;
        return Icons.directions_car;
      case EmissionCategory.food:
        final meal = entry.mealType;
        if (meal != null) return meal.icon;
        return Icons.restaurant;
      case EmissionCategory.energy:
        return Icons.bolt;
      case EmissionCategory.shopping:
        return Icons.shopping_bag;
      case EmissionCategory.waste:
        return Icons.recycling;
    }
  }
}

class _CategoryLegend extends StatelessWidget {
  final Map<String, double> breakdown;
  const _CategoryLegend({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 4,
      children: breakdown.keys.map((cat) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: VoetjeColors.categoryColor(cat),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              cat[0].toUpperCase() + cat.substring(1),
              style: VoetjeTypography.caption().copyWith(
                color: VoetjeColors.captionColorOf(context),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
