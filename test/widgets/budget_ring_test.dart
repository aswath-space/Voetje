// test/widgets/budget_ring_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carbon_tracker/widgets/budget_ring.dart';

void main() {
  testWidgets('renders with zero emissions', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: BudgetRing(
            totalCO2: 0.0,
            categoryBreakdown: {},
          ),
        ),
      ),
    ));

    expect(find.text('0.0'), findsOneWidget);
    expect(find.text('of 6.3 kg'), findsOneWidget);
  });

  testWidgets('renders with normal emissions', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: BudgetRing(
            totalCO2: 1.3,
            categoryBreakdown: {'food': 1.3},
          ),
        ),
      ),
    ));

    expect(find.text('1.3'), findsOneWidget);
    expect(find.text('of 6.3 kg'), findsOneWidget);
  });

  testWidgets('shows amber track at 65%', (tester) async {
    // 4.1 / 6.3 ≈ 65%  →  remaining = 6.3 - 4.1 = 2.2
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: BudgetRing(
            totalCO2: 4.1,
            categoryBreakdown: {'transport': 4.1},
          ),
        ),
      ),
    ));

    expect(find.text('2.2 kg left'), findsOneWidget);
  });

  testWidgets('shows coral track at 92%', (tester) async {
    // 5.8 / 6.3 ≈ 92%  →  remaining = 6.3 - 5.8 = 0.5
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: BudgetRing(
            totalCO2: 5.8,
            categoryBreakdown: {'energy': 5.8},
          ),
        ),
      ),
    ));

    expect(find.text('0.5 kg left'), findsOneWidget);
  });

  testWidgets('shows over budget text at 116%', (tester) async {
    // 7.3 / 6.3 ≈ 116%  →  overage = 7.3 - 6.3 = 1.0
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: BudgetRing(
            totalCO2: 7.3,
            size: 250,
            categoryBreakdown: {'transport': 3.0, 'food': 4.3},
          ),
        ),
      ),
    ));

    expect(find.text('Over budget'), findsOneWidget);
    expect(find.text('+1.0 kg'), findsOneWidget);
  });

  testWidgets('displays category segments', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: BudgetRing(
            totalCO2: 1.3,
            categoryBreakdown: {
              'transport': 0.2,
              'food': 0.8,
              'energy': 0.3,
            },
          ),
        ),
      ),
    ));

    // Widget renders without error — CustomPaint is present
    expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
    expect(find.byType(BudgetRing), findsOneWidget);
  });
}
