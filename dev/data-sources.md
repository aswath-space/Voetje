# Data Sources & Methodology

> Last verified: 2026-03-18
> Next review due: 2027-03 (annual, or when IEA/DEFRA/EPA publish new factors)
>
> All reference data lives in two files: `lib/data/country_defaults.dart` and `lib/data/emission_factors.dart`.

---

## Electricity Grid Intensity

**What:** g CO2e emitted per kWh of electricity consumed, by country and sub-national region.

**Used in:** Country energy estimates, electric vehicle CO2, household electricity CO2.

**File:** `CountryDefaults.gridIntensity` and `CountryDefaults.regionGrid`

| Source | Coverage | URL |
|--------|----------|-----|
| IEA Emissions Factors 2024 | 150 countries, national level | https://www.iea.org/data-and-statistics/data-product/emissions-factors-2024 |
| EPA eGRID 2023 | US states and subregions | https://www.epa.gov/egrid |
| DEFRA 2024 Conversion Factors | UK national (load-weighted) | https://www.gov.uk/government/collections/government-conversion-factors-for-company-reporting |
| Canada Environment & Climate Change | Canadian provinces (OBPS factors) | https://www.canada.ca/en/environment-climate-change/services/climate-change/pricing-pollution-how-it-will-work/output-based-pricing-system/federal-greenhouse-gas-offset-system/emission-factors-reference-values.html |
| TAF Ontario Emissions Report 2024 | Ontario province | https://taf.ca/ |
| Alberta GHG Performance Reports | Alberta province | https://www.alberta.ca/albertas-greenhouse-gas-emissions-reduction-performance |
| Australian NGA Factors 2024 | Australian states (Scope 2) | https://www.dcceew.gov.au/climate-change/publications/national-greenhouse-accounts-factors-2024 |

### Current values

| Code | Country | Grid (g/kWh) | Year verified |
|------|---------|-------------|---------------|
| IS | Iceland | 10 | 2024 |
| NO | Norway | 20 | 2024 |
| SE | Sweden | 30 | 2024 |
| CH | Switzerland | 35 | 2024 |
| FR | France | 60 | 2024 |
| BR | Brazil | 80 | 2024 |
| NZ | New Zealand | 90 | 2024 |
| CA | Canada (national) | 120 | 2024 |
| ES | Spain | 150 | 2024 |
| GB | United Kingdom | 160 | 2024 (DEFRA 2024: 177; real-time: 124) |
| NL | Netherlands | 280 | 2024 |
| IT | Italy | 300 | 2024 |
| US | United States (national) | 370 | 2023 (eGRID) |
| DE | Germany | 380 | 2023 (trending ~300 in 2024) |
| KR | South Korea | 420 | 2024 |
| MX | Mexico | 450 | 2024 |
| JP | Japan | 450 | 2024 |
| PK | Pakistan | 480 | 2024 |
| AU | Australia (national) | 550 | 2023 (NGA: 549) |
| CN | China | 550 | 2024 |
| NG | Nigeria | 570 | 2024 |
| IN | India | 700 | 2024 |
| PL | Poland | 750 | 2024 |
| ZA | South Africa | 900 | 2024 |
| ?? | Fallback (global avg) | 400 | IEA global average |

### US state overrides (eGRID 2023)

| State | Grid (g/kWh) |
|-------|-------------|
| VT | 10 |
| WA | 75 |
| CA | 180 |
| NY | 190 |
| TX | 350 |
| FL | 360 |
| OH | 480 |
| WV | 800 |
| WY | 830 |

### Canadian province overrides

| Province | Grid (g/kWh) | Source |
|----------|-------------|--------|
| QC | 2 | Hydro-Quebec |
| MB | 3 | Manitoba Hydro |
| BC | 15 | BC Hydro |
| ON | 75 | TAF Ontario 2024 |
| NB | 300 | CER profiles |
| AB | 470 | Alberta Gov 2023 |
| SK | 600 | CER profiles |
| NS | 600 | CER profiles |

### Australian state overrides (NGA 2024)

