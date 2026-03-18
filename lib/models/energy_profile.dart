// lib/models/energy_profile.dart
import 'dart:convert';

enum HeatingType {
  electric('Electric heater/AC', '⚡'),
  gas('Gas boiler', '🔥'),
  oil('Oil heating', '🛢️'),
  wood('Wood/pellets', '🪵'),
  notSure('Not sure', '🤷');

  const HeatingType(this.label, this.emoji);
  final String label;
  final String emoji;
}

enum EnergyTrackingMethod { estimate, bills }

class EnergyProfile {
  final String countryCode;
  final String? stateCode;
  final List<HeatingType> heatingTypes;
  final int householdSize;
  final EnergyTrackingMethod method;
  final double adjustmentFactor;
  final DateTime updatedAt;

  const EnergyProfile({
    required this.countryCode,
    this.stateCode,
    required this.heatingTypes,
    required this.householdSize,
    required this.method,
    this.adjustmentFactor = 1.0,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'country_code': countryCode,
    'state_code': stateCode,
    'heating_types': jsonEncode(heatingTypes.map((h) => h.name).toList()),
    'household_size': householdSize,
    'tracking_method': method.name,
    'adjustment_factor': adjustmentFactor,
    'updated_at': updatedAt.toIso8601String(),
  };

  factory EnergyProfile.fromMap(Map<String, dynamic> map) {
    final heatingNames = (jsonDecode(map['heating_types'] as String) as List).cast<String>();
    return EnergyProfile(
      countryCode: map['country_code'] as String,
      stateCode: map['state_code'] as String?,
      heatingTypes: heatingNames
          .map((n) => HeatingType.values.firstWhere((h) => h.name == n,
              orElse: () => HeatingType.notSure))
          .toList(),
      householdSize: map['household_size'] as int,
      method: EnergyTrackingMethod.values.firstWhere(
          (m) => m.name == map['tracking_method'],
          orElse: () => EnergyTrackingMethod.estimate),
      adjustmentFactor: (map['adjustment_factor'] as num).toDouble(),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
