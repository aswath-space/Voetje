// test/widgets/todays_meals_card_test.dart
// TodaysMealsCard was removed in the UX refresh. This file now tests
// StillToLogCard, which replaced it as the "nudge to log" widget.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carbon_tracker/widgets/still_to_log_card.dart';

void main() {
  testWidgets('StillToLogCard renders label and icon', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StillToLogCard(
          label: 'Breakfast',
          icon: Icons.free_breakfast,
          color: Colors.green,
          onTap: () {},
        ),
      ),
    ));
    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.byIcon(Icons.free_breakfast), findsOneWidget);
  });

  testWidgets('StillToLogCard calls onTap when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StillToLogCard(
          label: 'Lunch',
          icon: Icons.lunch_dining,
          color: Colors.orange,
          onTap: () => tapped = true,
        ),
      ),
    ));
    await tester.tap(find.byType(StillToLogCard));
    expect(tapped, isTrue);
  });
}
