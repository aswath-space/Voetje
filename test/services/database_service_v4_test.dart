import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:carbon_tracker/services/database_service.dart';
import 'package:carbon_tracker/models/saved_place.dart';
import 'package:carbon_tracker/models/route_preset.dart';

void main() {
  setUpAll(() => sqfliteFfiInit());

  Future<dynamic> openAt(int version) => databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: version,
          onCreate: DatabaseService.createSchema,
          onUpgrade: DatabaseService.migrateSchema,
          // Mirror production _initDatabase so FK cascades fire in tests too.
          onOpen: (db) async => db.execute('PRAGMA foreign_keys = ON'),
        ),
      );

  test('saved_places table exists after fresh v4 create', () async {
    final db = await openAt(4);
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='saved_places'",
    );
    expect(rows.length, 1);
    await db.close();
  });

  test('route_presets table exists after fresh v4 create', () async {
    final db = await openAt(4);
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='route_presets'",
    );
    expect(rows.length, 1);
    await db.close();
  });

  test('v3->v4 migration creates saved_places and route_presets', () async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: DatabaseService.createSchema,
      ),
    );
    // Verify tables don't exist in v3
    final before = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='saved_places'",
    );
    expect(before, isEmpty);

    await DatabaseService.migrateSchema(db, 3, 4);

    final after = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('saved_places','route_presets')",
    );
    expect(after.length, 2);
    await db.close();
  });

  test('insertSavedPlace returns id, getSavedPlaces returns it', () async {
    final db = await openAt(4);
    final svc = DatabaseService.forTesting(db);
    final id = await svc.insertSavedPlace(
      SavedPlace(name: 'Home', latitude: 51.5074, longitude: -0.1278),
    );
    expect(id, greaterThan(0));
    final places = await svc.getSavedPlaces();
    expect(places.length, 1);
    expect(places.first.name, 'Home');
    expect(places.first.id, id);
    await db.close();
  });

  test('deleteSavedPlace cascades to route_presets', () async {
    final db = await openAt(4);
    final svc = DatabaseService.forTesting(db);
    final idA = await svc.insertSavedPlace(
      SavedPlace(name: 'A', latitude: 51.5, longitude: -0.1),
    );
    final idB = await svc.insertSavedPlace(
      SavedPlace(name: 'B', latitude: 51.6, longitude: -0.2),
    );
    await svc.upsertRoutePreset(RoutePreset(
      fromPlaceId: idA,
      toPlaceId: idB,
      lastMode: 'carMedium',
      lastUsedAt: DateTime.now(),
    ));
    // Confirm preset exists
    var preset = await svc.getRoutePreset(idA, idB);
    expect(preset, isNotNull);

    // Delete place A — preset should cascade-delete
    await svc.deleteSavedPlace(idA);
    preset = await svc.getRoutePreset(idA, idB);
    expect(preset, isNull);
    await db.close();
  });

  test('upsertRoutePreset updates lastMode on second call', () async {
    final db = await openAt(4);
    final svc = DatabaseService.forTesting(db);
    final idA = await svc.insertSavedPlace(
      SavedPlace(name: 'A', latitude: 51.5, longitude: -0.1),
    );
    final idB = await svc.insertSavedPlace(
      SavedPlace(name: 'B', latitude: 51.6, longitude: -0.2),
    );

    await svc.upsertRoutePreset(RoutePreset(
      fromPlaceId: idA,
      toPlaceId: idB,
      lastMode: 'carMedium',
      lastUsedAt: DateTime(2026, 1, 1),
    ));
    await svc.upsertRoutePreset(RoutePreset(
      fromPlaceId: idA,
      toPlaceId: idB,
      lastMode: 'bus',
      lastUsedAt: DateTime(2026, 3, 1),
    ));

    final preset = await svc.getRoutePreset(idA, idB);
    expect(preset!.lastMode, 'bus');
    await db.close();
  });
}
