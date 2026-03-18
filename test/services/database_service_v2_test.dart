// test/services/database_service_v2_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:carbon_tracker/services/database_service.dart';

void main() {
  setUpAll(() => sqfliteFfiInit());

  test('energy_profiles table exists after v2 migration', () async {
    final factory = databaseFactoryFfi;
    final db = await factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, v) => DatabaseService.createSchema(db, v),
        onUpgrade: (db, old, v) => DatabaseService.migrateSchema(db, old, v),
      ),
    );
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='energy_profiles'",
    );
    expect(tables.length, 1);
    await db.close();
  });
}
