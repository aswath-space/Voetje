// test/widgets/add_place_sheet_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carbon_tracker/providers/emission_provider.dart';
import 'package:carbon_tracker/models/saved_place.dart';
import 'package:carbon_tracker/widgets/add_place_sheet.dart';

class _StubEmissionProvider extends EmissionProvider {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> refreshData({SharedPreferences? prefs, bool silent = false}) async {}

  @override
  Future<void> savePlace(SavedPlace place) async {}
}

/// Helper that opens AddPlaceSheet inside a modal bottom sheet,
/// matching how the app uses it in production.
Widget buildTestApp({SavedPlace? editing}) {
  return MaterialApp(
    home: ChangeNotifierProvider<EmissionProvider>(
      create: (_) => _StubEmissionProvider(),
      child: _SheetOpener(editing: editing),
    ),
  );
}

/// Scaffold with a button that opens AddPlaceSheet as a modal bottom sheet.
class _SheetOpener extends StatelessWidget {
  final SavedPlace? editing;
  const _SheetOpener({this.editing});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => editing == null
                ? const AddPlaceSheet()
                : AddPlaceSheet(editing: editing),
          ),
          child: const Text('Open'),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('sheet renders a name field and a "Use my location" button',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Name text field
    expect(find.widgetWithText(TextField, 'Name'), findsOneWidget);

    // "Use my location" button
    expect(find.text('Use my location'), findsOneWidget);
  });

  testWidgets('save button is disabled when the name is empty', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // The save button should say "Add place" and be disabled (onPressed == null)
    final addPlaceButton = find.widgetWithText(FilledButton, 'Add place');
    expect(addPlaceButton, findsOneWidget);

    final FilledButton button = tester.widget(addPlaceButton);
    expect(button.onPressed, isNull, reason: 'Save button should be disabled when name is empty');
  });
}
