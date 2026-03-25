import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carbon_tracker/config/design_tokens.dart';
import 'package:carbon_tracker/providers/emission_provider.dart';
import 'package:carbon_tracker/data/country_defaults.dart';
import 'package:carbon_tracker/screens/diet_profile_screen.dart';
import 'package:carbon_tracker/screens/energy_setup_screen.dart';
import 'package:carbon_tracker/screens/saved_places_screen.dart';
import 'package:carbon_tracker/screens/support_screen.dart';
import 'package:carbon_tracker/screens/data_sources_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<EmissionProvider, ({
      String unit,
      bool food,
      int dietPlant,
      int dietChicken,
      int dietRed,
      bool energy,
      String? energyCountry,
      List<String> heatingTypeLabels,
      bool shopping,
      bool waste,
      int wasteBinCount,
      int placesCount,
    })>(
      selector: (_, p) => (
        unit: p.preferredUnit,
        food: p.foodEnabled,
        dietPlant: p.dietPlant,
        dietChicken: p.dietChicken,
        dietRed: p.dietRed,
        energy: p.energyEnabled,
        energyCountry: p.energyProfile?.countryCode,
        heatingTypeLabels: p.energyProfile?.heatingTypes
                .where((h) => h.name != 'notSure')
                .map((h) => h.label)
                .toList() ??
            [],
        shopping: p.shoppingEnabled,
        waste: p.wasteEnabled,
        wasteBinCount: p.wasteSetup?.enabledBins.length ?? 0,
        placesCount: p.savedPlaces.length,
      ),
      builder: (context, s, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: EdgeInsets.fromLTRB(
              VoetjeSpacing.screenEdge,
              VoetjeSpacing.sectionGap,
              VoetjeSpacing.screenEdge,
              MediaQuery.of(context).padding.bottom + 32,
            ),
            children: [
              // ── Card 1: YOUR PROFILE ────────────────────────────────
              const _SectionLabel('YOUR PROFILE'),
              const SizedBox(height: 8),
              _SettingsCard(
                children: [
                  // Distance unit — inline segmented control
                  _RowItem(
                    icon: Icons.straighten,
                    label: 'Distance unit',
                    trailing: _UnitSegmentedControl(
                      value: s.unit,
                      onChanged: (v) => context
                          .read<EmissionProvider>()
                          .setPreferredUnit(v),
                    ),
                  ),

                  if (s.food) ...[
                    const _RowDivider(),
                    _RowItem(
                      icon: Icons.restaurant,
                      label: 'Diet profile',
                      subtitle:
                          '${s.dietPlant} plant, ${s.dietChicken} chicken, ${s.dietRed} red meat',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DietProfileScreen(),
                        ),
                      ),
                    ),
                  ],

                  if (s.energy) ...[
                    const _RowDivider(),
                    _RowItem(
                      icon: Icons.bolt,
                      label: 'Energy profile',
                      subtitle: _energySubtitle(s.energyCountry, s.heatingTypeLabels),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EnergySetupScreen(),
                        ),
                      ),
                    ),
                  ],

                  const _RowDivider(),
                  _RowItem(
                    icon: Icons.location_on,
                    label: 'Saved places',
                    subtitle: s.placesCount == 0
                        ? 'None saved'
                        : '${s.placesCount} place${s.placesCount == 1 ? '' : 's'}',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SavedPlacesScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VoetjeSpacing.sectionGap),

              // ── Card 2: CATEGORIES ──────────────────────────────────
              const _SectionLabel('CATEGORIES'),
              const SizedBox(height: 8),
              _SettingsCard(
                children: [
                  const _CategoryRow(
                    category: 'transport',
                    icon: Icons.directions_car,
                    label: 'Transport',
                    alwaysOn: true,
                  ),
                  const _RowDivider(),
                  _CategoryRow(
                    category: 'food',
                    icon: Icons.restaurant,
                    label: 'Food',
                    value: s.food,
                    onChanged: (v) {
                      final provider = context.read<EmissionProvider>();
                      v ? provider.enableFood() : provider.disableFood();
                    },
                  ),
                  const _RowDivider(),
                  _CategoryRow(
                    category: 'energy',
                    icon: Icons.bolt,
                    label: 'Energy',
                    value: s.energy,
                    onChanged: (v) {
                      final provider = context.read<EmissionProvider>();
                      v ? provider.enableEnergy() : provider.disableEnergy();
                    },
                  ),
                  const _RowDivider(),
                  _CategoryRow(
                    category: 'shopping',
                    icon: Icons.shopping_bag,
                    label: 'Shopping',
                    value: s.shopping,
                    onChanged: (v) {
                      final provider = context.read<EmissionProvider>();
                      v ? provider.enableShopping() : provider.disableShopping();
                    },
                  ),
                  const _RowDivider(),
                  _CategoryRow(
                    category: 'waste',
                    icon: Icons.recycling,
                    label: 'Waste',
                    value: s.waste,
                    onChanged: (v) {
                      final provider = context.read<EmissionProvider>();
                      v ? provider.enableWaste() : provider.disableWaste();
                    },
                  ),
                ],
              ),
              const SizedBox(height: VoetjeSpacing.sectionGap),

              // ── Card 3: DATA ────────────────────────────────────────
              const _SectionLabel('DATA'),
              const SizedBox(height: 8),
              _SettingsCard(
                children: [
                  _RowItem(
                    icon: Icons.download,
                    label: 'Export',
                    onTap: () => _exportData(context),
                  ),
                  const _RowDivider(),
                  _RowItem(
                    icon: Icons.upload,
                    label: 'Import',
                    onTap: () => _importData(context),
                  ),
                  const _RowDivider(),
                  _RowItem(
                    icon: Icons.delete_outline,
                    label: 'Clear all data',
                    iconColor: VoetjeColors.destructive,
                    labelColor: VoetjeColors.destructive,
                    onTap: () => _clearData(context),
                  ),
                  Divider(
                    color: VoetjeColors.dividerOf(context),
                    height: 16,
                    thickness: 1,
                  ),
                  _RowItem(
                    icon: Icons.info_outline,
                    label: 'About Our Data',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DataSourcesScreen(),
                      ),
                    ),
                  ),
                  const _RowDivider(),
                  _RowItem(
                    icon: Icons.favorite_outline,
                    label: 'Support This Project',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SupportScreen()),
                    ),
                  ),
                  const _RowDivider(),
                  const _RowItem(
                    icon: Icons.info_outline,
                    label: 'About Voetje',
                    trailing: Text(
                      'v1.0.0',
                      style: TextStyle(
                        fontSize: 13,
                        color: VoetjeColors.captionColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _energySubtitle(String? countryCode, List<String> heatingLabels) {
    final country = CountryDefaults.nameForCode(countryCode ?? '');
    if (heatingLabels.isEmpty) return country;
    final heating = heatingLabels.length == 1
        ? heatingLabels.first
        : '${heatingLabels.length} heating types';
    return '$country · $heating';
  }

  Future<void> _exportData(BuildContext context) async {
    final provider = context.read<EmissionProvider>();
    try {
      final summary = await provider.syncService.getDataSummary();
      if (!context.mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Export Data'),
          content: Text(
            'Export ${summary['entryCount']} entries (${summary['sizeKB']} KB) '
            'as a JSON file?\n\n'
            'You can save it to Google Drive, OneDrive, or share it '
            'however you like.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Export'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await provider.syncService.shareExport();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context) async {
    final provider = context.read<EmissionProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text(
          'Select a Voetje backup file (.json) to import.\n\n'
          'New entries will be added alongside your existing data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Choose File'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final count = await provider.syncService.importData();
    if (!context.mounted) return;

    if (count > 0) {
      await provider.refreshData();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $count entries')),
      );
    } else if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Import failed — invalid file format')),
      );
    }
  }

  Future<void> _clearData(BuildContext context) async {
    final provider = context.read<EmissionProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all your emission entries and habit history. '
          'Your tracking setup (energy profile, waste bins) will be kept.\n\n'
          'Consider exporting a backup first. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: VoetjeColors.destructive),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.db.clearAll();
      await provider.refreshData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared')),
        );
      }
    }
  }
}

