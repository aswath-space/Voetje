import 'package:flutter_test/flutter_test.dart';
import 'package:carbon_tracker/models/emission_entry.dart';
import 'package:carbon_tracker/models/waste_setup.dart';
import 'package:carbon_tracker/services/waste_calculator.dart';

void main() {
  // ── kg estimation ──────────────────────────────────────────────────────────

  group('kgFromFillFraction', () {
    test('empty bin = 0 kg', () {
      expect(WasteCalculator.kgFromFillFraction(0.0), 0.0);
    });

    test('full bin = 240L × 1.0 × 0.2 = 48 kg', () {
      expect(WasteCalculator.kgFromFillFraction(1.0), closeTo(48.0, 0.001));
    });

    test('half bin = 24 kg', () {
      expect(WasteCalculator.kgFromFillFraction(0.5), closeTo(24.0, 0.001));
    });

    test('quarter bin = 12 kg', () {
      expect(WasteCalculator.kgFromFillFraction(0.25), closeTo(12.0, 0.001));
    });

    test('fill > 1.0 is clamped to 1.0', () {
      expect(WasteCalculator.kgFromFillFraction(2.0),
          WasteCalculator.kgFromFillFraction(1.0));
    });
  });

  group('kgFromBagCount', () {
    test('0 bags = 0 kg', () {
      expect(WasteCalculator.kgFromBagCount(0), 0.0);
    });

    test('1 bag = 3 kg', () {
      expect(WasteCalculator.kgFromBagCount(1), closeTo(3.0, 0.001));
    });

    test('3 bags = 9 kg', () {
      expect(WasteCalculator.kgFromBagCount(3), closeTo(9.0, 0.001));
    });
  });

  // ── CO2 calculation ────────────────────────────────────────────────────────

  group('co2ForFill', () {
    test('general waste: full bin → 48 kg × 0.58 = 27.84 kg CO2', () {
      expect(
        WasteCalculator.co2ForFill(BinType.generalWaste, 1.0),
        closeTo(27.84, 0.01),
      );
    });

    test('recycling: full bin is negative CO2 (savings)', () {
      final co2 = WasteCalculator.co2ForFill(BinType.recycling, 1.0);
      expect(co2, isNegative);
    });

    test('compost: positive but small CO2', () {
      final co2 = WasteCalculator.co2ForFill(BinType.compost, 1.0);
      expect(co2, greaterThan(0));
      expect(co2, lessThan(5.0)); // much less than landfill
    });
  });

  group('co2ForBags', () {
    test('2 bags of general waste → 6 kg × 0.58 = 3.48 kg CO2', () {
      expect(
        WasteCalculator.co2ForBags(BinType.generalWaste, 2),
        closeTo(3.48, 0.01),
      );
    });
  });

  // ── recycling rate ─────────────────────────────────────────────────────────

  group('recyclingRate', () {
    test('no entries → 0%', () {
      expect(WasteCalculator.recyclingRate([]), 0.0);
    });

    test('only general waste → 0%', () {
      final entries = [
        EmissionEntry.waste(
          date: DateTime.now(),
          binType: BinType.generalWaste,
          kgWeight: 10.0,
        ),
      ];
      expect(WasteCalculator.recyclingRate(entries), 0.0);
    });

    test('only recycling → 100%', () {
      final entries = [
        EmissionEntry.waste(
          date: DateTime.now(),
          binType: BinType.recycling,
          kgWeight: 8.0,
        ),
      ];
      expect(WasteCalculator.recyclingRate(entries), closeTo(100.0, 0.001));
    });

    test('50% general + 50% recycling → 50%', () {
      final entries = [
        EmissionEntry.waste(
          date: DateTime.now(),
          binType: BinType.generalWaste,
          kgWeight: 10.0,
        ),
        EmissionEntry.waste(
          date: DateTime.now(),
          binType: BinType.recycling,
          kgWeight: 10.0,
        ),
      ];
      expect(WasteCalculator.recyclingRate(entries), closeTo(50.0, 0.001));
    });

    test('compost counts as diverted (recycling)', () {
      final entries = [
        EmissionEntry.waste(
          date: DateTime.now(),
          binType: BinType.generalWaste,
          kgWeight: 6.0,
        ),
        EmissionEntry.waste(
          date: DateTime.now(),
          binType: BinType.compost,
          kgWeight: 2.0,
        ),
        EmissionEntry.waste(
          date: DateTime.now(),
          binType: BinType.recycling,
          kgWeight: 2.0,
        ),
      ];
      // diverted = 4, total = 10 → 40%
      expect(WasteCalculator.recyclingRate(entries), closeTo(40.0, 0.001));
    });

    test('ignores non-waste entries', () {
      final wasteEntry = EmissionEntry.waste(
        date: DateTime.now(),
        binType: BinType.generalWaste,
        kgWeight: 10.0,
      );
      final transportEntry = EmissionEntry(
        date: DateTime.now(),
        category: EmissionCategory.transport,
        subCategory: 'bus',
        value: 5.0,
        co2Kg: 0.3,
      );
      expect(
        WasteCalculator.recyclingRate([wasteEntry, transportEntry]),
        0.0,
      );
    });
  });

  // ── habit streak ───────────────────────────────────────────────────────────

  group('habitStreak', () {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));

    HabitLog log(DateTime date) =>
        HabitLog(date: date, habitType: HabitType.reusableBag);

    test('no logs → 0', () {
      expect(WasteCalculator.habitStreak([], HabitType.reusableBag), 0);
    });

    test('only today → streak = 1', () {
      expect(
        WasteCalculator.habitStreak([log(today)], HabitType.reusableBag),
        1,
      );
    });

    test('today + yesterday → streak = 2', () {
      expect(
        WasteCalculator.habitStreak(
            [log(today), log(yesterday)], HabitType.reusableBag),
        2,
      );
    });

    test('consecutive 3 days ending today → streak = 3', () {
      expect(
        WasteCalculator.habitStreak(
            [log(today), log(yesterday), log(twoDaysAgo)],
            HabitType.reusableBag),
        3,
      );
    });

    test('gap in streak → only counts from most recent run', () {
      final threeDaysAgo = today.subtract(const Duration(days: 3));
      // today + yesterday, then a gap, then 3-days-ago
      expect(
        WasteCalculator.habitStreak(
            [log(today), log(yesterday), log(threeDaysAgo)],
            HabitType.reusableBag),
        2,
      );
    });

    test('last log was two days ago (not yesterday or today) → 0', () {
      expect(
        WasteCalculator.habitStreak([log(twoDaysAgo)], HabitType.reusableBag),
        0,
      );
    });

    test('different habit type is not counted', () {
      expect(
        WasteCalculator.habitStreak([log(today)], HabitType.reusableBottle),
        0,
      );
    });
  });

  // ── WasteSetup model ───────────────────────────────────────────────────────

  group('WasteSetup', () {
    test('toMap / fromMap round-trip', () {
      const setup = WasteSetup(
        enabledBins: [BinType.generalWaste, BinType.recycling],
        housingType: HousingType.ownBins,
      );
      final map = setup.toMap();
      final restored = WasteSetup.fromMap(map);
      expect(restored.enabledBins, setup.enabledBins);
      expect(restored.housingType, setup.housingType);
    });

    test('hasRecycling is true when recycling bin enabled', () {
      const setup = WasteSetup(
        enabledBins: [BinType.generalWaste, BinType.recycling],
        housingType: HousingType.ownBins,
      );
      expect(setup.hasRecycling, isTrue);
    });

    test('hasRecycling is true when compost bin enabled', () {
      const setup = WasteSetup(
        enabledBins: [BinType.generalWaste, BinType.compost],
        housingType: HousingType.communalBins,
      );
      expect(setup.hasRecycling, isTrue);
    });

    test('hasRecycling is false when only general waste', () {
      const setup = WasteSetup(
        enabledBins: [BinType.generalWaste],
        housingType: HousingType.ownBins,
      );
      expect(setup.hasRecycling, isFalse);
    });
  });

  // ── EmissionEntry.waste factory ────────────────────────────────────────────

  group('EmissionEntry.waste', () {
    test('co2Kg = kgWeight × co2PerKg for general waste', () {
      const kg = 10.0;
      final entry = EmissionEntry.waste(
        date: DateTime.now(),
        binType: BinType.generalWaste,
        kgWeight: kg,
      );
      expect(entry.co2Kg, closeTo(kg * BinType.generalWaste.co2PerKg, 0.001));
      expect(entry.category, EmissionCategory.waste);
      expect(entry.subCategory, BinType.generalWaste.name);
      expect(entry.value, kg);
    });

    test('recycling entry has negative co2Kg', () {
      final entry = EmissionEntry.waste(
        date: DateTime.now(),
        binType: BinType.recycling,
        kgWeight: 5.0,
      );
      expect(entry.co2Kg, isNegative);
    });

    test('binType getter returns correct BinType', () {
      final entry = EmissionEntry.waste(
        date: DateTime.now(),
        binType: BinType.foodWaste,
        kgWeight: 3.0,
      );
      expect(entry.binType, BinType.foodWaste);
    });
  });
}
