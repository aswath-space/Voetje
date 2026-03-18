import 'package:carbon_tracker/models/meal_type.dart';

class FoodCalculator {
  /// Total weekly CO2 from a diet profile (all values in number of meals/week).
  static double weeklyProfileCO2({
    required int plantBased,
    required int chickenOrFish,
    required int inBetween,
    required int redMeat,
    required int fastFood,
  }) {
    return plantBased * MealType.plantBased.co2Kg +
        chickenOrFish * MealType.chickenOrFish.co2Kg +
        inBetween * MealType.inBetween.co2Kg +
        redMeat * MealType.redMeat.co2Kg +
        fastFood * MealType.fastFood.co2Kg;
  }

  /// Meals not explicitly assigned in the profile.
  /// These are assumed to be "in between" (1.5 kg).
  /// Total meals/week assumed to be 21 (3 per day).
  static int remainingMeals({
    required int plant,
    required int chicken,
    required int between,
    required int red,
    required int fast,
  }) {
    return (21 - plant - chicken - between - red - fast).clamp(0, 21);
  }
}
