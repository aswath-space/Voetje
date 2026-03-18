// Waste & Recycling setup model.
// Stores the user's bin types and housing type (own bins vs communal).

import 'package:flutter/material.dart';

enum BinType {
  generalWaste('General Waste', Icons.delete_outline, 0.58),
  recycling('Recycling', Icons.recycling, -0.30),
  foodWaste('Food Waste', Icons.restaurant_outlined, 0.70),
  compost('Compost', Icons.yard_outlined, 0.05);

  const BinType(this.label, this.icon, this.co2PerKg);

  final String label;
  final IconData icon;

  /// kg CO2e per kg of waste disposed via this method.
  /// Negative = net saving (recycling displaces virgin-material production).
  final double co2PerKg;

  /// True for bins whose waste is diverted from landfill.
  bool get isRecycling => this == recycling || this == compost;
}

enum HousingType {
  ownBins('I have my own bins/wheelie bins', Icons.home_outlined),
  communalBins('I use shared/communal bins', Icons.apartment_outlined);

  const HousingType(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum HabitType {
  reusableBag('Reusable bag', Icons.shopping_bag_outlined),
  reusableBottle('Reusable bottle', Icons.water_drop_outlined),
  reusableCup('Reusable cup', Icons.coffee_outlined);

  const HabitType(this.label, this.icon);
  final String label;
  final IconData icon;
}

class WasteSetup {
  final List<BinType> enabledBins;
  final HousingType housingType;

  const WasteSetup({
    required this.enabledBins,
    required this.housingType,
  });

  /// True when the user has at least one recycling-diversion bin.
  bool get hasRecycling =>
      enabledBins.any((b) => b == BinType.recycling || b == BinType.compost);

  Map<String, dynamic> toMap() => {
        'enabled_bins': enabledBins.map((b) => b.name).join(','),
        'housing_type': housingType.name,
      };

  factory WasteSetup.fromMap(Map<String, dynamic> map) {
    final raw = map['enabled_bins'] as String;
    final binNames = raw.isEmpty ? <String>[] : raw.split(',');
    return WasteSetup(
      enabledBins: binNames
          .map((name) {
            try {
              return BinType.values.firstWhere((b) => b.name == name);
            } catch (_) {
              return null;
            }
          })
          .whereType<BinType>()
          .toList(),
      housingType: HousingType.values.firstWhere(
        (h) => h.name == map['housing_type'],
        orElse: () => HousingType.ownBins,
      ),
    );
  }
}

/// A single daily habit check-off.
class HabitLog {
  final int? id;
  final DateTime date;
  final HabitType habitType;
  final DateTime createdAt;

  HabitLog({
    this.id,
    required this.date,
    required this.habitType,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'date': date.toIso8601String(),
        'habit_type': habitType.name,
        'created_at': createdAt.toIso8601String(),
      };

  factory HabitLog.fromMap(Map<String, dynamic> map) => HabitLog(
        id: map['id'] as int?,
        date: DateTime.parse(map['date'] as String),
        habitType: HabitType.values.firstWhere(
          (h) => h.name == map['habit_type'],
          orElse: () => HabitType.reusableBag,
        ),
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
