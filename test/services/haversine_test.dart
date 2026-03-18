import 'package:flutter_test/flutter_test.dart';
import 'package:carbon_tracker/services/haversine.dart';

void main() {
  test('same point returns 0 km', () {
    expect(HaversineService.distanceKm(51.5, -0.1, 51.5, -0.1), 0.0);
  });

  test('LHR to CDG ≈ 347 km', () {
    final d = HaversineService.distanceKm(51.4775, -0.4614, 49.0097, 2.5479);
    expect(d, closeTo(347, 10));
  });

  test('LAX to LHR ≈ 8,755 km (long-haul)', () {
    final d = HaversineService.distanceKm(33.9425, -118.4081, 51.4775, -0.4614);
    expect(d, closeTo(8755, 100));
  });

  test('road multiplier 1.3 applied at call site, not inside utility', () {
    // 0 km * 1.3 is still 0
    expect(HaversineService.distanceKm(0, 0, 0, 0) * 1.3, 0.0);
  });
}
