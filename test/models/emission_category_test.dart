// test/models/emission_category_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:carbon_tracker/models/emission_entry.dart';

void main() {
  test('EmissionCategory has all 5 values', () {
    expect(EmissionCategory.values.length, 5);
    expect(EmissionCategory.food.label, 'Food');
    expect(EmissionCategory.food.emoji, '🍽️');
    expect(EmissionCategory.energy.label, 'Home Energy');
    expect(EmissionCategory.shopping.emoji, '🛍️');
    expect(EmissionCategory.waste.emoji, '♻️');
  });
}
