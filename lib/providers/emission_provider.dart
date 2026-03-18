import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carbon_tracker/models/emission_entry.dart';
import 'package:carbon_tracker/models/energy_profile.dart';
import 'package:carbon_tracker/models/waste_setup.dart';
import 'package:carbon_tracker/models/saved_place.dart';
import 'package:carbon_tracker/models/route_preset.dart';
import 'package:carbon_tracker/models/transport_mode.dart';
import 'package:carbon_tracker/models/meal_type.dart';
import 'package:carbon_tracker/services/database_service.dart';
import 'package:carbon_tracker/services/cloud_sync_service.dart';
import 'package:carbon_tracker/services/energy_calculator.dart';
import 'package:carbon_tracker/services/waste_calculator.dart';

/// Central state management for the app.
/// Uses ChangeNotifier + Provider for simplicity.
class EmissionProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  late final CloudSyncService syncService;

  static const _kWasteEnabled = 'waste_enabled';
  static const _kWasteSuggestionDismissed = 'waste_suggestion_dismissed';
  static const _kFoodEnabled = 'food_enabled';
  static const _kDietPlant = 'diet_plant';
  static const _kDietChicken = 'diet_chicken';
  static const _kDietBetween = 'diet_between';
  static const _kDietRed = 'diet_red';
  static const _kDietFast = 'diet_fast';
  static const _kEnergyEnabled = 'energy_enabled';
  static const _kShoppingEnabled = 'shopping_enabled';
  static const _kInstallDate = 'install_date';
  static const _kFoodSuggestionDismissed = 'food_suggestion_dismissed';
  static const _kEnergySuggestionDismissed = 'energy_suggestion_dismissed';

  bool _isFirstLaunch = true;
  bool _isLoading = false;
  List<EmissionEntry> _recentEntries = [];
  double _todayCO2 = 0;
  double _todayTransportCO2 = 0;
  double _weekCO2 = 0;
  double _previousWeekCO2 = 0;
  double _monthCO2 = 0;
  List<DailyCO2> _weeklyChart = [];
  List<ModeCO2> _modeBreakdown = [];
  String _preferredUnit = 'km'; // km or mi

  bool _foodEnabled = false;
  int _dietPlant = 7, _dietChicken = 5, _dietBetween = 4, _dietRed = 3, _dietFast = 2;
  double _todayFoodCO2 = 0;
  List<EmissionEntry> _todayFoodEntries = [];
  bool _shouldSuggestFood = false;

  bool _energyEnabled = false;
  EnergyProfile? _energyProfile;
  double _energyDailyAvgCO2 = 0;
  bool _shouldSuggestEnergy = false;

  bool _shoppingEnabled = false;
  double _monthlyShoppingCO2 = 0;
  bool _shouldSuggestShopping = false;

  bool _wasteEnabled = false;
  WasteSetup? _wasteSetup;
  double _weeklyWasteCO2 = 0;
  double _recyclingRate = 0;
  List<HabitLog> _recentHabitLogs = [];
  bool _shouldSuggestWaste = false;
  final Map<HabitType, int> _habitStreaks = {};
  int _topHabitStreak = 0;
  HabitType? _topHabitType;

  double _lifetimeSecondHandSavings = 0;

  List<SavedPlace> _savedPlaces = [];
  final Map<String, RoutePreset> _routePresetCache = {};
  String? _refreshError;

  bool _initialized = false;

  // Getters
  bool get isFirstLaunch => _isFirstLaunch;
  bool get isLoading => _isLoading;
  List<EmissionEntry> get recentEntries => _recentEntries;
  double get todayCO2 => _todayCO2;
  double get todayTransportCO2 => _todayTransportCO2;
  double get weekCO2 => _weekCO2;
  double get previousWeekCO2 => _previousWeekCO2;
  double get monthCO2 => _monthCO2;
  List<DailyCO2> get weeklyChart => _weeklyChart;
  List<ModeCO2> get modeBreakdown => _modeBreakdown;
  String get preferredUnit => _preferredUnit;
  DatabaseService get db => _db;

  bool get foodEnabled => _foodEnabled;
  int get dietPlant => _dietPlant;
  int get dietChicken => _dietChicken;
  int get dietBetween => _dietBetween;
  int get dietRed => _dietRed;
  int get dietFast => _dietFast;
  double get todayFoodCO2 => _todayFoodCO2;
  List<EmissionEntry> get todayFoodEntries => List.unmodifiable(_todayFoodEntries);
  bool get shouldSuggestFood => _shouldSuggestFood;

  bool get energyEnabled => _energyEnabled;
  EnergyProfile? get energyProfile => _energyProfile;
  double get energyDailyAvgCO2 => _energyDailyAvgCO2;
  bool get shouldSuggestEnergy => _shouldSuggestEnergy;
  bool get initialized => _initialized;

  bool get shoppingEnabled => _shoppingEnabled;
  double get monthlyShoppingCO2 => _monthlyShoppingCO2;
  bool get shouldSuggestShopping => _shouldSuggestShopping;

  bool get wasteEnabled => _wasteEnabled;
  WasteSetup? get wasteSetup => _wasteSetup;
  double get weeklyWasteCO2 => _weeklyWasteCO2;
  double get recyclingRate => _recyclingRate;
  List<HabitLog> get recentHabitLogs => List.unmodifiable(_recentHabitLogs);
  bool get shouldSuggestWaste => _shouldSuggestWaste;
  int habitStreakFor(HabitType type) => _habitStreaks[type] ?? 0;
  int get topHabitStreak => _topHabitStreak;
  HabitType? get topHabitType => _topHabitType;

  double get lifetimeSecondHandSavings => _lifetimeSecondHandSavings;

  List<SavedPlace> get savedPlaces => List.unmodifiable(_savedPlaces);
  RoutePreset? cachedRoutePreset(int fromId, int toId) => _routePresetCache['$fromId-$toId'];
  String? get refreshError => _refreshError;

  /// Today's CO2 broken down by enabled category.
  Map<String, double> get todayCategoryBreakdown => {
    'transport': _todayTransportCO2,
    if (_foodEnabled) 'food': _todayFoodCO2,
    if (_energyEnabled) 'energy': _energyDailyAvgCO2,
    if (_shoppingEnabled) 'shopping': _monthlyShoppingCO2 / 30,
    if (_wasteEnabled) 'waste': _weeklyWasteCO2 / 7,
  };

  /// Today's logged entries (all categories).
  List<EmissionEntry> _todayEntries = [];
  List<EmissionEntry> get todayLoggedEntries => _todayEntries;

  /// Food meal slots not yet logged today.
  List<Map<String, dynamic>> get todayStillToLog {
    if (!_foodEnabled) return [];
    final loggedSlots = <MealSlot>{};
    for (final entry in _todayFoodEntries) {
      final note = entry.note ?? '';
      for (final slot in MealSlot.values) {
        if (slot == MealSlot.snack) continue; // snacks are unlimited
        if (note.startsWith(slot.label)) {
          loggedSlots.add(slot);
        }
      }
    }
    final stillToLog = <Map<String, dynamic>>[];
    for (final slot in [MealSlot.breakfast, MealSlot.lunch, MealSlot.dinner]) {
      if (!loggedSlots.contains(slot)) {
        stillToLog.add({
          'category': 'food',
          'label': slot.label,
          'slot': slot,
        });
      }
    }
    return stillToLog;
  }

  /// Initialize the provider on app start
  Future<void> initialize() async {
    syncService = CloudSyncService(_db);
    final results = await Future.wait([
      SharedPreferences.getInstance(),
      _db.getEnergyProfile(),
      _db.getSavedPlaces(),
      _db.getAllRoutePresets(),
      _db.getWasteSetup(),
    ]);
    final prefs = results[0] as SharedPreferences;
    _isFirstLaunch = prefs.getBool('is_first_launch') ?? true;
    _preferredUnit = prefs.getString('preferred_unit') ?? 'km';
    _foodEnabled = prefs.getBool(_kFoodEnabled) ?? false;
    _dietPlant = prefs.getInt(_kDietPlant) ?? 7;
    _dietChicken = prefs.getInt(_kDietChicken) ?? 5;
    _dietBetween = prefs.getInt(_kDietBetween) ?? 4;
    _dietRed = prefs.getInt(_kDietRed) ?? 3;
    _dietFast = prefs.getInt(_kDietFast) ?? 2;
    if (_isFirstLaunch) {
      await prefs.setString(_kInstallDate, DateTime.now().toIso8601String());
    }
    _energyEnabled = prefs.getBool(_kEnergyEnabled) ?? false;
    _energyProfile = results[1] as EnergyProfile?;
    _shoppingEnabled = prefs.getBool(_kShoppingEnabled) ?? false;
    _wasteEnabled = prefs.getBool(_kWasteEnabled) ?? false;
    _wasteSetup = results[4] as WasteSetup?;
    _savedPlaces = results[2] as List<SavedPlace>;
    _routePresetCache.clear();
    for (final p in results[3] as List<RoutePreset>) {
      _routePresetCache['${p.fromPlaceId}-${p.toPlaceId}'] = p;
    }
    await refreshData(prefs: prefs, silent: true);
    _initialized = true;
    notifyListeners();
  }

  /// Mark onboarding as complete (enables all categories by default)
  Future<void> completeOnboarding() async {
    await completeOnboardingWithCategories(
      food: true, energy: true, shopping: true, waste: true,
    );
  }

  /// Complete onboarding with selective category enablement
  Future<void> completeOnboardingWithCategories({
    required bool food,
    required bool energy,
    required bool shopping,
    required bool waste,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool(_kFoodEnabled, food),
      prefs.setBool(_kEnergyEnabled, energy),
      prefs.setBool(_kShoppingEnabled, shopping),
      prefs.setBool(_kWasteEnabled, waste),
      prefs.setBool('is_first_launch', false),
    ]);
    _foodEnabled = food;
    _energyEnabled = energy;
    _shoppingEnabled = shopping;
    _wasteEnabled = waste;
    _isFirstLaunch = false;
    await refreshData(prefs: prefs);
    notifyListeners();
  }

  /// Set preferred distance unit
  Future<void> setPreferredUnit(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_unit', unit);
    _preferredUnit = unit;
    notifyListeners();
  }

  /// Refresh all dashboard data
  Future<void> refreshData({SharedPreferences? prefs, bool silent = false}) async {
    _isLoading = true;
    _refreshError = null;
    if (!silent) notifyListeners();

    try {
      prefs ??= await SharedPreferences.getInstance();

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      // All queries launched concurrently via a named-futures map.
      // Note: weekCO2 sums all emission rows within the ISO week. Energy bills
      // are timestamped to their billing month start, so they only appear in
      // weekCO2 during the week they were entered. This is an inherent limitation
      // of storing energy as a monthly lump-sum rather than distributing it daily.
      // The dashboard shows energy as "(daily avg)" to make this explicit.
      final queries = <String, Future>{
        'todayTransport': _db.getTotalCO2(startDate: todayStart, endDate: now, category: EmissionCategory.transport),
        'weekTotal': _db.getTotalCO2(startDate: weekStart, endDate: now),
        'prevWeekTotal': _db.getTotalCO2(startDate: weekStart.subtract(const Duration(days: 7)), endDate: weekStart),
        'monthTotal': _db.getTotalCO2(startDate: monthStart, endDate: now),
        'recent': _db.getEntries(limit: 10),
        'todayAll': _db.getEntries(startDate: todayStart, endDate: now),
        'dailyTotals': _db.getDailyTotals(startDate: todayStart.subtract(const Duration(days: 6)), endDate: now),
        'modeTotals': _db.getModeTotals(startDate: monthStart, endDate: now),
        'transportCount': _db.getEntryCount(category: EmissionCategory.transport),
        'totalCount': _db.getEntryCount(),
        if (_foodEnabled) 'todayFood': _db.getTotalCO2(startDate: todayStart, endDate: now, category: EmissionCategory.food),
        if (_foodEnabled) 'todayFoodEntries': _db.getEntries(startDate: todayStart, endDate: now, category: EmissionCategory.food),
        if (_energyEnabled && _energyProfile != null) 'energyEntries': _db.getEntries(
          startDate: monthStart.subtract(const Duration(days: 60)), endDate: now, category: EmissionCategory.energy, limit: 5),
        if (_shoppingEnabled) 'shoppingMonthly': _db.getTotalCO2(startDate: monthStart, endDate: now, category: EmissionCategory.shopping),
        if (_shoppingEnabled) 'shoppingSavings': _db.getShoppingLifetimeSavings(),
        if (_wasteEnabled) 'wasteEntries': _db.getEntries(startDate: weekStart, endDate: now, category: EmissionCategory.waste),
        if (_wasteEnabled) 'habitLogs': _db.getHabitLogs(limitDays: 60),
      };
      final keys = queries.keys.toList();
      final values = await Future.wait(queries.values);
      final r = Map<String, dynamic>.fromIterables(keys, values);

      // --- Base fields ---
      _todayTransportCO2 = r['todayTransport'] as double;
      _todayCO2 = _todayTransportCO2;
      _weekCO2 = r['weekTotal'] as double;
      _previousWeekCO2 = r['prevWeekTotal'] as double;
      _monthCO2 = r['monthTotal'] as double;
      _recentEntries = r['recent'] as List<EmissionEntry>;
      _todayEntries = r['todayAll'] as List<EmissionEntry>;
      _weeklyChart = r['dailyTotals'] as List<DailyCO2>;
      _modeBreakdown = r['modeTotals'] as List<ModeCO2>;

      // --- Food ---
      if (_foodEnabled) {
        _todayFoodCO2 = r['todayFood'] as double;
        _todayFoodEntries = r['todayFoodEntries'] as List<EmissionEntry>;
        _todayCO2 += _todayFoodCO2;
      } else {
        _todayFoodCO2 = 0;
        _todayFoodEntries = [];
      }

      // Food suggestion unlock trigger
      final transportCount = r['transportCount'] as int;
      final foodDismissed = prefs.getBool(_kFoodSuggestionDismissed) ?? false;
      _shouldSuggestFood = !_foodEnabled && !foodDismissed && transportCount >= 7;

      // --- Energy ---
      // Compute daily average, then fold into the daily footprint total.
      // Shopping (monthly) and waste (weekly) are intentionally excluded from
      // _todayCO2 — they are shown in the breakdown with their own time-scale
      // labels and cannot be meaningfully attributed to a single day.
      if (_energyEnabled && _energyProfile != null) {
        final energyEntries = r['energyEntries'] as List<EmissionEntry>;
        if (energyEntries.isNotEmpty) {
          // Find the most recent billing month (from the most recent entry's date)
          final mostRecentEntry = energyEntries.first;
          final billingMonth = DateTime(mostRecentEntry.date.year, mostRecentEntry.date.month);
          // Sum all entries from that same billing month (handles both electricity + gas)
          final monthlyTotal = energyEntries
              .where((e) => e.date.year == billingMonth.year && e.date.month == billingMonth.month)
              .fold<double>(0, (sum, e) => sum + e.co2Kg);
          _energyDailyAvgCO2 = EnergyCalculator.dailyAverage(
            monthlyCO2: monthlyTotal,
            month: billingMonth,
          );
        } else {
          // Fall back to quick estimate, divided by actual days in current month
          final monthlyEstimate = EnergyCalculator.quickEstimate(
            countryCode: _energyProfile!.countryCode,
            householdSize: _energyProfile!.householdSize,
            adjustmentFactor: _energyProfile!.adjustmentFactor,
            heatingTypes: _energyProfile!.heatingTypes,
          );
          _energyDailyAvgCO2 = EnergyCalculator.dailyAverage(
            monthlyCO2: monthlyEstimate,
            month: DateTime(now.year, now.month),
          );
        }
        // Include energy daily avg in the headline daily footprint number.
        _todayCO2 += _energyDailyAvgCO2;
      } else {
        _energyDailyAvgCO2 = 0;
      }

      // --- Shopping ---
      if (_shoppingEnabled) {
        _monthlyShoppingCO2 = r['shoppingMonthly'] as double;
        _lifetimeSecondHandSavings = r['shoppingSavings'] as double;
      } else {
        _monthlyShoppingCO2 = 0;
        _lifetimeSecondHandSavings = 0;
      }
      // Shopping unlock: after energy is enabled
      _shouldSuggestShopping = !_shoppingEnabled && _energyEnabled;

      // --- Waste ---
      if (_wasteEnabled) {
        final wasteEntries = r['wasteEntries'] as List<EmissionEntry>;
        _weeklyWasteCO2 = wasteEntries.fold(0.0, (s, e) => s + e.co2Kg);
        _recyclingRate = WasteCalculator.recyclingRate(wasteEntries);
        _recentHabitLogs = r['habitLogs'] as List<HabitLog>;
        _recomputeHabitStreaks();
      } else {
        _weeklyWasteCO2 = 0;
        _recyclingRate = 0;
        _recentHabitLogs = [];
        _habitStreaks.clear();
        _topHabitStreak = 0;
        _topHabitType = null;
      }
      // Waste unlock: after shopping is enabled
      final wasteDismissed = prefs.getBool(_kWasteSuggestionDismissed) ?? false;
      _shouldSuggestWaste = !_wasteEnabled && _shoppingEnabled && !wasteDismissed;

      // Energy unlock trigger: 30+ total entries OR 4+ weeks since install
      final totalEntries = r['totalCount'] as int;
      final installDateStr = prefs.getString(_kInstallDate);
      bool fourWeeksOld = false;
      if (installDateStr != null) {
        final installDate = DateTime.parse(installDateStr);
        fourWeeksOld = DateTime.now().difference(installDate).inDays >= 28;
      }
      final energyDismissed = prefs.getBool(_kEnergySuggestionDismissed) ?? false;
      _shouldSuggestEnergy =
          !_energyEnabled && !energyDismissed && (totalEntries >= 30 || fourWeeksOld);
    } catch (e) {
      debugPrint('Error refreshing data: $e');
      _refreshError = 'Unable to load data. Pull down to refresh.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new emission entry
  Future<void> addEntry(EmissionEntry entry) async {
    await _db.insertEntry(entry);
    await refreshData();
  }

  /// Delete an entry
  Future<void> deleteEntry(int id) async {
    await _db.deleteEntry(id);
    await refreshData();
  }

  /// Update an entry
  Future<void> updateEntry(EmissionEntry entry) async {
    await _db.updateEntry(entry);
    await refreshData();
  }

  /// Dismiss the food unlock card for this install.
  Future<void> dismissFoodSuggestion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kFoodSuggestionDismissed, true);
    _shouldSuggestFood = false;
    notifyListeners();
  }

  /// Dismiss the energy unlock card for this install.
  Future<void> dismissEnergySuggestion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnergySuggestionDismissed, true);
    _shouldSuggestEnergy = false;
    notifyListeners();
  }

  /// Enable food tracking
  Future<void> enableFood() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kFoodEnabled, true);
    await prefs.remove(_kFoodSuggestionDismissed);
    _foodEnabled = true;
    await refreshData();
  }

  /// Save the user's weekly diet profile
  Future<void> saveDietProfile({
    required int plant,
    required int chicken,
    required int between,
    required int red,
    required int fast,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kDietPlant, plant);
    await prefs.setInt(_kDietChicken, chicken);
    await prefs.setInt(_kDietBetween, between);
    await prefs.setInt(_kDietRed, red);
    await prefs.setInt(_kDietFast, fast);
    _dietPlant = plant;
    _dietChicken = chicken;
    _dietBetween = between;
    _dietRed = red;
    _dietFast = fast;
    notifyListeners();
  }

  /// Get entries for history screen with pagination
  Future<List<EmissionEntry>> getHistoryEntries({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    return _db.getEntries(
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      offset: offset,
    );
  }

  /// Convert km to user's preferred unit
  double convertDistance(double km) {
    if (_preferredUnit == 'mi') return km * 0.621371;
    return km;
  }

  /// Convert from user's preferred unit to km
  double toKm(double distance) {
    if (_preferredUnit == 'mi') return distance / 0.621371;
    return distance;
  }

  String get unitLabel => _preferredUnit == 'mi' ? 'mi' : 'km';

  /// Complete energy setup and enable energy tracking.
  Future<void> setupEnergy(EnergyProfile profile) async {
    await _db.saveEnergyProfile(profile);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnergyEnabled, true);
    await prefs.remove(_kEnergySuggestionDismissed);
    _energyEnabled = true;
    _energyProfile = profile;
    await refreshData();
  }

  /// Enable shopping tracking.
  Future<void> enableShopping() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShoppingEnabled, true);
    _shoppingEnabled = true;
    await refreshData();
  }

  /// Enable energy tracking (flag only — tab will prompt setup if profile is null).
  Future<void> enableEnergy() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnergyEnabled, true);
    _energyEnabled = true;
    notifyListeners();
  }

  /// Enable waste tracking (flag only — tab will prompt setup if wasteSetup is null).
  Future<void> enableWaste() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kWasteEnabled, true);
    _wasteEnabled = true;
    notifyListeners();
  }

  /// Disable food tracking. Profile (diet split) survives — user doesn't redo setup.
  Future<void> disableFood() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kFoodEnabled, false);
    _foodEnabled = false;
    _todayFoodCO2 = 0;
    _todayFoodEntries = [];
    notifyListeners();
  }

  /// Disable energy tracking. Profile survives — user doesn't redo setup.
  Future<void> disableEnergy() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnergyEnabled, false);
    _energyEnabled = false;
    _energyDailyAvgCO2 = 0;
    notifyListeners();
  }

  /// Disable shopping tracking.
  Future<void> disableShopping() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShoppingEnabled, false);
    _shoppingEnabled = false;
    _monthlyShoppingCO2 = 0;
    _lifetimeSecondHandSavings = 0;
    notifyListeners();
  }

  /// Disable waste tracking. WasteSetup survives — user doesn't redo setup.
  Future<void> disableWaste() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kWasteEnabled, false);
    _wasteEnabled = false;
    _weeklyWasteCO2 = 0;
    notifyListeners();
  }

  /// Complete waste setup and enable waste tracking.
  Future<void> setupWaste(WasteSetup setup) async {
    await _db.saveWasteSetup(setup);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kWasteEnabled, true);
    await prefs.remove(_kWasteSuggestionDismissed);
    _wasteEnabled = true;
    _wasteSetup = setup;
    await refreshData();
  }

  /// Dismiss the waste unlock suggestion.
  Future<void> dismissWasteSuggestion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kWasteSuggestionDismissed, true);
    _shouldSuggestWaste = false;
    notifyListeners();
  }

  /// Recompute per-habit streaks and the dashboard top-streak from cached logs.
  void _recomputeHabitStreaks() {
    _topHabitStreak = 0;
    _topHabitType = null;
    for (final habit in HabitType.values) {
      final s = WasteCalculator.habitStreak(_recentHabitLogs, habit);
      _habitStreaks[habit] = s;
      if (s > _topHabitStreak) {
        _topHabitStreak = s;
        _topHabitType = habit;
      }
    }
  }

  /// Delete and insert entries atomically, then refresh once.
  /// Use instead of looping addEntry/deleteEntry to avoid cascading refreshes.
  Future<void> batchReplace({
    required List<int> idsToDelete,
    required List<EmissionEntry> entriesToInsert,
  }) async {
    await _db.batchReplace(
      idsToDelete: idsToDelete,
      entriesToInsert: entriesToInsert,
    );
    await refreshData();
  }

  /// Toggle a daily habit on/off for today.
  Future<void> toggleHabit(HabitType habitType) async {
    final isLogged = await _db.isHabitLoggedToday(habitType);
    final today = DateTime.now();
    if (isLogged) {
      await _db.deleteHabitLog(today, habitType);
    } else {
      await _db.insertHabitLog(HabitLog(date: today, habitType: habitType));
    }
    _recentHabitLogs = await _db.getHabitLogs(limitDays: 60);
    _recomputeHabitStreaks();
    notifyListeners();
  }

  /// Whether a habit has been logged today.
  Future<bool> isHabitLoggedToday(HabitType habitType) =>
      _db.isHabitLoggedToday(habitType);

  /// Update the user's energy adjustment factor (estimate mode slider).
  Future<void> updateEnergyAdjustment(double factor) async {
    if (_energyProfile == null) return;
    final updated = EnergyProfile(
      countryCode: _energyProfile!.countryCode,
      stateCode: _energyProfile!.stateCode,
      heatingTypes: _energyProfile!.heatingTypes,
      householdSize: _energyProfile!.householdSize,
      method: _energyProfile!.method,
      adjustmentFactor: factor,
      updatedAt: DateTime.now(),
    );
    await _db.saveEnergyProfile(updated);
    _energyProfile = updated;
    await refreshData();
  }

  // --- Saved Places ---

  Future<void> savePlace(SavedPlace place) async {
    if (place.id == null) {
      await _db.insertSavedPlace(place);
    } else {
      await _db.updateSavedPlace(place);
    }
    _savedPlaces = await _db.getSavedPlaces();
    notifyListeners();
  }

  Future<void> deletePlace(int id) async {
    await _db.deleteSavedPlace(id);
    _savedPlaces = await _db.getSavedPlaces();
    _routePresetCache.removeWhere(
      (key, _) => key.startsWith('$id-') || key.endsWith('-$id'),
    );
    notifyListeners();
  }

  Future<int> routePresetCountForPlace(int placeId) async {
    final presets = await _db.getRoutePresetsForPlace(placeId);
    return presets.length;
  }

  Future<void> upsertRoutePreset(int fromPlaceId, int toPlaceId, TransportMode mode) async {
    final ids = _savedPlaces.map((p) => p.id).toSet();
    if (!ids.contains(fromPlaceId) || !ids.contains(toPlaceId)) return;
    final preset = RoutePreset(
      fromPlaceId: fromPlaceId,
      toPlaceId: toPlaceId,
      lastMode: mode.name,
      lastUsedAt: DateTime.now(),
    );
    await _db.upsertRoutePreset(preset);
    _routePresetCache['$fromPlaceId-$toPlaceId'] = preset;
  }

}
