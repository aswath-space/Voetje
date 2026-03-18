// test/widgets/route_picker_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carbon_tracker/models/saved_place.dart';
import 'package:carbon_tracker/providers/emission_provider.dart';
import 'package:carbon_tracker/widgets/route_picker.dart';

// ---------------------------------------------------------------------------
// Stub provider with configurable savedPlaces
// ---------------------------------------------------------------------------
class _StubEmissionProvider extends EmissionProvider {
  final List<SavedPlace> _places;

  _StubEmissionProvider({List<SavedPlace>? places})
      : _places = places ?? [];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> refreshData({SharedPreferences? prefs, bool silent = false}) async {}

  @override
  List<SavedPlace> get savedPlaces => List.unmodifiable(_places);

  @override
  Future<void> savePlace(SavedPlace place) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
Widget _buildApp({List<SavedPlace>? places}) {
  return MaterialApp(
    home: ChangeNotifierProvider<EmissionProvider>(
      create: (_) => _StubEmissionProvider(places: places),
      child: Scaffold(
        body: RoutePicker(onRouteSelected: (d, m, f, t) {}),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  group('RoutePicker', () {
    testWidgets('when < 2 saved places, shows "+ Add place" button',
        (tester) async {
      await tester.pumpWidget(_buildApp(places: []));
      await tester.pump();

      // Should show the inline "+ Add place" action chip
      expect(find.text('+ Add place'), findsOneWidget);

      // Should NOT show the old "Settings" nudge text
      expect(find.textContaining('Settings'), findsNothing);
    });

    testWidgets(
        'when >= 2 saved places, shows From/To dropdowns and "+ Add" chip',
        (tester) async {
      final places = [
        SavedPlace(id: 1, name: 'Home', latitude: 51.5, longitude: -0.1),
        SavedPlace(id: 2, name: 'Office', latitude: 51.6, longitude: -0.2),
      ];

      await tester.pumpWidget(_buildApp(places: places));
      await tester.pump();

      // From/To dropdowns should be present (label + hint = 2 each)
      expect(find.text('From'), findsWidgets);
      expect(find.text('To'), findsWidgets);

      // The small "+ Add" chip should appear
      expect(find.text('+ Add'), findsOneWidget);
    });
  });
}
