import 'package:flutter/material.dart';

enum MealType {
  plantBased('Plant-based', 0.5, Icons.eco, Color(0xFF4CAF50)),
  chickenOrFish('Chicken or fish', 1.0, Icons.set_meal, Color(0xFFFFC107)),
  inBetween('In between', 1.5, Icons.restaurant, Color(0xFFFF9800)),
  redMeat('Red meat', 3.3, Icons.lunch_dining, Color(0xFFF44336)),
  fastFood('Fast food', 2.5, Icons.fastfood, Color(0xFF795548)),
  snack('Snack', 0.2, Icons.cookie, Color(0xFF9E9E9E));

  const MealType(this.label, this.co2Kg, this.icon, this.color);
  final String label;
  final double co2Kg;
  final IconData icon;
  final Color color;
}

enum MealSlot {
  breakfast('Breakfast', '☀️'),
  lunch('Lunch', '🍱'),
  dinner('Dinner', '🌙'),
  snack('Snack', '🍪');

  const MealSlot(this.label, this.emoji);
  final String label;
  final String emoji;

  /// Returns the appropriate slot based on local time of day.
  static MealSlot slotForTime(DateTime time) {
    final h = time.hour;
    if (h >= 5 && h < 10) return MealSlot.breakfast;
    if (h >= 10 && h < 15) return MealSlot.lunch;
    if (h >= 15 && h < 21) return MealSlot.dinner;
    return MealSlot.snack;
  }
}
