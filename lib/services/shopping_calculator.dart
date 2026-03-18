import 'package:carbon_tracker/data/emission_factors.dart';
import 'package:carbon_tracker/models/meal_type.dart';
import 'package:carbon_tracker/models/shopping_item.dart';

class ShoppingCalculator {
  static double co2(ShoppingItem item, ShoppingCondition condition) =>
      item.co2Kg(condition);

  static double savedVsNew(ShoppingItem item, ShoppingCondition condition) =>
      item.savedVsNew(condition);

  /// How many km of car driving equals this CO2.
  static double drivingEquivalent(double co2Kg) =>
      co2Kg / EmissionFactors.avgCarKgPerKm;

  /// How many beef meals equal this CO2.
  static double beefMealsEquivalent(double co2Kg) =>
      co2Kg / MealType.redMeat.co2Kg;
}
