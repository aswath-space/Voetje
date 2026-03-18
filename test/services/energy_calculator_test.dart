import 'package:flutter_test/flutter_test.dart';
import 'package:carbon_tracker/services/energy_calculator.dart';

void main() {
  group('EnergyCalculator', () {
    test('UK electricity: 350 kWh × 0.160 kg/kWh = 56.0 kg', () {
      expect(EnergyCalculator.electricityCO2(kWh: 350, countryCode: 'GB'), closeTo(56.0, 0.1));
    });

    test('France electricity is much lower than Poland', () {
      final fr = EnergyCalculator.electricityCO2(kWh: 350, countryCode: 'FR');
      final pl = EnergyCalculator.electricityCO2(kWh: 350, countryCode: 'PL');
      expect(fr, lessThan(pl));
    });

    test('household scale: 1 person = 0.47', () =>
        expect(EnergyCalculator.householdScale(1), 0.47));
    test('household scale: 2 people = 0.42', () =>
        expect(EnergyCalculator.householdScale(2), 0.42));
    test('household scale: 4 people = 0.28', () =>
        expect(EnergyCalculator.householdScale(4), 0.28));
    test('household scale: 5+ people = 0.22', () =>
        expect(EnergyCalculator.householdScale(5), 0.22));

    test('personalCO2 = householdCO2 × scale(2)', () {
      expect(EnergyCalculator.personalCO2(householdCO2: 100.0, householdSize: 2), closeTo(42.0, 0.01));
    });

    test('gasCO2: 12000 kWh × 0.184 = 2208 kg/year', () {
      expect(EnergyCalculator.gasCO2(kWh: 12000), closeTo(2208, 1.0));
    });

    test('costToKwh UK: £56 ÷ £0.28/kWh = 200 kWh', () {
      expect(EnergyCalculator.costToKwh(cost: 56.0, countryCode: 'GB'), closeTo(200, 1));
    });

    test('dailyAverage: Feb 2026 (28 days)', () {
      expect(
        EnergyCalculator.dailyAverage(monthlyCO2: 84.0, month: DateTime(2026, 2)),
        closeTo(3.0, 0.01),
      );
    });

    test('quickEstimate for UK 2-person household > 0', () {
      expect(EnergyCalculator.quickEstimate(countryCode: 'GB', householdSize: 2), greaterThan(0));
    });

    test('quickEstimate with adjustment factor 0.5 halves the result', () {
      final base = EnergyCalculator.quickEstimate(countryCode: 'GB', householdSize: 1);
      final adjusted = EnergyCalculator.quickEstimate(countryCode: 'GB', householdSize: 1, adjustmentFactor: 0.5);
      expect(adjusted, closeTo(base * 0.5, 0.01));
    });
  });
}
