/// Central registry of all emission factors and physical constants.
///
/// Every CO2 factor, physical constant, and reference value used in
/// calculations lives here. Review annually against DEFRA/IEA/EPA updates.
///
/// Sources cited inline per constant.
abstract final class EmissionFactors {
  // ---------------------------------------------------------------------------
  // Energy
  // ---------------------------------------------------------------------------

  /// Natural gas combustion factor. Source: DEFRA 2023.
  static const double gasKgCO2PerKwh = 0.184;

  /// Heating oil combustion factor. Source: DEFRA 2023.
  static const double oilKgCO2PerKwh = 0.298;

  /// Wood/pellet combustion factor (net of biogenic credit). Source: DEFRA 2023.
  /// Gross combustion is ~0.39 but DEFRA biogenic accounting nets to ~0.016.
  static const double woodKgCO2PerKwh = 0.016;

  /// Typical annual oil heating consumption (kWh/year, UK average).
  static const double defaultOilAnnualKwh = 18000;

  /// Typical annual wood/pellet heating consumption (kWh/year, UK average).
  static const double defaultWoodAnnualKwh = 15000;

  /// Average BEV energy consumption. Midpoint of 150–250 Wh/km range.
  static const double evKwhPerKm = 0.2;

  // ---------------------------------------------------------------------------
  // Waste
  // ---------------------------------------------------------------------------

  /// Mixed household waste density. Source: EPA WARM model.
  static const double wasteDensityKgPerL = 0.2;

  /// Standard UK wheelie bin size in liters (240L is most common).
  static const double defaultBinLiters = 240.0;

  /// Weight of a standard kitchen rubbish bag.
  static const double kgPerBag = 3.0;

  // ---------------------------------------------------------------------------
  // Equivalencies (for human-readable comparisons)
  // ---------------------------------------------------------------------------

  /// CO2 per full smartphone charge. Source: EPA (US grid avg).
  static const double smartphoneChargeKg = 0.005;

  /// CO2 absorbed by one tree per year. Source: Arbor Day Foundation.
  static const double treeAbsorptionKgPerYear = 21.77;

  /// CO2 for a one-way London–Paris flight. Source: DEFRA 2023.
  static const double londonParisFlightKg = 90.0;

  /// Average car CO2 per km (matches TransportMode.carMedium).
  /// Single source of truth for driving-equivalent comparisons.
  static const double avgCarKgPerKm = 0.171;

  // ---------------------------------------------------------------------------
  // Targets
  // ---------------------------------------------------------------------------

  /// Paris Agreement 2030 per-capita annual target.
  static const double parisAnnualKg = 2300.0;

  /// Daily budget derived from annual target.
  static const double parisDailyKg = parisAnnualKg / 365;

  /// Regional annual averages (tonnes CO2 per person).
  static const double globalAvgAnnualTonnes = 4.7;
  static const double usAvgAnnualTonnes = 16.0;
  static const double euAvgAnnualTonnes = 6.8;

  // ---------------------------------------------------------------------------
  // Household energy scaling
  // ---------------------------------------------------------------------------

  /// Per-person share of national-average household energy by household size.
  /// Derived from UK BEIS household energy survey; ratios are broadly
  /// consistent across OECD countries.
  static const Map<int, double> householdScale = {
    1: 0.47, 2: 0.42, 3: 0.33, 4: 0.28,
  };

  /// Fallback for households of 5+ people.
  static const double householdScaleDefault = 0.22;

  /// Look up household scale factor for a given size.
  static double householdScaleFor(int size) =>
      householdScale[size] ?? householdScaleDefault;
}
