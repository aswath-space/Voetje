import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:carbon_tracker/models/emission_entry.dart';
import 'package:carbon_tracker/models/energy_profile.dart';
import 'package:carbon_tracker/models/waste_setup.dart';
import 'package:carbon_tracker/models/saved_place.dart';
import 'package:carbon_tracker/models/route_preset.dart';

/// Local SQLite database for storing emission entries.
/// All data stays on-device unless the user explicitly exports it.
class DatabaseService {
  // Shared production database — opened once, reused across all instances.
  static Database? _sharedDatabase;
  // Per-instance override for testing — never touches the shared static.
  final Database? _testDatabase;

  static const _dbName = 'carbon_tracker.db';
  static const _dbVersion = 4;
  static const _table = 'emissions';

  DatabaseService() : _testDatabase = null;

  /// Testing-only constructor. Sets a per-instance database so tests
  /// don't contaminate each other or the class-level shared reference.
  DatabaseService.forTesting(Database db) : _testDatabase = db;

  Future<Database> get database async {
    if (_testDatabase != null) return _testDatabase;
    _sharedDatabase ??= await _initDatabase();
    return _sharedDatabase!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: DatabaseService.createSchema,
      onUpgrade: DatabaseService.migrateSchema,
      onOpen: (db) async => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  /// Public for testing (in-memory DB in tests).
  /// Creates all tables that belong to [version] and below.
  static Future<void> createSchema(Database db, int version) async {
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
    await db.execute('CREATE INDEX idx_emissions_category ON emissions (category)');
    await _createEnergyProfilesTable(db);
    if (version >= 3) await _createWasteTables(db);
    if (version >= 4) await _createSavedPlacesTables(db);
  }

  static Future<void> migrateSchema(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await _createEnergyProfilesTable(db);
    if (oldVersion < 3) await _createWasteTables(db);
    if (oldVersion < 4) await _createSavedPlacesTables(db);
  }

  static Future<void> _createEnergyProfilesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS energy_profiles (
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
  }

  static Future<void> _createWasteTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS waste_setup (
        id INTEGER PRIMARY KEY,
        enabled_bins TEXT NOT NULL DEFAULT '',
        housing_type TEXT NOT NULL DEFAULT 'ownBins',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS habit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        habit_type TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_habit_logs_date ON habit_logs (date)',
    );
  }

