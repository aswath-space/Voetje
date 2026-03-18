import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carbon_tracker/config/design_tokens.dart';
import 'package:carbon_tracker/data/item_catalog.dart';
import 'package:carbon_tracker/models/emission_entry.dart';
import 'package:carbon_tracker/models/shopping_item.dart';
import 'package:carbon_tracker/providers/emission_provider.dart';
import 'package:carbon_tracker/screens/second_hand_celebration_screen.dart';
import 'package:carbon_tracker/services/shopping_calculator.dart';

class AddShoppingScreen extends StatefulWidget {
  const AddShoppingScreen({super.key});

  @override
  State<AddShoppingScreen> createState() => _AddShoppingScreenState();
}

class _AddShoppingScreenState extends State<AddShoppingScreen> {
  final _searchCtrl = TextEditingController();
  ShoppingItem? _selectedItem;
  ShoppingCondition _condition = ShoppingCondition.newItem;
  ShoppingCategory? _browsedCategory;
  List<ShoppingItem> _searchResults = ItemCatalog.all;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchResults = ItemCatalog.search(_searchCtrl.text);
      _browsedCategory = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedItem != null) return _buildDetailView(context);
    return _buildBrowseView(context);
  }

  Widget _buildBrowseView(BuildContext context) {
    return Scaffold(
      backgroundColor: VoetjeColors.background,
      appBar: AppBar(
        title: Text('Log a Purchase', style: VoetjeTypography.pageTitle()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(children: [
        // Search field
        Padding(
          padding: const EdgeInsets.fromLTRB(
              VoetjeSpacing.screenEdge, 8, VoetjeSpacing.screenEdge, 8),
          child: TextField(
            controller: _searchCtrl,
            autofocus: true,
            style: VoetjeTypography.body(),
            decoration: InputDecoration(
              hintText: 'Search: "jeans", "phone"...',
              hintStyle: VoetjeTypography.caption().copyWith(
                    fontSize: 13,
                    color: VoetjeColors.textMuted,
                  ),
              prefixIcon:
                  const Icon(Icons.search, color: VoetjeColors.textMuted),
              filled: true,
              fillColor: VoetjeColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(VoetjeRadius.input),
                borderSide: const BorderSide(
                    color: VoetjeColors.border, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(VoetjeRadius.input),
                borderSide: const BorderSide(
                    color: VoetjeColors.border, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(VoetjeRadius.input),
                borderSide: const BorderSide(
                    color: VoetjeColors.primaryMedium, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          color: VoetjeColors.textMuted),
                      onPressed: () => _searchCtrl.clear())
                  : null,
            ),
          ),
        ),

        if (_searchCtrl.text.isEmpty) ...[
          // Category filter chips
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: VoetjeSpacing.screenEdge),
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ShoppingCategory.values
                    .map((cat) {
                      final isSelected = _browsedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _browsedCategory = isSelected ? null : cat;
                            _searchResults = isSelected
                                ? ItemCatalog.all
                                : ItemCatalog.byCategory(cat);
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? VoetjeColors.primary
                                  : VoetjeColors.surface,
                              borderRadius:
                                  BorderRadius.circular(VoetjeRadius.chip),
                              border: Border.all(
                                color: isSelected
                                    ? VoetjeColors.primary
                                    : VoetjeColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  cat.icon,
                                  size: 14,
                                  color: isSelected
                                      ? VoetjeColors.surface
                                      : VoetjeColors.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  cat.label,
                                  style: VoetjeTypography.caption().copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? VoetjeColors.surface
                                        : VoetjeColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    })
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
                horizontal: VoetjeSpacing.screenEdge),
            itemCount: _searchResults.length + 1, // +1 for "Other / Custom"
            itemBuilder: (ctx, i) {
              if (i == _searchResults.length) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ItemCard(
                    icon: Icons.edit_outlined,
                    name: 'Other / Custom item',
                    subtitle: 'Enter a custom item',
                    categoryLabel: '',
                    onTap: () =>
                        setState(() => _selectedItem = const ShoppingItem(
                              name: 'Custom item',
                              co2KgNew: 30.0,
                              icon: Icons.category_outlined,
                              category: ShoppingCategory.other,
                            )),
                  ),
                );
              }
              final item = _searchResults[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ItemCard(
                  icon: item.icon,
                  name: item.name,
                  subtitle:
                      '${item.co2KgNew.toStringAsFixed(0)} kg CO₂ (new)',
                  categoryLabel: item.category.label,
                  onTap: () => setState(() => _selectedItem = item),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildDetailView(BuildContext context) {
    final item = _selectedItem!;
    final saved = ShoppingCalculator.savedVsNew(item, _condition);
    final drivingKm = ShoppingCalculator.drivingEquivalent(item.co2KgNew);
    final beefMeals = ShoppingCalculator.beefMealsEquivalent(item.co2KgNew);

    return Scaffold(
      backgroundColor: VoetjeColors.background,
      appBar: AppBar(
        title: Text(item.name, style: VoetjeTypography.pageTitle()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
            onPressed: () => setState(() {
                  _selectedItem = null;
                  _condition = ShoppingCondition.newItem;
                })),
      ),
      body: Padding(
        padding: const EdgeInsets.all(VoetjeSpacing.screenEdge),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Impact card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(VoetjeRadius.card),
                  boxShadow: const [
                    BoxShadow(
                      color: VoetjeColors.shadowLight,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    )
                  ],
                ),
                padding:
                    const EdgeInsets.all(VoetjeSpacing.cardPadding + 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'NEW ${item.name} = ${item.co2KgNew.toStringAsFixed(0)} kg CO₂',
                        style: VoetjeTypography.bodyEmphasis().copyWith(
                              fontWeight: FontWeight.w700,
                            )),
                    const SizedBox(height: 8),
                    Text('That\'s the same as:',
                        style: VoetjeTypography.caption()),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.directions_car_outlined, size: 16, color: VoetjeColors.textMuted),
                      const SizedBox(width: 6),
                      Text('Driving ${drivingKm.toStringAsFixed(0)} km', style: VoetjeTypography.body()),
                    ]),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.lunch_dining, size: 16, color: VoetjeColors.textMuted),
                      const SizedBox(width: 6),
                      Text('${beefMeals.toStringAsFixed(0)} beef meals', style: VoetjeTypography.body()),
                    ]),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.smartphone_outlined, size: 16, color: VoetjeColors.textMuted),
                      const SizedBox(width: 6),
                      Text('${(item.co2KgNew / 0.008).toStringAsFixed(0)} smartphone charges', style: VoetjeTypography.body()),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('WAS THIS...',
                  style: VoetjeTypography.sectionLabel()),
              const SizedBox(height: 10),

              // Condition selector
              Row(
                children: ShoppingCondition.values
                    .where((c) => c != ShoppingCondition.repaired)
                    .map((c) {
                  final isSelected = _condition == c;
                  final isSecondHand = c == ShoppingCondition.secondHand;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => setState(() => _condition = c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isSecondHand
                                    ? VoetjeColors.primary
                                    : VoetjeColors.primary)
                                : VoetjeColors.surface,
                            borderRadius:
                                BorderRadius.circular(VoetjeRadius.card),
                            border: Border.all(
                              color: isSelected
                                  ? VoetjeColors.primary
                                  : VoetjeColors.border,
                              width: isSelected ? 2 : 1.5,
                            ),
                          ),
                          child: Column(children: [
                            Icon(
                              c == ShoppingCondition.newItem
                                  ? Icons.new_releases_outlined
                                  : Icons.recycling,
                              size: 22,
                              color: isSelected
                                  ? VoetjeColors.surface
                                  : VoetjeColors.textPrimary,
                            ),
                            const SizedBox(height: 4),
                            Text(c.label,
                                style: VoetjeTypography.caption().copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? VoetjeColors.surface
                                          : VoetjeColors.textPrimary,
                                    )),
                            Text(
                                '${ShoppingCalculator.co2(item, c).toStringAsFixed(1)} kg',
                                style: VoetjeTypography.caption().copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: isSelected
                                          ? VoetjeColors.surface
                                          : VoetjeColors.textPrimary,
                                    )),
                          ]),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              if (saved > 0) ...[
                const SizedBox(height: 10),
                Text(
                    'Choosing second-hand saves ${saved.toStringAsFixed(1)} kg CO₂!',
                    style: VoetjeTypography.caption().copyWith(
                          color: VoetjeColors.primaryMedium,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        )),
              ],

              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: Text(
                    'Log ${item.name} (${_condition.label})',
                    style: VoetjeTypography.buttonLabel(),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VoetjeColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor:
                        VoetjeColors.primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(VoetjeRadius.card),
                    ),
                  ),
                  onPressed: _save,
                ),
              ),
            ]),
      ),
    );
  }

  Future<void> _save() async {
    final item = _selectedItem!;
    final provider = context.read<EmissionProvider>();
    final entry = EmissionEntry.shopping(
      date: DateTime.now(),
      item: item,
      condition: _condition,
    );
    await provider.addEntry(entry);

    if (!mounted) return;

    if (_condition == ShoppingCondition.secondHand) {
      final savings = ShoppingCalculator.savedVsNew(item, _condition);
      final lifetimeSavings = provider.lifetimeSecondHandSavings;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => SecondHandCelebrationScreen(
                  itemName: item.name,
                  savedCO2: savings,
                  lifetimeSavings: lifetimeSavings,
                )),
      );
    } else {
      Navigator.pop(context);
    }
  }
}

// ─── Item card widget ─────────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final String subtitle;
  final String categoryLabel;
  final VoidCallback onTap;

  const _ItemCard({
    required this.icon,
    required this.name,
    required this.subtitle,
    required this.categoryLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: VoetjeColors.surface,
          borderRadius: BorderRadius.circular(VoetjeRadius.card),
          boxShadow: const [
            BoxShadow(
              color: VoetjeColors.shadowLight,
              blurRadius: 3,
              offset: Offset(0, 1),
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: VoetjeColors.background,
                borderRadius:
                    BorderRadius.circular(VoetjeRadius.iconContainer),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 22, color: VoetjeColors.textMuted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: VoetjeTypography.body()),
                  const SizedBox(height: 2),
                  Text(subtitle, style: VoetjeTypography.caption()),
                ],
              ),
            ),
            if (categoryLabel.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: VoetjeColors.background,
                  borderRadius:
                      BorderRadius.circular(VoetjeRadius.chip),
                ),
                child: Text(
                  categoryLabel,
                  style: VoetjeTypography.sectionLabel().copyWith(
                        fontSize: 10,
                        letterSpacing: 0,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
