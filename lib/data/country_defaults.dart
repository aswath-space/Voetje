/// Single source of truth for all country-specific reference data.
///
/// Adding a country = adding one entry to [countries].
/// The compiler enforces that every country has all required fields.
///
/// Sources: IEA 2023 household energy balances, DEFRA 2023, national statistics.
class CountryDefaults {
  final String code;           // ISO 3166-1 alpha-2
  final String name;
  final String currencySymbol; // for bill-entry UI display
  final int gridIntensity;     // g CO2e per kWh (IEA / DEFRA 2023)
  final double annualKwh;      // household electricity kWh/year
  final double? annualGasKwh;  // household gas kWh/year (null = gas uncommon)
  final double elecPrice;      // local currency per kWh
  final double? gasPrice;      // local currency per kWh (null = no data)
  final Map<String, String>? regions;   // regionCode → display name
  final Map<String, int>? regionGrid;   // regionCode → g CO2/kWh override

  const CountryDefaults({
    required this.code,
    required this.name,
    required this.currencySymbol,
    required this.gridIntensity,
    required this.annualKwh,
    this.annualGasKwh,
    required this.elecPrice,
    this.gasPrice,
    this.regions,
    this.regionGrid,
  });

  /// Whether this country has gas heating data (controls gas UI visibility).
  bool get hasGas => annualGasKwh != null;

  /// Whether this country has sub-national region/state overrides.
  bool get hasRegions => regions != null && regions!.isNotEmpty;

  /// Grid intensity for a specific region, falling back to country default.
  int gridForRegion(String? regionCode) =>
      regionGrid?[regionCode] ?? gridIntensity;

  // ---------------------------------------------------------------------------
  // Country registry
  // ---------------------------------------------------------------------------