  static Future<void> _createSavedPlacesTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS saved_places (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS route_presets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        from_place_id INTEGER NOT NULL REFERENCES saved_places(id) ON DELETE CASCADE,
        to_place_id INTEGER NOT NULL REFERENCES saved_places(id) ON DELETE CASCADE,
        last_mode TEXT,
        last_used_at TEXT,
        UNIQUE(from_place_id, to_place_id)
      )
    ''');
  }

  // --- CRUD Operations ---

  Future<int> insertEntry(EmissionEntry entry) async {
    final db = await database;
    return db.insert(_table, entry.toMap());
  }

  Future<int> updateEntry(EmissionEntry entry) async {
    final db = await database;
    return db.update(
      _table,
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteEntry(int id) async {
    final db = await database;
    return db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<EmissionEntry?> getEntry(int id) async {
    final db = await database;
    final results = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return EmissionEntry.fromMap(results.first);
  }

  /// Get all entries for a date range, ordered by date descending
  Future<List<EmissionEntry>> getEntries({
    DateTime? startDate,
    DateTime? endDate,
    EmissionCategory? category,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (startDate != null) {
      where.add('date >= ?');
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      where.add('date <= ?');
      whereArgs.add(endDate.toIso8601String());
    }
    if (category != null) {
      where.add('category = ?');
      whereArgs.add(category.name);
    }

    final results = await db.query(
      _table,
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );

    return results.map((r) => EmissionEntry.fromMap(r)).toList();
  }

  /// Get total CO2 for a date range
  Future<double> getTotalCO2({
    required DateTime startDate,
    required DateTime endDate,
    EmissionCategory? category,
  }) async {
    final db = await database;
    final where = ['date >= ?', 'date <= ?'];
    final whereArgs = <dynamic>[
      startDate.toIso8601String(),
      endDate.toIso8601String(),
    ];

    if (category != null) {
      where.add('category = ?');
      whereArgs.add(category.name);
    }

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(co2_kg), 0) as total FROM $_table WHERE ${where.join(' AND ')}',
      whereArgs,
    );

    return (result.first['total'] as num).toDouble();
  }

  /// Get daily totals for chart display
  Future<List<DailyCO2>> getDailyTotals({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT
        substr(date, 1, 10) as day,
        SUM(co2_kg) as total_co2,
        COUNT(*) as entry_count
      FROM $_table
      WHERE date >= ? AND date <= ?
      GROUP BY substr(date, 1, 10)
      ORDER BY day ASC
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    return results.map((r) => DailyCO2.fromMap(r)).toList();
  }

  /// Get breakdown by transport mode
  Future<List<ModeCO2>> getModeTotals({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT
        sub_category,
        SUM(co2_kg) as total_co2,
        SUM(value) as total_distance,
        COUNT(*) as trip_count
      FROM $_table
      WHERE date >= ? AND date <= ? AND category = 'transport'
      GROUP BY sub_category
      ORDER BY total_co2 DESC
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    return results.map((r) => ModeCO2.fromMap(r)).toList();
  }

  /// Delete and insert entries atomically in a single transaction.
  /// Callers use this instead of looping deleteEntry/insertEntry to avoid
  /// triggering multiple refreshData() calls.
  Future<void> batchReplace({
    required List<int> idsToDelete,
    required List<EmissionEntry> entriesToInsert,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final id in idsToDelete) {
        await txn.delete(_table, where: 'id = ?', whereArgs: [id]);
      }
      for (final entry in entriesToInsert) {
        await txn.insert(_table, entry.toMap());
      }
    });
  }

  /// Aggregate lifetime CO2 savings from second-hand shopping entries.
  /// Uses a single SQL SUM rather than loading all rows into Dart.
  Future<double> getShoppingLifetimeSavings() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(CASE WHEN value > co2_kg THEN value - co2_kg ELSE 0 END), 0) '
      "AS savings FROM $_table WHERE category = 'shopping'",
    );
    return (result.first['savings'] as num).toDouble();
  }

  /// Export all data as JSON (for cloud backup)
  Future<String> exportToJson() async {
    final entries = await getEntries();
    final data = {
      'version': _dbVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'entries': entries.map((e) => e.toJson()).toList(),
    };
    return jsonEncode(data);
  }

  /// Import data from JSON (from cloud backup).
  /// Returns the number of new entries imported.
  /// Skips duplicates by comparing (date, category, subCategory, value, co2Kg).
  /// Throws [FormatException] if the JSON is malformed.
  Future<int> importFromJson(String jsonString) async {
    final dynamic decoded;
    try {
      decoded = jsonDecode(jsonString);
    } catch (e) {
      throw FormatException('Invalid backup file: $e');
    }
    if (decoded is! Map<String, dynamic> || decoded['entries'] is! List) {
      throw const FormatException('Backup file missing "entries" array');
    }
    final entries = (decoded['entries'] as List)
        .map((e) => EmissionEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    final db = await database;

    // Build a set of existing entry fingerprints for deduplication.
    final existing = await db.query(_table,
        columns: ['date', 'category', 'sub_category', 'value', 'co2_kg']);
    final fingerprints = existing.map((r) =>
        '${r['date']}|${r['category']}|${r['sub_category']}|${r['value']}|${r['co2_kg']}')
        .toSet();

    int count = 0;
    await db.transaction((txn) async {
      for (final entry in entries) {
        final fp = '${entry.date.toIso8601String()}|${entry.category.name}'
            '|${entry.subCategory}|${entry.value}|${entry.co2Kg}';
        if (fingerprints.contains(fp)) continue;
        fingerprints.add(fp);
        await txn.insert(_table, entry.copyWith(id: null).toMap());
        count++;
      }
    });
    return count;
  }

  /// Clear all tracking data (emission entries and habit logs).
  /// Preserves user configuration (energy_profiles, waste_setup).
  Future<void> clearAll() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(_table);
      await txn.delete('habit_logs');
    });
  }

  /// Get entry count, optionally filtered by category
  Future<int> getEntryCount({EmissionCategory? category}) async {
    final db = await database;
    if (category == null) {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_table');
      return (result.first['count'] as int?) ?? 0;
    }
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_table WHERE category = ?',
      [category.name],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  // --- Energy Profile CRUD ---

  Future<void> saveEnergyProfile(EnergyProfile profile) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final map = profile.toMap()
      ..['created_at'] = now
      ..['updated_at'] = now;
    // Wrap in a transaction so the profile is never lost on a crash
    // between the DELETE and INSERT.
    await db.transaction((txn) async {
      await txn.delete('energy_profiles');
      await txn.insert('energy_profiles', map);
    });
  }

  Future<EnergyProfile?> getEnergyProfile() async {
    final db = await database;
    final results = await db.query('energy_profiles', limit: 1);
    if (results.isEmpty) return null;
    return EnergyProfile.fromMap(results.first);
  }

  // --- Waste Setup CRUD ---

  Future<void> saveWasteSetup(WasteSetup setup) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      await txn.delete('waste_setup');
      await txn.insert('waste_setup', {
        ...setup.toMap(),
        'created_at': now,
        'updated_at': now,
      });
    });
  }

  Future<WasteSetup?> getWasteSetup() async {
    final db = await database;
    final results = await db.query('waste_setup', limit: 1);
    if (results.isEmpty) return null;
    return WasteSetup.fromMap(results.first);
  }

  // --- Habit Log CRUD ---

  Future<void> insertHabitLog(HabitLog log) async {
    final db = await database;
    await db.insert('habit_logs', log.toMap());
  }

  Future<void> deleteHabitLog(DateTime date, HabitType habitType) async {
    final db = await database;
    await db.delete(
      'habit_logs',
      where: 'date LIKE ? AND habit_type = ?',
      whereArgs: ['${date.toIso8601String().substring(0, 10)}%', habitType.name],
    );
  }

  Future<bool> isHabitLoggedToday(HabitType habitType) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final result = await db.rawQuery(
      'SELECT COUNT(*) as c FROM habit_logs WHERE date LIKE ? AND habit_type = ?',
      ['$today%', habitType.name],
    );
    return ((result.first['c'] as int?) ?? 0) > 0;
  }

  Future<List<HabitLog>> getHabitLogs({int limitDays = 60}) async {
    final db = await database;
    final since = DateTime.now()
        .subtract(Duration(days: limitDays))
        .toIso8601String();
    final results = await db.query(
      'habit_logs',
      where: 'date >= ?',
      whereArgs: [since],
      orderBy: 'date DESC',
    );
    return results.map(HabitLog.fromMap).toList();
  }

  // --- Saved Places CRUD ---

  Future<int> insertSavedPlace(SavedPlace place) async {
    final db = await database;
    return db.insert('saved_places', place.toMap());
  }

  Future<List<SavedPlace>> getSavedPlaces() async {
    final db = await database;
    final rows = await db.query('saved_places', orderBy: 'created_at ASC');
    return rows.map(SavedPlace.fromMap).toList();
  }

  Future<void> updateSavedPlace(SavedPlace place) async {
    final db = await database;
    await db.update(
      'saved_places',
      place.toMap(),
      where: 'id = ?',
      whereArgs: [place.id],
    );
  }

  Future<void> deleteSavedPlace(int id) async {
    final db = await database;
    // FK cascade is enabled globally in _initDatabase onOpen.
    await db.delete('saved_places', where: 'id = ?', whereArgs: [id]);
  }

  // --- Route Presets CRUD ---

  Future<void> upsertRoutePreset(RoutePreset preset) async {
    final db = await database;
    await db.insert(
      'route_presets',
      preset.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<RoutePreset?> getRoutePreset(int fromPlaceId, int toPlaceId) async {
    final db = await database;
    final rows = await db.query(
      'route_presets',
      where: 'from_place_id = ? AND to_place_id = ?',
      whereArgs: [fromPlaceId, toPlaceId],
      limit: 1,
    );
    return rows.isEmpty ? null : RoutePreset.fromMap(rows.first);
  }

  Future<List<RoutePreset>> getRoutePresetsForPlace(int placeId) async {
    final db = await database;
    final rows = await db.query(
      'route_presets',
      where: 'from_place_id = ? OR to_place_id = ?',
      whereArgs: [placeId, placeId],
    );
    return rows.map(RoutePreset.fromMap).toList();
  }

  /// Load all route presets in one query instead of N per-place queries.
  Future<List<RoutePreset>> getAllRoutePresets() async {
    final db = await database;
    final rows = await db.query('route_presets');
    return rows.map(RoutePreset.fromMap).toList();
  }
}

/// Daily CO2 aggregate for charts
class DailyCO2 {
  final DateTime day;
  final double totalCO2;
  final int entryCount;

  DailyCO2({
    required this.day,
    required this.totalCO2,
    required this.entryCount,
  });

  factory DailyCO2.fromMap(Map<String, dynamic> map) {
    return DailyCO2(
      day: DateTime.parse(map['day'] as String),
      totalCO2: (map['total_co2'] as num).toDouble(),
      entryCount: (map['entry_count'] as int?) ?? 0,
    );
  }
}

/// Transport mode CO2 aggregate
class ModeCO2 {
  final String subCategory;
  final double totalCO2;
  final double totalDistance;
  final int tripCount;

  ModeCO2({
    required this.subCategory,
    required this.totalCO2,
    required this.totalDistance,
    required this.tripCount,
  });

  factory ModeCO2.fromMap(Map<String, dynamic> map) {
    return ModeCO2(
      subCategory: map['sub_category'] as String,
      totalCO2: (map['total_co2'] as num).toDouble(),
      totalDistance: (map['total_distance'] as num).toDouble(),
      tripCount: (map['trip_count'] as int?) ?? 0,
    );
  }
}