| State | Grid (g/kWh) | Notes |
|-------|-------------|-------|
| TAS | 20 | Hydro dominant |
| SA | 200 | Wind + solar growing rapidly |
| ACT | 200 | 100% renewable purchasing |
| AU (national) | 550 | National average |
| WA | 550 | Gas + coal (SWIS grid) |
| NT | 600 | Gas dominant |
| NSW | 660 | Coal + gas |
| QLD | 750 | Coal dominant |
| VIC | 800 | Brown coal (Latrobe Valley) |

---

## Household Energy Consumption

**What:** Average annual household electricity and gas consumption in kWh.

**Used in:** Energy quick-estimate mode (for users who don't enter bills).

**File:** `CountryDefaults.annualKwh` and `CountryDefaults.annualGasKwh`

| Source | Coverage | URL |
|--------|----------|-----|
| IEA World Energy Balances 2023 | Household electricity by country | https://www.iea.org/data-and-statistics |
| Eurostat Energy Statistics | EU household gas consumption | https://ec.europa.eu/eurostat/statistics-explained/index.php?title=Energy_consumption_in_households |
| EIA Residential Energy Consumption Survey | US households | https://www.eia.gov/consumption/residential/ |
| Australian Energy Update 2024 | Australian households | https://www.energy.gov.au/publications/australian-energy-update-2025 |

**Note:** `annualKwh` represents the national average *household* total (not per-capita). The household scale factors in `EmissionFactors.householdScale` adjust this to per-person estimates based on household size.

**Note:** `annualGasKwh` is only defined for countries where gas heating is prevalent. When `null`, the app hides the gas section in bill entry and excludes gas from estimates. The presence of this field is a data-driven UI toggle — not just a number.

---

## Combustion Emission Factors

**What:** kg CO2e emitted per kWh of fuel burned.

**Used in:** Gas/oil/wood bill entry and quick estimates.

**File:** `EmissionFactors` in `lib/data/emission_factors.dart`

| Factor | Value | Source |
|--------|-------|--------|
| Natural gas | 0.184 kg CO2e/kWh | DEFRA 2023 Conversion Factors, Table 1c |
| Heating oil | 0.298 kg CO2e/kWh | DEFRA 2023 Conversion Factors, Table 1c |
| Wood/pellets | 0.016 kg CO2e/kWh | DEFRA 2023 (net of biogenic; gross ~0.39) |

**Decision:** Wood uses the DEFRA net-biogenic factor (0.016) rather than gross combustion (0.39). This follows UK government reporting guidance which treats sustainably-sourced biomass as near-carbon-neutral. Some methodologies disagree. The choice is documented here for transparency.

---

## Transport Emission Factors

**What:** kg CO2e per km per passenger, by transport mode.

**Used in:** Transport entry CO2 calculation.

**File:** `TransportMode` enum in `lib/models/transport_mode.dart`

| Source | Coverage | URL |
|--------|----------|-----|
| DEFRA 2023 Conversion Factors | UK average factors, all modes | https://www.gov.uk/government/collections/government-conversion-factors-for-company-reporting |
| EPA GHG Equivalencies | US transport comparisons | https://www.epa.gov/energy/greenhouse-gas-equivalencies-calculator |

| Mode | Factor (kg/km) | Source note |
|------|---------------|-------------|
| Walking | 0.000 | Zero direct emissions |
| Cycling | 0.000 | Zero direct emissions |
| E-bike | 0.005 | Electricity at ~25 Wh/km |
| Bus | 0.089 | DEFRA average local bus, per passenger |
| Train | 0.035 | DEFRA national rail, per passenger |
| Metro/Subway | 0.033 | DEFRA light rail/tram |
| Car (small) | 0.142 | DEFRA small petrol car, single occupant |
| Car (medium) | 0.171 | DEFRA medium petrol car, single occupant |
| Car (large/SUV) | 0.209 | DEFRA large car, single occupant |
| Electric car | 0.047 (fallback) | UK grid; dynamically computed per-country |
| Hybrid car | 0.109 | DEFRA plug-in hybrid |
| Motorcycle | 0.103 | DEFRA average motorcycle |
| Taxi/rideshare | 0.210 | Includes deadheading overhead |
| Flight (short) | 0.255 | DEFRA short-haul economy (incl. RFI uplift) |
| Flight (long) | 0.195 | DEFRA long-haul economy (incl. RFI uplift) |
| Ferry | 0.019 | DEFRA foot passenger |

**Electric vehicle note:** The static 0.047 kg/km is a UK-grid fallback only. When the user has an energy profile, the app computes `gridIntensity × 0.2 kWh/km / 1000` using their local grid, which can range from 0.002 (Norway) to 0.180 (South Africa).

**Car carpooling:** Car modes divide by passenger count. Public transport modes do not (already per-passenger).

---

## Food Emission Factors

**What:** kg CO2e per meal, by meal type.

**File:** `MealType` enum in `lib/models/meal_type.dart`

| Source | URL |
|--------|-----|
| Poore & Nemecek 2018 (via Our World in Data) | https://ourworldindata.org/food-choice-vs-eating-local |
| DEFRA 2023 | Supplementary for UK-specific items |

| Meal type | Factor (kg CO2) | Basis |
|-----------|----------------|-------|
| Plant-based | 0.5 | Avg plant meal (grains, legumes, veg) |
| Chicken or fish | 1.0 | Avg poultry/fish meal |
| In between | 1.5 | Mixed meal |
| Red meat | 3.3 | Avg beef/lamb meal |
| Fast food | 2.5 | Avg fast food meal (meat + processing) |
| Snack | 0.2 | Small snack item |

---

## Shopping Emission Factors

**What:** kg CO2e per new item purchased (manufacture + supply chain only, excluding use-phase).

**File:** `ItemCatalog` in `lib/data/item_catalog.dart`

| Source | URL |
|--------|-----|
| Vendor LCA reports | Apple, Samsung, Dell environmental reports |
| WRAP (UK) | https://wrap.org.uk |
| Industry averages | Textile Exchange, Ellen MacArthur Foundation |

**Methodology decision:** All values are **manufacture-only** (cradle-to-gate + transport). Use-phase emissions (washing, electricity consumption) are excluded because the user generates those regardless of the purchase event. This was standardised in the March 2026 audit — prior values for clothing used full-lifecycle figures (Levi's LCA etc.) which inflated jeans by 2.2x and T-shirts by 2.3x.

### Condition multipliers

| Condition | Multiplier | Rationale |
|-----------|-----------|-----------|
| New | 1.00 | Full manufacture CO2 |
| Second-hand | 0.10 | Transport + resale processing only |
| Repaired | 0.05 | Parts + labour materials; lower than second-hand |

---

## Waste Emission Factors

**What:** kg CO2e per kg of waste disposed.

**File:** `BinType` enum in `lib/models/waste_setup.dart`, constants in `EmissionFactors`

| Source | URL |
|--------|-----|
| EPA WARM Model | https://www.epa.gov/warm |
| DEFRA 2023 | Waste disposal factors |

| Bin type | Factor (kg CO2/kg) | Notes |
|----------|-------------------|-------|
| General waste | 0.58 | Landfill with gas capture |
| Recycling | -0.30 | Net saving (displaces virgin material) |
| Food waste | 0.70 | Anaerobic digestion/composting |
| Compost | 0.05 | Home composting, minimal processing |

| Constant | Value | Source |
|----------|-------|--------|
| Default bin size | 240 L | Standard UK wheelie bin |
| Waste density | 0.2 kg/L | EPA WARM mixed household waste |
| Bag weight | 3.0 kg | Standard kitchen rubbish bag |

---

## Equivalency Constants

**What:** Reference values used for human-readable "equivalent to X" comparisons.

**File:** `EmissionFactors` in `lib/data/emission_factors.dart`

| Constant | Value | Source |
|----------|-------|--------|
| Smartphone charge | 0.005 kg CO2 | EPA GHG Equivalencies (US grid avg) |
| Tree absorption | 21.77 kg CO2/year | Arbor Day Foundation |
| London-Paris flight | 90 kg CO2 | DEFRA 2023 short-haul |
| Average car per km | 0.171 kg CO2 | DEFRA medium petrol car (= TransportMode.carMedium) |
| Paris 2030 target | 2,300 kg CO2/year (6.3 kg/day) | IPCC AR6 per-capita pathway |

---

## Household Scale Factors

**What:** Per-person share of national-average household energy, by household size.

**File:** `EmissionFactors.householdScale`

| Source | URL |
|--------|-----|
| UK BEIS Household Energy Survey | https://www.gov.uk/government/statistics/energy-consumption-in-the-uk |

| Household size | Scale factor | Meaning |
|---------------|-------------|---------|
| 1 person | 0.47 | Uses ~47% of national avg household energy |
| 2 people | 0.42 | Each uses ~42% |
| 3 people | 0.33 | Each uses ~33% |
| 4 people | 0.28 | Each uses ~28% |
| 5+ people | 0.22 | Each uses ~22% |

**Note:** These ratios are derived from UK data but are broadly consistent across OECD countries due to similar economies of scale in heating, lighting, and appliances.

---

## Methodology Notes

### Core formula

```
CO2e (kg) = Activity Data x Emission Factor
```

All values are kg CO2e (CO2-equivalent using GWP-100). When choosing between high/low published factors, I lean slightly high to avoid false comfort — except for positive actions (EV, cycling, second-hand) where I lean slightly low to encourage adoption.

### Per-kg food reference (for factor updates)

The meal-type factors are derived from these per-kg values:

| Food | kg CO2e/kg | Source |
|------|-----------|--------|
| Beef (beef herd) | 60.0 | Poore & Nemecek 2018 |
| Lamb | 24.0 | Poore & Nemecek 2018 |
| Cheese | 21.0 | Poore & Nemecek 2018 |
| Pork | 7.0 | Poore & Nemecek 2018 |
| Chicken | 6.0 | Poore & Nemecek 2018 |
| Eggs | 4.5 | Poore & Nemecek 2018 |
| Rice | 4.0 | Poore & Nemecek 2018 |
| Tofu | 3.0 | Poore & Nemecek 2018 |
| Beans/lentils | 0.9 | Poore & Nemecek 2018 |
| Vegetables (avg) | 0.5 | Poore & Nemecek 2018 |

### Accuracy expectations

| Category | Accuracy | Main uncertainty |
|----------|---------|-----------------|
| Transport | ±10-20% | User's actual vehicle vs. category average |
| Food | ±30-50% | Meal-type classification is coarse by design |
| Energy | ±10-15% (kWh), ±30% (cost) | Grid intensity well-known; cost estimation rough |
| Shopping | ±50-100% | LCA data varies by brand/origin |
| Waste | ±40-60% | Volume-to-mass estimation rough |

### Daily budget

Paris Agreement 2030 target: 2.3 t CO2e/person/year = 6.3 kg/day.

The app doesn't enforce per-category budgets — just the total. The budget bar on the dashboard uses this single target.

---

## Review Cadence

Grid intensities are decarbonising rapidly (UK dropped 41% in one year). Recommend reviewing all data annually against:

| Source | Publishes | What to update |
|--------|-----------|---------------|
| IEA Emissions Factors | Annually (Q1) | Country grid intensities |
| EPA eGRID | January each year | US state grid values |
| DEFRA Conversion Factors | June each year | UK grid, combustion factors, transport |
| Canadian provincial reports | Varies | CA province grids |
| Australian NGA Factors | September each year | AU state grids |

---

## Licences & Attribution

All data sources used in the app have licences compatible with MIT:

| Source | Licence | Attribution required |
|--------|---------|---------------------|
| DEFRA GHG Conversion Factors | Open Government Licence v3.0 | Yes |
| EPA GHG Factors Hub / eGRID | US Federal public domain | Recommended |
| IEA Emissions Factors | IEA terms (non-commercial OK) | Yes |
| Poore & Nemecek 2018 | © AAAS (numbers are facts, freely usable) | Academic citation |
| Our World in Data | CC BY 4.0 | Yes |
| OurAirports | Public domain | Not required |
| EPA WARM Model | US Federal public domain | Recommended |

The in-app Data Sources screen (`lib/screens/data_sources_screen.dart`) satisfies these attribution requirements.

**GPL note:** The NMF.earth carbon-footprint npm library (GPL v3) was used as a cross-reference only — no code was imported. Underlying emission numbers are factual data and not copyrightable.
