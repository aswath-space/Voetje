import 'package:flutter_test/flutter_test.dart';
import 'package:carbon_tracker/data/item_catalog.dart';
import 'package:carbon_tracker/models/shopping_item.dart';
import 'package:carbon_tracker/services/shopping_calculator.dart';

void main() {
  late ShoppingItem phone;

  setUp(() {
    phone = ItemCatalog.electronics.firstWhere((i) => i.name == 'Smartphone');
  });

  test('new phone = 70 kg',
      () => expect(ShoppingCalculator.co2(phone, ShoppingCondition.newItem), 70.0));

  test('second-hand phone = 7.0 kg (70 × 0.10)', () =>
      expect(ShoppingCalculator.co2(phone, ShoppingCondition.secondHand),
          closeTo(7.0, 0.01)));

  test('repaired phone = 3.5 kg (70 × 0.05)', () =>
      expect(ShoppingCalculator.co2(phone, ShoppingCondition.repaired),
          closeTo(3.5, 0.01)));

  test('savings new→secondHand = 63 kg', () =>
      expect(ShoppingCalculator.savedVsNew(phone, ShoppingCondition.secondHand),
          closeTo(63.0, 0.01)));

  test('savings new→new = 0', () =>
      expect(ShoppingCalculator.savedVsNew(phone, ShoppingCondition.newItem),
          closeTo(0, 0.001)));

  test('drivingEquivalent: 70 kg / 0.171 ≈ 409 km', () =>
      expect(ShoppingCalculator.drivingEquivalent(70.0), closeTo(409, 1)));

  test('beefMealsEquivalent: 70 kg / 3.3 ≈ 21 meals', () =>
      expect(ShoppingCalculator.beefMealsEquivalent(70.0), closeTo(21, 1)));
}
