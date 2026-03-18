import 'package:flutter_test/flutter_test.dart';
import 'package:carbon_tracker/data/item_catalog.dart';
import 'package:carbon_tracker/models/emission_entry.dart';
import 'package:carbon_tracker/models/shopping_item.dart';

void main() {
  late ShoppingItem phone;
  setUp(() =>
      phone = ItemCatalog.electronics.firstWhere((i) => i.name == 'Smartphone'));

  test('EmissionEntry.shopping new: co2Kg = 70, value = 70', () {
    final e = EmissionEntry.shopping(
        date: DateTime.now(), item: phone, condition: ShoppingCondition.newItem);
    expect(e.category, EmissionCategory.shopping);
    expect(e.co2Kg, 70.0);
    expect(e.value, 70.0);
    expect(e.subCategory, 'Smartphone__newItem');
  });

  test('EmissionEntry.shopping second-hand: co2Kg = 7.0, value = 70', () {
    final e = EmissionEntry.shopping(
        date: DateTime.now(),
        item: phone,
        condition: ShoppingCondition.secondHand);
    expect(e.co2Kg, closeTo(7.0, 0.01)); // 70 × 0.10
    expect(e.value, 70.0);
    expect(e.subCategory, 'Smartphone__secondHand');
  });

  test('savings = value - co2Kg', () {
    final e = EmissionEntry.shopping(
        date: DateTime.now(),
        item: phone,
        condition: ShoppingCondition.secondHand);
    expect(e.value - e.co2Kg, closeTo(63.0, 0.01)); // 70 - 7
  });
}
