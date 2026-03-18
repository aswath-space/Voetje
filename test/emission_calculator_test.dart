import 'package:flutter_test/flutter_test.dart';
import 'package:carbon_tracker/models/transport_mode.dart';
import 'package:carbon_tracker/models/emission_entry.dart';
import 'package:carbon_tracker/services/emission_calculator.dart';

void main() {
  group('TransportMode emission factors', () {
    test('walking and cycling produce zero emissions', () {
      expect(TransportMode.walking.kgCO2PerKm, 0.0);
      expect(TransportMode.cycling.kgCO2PerKm, 0.0);
    });

    test('electric car emits less than petrol car', () {
      expect(
        TransportMode.carElectric.kgCO2PerKm,
        lessThan(TransportMode.carMedium.kgCO2PerKm),
      );
    });

    test('train emits less than car', () {
      expect(
        TransportMode.train.kgCO2PerKm,
        lessThan(TransportMode.carSmall.kgCO2PerKm),
      );
    });

    test('calculateCO2 multiplies factor by distance', () {
      final co2 = TransportMode.carMedium.calculateCO2(100);
      expect(co2, closeTo(17.1, 0.1));
    });

    test('carpooling divides emissions by passengers', () {
      final solo = TransportMode.carMedium.calculateCO2(100, passengers: 1);
      final shared = TransportMode.carMedium.calculateCO2(100, passengers: 4);
      expect(shared, closeTo(solo / 4, 0.01));
    });

    test('passengers do not affect public transport', () {
      final bus1 = TransportMode.bus.calculateCO2(10, passengers: 1);
      final bus4 = TransportMode.bus.calculateCO2(10, passengers: 4);
      // Public transport factor is already per-passenger
      expect(bus1, equals(bus4));
    });
  });

  group('EmissionEntry', () {
    test('transport factory creates correct entry', () {
      final entry = EmissionEntry.transport(
        date: DateTime(2024, 3, 15),
        mode: TransportMode.carMedium,
        distanceKm: 50,
        passengers: 2,
      );

      expect(entry.category, EmissionCategory.transport);
      expect(entry.subCategory, 'carMedium');
      expect(entry.value, 50);
      expect(entry.co2Kg, closeTo(4.275, 0.01)); // 0.171 * 50 / 2
      expect(entry.passengers, 2);
    });

    test('serialization roundtrip preserves data', () {
      final original = EmissionEntry.transport(
        date: DateTime(2024, 6, 1),
        mode: TransportMode.train,
        distanceKm: 200,
        note: 'Weekend trip',
      );

      final map = original.toMap();
      final restored = EmissionEntry.fromMap(map);

      expect(restored.category, original.category);
      expect(restored.subCategory, original.subCategory);
      expect(restored.value, original.value);
      expect(restored.co2Kg, original.co2Kg);
      expect(restored.note, original.note);
    });

    test('transportMode getter resolves enum', () {
      final entry = EmissionEntry.transport(
        date: DateTime.now(),
        mode: TransportMode.flightShort,
        distanceKm: 500,
      );
      expect(entry.transportMode, TransportMode.flightShort);
    });
  });

  group('EmissionCalculator', () {
    test('percentOfDailyBudget is correct', () {
      // Paris target: 2300 kg/year = ~6.3 kg/day
      final percent = EmissionCalculator.percentOfDailyBudget(6.3);
      expect(percent, closeTo(100, 1));
    });

    test('zero emissions gives correct comparison', () {
      final result = EmissionCalculator.getQuickComparison(0);
      expect(result.toLowerCase(), contains('zero'));
    });

    test('suggestAlternative recommends walking for short trips', () {
      final suggestion = EmissionCalculator.suggestAlternative(
        TransportMode.carMedium,
        1.5,
      );
      expect(suggestion, isNotNull);
      expect(suggestion!.toLowerCase(), contains('walk'));
    });

    test('suggestAlternative recommends cycling for medium trips', () {
      final suggestion = EmissionCalculator.suggestAlternative(
        TransportMode.carMedium,
        5,
      );
      expect(suggestion, isNotNull);
      expect(suggestion!.toLowerCase(), contains('cycling'));
    });
  });
}
