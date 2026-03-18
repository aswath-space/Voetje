import 'package:flutter_test/flutter_test.dart';
import 'package:carbon_tracker/models/saved_place.dart';
import 'package:carbon_tracker/models/route_preset.dart';

void main() {
  group('SavedPlace', () {
    test('toMap/fromMap round-trip preserves all fields', () {
      final place = SavedPlace(
        id: 1,
        name: 'Home',
        latitude: 51.5074,
        longitude: -0.1278,
        createdAt: DateTime(2026, 1, 15),
      );
      final restored = SavedPlace.fromMap(place.toMap());
      expect(restored.id, 1);
      expect(restored.name, 'Home');
      expect(restored.latitude, 51.5074);
      expect(restored.longitude, -0.1278);
      expect(restored.createdAt, DateTime(2026, 1, 15));
    });

    test('toMap omits id when null', () {
      final place = SavedPlace(name: 'Office', latitude: 51.5, longitude: -0.09);
      expect(place.toMap().containsKey('id'), isFalse);
    });
  });

  group('RoutePreset', () {
    test('toMap/fromMap round-trip with mode and timestamp', () {
      final preset = RoutePreset(
        id: 3,
        fromPlaceId: 1,
        toPlaceId: 2,
        lastMode: 'carMedium',
        lastUsedAt: DateTime(2026, 3, 15, 9, 0),
      );
      final restored = RoutePreset.fromMap(preset.toMap());
      expect(restored.id, 3);
      expect(restored.fromPlaceId, 1);
      expect(restored.toPlaceId, 2);
      expect(restored.lastMode, 'carMedium');
      expect(restored.lastUsedAt, DateTime(2026, 3, 15, 9, 0));
    });

    test('toMap/fromMap round-trip with nulls', () {
      const preset = RoutePreset(fromPlaceId: 1, toPlaceId: 2);
      final restored = RoutePreset.fromMap(preset.toMap());
      expect(restored.lastMode, isNull);
      expect(restored.lastUsedAt, isNull);
    });
  });
}
