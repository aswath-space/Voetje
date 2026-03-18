import 'package:flutter/material.dart';
import 'package:carbon_tracker/models/transport_mode.dart';
import 'package:carbon_tracker/models/meal_type.dart';
import 'package:carbon_tracker/models/shopping_item.dart';
import 'package:carbon_tracker/models/waste_setup.dart';

/// Represents a single CO2 emission entry.
/// Currently transport-only; designed to extend to food, energy, etc.
class EmissionEntry {
  final int? id;
  final DateTime date;
  final EmissionCategory category;
  final String subCategory; // e.g., transport mode name
  final double value; // distance in km (for transport)
  final double co2Kg; // calculated CO2 in kg
  final String? note;
  final int passengers; // for carpooling calculations
  final DateTime createdAt;

  EmissionEntry({
    this.id,
    required this.date,
    required this.category,
    required this.subCategory,
    required this.value,
    required this.co2Kg,
    this.note,
    this.passengers = 1,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create from a transport trip.
  /// Pass [countryCode] for electric car entries to use local grid intensity.
  factory EmissionEntry.transport({
    int? id,
    required DateTime date,
    required TransportMode mode,
    required double distanceKm,
    int passengers = 1,
    String? note,
    String? countryCode,
  }) {
    return EmissionEntry(
      id: id,
      date: date,
      category: EmissionCategory.transport,
      subCategory: mode.name,
      value: distanceKm,
      co2Kg: mode.calculateCO2(distanceKm, passengers: passengers, countryCode: countryCode),
      passengers: passengers,
      note: note,
    );
  }

  /// Create from a food/meal log
  factory EmissionEntry.food({
    int? id,
    required DateTime date,
    required MealType mealType,
    required MealSlot slot,
    String? note,
  }) {
    return EmissionEntry(
      id: id,
      date: date,
      category: EmissionCategory.food,
      subCategory: mealType.name,
      value: 1.0,
      co2Kg: mealType.co2Kg,
      // Always prefix with slot label so TodaysMealsCard can identify the slot
      // even when the user has added a custom note.
      // Format: "Breakfast" (no note) or "Breakfast: homemade curry" (with note).
      note: note != null ? '${slot.label}: $note' : slot.label,
    );
  }

  /// Get the TransportMode enum from subCategory string
  TransportMode? get transportMode {
    if (category != EmissionCategory.transport) return null;
    try {
      return TransportMode.values.firstWhere((m) => m.name == subCategory);
    } catch (_) {
      return null;
    }
  }

  /// Create from a shopping purchase
  factory EmissionEntry.shopping({
    int? id,
    required DateTime date,
    required ShoppingItem item,
    required ShoppingCondition condition,
    String? note,
  }) {
    return EmissionEntry(
      id: id,
      date: date,
      category: EmissionCategory.shopping,
      subCategory: '${item.name}__${condition.name}',
      value: item.co2KgNew, // preserve new-item price for savings calculation
      co2Kg: item.co2Kg(condition),
      note: note,
    );
  }

  /// Create from a weekly waste bin log.
  /// [kgWeight] is the estimated kg of waste; [co2Kg] = kgWeight × binType.co2PerKg.
  factory EmissionEntry.waste({
    int? id,
    required DateTime date,
    required BinType binType,
    required double kgWeight,
    String? note,
  }) {
    return EmissionEntry(
      id: id,
      date: date,
      category: EmissionCategory.waste,
      subCategory: binType.name,
      value: kgWeight,
      co2Kg: kgWeight * binType.co2PerKg,
      note: note,
    );
  }

  /// Get the BinType from subCategory (for waste entries).
  BinType? get binType {
    if (category != EmissionCategory.waste) return null;
    try {
      return BinType.values.firstWhere((b) => b.name == subCategory);
    } catch (_) {
      return null;
    }
  }

  /// Parse shopping item name and condition from subCategory.
  /// subCategory format: "Smartphone__secondHand"
  (String itemName, ShoppingCondition condition)? get shoppingDetails {
    if (category != EmissionCategory.shopping) return null;
    final parts = subCategory.split('__');
    if (parts.length != 2) return null;
    try {
      final cond =
          ShoppingCondition.values.firstWhere((c) => c.name == parts[1]);
      return (parts[0], cond);
    } catch (_) {
      return null;
    }
  }

  /// Get the MealType from subCategory (for food entries).
  MealType? get mealType {
    if (category != EmissionCategory.food) return null;
    try {
      return MealType.values.firstWhere((m) => m.name == subCategory);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date.toIso8601String(),
      'category': category.name,
      'sub_category': subCategory,
      'value': value,
      'co2_kg': co2Kg,
      'note': note,
      'passengers': passengers,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory EmissionEntry.fromMap(Map<String, dynamic> map) {
    return EmissionEntry(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      category: EmissionCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => EmissionCategory.transport,
      ),
      subCategory: map['sub_category'] as String,
      value: (map['value'] as num).toDouble(),
      co2Kg: (map['co2_kg'] as num).toDouble(),
      note: map['note'] as String?,
      passengers: (map['passengers'] as int?) ?? 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// For JSON export/import (cloud sync)
  Map<String, dynamic> toJson() => toMap();

  factory EmissionEntry.fromJson(Map<String, dynamic> json) =>
      EmissionEntry.fromMap(json);

  EmissionEntry copyWith({
    int? id,
    DateTime? date,
    EmissionCategory? category,
    String? subCategory,
    double? value,
    double? co2Kg,
    String? note,
    int? passengers,
  }) {
    return EmissionEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      value: value ?? this.value,
      co2Kg: co2Kg ?? this.co2Kg,
      note: note ?? this.note,
      passengers: passengers ?? this.passengers,
      createdAt: createdAt,
    );
  }
}

/// Top-level emission categories.
/// Start with transport; more coming soon.
enum EmissionCategory {
  transport('Transport', Icons.directions_car_outlined),
  food('Food', Icons.restaurant),
  energy('Home Energy', Icons.bolt),
  shopping('Shopping', Icons.shopping_bag_outlined),
  waste('Waste', Icons.recycling);

  const EmissionCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}
