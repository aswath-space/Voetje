// test/models/meal_type_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:carbon_tracker/models/meal_type.dart';

void main() {
  group('MealType', () {
    test('plantBased factor is 0.5 kg', () => expect(MealType.plantBased.co2Kg, 0.5));
    test('chickenOrFish factor is 1.0 kg', () => expect(MealType.chickenOrFish.co2Kg, 1.0));
    test('inBetween factor is 1.5 kg', () => expect(MealType.inBetween.co2Kg, 1.5));
    test('redMeat factor is 3.3 kg', () => expect(MealType.redMeat.co2Kg, 3.3));
    test('fastFood factor is 2.5 kg', () => expect(MealType.fastFood.co2Kg, 2.5));
    test('snack factor is 0.2 kg', () => expect(MealType.snack.co2Kg, 0.2));
    test('all meal types have non-empty labels', () {
      for (final m in MealType.values) {
        expect(m.label, isNotEmpty);
      }
    });
  });

  group('MealSlot.slotForTime', () {
    test('7am → breakfast', () =>
        expect(MealSlot.slotForTime(DateTime(2026, 1, 1, 7)), MealSlot.breakfast));
    test('12pm → lunch', () =>
        expect(MealSlot.slotForTime(DateTime(2026, 1, 1, 12)), MealSlot.lunch));
    test('18pm → dinner', () =>
        expect(MealSlot.slotForTime(DateTime(2026, 1, 1, 18)), MealSlot.dinner));
    test('22pm → snack', () =>
        expect(MealSlot.slotForTime(DateTime(2026, 1, 1, 22)), MealSlot.snack));
    test('3am → snack', () =>
        expect(MealSlot.slotForTime(DateTime(2026, 1, 1, 3)), MealSlot.snack));
  });
}
