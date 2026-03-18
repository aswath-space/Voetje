// test/widgets/category_picker_sheet_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carbon_tracker/widgets/category_picker_sheet.dart';

/// Helper that opens the expanding log sheet inside a modal bottom sheet,
/// matching how the app uses it in production.
class _SheetOpener extends StatelessWidget {
  final bool foodEnabled;
  final bool energyEnabled;
  final bool shoppingEnabled;
  final bool wasteEnabled;

  const _SheetOpener({
    this.foodEnabled = true,
    this.energyEnabled = true,
    this.shoppingEnabled = true,
    this.wasteEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => CategoryPickerSheet(
                foodEnabled: foodEnabled,
                energyEnabled: energyEnabled,
                shoppingEnabled: shoppingEnabled,
                wasteEnabled: wasteEnabled,
              ),
            );
          },
          child: const Text('Open'),
        ),
      ),
    );
  }
}

Widget buildTestApp({
  bool foodEnabled = true,
  bool energyEnabled = true,
  bool shoppingEnabled = true,
  bool wasteEnabled = true,
}) {
  return MaterialApp(
    home: _SheetOpener(
      foodEnabled: foodEnabled,
      energyEnabled: energyEnabled,
      shoppingEnabled: shoppingEnabled,
      wasteEnabled: wasteEnabled,
    ),
  );
}

void main() {
  testWidgets('Shows all 5 tiles when all categories enabled', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Transport'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Energy'), findsOneWidget);
    expect(find.text('Shopping'), findsOneWidget);
    expect(find.text('Waste'), findsOneWidget);
  });

  testWidgets('Hides disabled categories (food=false, waste=false)',
      (tester) async {
    await tester.pumpWidget(buildTestApp(
      foodEnabled: false,
      wasteEnabled: false,
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Transport'), findsOneWidget);
    expect(find.text('Food'), findsNothing);
    expect(find.text('Energy'), findsOneWidget);
    expect(find.text('Shopping'), findsOneWidget);
    expect(find.text('Waste'), findsNothing);
  });

  testWidgets('Transport is always visible even when all others disabled',
      (tester) async {
    await tester.pumpWidget(buildTestApp(
      foodEnabled: false,
      energyEnabled: false,
      shoppingEnabled: false,
      wasteEnabled: false,
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Transport'), findsOneWidget);
    expect(find.text('Food'), findsNothing);
    expect(find.text('Energy'), findsNothing);
    expect(find.text('Shopping'), findsNothing);
    expect(find.text('Waste'), findsNothing);
  });

  testWidgets('Uses a 2-column GridView', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final gridFinder = find.byType(GridView);
    expect(gridFinder, findsOneWidget);

    final GridView grid = tester.widget(gridFinder);
    final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2);
  });

  testWidgets('Sheet shows title text', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('What are you logging?'), findsOneWidget);
  });
}