// ── Private widgets ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(text, style: VoetjeTypography.sectionLabel().copyWith(
        color: VoetjeColors.labelColorOf(context),
      )),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: VoetjeColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(VoetjeRadius.card + 2),
        boxShadow: const [
          BoxShadow(
            color: VoetjeColors.shadowLight,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: VoetjeColors.dividerOf(context),
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
    );
  }
}

class _RowItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _RowItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? VoetjeColors.textMutedOf(context);
    final effectiveLabelColor = labelColor ?? VoetjeColors.textPrimaryOf(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: VoetjeIconSize.smallIcon, color: effectiveIconColor),
            const SizedBox(width: VoetjeSpacing.iconTextGap),
            Expanded(
              child: subtitle != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: effectiveLabelColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(subtitle!, style: VoetjeTypography.caption().copyWith(
                          color: VoetjeColors.captionColorOf(context),
                        )),
                      ],
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: effectiveLabelColor,
                      ),
                    ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ] else if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right,
                  size: VoetjeIconSize.smallIcon, color: VoetjeColors.borderOf(context)),
            ],
          ],
        ),
      ),
    );
  }
}

class _UnitSegmentedControl extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _UnitSegmentedControl({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: VoetjeColors.backgroundOf(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['km', 'mi'].map((seg) {
          final selected = value == seg;
          return GestureDetector(
            onTap: () => onChanged(seg),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: selected ? VoetjeColors.primaryOf(context) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                seg,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? VoetjeColors.surfaceOf(context) : VoetjeColors.textMutedOf(context),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String category;
  final IconData icon;
  final String label;
  final bool alwaysOn;
  final bool? value;
  final ValueChanged<bool>? onChanged;

  const _CategoryRow({
    required this.category,
    required this.icon,
    required this.label,
    this.alwaysOn = false,
    this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: VoetjeIconSize.smallContainer,
            height: VoetjeIconSize.smallContainer,
            decoration: BoxDecoration(
              color: VoetjeColors.categoryBackgroundOf(context, category),
              borderRadius: BorderRadius.circular(VoetjeIconSize.smallRadius),
            ),
            child: Icon(
              icon,
              size: VoetjeIconSize.smallIcon,
              color: VoetjeColors.categoryColor(category),
            ),
          ),
          const SizedBox(width: VoetjeSpacing.iconTextGap),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: VoetjeColors.textPrimaryOf(context),
              ),
            ),
          ),
          if (alwaysOn)
            Text(
              'Always on',
              style: TextStyle(
                fontSize: 12,
                color: VoetjeColors.captionColorOf(context),
              ),
            )
          else
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: value ?? false,
                onChanged: onChanged,
              ),
            ),
        ],
      ),
    );
  }
}
