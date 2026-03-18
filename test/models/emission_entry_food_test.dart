// test/models/emission_entry_food_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:carbon_tracker/models/emission_entry.dart';
import 'package:carbon_tracker/models/meal_type.dart';

void main() {
  group('EmissionEntry.food', () {
    final entry = EmissionEntry.food(
      date: DateTime(2026, 3, 13),
      mealType: MealType.redMeat,
      slot: MealSlot.dinner,
    );

    test('category is food', () => expect(entry.category, EmissionCategory.food));
    test('co2Kg is 3.3', () => expect(entry.co2Kg, 3.3));
    test('subCategory is meal type name', () => expect(entry.subCategory, 'redMeat'));
    test('value is 1.0 (one meal)', () => expect(entry.value, 1.0));
    test('note defaults to slot label', () => expect(entry.note, 'Dinner'));

    test('round-trips through toMap/fromMap', () {
      final map = entry.toMap();
      final restored = EmissionEntry.fromMap(map);
      expect(restored.category, EmissionCategory.food);
      expect(restored.co2Kg, 3.3);
    });
  });
}
