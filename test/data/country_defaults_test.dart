import 'package:flutter_test/flutter_test.dart';
import 'package:carbon_tracker/data/country_defaults.dart';

void main() {
  group('CountryDefaults', () {
    test('UK grid is 160 g/kWh', () {
      expect(CountryDefaults.forCode('GB').gridIntensity, 160);
    });

    test('France grid is 60 g/kWh', () {
      expect(CountryDefaults.forCode('FR').gridIntensity, 60);
    });

    test('India grid is 700 g/kWh', () {
      expect(CountryDefaults.forCode('IN').gridIntensity, 700);
    });

    test('unknown country falls back to 400 (global avg)', () {
      expect(CountryDefaults.forCode('XX').gridIntensity, 400);
    });

    test('US with Washington state region is 75', () {
      final us = CountryDefaults.forCode('US');
      expect(us.gridForRegion('WA'), 75);
    });

    test('US without region is 370 (national avg)', () {
      final us = CountryDefaults.forCode('US');
      expect(us.gridForRegion(null), 370);
    });

    test('US with unknown region falls back to national avg', () {
      final us = CountryDefaults.forCode('US');
      expect(us.gridForRegion('XX'), 370);
    });

    test('AU has state-level grid overrides', () {
      final au = CountryDefaults.forCode('AU');
      expect(au.hasRegions, isTrue);
      expect(au.gridForRegion('TAS'), 20);   // hydro
      expect(au.gridForRegion('VIC'), 800);  // brown coal
    });

    test('CA has provincial grid overrides', () {
      final ca = CountryDefaults.forCode('CA');
      expect(ca.hasRegions, isTrue);
      expect(ca.gridForRegion('QC'), 2);    // hydro
      expect(ca.gridForRegion('AB'), 470);  // coal + gas
      expect(ca.gridForRegion('ON'), 75);   // nuclear + hydro
    });

    test('all country codes are 2 chars', () {
      for (final code in CountryDefaults.countries.keys) {
        expect(code.length, 2);
      }
    });

    test('every country has positive grid intensity', () {
      for (final c in CountryDefaults.countries.values) {
        expect(c.gridIntensity, greaterThan(0));
      }
    });

    test('every country has positive annualKwh', () {
      for (final c in CountryDefaults.countries.values) {
        expect(c.annualKwh, greaterThan(0));
      }
    });

    test('every country has positive elecPrice', () {
      for (final c in CountryDefaults.countries.values) {
        expect(c.elecPrice, greaterThan(0));
      }
    });

    test('hasGas is true only for countries with annualGasKwh', () {
      expect(CountryDefaults.forCode('GB').hasGas, isTrue);
      expect(CountryDefaults.forCode('US').hasGas, isTrue);
      expect(CountryDefaults.forCode('IN').hasGas, isFalse);
      expect(CountryDefaults.forCode('JP').hasGas, isFalse);
    });

    test('hasRegions is true for US, CA, AU', () {
      expect(CountryDefaults.forCode('US').hasRegions, isTrue);
      expect(CountryDefaults.forCode('CA').hasRegions, isTrue);
      expect(CountryDefaults.forCode('AU').hasRegions, isTrue);
      expect(CountryDefaults.forCode('GB').hasRegions, isFalse);
    });

    test('nameForCode returns name for known, code for unknown', () {
      expect(CountryDefaults.nameForCode('GB'), 'United Kingdom');
      expect(CountryDefaults.nameForCode('ZZ'), 'ZZ');
    });

    test('countries has at least 20 entries', () {
      expect(CountryDefaults.countries.length, greaterThanOrEqualTo(20));
    });
  });
}
