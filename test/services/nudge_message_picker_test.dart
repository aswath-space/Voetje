// test/services/nudge_message_picker_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:carbon_tracker/models/emission_entry.dart';
import 'package:carbon_tracker/models/meal_type.dart';
import 'package:carbon_tracker/models/transport_mode.dart';
import 'package:carbon_tracker/models/waste_setup.dart';
import 'package:carbon_tracker/services/nudge_message_picker.dart';

void main() {
  // Helper builders — note: EmissionEntry.food uses parameter name 'slot', not 'mealSlot'
  EmissionEntry carEntry() => EmissionEntry.transport(
        mode: TransportMode.carMedium,
        distanceKm: 10,
        date: DateTime.now(),
      );

  EmissionEntry busEntry() => EmissionEntry.transport(
        mode: TransportMode.bus,
        distanceKm: 5,
        date: DateTime.now(),
      );

  EmissionEntry redMeatEntry() => EmissionEntry.food(
        mealType: MealType.redMeat,
        slot: MealSlot.dinner,
        date: DateTime.now(),
      );

  EmissionEntry plantEntry() => EmissionEntry.food(
        mealType: MealType.plantBased,
        slot: MealSlot.lunch,
        date: DateTime.now(),
      );

  group('NudgeMessagePicker.pickFromData', () {
    test('always returns a non-empty message', () {
      final msg = NudgeMessagePicker.pickFromData(
        wasteEnabled: false,
        habitStreaks: {},
        todayHabitTypes: {},
        recentEntries: [],
      );
      expect(msg.text, isNotEmpty);
      expect(msg.emoji, isNotEmpty);
    });

    test('falls back to general lines when waste disabled', () {
      for (var i = 0; i < 50; i++) {
        final msg = NudgeMessagePicker.pickFromData(
          wasteEnabled: false,
          habitStreaks: {HabitType.reusableCup: 5},
          todayHabitTypes: {},
          recentEntries: [],
        );
        expect(msg.text.contains('barista'), isFalse);
        expect(msg.text.contains('{streak}'), isFalse);
      }
    });

    test('can pick habit lines when waste enabled and streak > 0', () {
      final found = <String>{};
      for (var i = 0; i < 100; i++) {
        final msg = NudgeMessagePicker.pickFromData(
          wasteEnabled: true,
          habitStreaks: {HabitType.reusableCup: 3},
          todayHabitTypes: {HabitType.reusableCup},
          recentEntries: [],
        );
        found.add(msg.text);
      }
      expect(
        found.any((t) => t.contains('cup') || t.contains('barista') || t.contains('Day')),
        isTrue,
      );
    });

    test('resolves {streak} placeholder', () {
      bool foundResolved = false;
      for (var i = 0; i < 100; i++) {
        final msg = NudgeMessagePicker.pickFromData(
          wasteEnabled: true,
          habitStreaks: {HabitType.reusableCup: 7},
          todayHabitTypes: {HabitType.reusableCup},
          recentEntries: [],
        );
        if (msg.text.contains('7')) foundResolved = true;
      }
      expect(foundResolved, isTrue);
    });

    test('never leaves {streak} or {days} unresolved in output', () {
      for (var i = 0; i < 50; i++) {
        final msg = NudgeMessagePicker.pickFromData(
          wasteEnabled: true,
          habitStreaks: {
            HabitType.reusableCup: 2,
            HabitType.reusableBottle: 4,
            HabitType.reusableBag: 1,
          },
          todayHabitTypes: {},
          recentEntries: [],
        );
        expect(msg.text.contains('{streak}'), isFalse);
        expect(msg.text.contains('{days}'), isFalse);
      }
    });

    test('can pick activity line when car entries present', () {
      final entries = List.generate(5, (_) => carEntry());
      final found = <String>{};
      for (var i = 0; i < 100; i++) {
        final msg = NudgeMessagePicker.pickFromData(
          wasteEnabled: false,
          habitStreaks: {},
          todayHabitTypes: {},
          recentEntries: entries,
        );
        found.add(msg.text);
      }
      expect(found.any((t) => t.contains('drove') || t.contains('bike')), isTrue);
    });

    test('resolves {days} with correct car count', () {
      final entries = List.generate(3, (_) => carEntry());
      bool foundResolved = false;
      for (var i = 0; i < 100; i++) {
        final msg = NudgeMessagePicker.pickFromData(
          wasteEnabled: false,
          habitStreaks: {},
          todayHabitTypes: {},
          recentEntries: entries,
        );
        if (msg.text.contains('drove') && msg.text.contains('3')) {
          foundResolved = true;
        }
      }
      expect(foundResolved, isTrue);
    });

    test('red meat entries produce red meat nudge', () {
      final entries = List.generate(3, (_) => redMeatEntry());
      final found = <String>{};
      for (var i = 0; i < 100; i++) {
        final msg = NudgeMessagePicker.pickFromData(
          wasteEnabled: false,
          habitStreaks: {},
          todayHabitTypes: {},
          recentEntries: entries,
        );
        found.add(msg.text);
      }
      expect(found.any((t) => t.contains('meat')), isTrue);
    });

    test('plant-based entries produce plant-based nudge', () {
      final entries = [plantEntry()];
      final found = <String>{};
      for (var i = 0; i < 100; i++) {
        final msg = NudgeMessagePicker.pickFromData(
          wasteEnabled: false,
          habitStreaks: {},
          todayHabitTypes: {},
          recentEntries: entries,
        );
        found.add(msg.text);
      }
      expect(found.any((t) => t.contains('Plant-based')), isTrue);
    });

    test('bus entries produce public transport nudge', () {
      final entries = List.generate(4, (_) => busEntry());
      final found = <String>{};
      for (var i = 0; i < 100; i++) {
        final msg = NudgeMessagePicker.pickFromData(
          wasteEnabled: false,
          habitStreaks: {},
          todayHabitTypes: {},
          recentEntries: entries,
        );
        found.add(msg.text);
      }
      expect(found.any((t) => t.contains('public transport')), isTrue);
    });
  });
}
