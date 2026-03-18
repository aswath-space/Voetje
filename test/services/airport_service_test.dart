import 'package:flutter_test/flutter_test.dart';
import 'package:carbon_tracker/services/airport_service.dart';

void main() {
  late AirportService svc;

  setUp(() {
    svc = AirportService.forTesting([
      const Airport(iata: 'LHR', name: 'Heathrow Airport', city: 'London', country: 'GB', lat: 51.4775, lon: -0.4614),
      const Airport(iata: 'CDG', name: 'Charles de Gaulle Airport', city: 'Paris', country: 'FR', lat: 49.0097, lon: 2.5479),
      const Airport(iata: 'JFK', name: 'John F Kennedy International', city: 'New York', country: 'US', lat: 40.6398, lon: -73.7789),
      const Airport(iata: 'LAX', name: 'Los Angeles International', city: 'Los Angeles', country: 'US', lat: 33.9425, lon: -118.4081),
    ]);
  });

  test('empty query returns empty list', () {
    expect(svc.search(''), isEmpty);
  });

  test('exact IATA code match', () {
    final results = svc.search('LHR');
    expect(results.first.iata, 'LHR');
  });

  test('IATA prefix match — LH matches LHR first', () {
    final results = svc.search('LH');
    expect(results.isNotEmpty, isTrue);
    expect(results.first.iata, 'LHR');
  });

  test('city name search (case-insensitive)', () {
    final results = svc.search('paris');
    expect(results.any((a) => a.iata == 'CDG'), isTrue);
  });

  test('airport name search', () {
    final results = svc.search('heathrow');
    expect(results.first.iata, 'LHR');
  });

  test('findByIata returns airport for known code', () {
    final airport = svc.findByIata('JFK');
    expect(airport, isNotNull);
    expect(airport!.city, 'New York');
  });

  test('findByIata returns null for unknown code', () {
    expect(svc.findByIata('ZZZ'), isNull);
  });

  test('results capped at 8', () {
    final results = svc.search('a');
    expect(results.length, lessThanOrEqualTo(8));
  });
}
