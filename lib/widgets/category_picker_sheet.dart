import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carbon_tracker/config/design_tokens.dart';

/// A bottom sheet that lets the user pick which emission category to log.
///
/// Designed to be shown via [showModalBottomSheet]. Tapping a tile pops the
/// sheet with the selected category key (e.g. "transport", "food"). The caller
/// is responsible for navigating to the appropriate screen.
///
/// Transport is always shown. The other categories are controlled by the
/// boolean flags [foodEnabled], [energyEnabled], [shoppingEnabled], and
/// [wasteEnabled].
class CategoryPickerSheet extends StatelessWidget {
  final bool foodEnabled;
  final bool energyEnabled;
  final bool shoppingEnabled;
  final bool wasteEnabled;

  const CategoryPickerSheet({
    super.key,
    required this.foodEnabled,
    required this.energyEnabled,
    required this.shoppingEnabled,
    required this.wasteEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final categories = <_Category>[
      const _Category(
        key: 'transport',
        label: 'Transport',
        icon: Icons.directions_bike,
      ),
      if (foodEnabled)
        const _Category(
          key: 'food',
          label: 'Food',
          icon: Icons.restaurant,
        ),
      if (energyEnabled)
        const _Category(
          key: 'energy',
          label: 'Energy',
          icon: Icons.bolt,
        ),
      if (shoppingEnabled)
        const _Category(
          key: 'shopping',
          label: 'Shopping',
          icon: Icons.shopping_bag,
        ),
      if (wasteEnabled)
        const _Category(
          key: 'waste',
          label: 'Waste',
          icon: Icons.recycling,
        ),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: VoetjeColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              'What are you logging?',
              style: VoetjeTypography.sectionHeader(),
            ),
            const SizedBox(height: 16),
            // 2-column grid of category tiles
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: categories.map((cat) {
                return _CategoryTile(
                  category: cat,
                  onTap: () => Navigator.pop(context, cat.key),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Category {
  final String key;
  final String label;
  final IconData icon;

  const _Category({
    required this.key,
    required this.label,
    required this.icon,
  });
}

class _CategoryTile extends StatelessWidget {
  final _Category category;
  final VoidCallback onTap;

  const _CategoryTile({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final iconBg = VoetjeColors.categoryBackground(category.key);
    final iconColor = VoetjeColors.categoryColor(category.key);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: VoetjeColors.border,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    category.icon,
                    size: 18,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  category.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: VoetjeColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
