// test/services/food_calculator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:carbon_tracker/services/food_calculator.dart';

void main() {
  group('FoodCalculator', () {
    test('all plant-based week: 21 × 0.5 = 10.5 kg', () {
      expect(
        FoodCalculator.weeklyProfileCO2(plantBased: 21, chickenOrFish: 0, inBetween: 0, redMeat: 0, fastFood: 0),
        closeTo(10.5, 0.001),
      );
    });

    test('mixed week calculates correctly', () {
      // 7×0.5 + 5×1.0 + 4×1.5 + 3×3.3 + 2×2.5 = 3.5+5+6+9.9+5 = 29.4
      expect(
        FoodCalculator.weeklyProfileCO2(plantBased: 7, chickenOrFish: 5, inBetween: 4, redMeat: 3, fastFood: 2),
        closeTo(29.4, 0.001),
      );
    });

    test('remainingMeals: 7+5+4+3+2=21 → 0 remaining', () {
      expect(
        FoodCalculator.remainingMeals(plant: 7, chicken: 5, between: 4, red: 3, fast: 2),
        0,
      );
    });

    test('remainingMeals: 7+5+0+0+0=12 → 9 remaining', () {
      expect(
        FoodCalculator.remainingMeals(plant: 7, chicken: 5, between: 0, red: 0, fast: 0),
        9,
      );
    });
  });
}
