import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:carbon_tracker/services/database_service.dart';

void main() {
  setUpAll(() => sqfliteFfiInit());

  Future<dynamic> openAt(int version) => databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: version,
          onCreate: (db, v) => DatabaseService.createSchema(db, v),
          onUpgrade: (db, old, v) => DatabaseService.migrateSchema(db, old, v),
        ),
      );

  test('waste_setup table exists after fresh v3 create', () async {
    final db = await openAt(3);
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='waste_setup'",
    );
    expect(tables.length, 1);
    await db.close();
  });

  test('habit_logs table exists after fresh v3 create', () async {
    final db = await openAt(3);
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='habit_logs'",
    );
    expect(tables.length, 1);
    await db.close();
  });

  test('energy_profiles still exists after v3 create', () async {
    final db = await openAt(3);
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='energy_profiles'",
    );
    expect(tables.length, 1);
    await db.close();
  });

  test('v2→v3 migration adds waste_setup and habit_logs', () async {
    // Build a real v2 schema in a fresh in-memory database (emissions + energy_profiles,
    // no waste tables), then run migrateSchema(db, 2, 3) directly to verify the upgrade.
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, v) async {
          // v2 schema: emissions table + energy_profiles (no waste tables yet)
          await db.execute('''
            CREATE TABLE emissions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date TEXT NOT NULL,
              category TEXT NOT NULL,
              sub_category TEXT NOT NULL,
              value REAL NOT NULL,
              co2_kg REAL NOT NULL,
              note TEXT,
              passengers INTEGER DEFAULT 1,
              created_at TEXT NOT NULL
            )
          ''');
          await db.execute('CREATE INDEX idx_emissions_date ON emissions (date)');
          await db.execute('''
            CREATE TABLE energy_profiles (
              id INTEGER PRIMARY KEY,
              country_code TEXT NOT NULL,
              state_code TEXT,
              heating_types TEXT NOT NULL DEFAULT '[]',
              household_size INTEGER NOT NULL DEFAULT 1,
              tracking_method TEXT NOT NULL DEFAULT 'estimate',
              adjustment_factor REAL NOT NULL DEFAULT 1.0,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        },
      ),
    );

    // Confirm v2 state: waste tables do not exist
    final wasteBeforeMigration = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='waste_setup'",
    );
    expect(wasteBeforeMigration, isEmpty, reason: 'waste_setup must not exist in v2');

    // Run the actual v2→v3 migration
    await DatabaseService.migrateSchema(db, 2, 3);

    final wasteTable = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='waste_setup'",
    );
    final habitTable = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='habit_logs'",
    );
    final energyTable = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='energy_profiles'",
    );

    expect(wasteTable.length, 1, reason: 'waste_setup created by v2→v3 migration');
    expect(habitTable.length, 1, reason: 'habit_logs created by v2→v3 migration');
    expect(energyTable.length, 1, reason: 'energy_profiles preserved during migration');
    await db.close();
  });
}
