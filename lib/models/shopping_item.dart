import 'package:flutter/material.dart';

enum ShoppingCondition {
  newItem('New', 1.0),
  secondHand('Second-hand', 0.10),
  repaired('Repaired', 0.05);

  const ShoppingCondition(this.label, this.multiplier);
  final String label;
  final double multiplier;
}

enum ShoppingCategory {
  clothing('Clothing', Icons.checkroom_outlined),
  electronics('Electronics', Icons.devices_outlined),
  furniture('Furniture', Icons.chair_outlined),
  other('Other', Icons.category_outlined);

  const ShoppingCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

class ShoppingItem {
  final String name;
  final double co2KgNew;
  final IconData icon;
  final ShoppingCategory category;
  final List<String> synonyms;

  const ShoppingItem({
    required this.name,
    required this.co2KgNew,
    required this.icon,
    required this.category,
    this.synonyms = const [],
  });

  /// CO2 for a given condition.
  double co2Kg(ShoppingCondition condition) => co2KgNew * condition.multiplier;

  /// Savings compared to buying new.
  double savedVsNew(ShoppingCondition condition) => co2KgNew - co2Kg(condition);
}
