// test/widgets/category_picker_sheet_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carbon_tracker/widgets/category_picker_sheet.dart';

/// Helper that opens CategoryPickerSheet inside a modal bottom sheet,
/// matching how the app uses it in production.
/// Records the popped result so tests can verify it.
class _SheetOpener extends StatefulWidget {
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
  State<_SheetOpener> createState() => _SheetOpenerState();
}

class _SheetOpenerState extends State<_SheetOpener> {
  String? result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () async {
                final value = await showModalBottomSheet<String>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => CategoryPickerSheet(
                    foodEnabled: widget.foodEnabled,
                    energyEnabled: widget.energyEnabled,
                    shoppingEnabled: widget.shoppingEnabled,
                    wasteEnabled: widget.wasteEnabled,
                  ),
                );
                setState(() => result = value);
              },
              child: const Text('Open'),
            ),
            if (result != null) Text('Result: $result'),
          ],
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

  testWidgets('Tapping Transport tile returns "transport"', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Transport'));
    await tester.pumpAndSettle();

    expect(find.text('Result: transport'), findsOneWidget);
  });

  testWidgets('Tapping Food tile returns "food"', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();

    expect(find.text('Result: food'), findsOneWidget);
  });

  testWidgets('Tapping Energy tile returns "energy"', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Energy'));
    await tester.pumpAndSettle();

    expect(find.text('Result: energy'), findsOneWidget);
  });

  testWidgets('Tapping Shopping tile returns "shopping"', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Shopping'));
    await tester.pumpAndSettle();

    expect(find.text('Result: shopping'), findsOneWidget);
  });

  testWidgets('Tapping Waste tile returns "waste"', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Waste'));
    await tester.pumpAndSettle();

    expect(find.text('Result: waste'), findsOneWidget);
  });
}
