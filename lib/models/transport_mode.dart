import 'package:flutter/material.dart';
import 'package:carbon_tracker/config/theme.dart';
import 'package:carbon_tracker/data/country_defaults.dart';
import 'package:carbon_tracker/data/emission_factors.dart';

/// Transport modes with their associated CO2 emission factors.
/// Factors are in kg CO2e per kilometer, sourced from:
/// - UK DEFRA 2023 emission factors
/// - EPA greenhouse gas equivalencies
/// - IEA transport data
enum TransportMode {
  walking(
    label: 'Walking',
    icon: Icons.directions_walk,
    color: AppColors.walking,
    kgCO2PerKm: 0.0,
    description: 'Zero emissions — the greenest way to travel',
  ),
  cycling(
    label: 'Cycling',
    icon: Icons.directions_bike,
    color: AppColors.cycling,
    kgCO2PerKm: 0.0,
    description: 'Zero direct emissions',
  ),
  eBike(
    label: 'E-Bike',
    icon: Icons.electric_bike,
    color: AppColors.cycling,
    kgCO2PerKm: 0.005,
    description: '~5g CO2/km from electricity',
  ),
  bus(
    label: 'Bus',
    icon: Icons.directions_bus,
    color: AppColors.publicTransport,
    kgCO2PerKm: 0.089,
    description: 'Average local bus per passenger',
  ),
  train(
    label: 'Train',
    icon: Icons.train,
    color: AppColors.publicTransport,
    kgCO2PerKm: 0.035,
    description: 'Average rail per passenger',
  ),
  subway(
    label: 'Metro/Subway',
    icon: Icons.subway,
    color: AppColors.publicTransport,
    kgCO2PerKm: 0.033,
    description: 'Urban metro per passenger',
  ),
  carSmall(
    label: 'Car (Small)',
    icon: Icons.directions_car,
    color: AppColors.car,
    kgCO2PerKm: 0.142,
    description: 'Small petrol car, single occupant',
  ),
  carMedium(
    label: 'Car (Medium)',
    icon: Icons.directions_car,
    color: AppColors.car,
    kgCO2PerKm: 0.171,
    description: 'Medium petrol car, single occupant',
  ),
  carLarge(
    label: 'Car (Large/SUV)',
    icon: Icons.directions_car,
    color: AppColors.highEmission,
    kgCO2PerKm: 0.209,
    description: 'Large car or SUV, single occupant',
  ),
  carElectric(
    label: 'Electric Car',
    icon: Icons.electric_car,
    color: AppColors.publicTransport,
    kgCO2PerKm: 0.047,
    description: 'BEV average (grid electricity)',
  ),
  carHybrid(
    label: 'Hybrid Car',
    icon: Icons.electric_car,
    color: AppColors.mediumEmission,
    kgCO2PerKm: 0.109,
    description: 'Plug-in hybrid average',
  ),
  motorcycle(
    label: 'Motorcycle',
    icon: Icons.two_wheeler,
    color: AppColors.car,
    kgCO2PerKm: 0.103,
    description: 'Average motorcycle',
  ),
  taxi(
    label: 'Taxi/Rideshare',
    icon: Icons.local_taxi,
    color: AppColors.car,
    kgCO2PerKm: 0.210,
    description: 'Includes deadheading overhead',
  ),
  flightShort(
    label: 'Flight (Short)',
    icon: Icons.flight,
    color: AppColors.flight,
    kgCO2PerKm: 0.255,
    description: 'Domestic/short-haul (<1500km)',
  ),
  flightLong(
    label: 'Flight (Long)',
    icon: Icons.flight,
    color: AppColors.flight,
    kgCO2PerKm: 0.195,
    description: 'Long-haul (>1500km), economy class',
  ),
  ferry(
    label: 'Ferry',
    icon: Icons.directions_boat,
    color: AppColors.publicTransport,
    kgCO2PerKm: 0.019,
    description: 'Foot passenger on ferry',
  );

  const TransportMode({
    required this.label,
    required this.icon,
    required this.color,
    required this.kgCO2PerKm,
    required this.description,
  });

  final String label;
  final IconData icon;
  final Color color;
  final double kgCO2PerKm;
  final String description;

  /// Calculate CO2 for a given distance, with optional passenger count
  /// to split shared car journeys.
  ///
  /// For [carElectric], pass [countryCode] to use the local grid intensity
  /// instead of the hardcoded UK-average fallback.
  double calculateCO2(double distanceKm, {int passengers = 1, String? countryCode}) {
    if (passengers < 1) passengers = 1;

    double factor = kgCO2PerKm;
    if (this == TransportMode.carElectric && countryCode != null) {
      final country = CountryDefaults.forCode(countryCode);
      // g CO2/kWh × kWh/km → g CO2/km → kg CO2/km
      factor = country.gridIntensity * EmissionFactors.evKwhPerKm / 1000;
    }

    if (isCarMode) {
      return (factor * distanceKm) / passengers;
    }
    return factor * distanceKm;
  }

  bool get isCarMode => switch (this) {
        carSmall || carMedium || carLarge || carElectric || carHybrid || taxi => true,
        _ => false,
      };

  /// Emission intensity rating for UI display.
  /// For [carElectric], pass [countryCode] for a grid-aware badge.
  EmissionLevel emissionLevelFor({String? countryCode}) {
    double factor = kgCO2PerKm;
    if (this == TransportMode.carElectric && countryCode != null) {
      final country = CountryDefaults.forCode(countryCode);
      factor = country.gridIntensity * EmissionFactors.evKwhPerKm / 1000;
    }
    if (factor <= 0.01) return EmissionLevel.zero;
    if (factor <= 0.05) return EmissionLevel.veryLow;
    if (factor <= 0.10) return EmissionLevel.low;
    if (factor <= 0.15) return EmissionLevel.medium;
    if (factor <= 0.20) return EmissionLevel.high;
    return EmissionLevel.veryHigh;
  }

  /// Shortcut that uses the static fallback (no country context).
  EmissionLevel get emissionLevel => emissionLevelFor();
}

enum EmissionLevel {
  zero('Zero', AppColors.lowEmission),
  veryLow('Very Low', AppColors.lowEmission),
  low('Low', Color(0xFF8BC34A)),
  medium('Medium', AppColors.mediumEmission),
  high('High', Color(0xFFFF9800)),
  veryHigh('Very High', AppColors.highEmission);

  const EmissionLevel(this.label, this.color);
  final String label;
  final Color color;
}
