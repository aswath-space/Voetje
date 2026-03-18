// Waste & Recycling setup model.
// Stores the user's bin types and housing type (own bins vs communal).

enum BinType {
  generalWaste('General Waste', '🗑️', 0.58),
  recycling('Recycling', '♻️', -0.30),
  foodWaste('Food Waste', '🍌', 0.70),
  compost('Compost', '🌿', 0.05);

  const BinType(this.label, this.emoji, this.co2PerKg);

  final String label;
  final String emoji;

  /// kg CO2e per kg of waste disposed via this method.
  /// Negative = net saving (recycling displaces virgin-material production).
  final double co2PerKg;

  /// True for bins whose waste is diverted from landfill.
  bool get isRecycling => this == recycling || this == compost;
}

enum HousingType {
  ownBins('I have my own bins/wheelie bins', '🏠'),
  communalBins('I use shared/communal bins', '🏢');

  const HousingType(this.label, this.emoji);
  final String label;
  final String emoji;
}

enum HabitType {
  reusableBag('Reusable bag', '🛍️'),
  reusableBottle('Reusable bottle', '🥤'),
  reusableCup('Reusable cup', '☕');

  const HabitType(this.label, this.emoji);
  final String label;
  final String emoji;
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