  /// All supported countries, keyed by ISO 3166-1 alpha-2 code.
  static const Map<String, CountryDefaults> countries = {
    'US': CountryDefaults(
      code: 'US', name: 'United States', currencySymbol: '\$',
      gridIntensity: 370, annualKwh: 10500, // eGRID 2023: ~368
      annualGasKwh: 12000, elecPrice: 0.16, gasPrice: 0.04,
      regions: {
        'WA': 'Washington', 'VT': 'Vermont', 'CA': 'California',
        'NY': 'New York', 'TX': 'Texas', 'FL': 'Florida',
        'OH': 'Ohio', 'WV': 'West Virginia', 'WY': 'Wyoming',
      },
      regionGrid: {
        'WA': 75, 'VT': 10, 'CA': 180, 'NY': 190,   // eGRID 2023
        'TX': 350, 'FL': 360, 'OH': 480, 'WV': 800, 'WY': 830,
      },
    ),
    'GB': CountryDefaults(
      code: 'GB', name: 'United Kingdom', currencySymbol: '£',
      gridIntensity: 160, annualKwh: 3800, // DEFRA 2024: 177; real-time 2024: 124; 160 is conservative midpoint
      annualGasKwh: 12000, elecPrice: 0.28, gasPrice: 0.06,
    ),
    'DE': CountryDefaults(
      code: 'DE', name: 'Germany', currencySymbol: '€',
      gridIntensity: 380, annualKwh: 3000,
      annualGasKwh: 15000, elecPrice: 0.35, gasPrice: 0.07,
    ),
    'AU': CountryDefaults(
      code: 'AU', name: 'Australia', currencySymbol: 'A\$',
      gridIntensity: 550, annualKwh: 7200, // NGA 2023: 549
      annualGasKwh: 15000, elecPrice: 0.30, gasPrice: 0.03,
      regions: {
        'NSW': 'New South Wales', 'VIC': 'Victoria', 'QLD': 'Queensland',
        'SA': 'South Australia', 'WA': 'Western Australia', 'TAS': 'Tasmania',
        'ACT': 'Australian Capital Territory', 'NT': 'Northern Territory',
      },
      regionGrid: {
        'TAS': 20,   // hydro dominant
        'SA': 200,    // wind + solar growing
        'ACT': 200,   // purchases renewables
        'VIC': 800,   // brown coal
        'NSW': 660,   // coal + gas
        'QLD': 750,   // coal dominant
        'WA': 550,    // gas + coal
        'NT': 600,    // gas dominant
      },
    ),
    'IN': CountryDefaults(
      code: 'IN', name: 'India', currencySymbol: '₹',
      gridIntensity: 700, annualKwh: 1200,
      elecPrice: 8.0,
    ),
    'FR': CountryDefaults(
      code: 'FR', name: 'France', currencySymbol: '€',
      gridIntensity: 60, annualKwh: 4500,
      annualGasKwh: 12000, elecPrice: 0.21, gasPrice: 0.08,
    ),
    'CA': CountryDefaults(
      code: 'CA', name: 'Canada', currencySymbol: 'C\$',
      gridIntensity: 120, annualKwh: 11000,
      annualGasKwh: 10000, elecPrice: 0.13, gasPrice: 0.04,
      regions: {
        'QC': 'Quebec', 'BC': 'British Columbia', 'ON': 'Ontario',
        'AB': 'Alberta', 'SK': 'Saskatchewan', 'MB': 'Manitoba',
        'NS': 'Nova Scotia', 'NB': 'New Brunswick',
      },
      regionGrid: {
        'QC': 2,    // 99% hydro
        'BC': 15,   // hydro dominant
        'MB': 3,    // hydro dominant
        'ON': 75,   // nuclear + hydro (TAF 2024: 74)
        'NB': 300,  // nuclear + gas + hydro mix
        'NS': 600,  // coal + gas
        'AB': 470,  // coal + gas (Alberta Gov 2023)
        'SK': 600,  // coal-heavy
      },
    ),
    'JP': CountryDefaults(
      code: 'JP', name: 'Japan', currencySymbol: '¥',
      gridIntensity: 450, annualKwh: 4300,
      elecPrice: 31.0,
    ),
    'IT': CountryDefaults(
      code: 'IT', name: 'Italy', currencySymbol: '€',
      gridIntensity: 300, annualKwh: 2800,
      annualGasKwh: 14000, elecPrice: 0.25, gasPrice: 0.09,
    ),
    'ES': CountryDefaults(
      code: 'ES', name: 'Spain', currencySymbol: '€',
      gridIntensity: 150, annualKwh: 3500,
      annualGasKwh: 9000, elecPrice: 0.22, gasPrice: 0.07,
    ),
    'CN': CountryDefaults(
      code: 'CN', name: 'China', currencySymbol: '¥',
      gridIntensity: 550, annualKwh: 3200,
      elecPrice: 0.55,
    ),
    'KR': CountryDefaults(
      code: 'KR', name: 'South Korea', currencySymbol: '₩',
      gridIntensity: 420, annualKwh: 4700,
      elecPrice: 140.0,
    ),
    'BR': CountryDefaults(
      code: 'BR', name: 'Brazil', currencySymbol: 'R\$',
      gridIntensity: 80, annualKwh: 2100,
      elecPrice: 0.80,
    ),
    'NZ': CountryDefaults(
      code: 'NZ', name: 'New Zealand', currencySymbol: 'NZ\$',
      gridIntensity: 90, annualKwh: 7500,
      elecPrice: 0.30,
    ),
    'NO': CountryDefaults(
      code: 'NO', name: 'Norway', currencySymbol: 'kr',
      gridIntensity: 20, annualKwh: 16000,
      elecPrice: 1.50,
    ),
    'SE': CountryDefaults(
      code: 'SE', name: 'Sweden', currencySymbol: 'kr',
      gridIntensity: 30, annualKwh: 8300,
      elecPrice: 2.00,
    ),
    'CH': CountryDefaults(
      code: 'CH', name: 'Switzerland', currencySymbol: 'CHF',
      gridIntensity: 35, annualKwh: 4500,
      elecPrice: 0.27,
    ),
    'IS': CountryDefaults(
      code: 'IS', name: 'Iceland', currencySymbol: 'kr',
      gridIntensity: 10, annualKwh: 12000,
      elecPrice: 0.15,
    ),
    'PL': CountryDefaults(
      code: 'PL', name: 'Poland', currencySymbol: 'zł',
      gridIntensity: 750, annualKwh: 3400,
      elecPrice: 1.10,
    ),
    'ZA': CountryDefaults(
      code: 'ZA', name: 'South Africa', currencySymbol: 'R',
      gridIntensity: 900, annualKwh: 10000,
      elecPrice: 2.50,
    ),
    'NL': CountryDefaults(
      code: 'NL', name: 'Netherlands', currencySymbol: '€',
      gridIntensity: 280, annualKwh: 3400,
      annualGasKwh: 11000, elecPrice: 0.28, gasPrice: 0.08,
    ),
    'MX': CountryDefaults(
      code: 'MX', name: 'Mexico', currencySymbol: 'MX\$',
      gridIntensity: 450, annualKwh: 2500,
      elecPrice: 1.50,
    ),
    'NG': CountryDefaults(
      code: 'NG', name: 'Nigeria', currencySymbol: '₦',
      gridIntensity: 570, annualKwh: 900,
      elecPrice: 70.0,
    ),
    'PK': CountryDefaults(
      code: 'PK', name: 'Pakistan', currencySymbol: '₨',
      gridIntensity: 480, annualKwh: 700,
      elecPrice: 25.0,
    ),
  };

  /// Fallback for countries not in [countries].
  static const fallback = CountryDefaults(
    code: '??', name: 'Global average', currencySymbol: '\$',
    gridIntensity: 400, annualKwh: 4000, // IEA global avg ~400
    elecPrice: 0.20,
  );

  /// Look up a country, falling back to [fallback] if not found.
  static CountryDefaults forCode(String code) => countries[code] ?? fallback;

  /// Display name for a country code, falling back to the code itself.
  static String nameForCode(String code) =>
      countries[code]?.name ?? code;
}
