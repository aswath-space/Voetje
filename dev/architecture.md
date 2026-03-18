# Architecture & Technical Decisions

> This document captures the key technical and methodology decisions made during development. For emission factor sources and values, see [data-sources.md](data-sources.md).
>
> This app was built using [Claude Code](https://claude.ai/claude-code). The architecture, data layer, calculations, tests, and audits were all developed with AI assistance. The methodology and data are sourced from real published research.

## Design Principles

Five rules that guide every screen and interaction:

1. **Empower, don't guilt.** Celebrate greener choices; never shame heavier ones. "You saved 2.3 kg by cycling" — not "You exceeded your budget."
2. **Speed over precision.** Logging an entry should take under 10 seconds. Losing the habit is worse than losing accuracy.
3. **Transparent methodology.** Every number traceable to a cited source. Open code means anyone can audit.
4. **Privacy as a feature.** No login, no server, no analytics. "Your data stays on your device" is the value proposition, not a limitation.
5. **Progressive disclosure.** One category at a time. Users master transport before food appears. Never dump all five on day one.

**Color language:** Green (zero) → light green (low) → amber (moderate) → orange (high) → red (very high). Applied to mode chips, budget bar, charts. Traffic-light system, universally understood.

**The "don't overthink it" principle:** Every screen has an obvious 2-3 tap default path. A tired person at 9pm should be able to log an entry without thinking.

## Data Layer

### Country data: one object per country

All country-specific reference data (grid intensity, consumption, prices, regions) lives in a single `CountryDefaults` class in `lib/data/country_defaults.dart`. Adding a country = adding one entry. The compiler enforces that every country has all required fields — no silent fallback mismatches.

Countries with sub-national grid variation (US states, Canadian provinces, Australian states) use `regions` and `regionGrid` maps on the same object.

### Emission factors: central registry

All scattered constants (gas factor, waste density, bin size, smartphone charge, Paris target, household scales, etc.) are consolidated in `lib/data/emission_factors.dart` with inline source citations. Services reference this registry rather than embedding their own constants.

### Shopping methodology: manufacture-only

All shopping item CO2 values use manufacture + supply chain only (cradle-to-gate), not full lifecycle. This was a deliberate decision: use-phase emissions (washing clothes, running a laptop) occur regardless of the purchase, so attributing them to the purchase event double-counts.

### Shopping conditions: repair < second-hand

The multipliers are: new (1.0), second-hand (0.10), repaired (0.05). Repair is scored as greener than second-hand because it avoids a transaction entirely and uses fewer new materials.

### Electric vehicle: grid-local calculation

Electric car CO2 is computed dynamically using the user's country/region grid intensity (not a fixed UK factor). Uses `gridIntensity * 0.2 kWh/km / 1000`. Falls back to 0.047 (UK average) when no energy profile exists.

### Household energy scaling

The `householdScale` factors represent per-person share of the national-average household's energy. A 1-person household uses ~47% of the average (not 100%), because the average household has ~2.4 people. Derived from UK BEIS data; ratios are consistent across OECD countries.

### Oil and wood heating

The energy quick-estimate checks the user's selected heating types. Oil heating adds ~5,364 kg CO2/year (DEFRA 0.298 kg/kWh × 18,000 kWh). Wood uses the DEFRA net-biogenic factor (0.016 kg/kWh) rather than gross combustion (0.39), following UK government reporting guidance.

### Today's Footprint scope

The headline daily CO2 number includes transport (actual today), food (actual today), and energy (daily average). Shopping (monthly) and waste (weekly) are excluded because they can't be meaningfully attributed to a single day. The budget bar label makes this explicit.

## Database

### Schema versioning

SQLite via sqflite, currently schema v4. Migrations in `DatabaseService.migrateSchema()` handle all version transitions without dropping tables. Users upgrading from any previous version keep all data.

### Import deduplication

`importFromJson` fingerprints existing entries by `(date, category, subCategory, value, co2Kg)` and skips matches. Prevents double-imports without requiring an explicit import ID.

### Static vs instance database

The production database uses a static `_sharedDatabase` (opened once, shared across all DatabaseService instances). The testing constructor sets a per-instance `_testDatabase` that never touches the shared reference — no cross-test contamination.

## Deferred / Known Limitations

These are acknowledged design limitations, not bugs:

| Area | Limitation | Reason deferred |
|------|-----------|----------------|
| Dashboard rebuilds | `Consumer<EmissionProvider>` wraps entire dashboard | Performance is acceptable at current scale; Selector narrowing is an optimization |
| Airport search | O(n) linear scan on 3,500 airports per keystroke | Fast enough on tested devices; debounce is a nice-to-have |
| Food slot in note field | Meal slot encoded as prefix in `note` text | Fixing requires DB migration; low real-world impact |
| Shopping `__` separator | `subCategory` uses unvalidated `__` delimiter | Input is from controlled ItemCatalog, not user text |
| Grid data decay | Values are snapshots that age ~10-20% per year | Annual review cadence documented in DATA_SOURCES.md |

## Future Integration Points

The data layer is structured to support:

| Feature | How |
|---------|-----|
| OpenMap API | Resolve coordinates → country code → `CountryDefaults.forCode()` |
| Remote factor updates | `CountryDefaults` can be loaded from JSON asset instead of Dart const |
| Real-time grid data | `gridIntensity` can become a getter that checks a cache |
| More regions | Any country can add `regions` + `regionGrid` |
| i18n | Country names already in data layer; UI strings ready to extract |

## File Reference

Every Dart file in `lib/`, what it does, and when you'd need to touch it.

### Data (`lib/data/`)

| File | Purpose | Touch when... |
|------|---------|---------------|
| `country_defaults.dart` | 24 countries: grid intensity, kWh, prices, regions | Adding a country, updating grid data |
| `emission_factors.dart` | All CO2 factors and physical constants | Annual DEFRA/IEA update |
| `item_catalog.dart` | 25 shopping items with CO2 values | Adding items, updating manufacture CO2 |
| `nudge_messages.dart` | Contextual dashboard messages | Adding/editing nudge copy |

### Models (`lib/models/`)

| File | Purpose | Touch when... |
|------|---------|---------------|
| `emission_entry.dart` | Core data model + `EmissionCategory` enum | Adding a new category |
| `transport_mode.dart` | 16 transport modes with CO2 factors | Adding a mode, updating DEFRA factors |
| `meal_type.dart` | 6 meal types + 4 meal slots with time boundaries | Changing food factors or slot times |
| `shopping_item.dart` | `ShoppingCondition` multipliers + `ShoppingCategory` | Changing condition logic |
| `waste_setup.dart` | `BinType`, `HousingType`, `HabitType`, `WasteSetup`, `HabitLog` | Adding bin types or habits |
| `energy_profile.dart` | `HeatingType`, `EnergyTrackingMethod`, `EnergyProfile` | Adding heating types or profile fields |
| `saved_place.dart` | GPS-bookmarked location | Changing place model |
| `route_preset.dart` | Saved A-B route with last-used mode | Changing route logic |

### Services (`lib/services/`)

| File | Purpose | Touch when... |
|------|---------|---------------|
| `database_service.dart` | SQLite schema (v4), CRUD, migrations | Adding tables/columns, fixing queries |
| `energy_calculator.dart` | Electricity, gas, oil, wood CO2; household scaling; quick estimate | Changing energy calculation logic |
| `waste_calculator.dart` | Fill fraction/bag count to kg to CO2; recycling rate; habit streaks | Changing waste formulas |
| `emission_calculator.dart` | Equivalencies, suggestions, daily budget % | Changing comparison text |
| `shopping_calculator.dart` | Driving/meal equivalents for shopping | Changing comparison logic |
| `food_calculator.dart` | Weekly diet profile CO2 | Changing food profile logic |
| `airport_service.dart` | Loads airports.json, IATA lookup, search | Updating airport data |
| `haversine.dart` | Great-circle distance between coordinates | Never (pure math) |
| `cloud_sync_service.dart` | JSON export/import with deduplication | Changing backup format |
| `nudge_message_picker.dart` | Selects contextual dashboard messages | Changing nudge selection logic |

### Screens (`lib/screens/`)

| File | Purpose |
|------|---------|
| `home_screen.dart` | Dashboard with all cards, charts, category breakdown |
| `add_entry_screen.dart` | Transport entry form (mode picker, distance, airports) |
| `add_food_screen.dart` | Food/meal entry form |
| `add_energy_screen.dart` | Energy bill entry form |
| `add_shopping_screen.dart` | Shopping item entry form |
| `add_waste_screen.dart` | Weekly waste bin entry form |
| `history_screen.dart` | Full entry history with pagination |
| `settings_screen.dart` | Preferences, data management, support link |
| `energy_setup_screen.dart` | 4-page energy setup wizard |
| `waste_setup_screen.dart` | 2-page waste setup wizard |
| `diet_profile_screen.dart` | Weekly diet profile editor |
| `onboarding_screen.dart` | First-launch walkthrough |
| `splash_nudge_screen.dart` | Daily nudge message on app open |
| `data_sources_screen.dart` | In-app "About Our Data" page |
| `support_screen.dart` | Donation/tip links |
| `saved_places_screen.dart` | Manage GPS-bookmarked locations |
| `second_hand_celebration_screen.dart` | Full-screen celebration after second-hand purchase |

### Widgets (`lib/widgets/`)

| File | Purpose |
|------|---------|
| `stat_card.dart` | Week/month stat display card |
| `emission_chart.dart` | 7-day bar chart (fl_chart) |
| `category_card.dart` | Transport mode breakdown row |
| `todays_meals_card.dart` | 3-slot meal summary card |
| `energy_dashboard_card.dart` | Energy daily average card |
| `shopping_dashboard_card.dart` | Shopping monthly CO2 + savings card |
| `waste_dashboard_card.dart` | Waste weekly CO2 + recycling rate card |
| `habit_check_row.dart` | Daily habit checkboxes |
| `airport_picker.dart` | Airport search autocomplete |
| `route_picker.dart` | Saved places A-B route selector |
| `add_place_sheet.dart` | Bottom sheet for adding a saved place |
| `category_picker_sheet.dart` | Bottom sheet for choosing entry category |
