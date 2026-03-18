import 'package:carbon_tracker/data/emission_factors.dart';
import 'package:carbon_tracker/models/emission_entry.dart';
import 'package:carbon_tracker/models/waste_setup.dart';

// Waste & Recycling calculation service.
// Converts bin fill fraction / bag count → estimated kg → kg CO2e.
// Emission factors from EPA WARM model and DEFRA 2023.
class WasteCalculator {
  // Estimated kg for a given bin fill fraction (own-bin users).
  // fill: 0.0 (empty) → 1.0 (overflowing).
  static double kgFromFillFraction(double fill) =>
      EmissionFactors.defaultBinLiters * fill.clamp(0.0, 1.0) * EmissionFactors.wasteDensityKgPerL;

  // Estimated kg from bag count (communal-bin users).
  static double kgFromBagCount(double bags) =>
      bags.clamp(0, 99) * EmissionFactors.kgPerBag;

  // kg CO2e for a given waste weight and bin type.
  static double co2ForKg(BinType binType, double kg) =>
      kg * binType.co2PerKg;

  // kg CO2e from a bin fill fraction.
  static double co2ForFill(BinType binType, double fill) =>
      co2ForKg(binType, kgFromFillFraction(fill));

  // kg CO2e from a bag count.
  static double co2ForBags(BinType binType, double bags) =>
      co2ForKg(binType, kgFromBagCount(bags));

  // Recycling rate as a percentage (0–100).
  // Computes: diverted_kg / (diverted_kg + landfill_kg) × 100.
  // entry.value is expected to hold estimated kg weight.
  static double recyclingRate(List<EmissionEntry> wasteEntries) {
    double divertedKg = 0;
    double totalKg = 0;

    for (final entry in wasteEntries) {
      if (entry.category != EmissionCategory.waste) continue;
      final binType = _parseBinType(entry.subCategory);
      if (binType == null) continue;

      final kg = entry.value;
      totalKg += kg;
      if (binType.isRecycling) divertedKg += kg;
    }

    if (totalKg <= 0) return 0;
    return (divertedKg / totalKg * 100).clamp(0.0, 100.0);
  }

  // Consecutive-day streak for a given habit type.
  // logs must be sorted newest-first.
  static int habitStreak(List<HabitLog> logs, HabitType habitType) {
    final relevant = logs
        .where((l) => l.habitType == habitType)
        .map((l) => DateTime(l.date.year, l.date.month, l.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // newest first

    if (relevant.isEmpty) return 0;

    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final yesterdayNorm = todayNorm.subtract(const Duration(days: 1));

    // Streak must include today or yesterday to be considered active.
    if (relevant.first != todayNorm && relevant.first != yesterdayNorm) {
      return 0;
    }

    int streak = 0;
    DateTime expected = relevant.first;
    for (final date in relevant) {
      if (date == expected) {
        streak++;
        expected = expected.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  static BinType? _parseBinType(String subCategory) {
    try {
      return BinType.values.firstWhere((b) => b.name == subCategory);
    } catch (_) {
      return null;
    }
  }
}
