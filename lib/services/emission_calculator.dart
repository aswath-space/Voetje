import 'package:carbon_tracker/data/emission_factors.dart';
import 'package:carbon_tracker/models/transport_mode.dart';

/// Utility class for CO2 equivalency calculations.
/// Helps users understand their footprint with relatable comparisons.
class EmissionCalculator {
  /// Convert kg CO2 to relatable equivalents
  static Map<String, String> getEquivalents(double co2Kg) {
    return {
      'trees': '${(co2Kg / EmissionFactors.treeAbsorptionKgPerYear).toStringAsFixed(1)} trees needed for a year to absorb this',
      'driving': '${(co2Kg / EmissionFactors.avgCarKgPerKm).toStringAsFixed(0)} km of average car driving',
      'smartphones': '${(co2Kg / EmissionFactors.smartphoneChargeKg).toStringAsFixed(0)} smartphone charges',
      'flights': '${(co2Kg / EmissionFactors.londonParisFlightKg).toStringAsFixed(2)} London→Paris flights',
    };
  }

  /// Get a single human-readable comparison for a CO2 value
  static String getQuickComparison(double co2Kg) {
    if (co2Kg < 0.01) return 'Practically zero emissions!';
    if (co2Kg < 0.5) return 'About ${(co2Kg / EmissionFactors.smartphoneChargeKg).round()} smartphone charges';
    if (co2Kg < 2) return 'Like driving ${(co2Kg / EmissionFactors.avgCarKgPerKm).toStringAsFixed(1)} km in an average car';
    if (co2Kg < 10) return 'A tree would need ${(co2Kg / EmissionFactors.treeAbsorptionKgPerYear * 365).round()} days to absorb this';
    if (co2Kg < 50) return '${(co2Kg / EmissionFactors.treeAbsorptionKgPerYear).toStringAsFixed(1)} trees needed for a year';
    return '${(co2Kg / EmissionFactors.londonParisFlightKg).toStringAsFixed(1)}x a London-Paris flight';
  }

  /// Calculate what percentage of daily budget a value represents
  /// Based on Paris Agreement 2030 target
  static double percentOfDailyBudget(double co2Kg) {
    return (co2Kg / EmissionFactors.parisDailyKg) * 100;
  }

  /// Suggest a greener alternative for a transport mode.
  /// Pass [countryCode] so EV comparisons use grid-local factors.
  static String? suggestAlternative(TransportMode mode, double distanceKm, {String? countryCode}) {
    if (distanceKm <= 2 && mode != TransportMode.walking) {
      return 'This distance is walkable! Walking would save ${mode.calculateCO2(distanceKm, countryCode: countryCode).toStringAsFixed(2)} kg CO2.';
    }
    if (distanceKm <= 8 && mode != TransportMode.cycling && mode != TransportMode.walking) {
      final savings = mode.calculateCO2(distanceKm, countryCode: countryCode);
      return 'Cycling this distance would save ${savings.toStringAsFixed(2)} kg CO2.';
    }
    if (mode == TransportMode.carMedium || mode == TransportMode.carLarge) {
      final busSavings = mode.calculateCO2(distanceKm, countryCode: countryCode) -
          TransportMode.bus.calculateCO2(distanceKm);
      if (busSavings > 0) {
        return 'Taking the bus would save ${busSavings.toStringAsFixed(2)} kg CO2.';
      }
    }
    if (mode == TransportMode.flightShort && distanceKm < 800) {
      final trainSavings = mode.calculateCO2(distanceKm, countryCode: countryCode) -
          TransportMode.train.calculateCO2(distanceKm);
      return 'A train would save ${trainSavings.toStringAsFixed(1)} kg CO2 for this distance.';
    }
    return null;
  }
}
