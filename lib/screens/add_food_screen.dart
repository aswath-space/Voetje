import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carbon_tracker/config/design_tokens.dart';
import 'package:carbon_tracker/models/meal_type.dart';
import 'package:carbon_tracker/models/emission_entry.dart';
import 'package:carbon_tracker/providers/emission_provider.dart';

class AddFoodScreen extends StatefulWidget {
  final MealSlot? initialSlot;
  const AddFoodScreen({super.key, this.initialSlot});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  late MealSlot _selectedSlot;
  MealType? _selectedMeal;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedSlot = widget.initialSlot ?? MealSlot.slotForTime(DateTime.now());
    if (_selectedSlot == MealSlot.snack) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _saveSnack());
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  bool _snackSaving = false;

  Future<void> _saveSnack() async {
    if (_snackSaving) return;
    _snackSaving = true;
    final provider = context.read<EmissionProvider>();
    final scaffoldMsg = ScaffoldMessenger.of(context);
    try {
      final entry = EmissionEntry.food(
        date: DateTime.now(),
        mealType: MealType.snack,
        slot: MealSlot.snack,
      );
      await provider.addEntry(entry);
      if (mounted) {
        scaffoldMsg.showSnackBar(
          SnackBar(
            content: Text(
              '🍪 Snack logged: ${MealType.snack.co2Kg} kg CO₂',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _snackSaving = false;
      if (mounted) {
        scaffoldMsg.showSnackBar(SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: VoetjeColors.destructive,
        ));
      }
    }
  }

  Future<void> _save() async {

    if (_selectedMeal == null) return;
    final provider = context.read<EmissionProvider>();
    final scaffoldMsg = ScaffoldMessenger.of(context);
    try {
      final entry = EmissionEntry.food(
        date: DateTime.now(),
        mealType: _selectedMeal!,
        slot: _selectedSlot,
        note: _noteController.text.isEmpty ? null : _noteController.text,
      );
      await provider.addEntry(entry);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        scaffoldMsg.showSnackBar(SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: VoetjeColors.destructive,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoetjeColors.background,
      appBar: AppBar(
        title: Text(
          'Log a Meal',
          style: VoetjeTypography.sectionHeader(),
        ),
        backgroundColor: VoetjeColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: VoetjeSpacing.screenEdge,
          vertical: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Meal slot chips ──────────────────────────────────────────
            Text('WHICH MEAL?', style: VoetjeTypography.sectionLabel()),
            const SizedBox(height: 10),
            Row(
              children: MealSlot.values.map((slot) {
                final isSelected = _selectedSlot == slot;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: slot != MealSlot.values.last ? 6 : 0,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        final wasSnack = _selectedSlot == MealSlot.snack;
                        setState(() => _selectedSlot = slot);
                        if (slot == MealSlot.snack && !wasSnack) {
                          _saveSnack();
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? VoetjeColors.primary
                              : VoetjeColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected
                              ? null
                              : Border.all(
                                  color: VoetjeColors.border, width: 1.5),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              slot.emoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              slot.label,
                              style: VoetjeTypography.caption().copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? VoetjeColors.surface
                                        : VoetjeColors.textMuted,
                                  ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── Meal type grid (only for non-snack slots) ────────────────
            if (_selectedSlot != MealSlot.snack) ...[
              Text('WHAT DID YOU EAT?', style: VoetjeTypography.sectionLabel()),
              const SizedBox(height: 10),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.5,
                children: [
                  MealType.plantBased,
                  MealType.chickenOrFish,
                  MealType.redMeat,
                  MealType.fastFood,
                ].map((meal) => _MealTypeCard(
                  meal: meal,
                  isSelected: _selectedMeal == meal,
                  onTap: () => setState(() => _selectedMeal = meal),
                )).toList(),
              ),

              const SizedBox(height: 8),

              // "Somewhere in between" option
              GestureDetector(
                onTap: () => setState(() => _selectedMeal = MealType.inBetween),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedMeal == MealType.inBetween
                        ? VoetjeColors.food.withValues(alpha: 0.07)
                        : VoetjeColors.surface,
                    border: Border.all(
                      color: _selectedMeal == MealType.inBetween
                          ? VoetjeColors.food
                          : VoetjeColors.border,
                      width: _selectedMeal == MealType.inBetween ? 2 : 1.5,
                    ),
                    borderRadius: BorderRadius.circular(VoetjeRadius.input),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        MealType.inBetween.icon,
                        color: MealType.inBetween.color,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Somewhere in between?  "Mostly veg with a bit of meat"',
                          style: VoetjeTypography.caption().copyWith(
                                fontSize: 12,
                                color: VoetjeColors.textSecondary,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Note field
              Container(
                decoration: BoxDecoration(
                  color: VoetjeColors.surface,
                  borderRadius: BorderRadius.circular(VoetjeRadius.input),
                  border: Border.all(
                      color: VoetjeColors.border, width: 1.5),
                ),
                child: TextField(
                  controller: _noteController,
                  style: VoetjeTypography.caption().copyWith(
                        fontSize: 13,
                        color: VoetjeColors.textPrimary,
                      ),
                  decoration: InputDecoration(
                    hintText: 'e.g. homemade vegan curry (optional)',
                    hintStyle: VoetjeTypography.caption().copyWith(
                          fontSize: 13,
                          color: VoetjeColors.textMuted,
                        ),
                    prefixIcon: const Icon(
                      Icons.note_alt_outlined,
                      color: VoetjeColors.textMuted,
                      size: 18,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _selectedMeal != null
                        ? [
                            BoxShadow(
                              color: VoetjeColors.primary
                                  .withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedMeal != null
                          ? VoetjeColors.primary
                          : VoetjeColors.border,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _selectedMeal != null ? _save : null,
                    child: Text(
                      'Save Meal',
                      style: VoetjeTypography.buttonLabel().copyWith(fontSize: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Meal type card ────────────────────────────────────────────────────────────

const Map<MealType, String> _mealDescriptions = {
  MealType.plantBased: 'Veg, legumes, tofu',
  MealType.chickenOrFish: 'Poultry, seafood, eggs',
  MealType.redMeat: 'Beef, pork, lamb',
  MealType.fastFood: 'Burgers, pizza, fried food',
};

class _MealTypeCard extends StatelessWidget {
  final MealType meal;
  final bool isSelected;
  final VoidCallback onTap;

  const _MealTypeCard({
    required this.meal,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? VoetjeColors.food.withValues(alpha: 0.07)
              : VoetjeColors.surface,
          border: Border.all(
            color: isSelected ? VoetjeColors.food : VoetjeColors.border,
            width: isSelected ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(VoetjeRadius.input),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(meal.icon, color: meal.color, size: 24),
            const SizedBox(height: 5),
            Text(
              meal.label,
              textAlign: TextAlign.center,
              style: VoetjeTypography.caption().copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: VoetjeColors.textPrimary,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              _mealDescriptions[meal] ?? '',
              textAlign: TextAlign.center,
              style: VoetjeTypography.caption().copyWith(
                    fontSize: 10,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
