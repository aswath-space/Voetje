# Contributing to Voetje

Thanks for your interest in contributing. Here's how to get started.

## A note on how this was built

I built Voetje using [Claude Code](https://claude.ai/claude-code) as my development tool. The architecture, calculations, tests, and this document were all written with AI assistance. I'm transparent about this because I think it matters — and because it means the codebase follows consistent patterns that should be easy to navigate even if you're new to it.

The data and methodology are real. Every emission factor is sourced from published research. The code has 173 passing tests. But if you spot something that looks off, please say so.

## Quick start

```bash
git clone https://github.com/aswath-space/voetje.git
cd voetje
flutter pub get
flutter test        # 173 tests, should all pass
flutter run         # run on connected device or emulator
```

Requires Flutter 3.27+ and Dart 3.11+.

## What I need help with

### iOS builds (high priority)

I don't have a Mac, so I can't build or test iOS at all. If you do:

1. Run `flutter build ios` and report any issues
2. Test the full flow: onboarding, logging entries across all 5 categories, settings
3. Check that SQLite, SharedPreferences, and file picker work correctly on iOS
4. Submit screenshots for the README

Even a "it builds and runs" confirmation is valuable.

### Adding countries

I support 24 countries with full data. Adding a new country is a single entry in `lib/data/country_defaults.dart`:

```dart
'TR': CountryDefaults(
  code: 'TR', name: 'Turkey', currencySymbol: '\u20BA',
  gridIntensity: 380,      // g CO2/kWh — source: IEA 2024
  annualKwh: 2500,          // household kWh/year — source: IEA
  elecPrice: 3.50,          // TRY per kWh
),
```

You need:
- Grid intensity (g CO2 per kWh) — from IEA or your national energy authority
- Average household electricity consumption (kWh/year)
- Electricity price in local currency per kWh
- (Optional) Gas consumption and price, if gas heating is common
- (Optional) State/province grid overrides if there's significant regional variation

Cite your sources in the PR description. See [dev/data-sources.md](dev/data-sources.md) for methodology details.

### Bug fixes and features

1. Check the issue tracker for open issues
2. For new features, open an issue first so we can discuss the approach
3. Keep PRs focused — one concern per PR

## Code standards

- `flutter analyze` must pass with zero issues
- `flutter test` must pass (currently 173 tests)
- Follow existing patterns in the codebase
- Don't add dependencies without discussion

### Data layer conventions

All emission factors and country data live in `lib/data/`:
- **`country_defaults.dart`** — one typed `CountryDefaults` per country (grid, kWh, prices, regions)
- **`emission_factors.dart`** — all CO2 factors and physical constants with inline source citations
- **`item_catalog.dart`** — shopping items by category

When updating emission factors:
- Note the old value, new value, and source in the PR description
- Update `dev/data-sources.md` with the new "last verified" date
- Update the in-app `data_sources_screen.dart` `_lastVerified` constant

### Architecture notes

- **State:** Single `EmissionProvider` (ChangeNotifier + Provider). No BLoC, no Riverpod.
- **Database:** SQLite via sqflite. Schema version in `database_service.dart`. Add migrations, never drop tables.
- **Models:** Immutable with `copyWith`. Enums for transport modes, meal types, bin types.
- **Services:** Pure calculation functions (static methods, no state). Services don't depend on Provider.
- **Screens:** Each entry form is a standalone screen. Dialogs/sheets for selection.

For more detail, see [dev/architecture.md](dev/architecture.md).

## Commit messages

I use conventional format:
```
feat: add Turkish country defaults
fix: correct Norwegian grid intensity
docs: update data-sources.md for 2027 IEA data
refactor: extract airport search into separate service
```

## Annual data review

All emission factors should be reviewed once a year against updated source publications. See the review cadence table in [dev/data-sources.md](dev/data-sources.md). If you notice a value that's out of date, a PR updating it (with source citation) is always welcome.
