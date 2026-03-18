import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carbon_tracker/config/design_tokens.dart';
import 'package:carbon_tracker/models/waste_setup.dart';
import 'package:carbon_tracker/providers/emission_provider.dart';

/// 2-screen setup wizard for Waste & Recycling.
/// Screen 1: Which bins do you have?
/// Screen 2: Own bins or communal?
class WasteSetupScreen extends StatefulWidget {
  const WasteSetupScreen({super.key});

  @override
  State<WasteSetupScreen> createState() => _WasteSetupScreenState();
}

class _WasteSetupScreenState extends State<WasteSetupScreen> {
  int _step = 0;

  // Step 1 selections
  final Set<BinType> _selectedBins = {
    BinType.generalWaste,
    BinType.recycling,
  };

  // Step 2 selection
  HousingType _housingType = HousingType.ownBins;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoetjeColors.background,
      appBar: AppBar(
        title:
            Text('Waste Setup', style: VoetjeTypography.pageTitle()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                VoetjeSpacing.screenEdge, 0,
                VoetjeSpacing.screenEdge, 8),
            child: Row(
              children: List.generate(2, (i) {
                final isFilled = i <= _step;
                return Expanded(
                  child: Padding(
                    padding:
                        EdgeInsets.only(right: i < 1 ? 6 : 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 3,
                      decoration: BoxDecoration(
                        color: isFilled
                            ? VoetjeColors.primaryMedium
                            : VoetjeColors.progressTrack,
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
      body: _step == 0
          ? _BinSelectionStep(
              selectedBins: _selectedBins,
              onToggle: (bin) => setState(() {
                if (_selectedBins.contains(bin)) {
                  _selectedBins.remove(bin);
                } else {
                  _selectedBins.add(bin);
                }
              }),
              onNext: () => setState(() => _step = 1),
            )
          : _HousingTypeStep(
              selected: _housingType,
              onSelect: (h) => setState(() => _housingType = h),
              onDone: _save,
            ),
    );
  }

  Future<void> _save() async {
    final setup = WasteSetup(
      enabledBins: _selectedBins.toList(),
      housingType: _housingType,
    );
    await context.read<EmissionProvider>().setupWaste(setup);
    if (mounted) Navigator.pop(context);
  }
}

// ─── Shared green pill button ─────────────────────────────────────────────────

class _GreenPillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _GreenPillButton({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: VoetjeColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: VoetjeColors.border,
          elevation: 2,
          shadowColor: VoetjeColors.primary.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(VoetjeRadius.card),
          ),
        ),
        child: Text(
          label,
          style: VoetjeTypography.buttonLabel(),
        ),
      ),
    );
  }
}

class _BinSelectionStep extends StatelessWidget {
  final Set<BinType> selectedBins;
  final void Function(BinType) onToggle;
  final VoidCallback onNext;

  const _BinSelectionStep({
    required this.selectedBins,
    required this.onToggle,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(VoetjeSpacing.screenEdge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What bins do you have at home?',
            style: VoetjeTypography.pageQuestion(),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap all that apply.',
            style: VoetjeTypography.body()
                .copyWith(color: VoetjeColors.textMuted),
          ),
          const SizedBox(height: 20),
          ...BinType.values.map((bin) => _BinTile(
                bin: bin,
                selected: selectedBins.contains(bin),
                onTap: () => onToggle(bin),
              )),
          const SizedBox(height: 28),
          _GreenPillButton(
            label: 'Next →',
            onPressed: selectedBins.isNotEmpty ? onNext : null,
          ),
        ],
      ),
    );
  }
}

class _BinTile extends StatelessWidget {
  final BinType bin;
  final bool selected;
  final VoidCallback onTap;

  const _BinTile({
    required this.bin,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: selected
                  ? VoetjeColors.primaryMedium
                  : VoetjeColors.border,
              width: selected ? 2 : 1.5,
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
          child: Row(
            children: [
              Icon(bin.icon, size: 24, color: VoetjeColors.primaryMedium),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  bin.label,
                  style: VoetjeTypography.caption().copyWith(
                        fontWeight: FontWeight.w600,
                        color: VoetjeColors.textPrimary,
                      ),
                ),
              ),
              Icon(
                selected
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
                color: selected
                    ? VoetjeColors.primaryMedium
                    : VoetjeColors.border,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HousingTypeStep extends StatelessWidget {
  final HousingType selected;
  final void Function(HousingType) onSelect;
  final VoidCallback onDone;

  const _HousingTypeStep({
    required this.selected,
    required this.onSelect,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(VoetjeSpacing.screenEdge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Do you have your own bins?',
            style: VoetjeTypography.pageQuestion(),
          ),
          const SizedBox(height: 6),
          Text(
            'This affects how we estimate your weekly waste.',
            style: VoetjeTypography.body()
                .copyWith(color: VoetjeColors.textMuted),
          ),
          const SizedBox(height: 20),
          ...HousingType.values.map((h) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => onSelect(h),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: selected == h
                            ? VoetjeColors.primaryMedium
                            : VoetjeColors.border,
                        width: selected == h ? 2 : 1.5,
                      ),
                      borderRadius:
                          BorderRadius.circular(VoetjeRadius.input),
                      boxShadow: const [
                        BoxShadow(
                          color: VoetjeColors.shadowLight,
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(h.icon, size: 28, color: VoetjeColors.primaryMedium),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            h.label,
                            style: VoetjeTypography.caption().copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: VoetjeColors.textPrimary,
                                ),
                          ),
                        ),
                        Icon(
                          selected == h
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: selected == h
                              ? VoetjeColors.primaryMedium
                              : VoetjeColors.border,
                        ),
                      ],
                    ),
                  ),
                ),
              )),
          const SizedBox(height: 28),
          _GreenPillButton(label: 'Done', onPressed: onDone),
        ],
      ),
    );
  }
}
