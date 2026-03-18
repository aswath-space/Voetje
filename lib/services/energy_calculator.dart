import 'package:carbon_tracker/data/country_defaults.dart';
import 'package:carbon_tracker/data/emission_factors.dart';
import 'package:carbon_tracker/models/energy_profile.dart';

class EnergyCalculator {
  /// kg CO2 from electricity consumption.
  static double electricityCO2({
    required double kWh,
    required String countryCode,
    String? stateCode,
  }) {
    final country = CountryDefaults.forCode(countryCode);
    final gPerKwh = country.gridForRegion(stateCode);
    return kWh * gPerKwh / 1000;
  }

  /// Household size → per-person scaling factor.
  static double householdScale(int size) =>
      EmissionFactors.householdScaleFor(size);

  /// Apply household scaling to get personal share.
  static double personalCO2({required double householdCO2, required int householdSize}) =>
      householdCO2 * householdScale(householdSize);

  /// kg CO2 from natural gas combustion.
  static double gasCO2({required double kWh}) =>
      kWh * EmissionFactors.gasKgCO2PerKwh;

  /// Convert energy cost to estimated kWh using country average price.
  /// Set [isGas] to true when converting a gas bill.
  static double costToKwh({
    required double cost,
    required String countryCode,
    bool isGas = false,
  }) {
    final country = CountryDefaults.forCode(countryCode);
    final price = isGas ? (country.gasPrice ?? 0.05) : country.elecPrice;
    if (price <= 0) return 0;
    return cost / price;
  }

  /// Daily average CO2 from a monthly total.
  static double dailyAverage({required double monthlyCO2, required DateTime month}) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    return monthlyCO2 / daysInMonth;
  }

  /// kg CO2 from heating oil combustion.
  static double oilCO2({required double kWh}) =>
      kWh * EmissionFactors.oilKgCO2PerKwh;

  /// kg CO2 from wood/pellet combustion (net of biogenic credit).
  static double woodCO2({required double kWh}) =>
      kWh * EmissionFactors.woodKgCO2PerKwh;

  /// Quick estimate: monthly personal CO2 using country averages.
  /// Includes electricity, gas (where available), and oil/wood if selected.
  static double quickEstimate({
    required String countryCode,
    required int householdSize,
    double adjustmentFactor = 1.0,
    List<HeatingType> heatingTypes = const [],
  }) {
    final clamped = adjustmentFactor.clamp(0.5, 2.0);
    final country = CountryDefaults.forCode(countryCode);
    final monthlyElecKwh = country.annualKwh / 12;
    double householdCO2 = electricityCO2(kWh: monthlyElecKwh, countryCode: countryCode);

    // Include gas for countries with gas heating data.
    if (country.hasGas) {
      final monthlyGasKwh = country.annualGasKwh! / 12;
      householdCO2 += gasCO2(kWh: monthlyGasKwh);
    }

    // Include oil/wood if the user selected those heating types.
    if (heatingTypes.contains(HeatingType.oil)) {
      householdCO2 += oilCO2(kWh: EmissionFactors.defaultOilAnnualKwh / 12);
    }
    if (heatingTypes.contains(HeatingType.wood)) {
      householdCO2 += woodCO2(kWh: EmissionFactors.defaultWoodAnnualKwh / 12);
    }

    final personal = personalCO2(householdCO2: householdCO2, householdSize: householdSize);
    return personal * clamped;
  }
}
