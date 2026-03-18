// test/screens/add_food_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:carbon_tracker/screens/add_food_screen.dart';
import 'package:carbon_tracker/models/meal_type.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carbon_tracker/providers/emission_provider.dart';
import 'package:carbon_tracker/models/emission_entry.dart';

// Minimal stub — only override addEntry to avoid DB calls in tests
class _StubEmissionProvider extends EmissionProvider {
  @override
  Future<void> initialize() async {
    // no-op in tests
  }

  @override
  Future<void> addEntry(EmissionEntry entry) async {
    // no-op in tests
  }

  @override
  Future<void> refreshData({SharedPreferences? prefs, bool silent = false}) async {
    // no-op in tests
  }
}

Widget buildScreen({MealSlot slot = MealSlot.dinner}) => MaterialApp(
  home: ChangeNotifierProvider<EmissionProvider>(
    create: (_) => _StubEmissionProvider(),
    child: AddFoodScreen(initialSlot: slot),
  ),
);

void main() {
  testWidgets('shows meal slot selector', (tester) async {
    await tester.pumpWidget(buildScreen(slot: MealSlot.dinner));
    await tester.pump();
    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Dinner'), findsOneWidget);
    expect(find.text('Snack'), findsOneWidget);
  });

  testWidgets('tapping Plant-based selects it (Save Meal button enabled)', (tester) async {
    await tester.pumpWidget(buildScreen(slot: MealSlot.dinner));
    await tester.pump();
    await tester.tap(find.text('Plant-based'));
    await tester.pump();
    // After selecting Plant-based, the Save Meal button becomes pressable
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('in between option visible', (tester) async {
    await tester.pumpWidget(buildScreen(slot: MealSlot.lunch));
    await tester.pump();
    expect(find.textContaining('Somewhere in between'), findsOneWidget);
  });
}
