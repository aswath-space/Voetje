// lib/services/nudge_message_picker.dart
import 'dart:math';

import 'package:carbon_tracker/data/nudge_messages.dart';
import 'package:carbon_tracker/models/emission_entry.dart';
import 'package:carbon_tracker/models/meal_type.dart';
import 'package:carbon_tracker/models/transport_mode.dart';
import 'package:carbon_tracker/models/waste_setup.dart';
import 'package:carbon_tracker/providers/emission_provider.dart';

class NudgeMessagePicker {
  NudgeMessagePicker._();

  static final _random = Random();

  /// Public entry point — extracts data from the provider and delegates to
  /// [pickFromData]. Call only after provider.initialized == true.
  static NudgeMessage pick(EmissionProvider provider) {
    final today = DateTime.now();

    // Derive today's logged habit types from recentHabitLogs (synchronous).
    // Do NOT call provider.isHabitLoggedToday() — it returns Future<bool>.
    final todayHabitTypes = provider.recentHabitLogs
        .where((log) =>
            log.date.year == today.year &&
            log.date.month == today.month &&
            log.date.day == today.day)
        .map((log) => log.habitType)
        .toSet();

    final habitStreaks = {
      for (final h in HabitType.values) h: provider.habitStreakFor(h),
    };

    return pickFromData(
      wasteEnabled: provider.wasteEnabled,
      habitStreaks: habitStreaks,
      todayHabitTypes: todayHabitTypes,
      recentEntries: provider.recentEntries,
    );
  }

  /// Pure selection logic — exposed for testing without mocks.
  static NudgeMessage pickFromData({
    required bool wasteEnabled,
    required Map<HabitType, int> habitStreaks,
    required Set<HabitType> todayHabitTypes,
    required List<EmissionEntry> recentEntries,
  }) {
    // 1. Habit lines (only if waste tracking is set up)
    if (wasteEnabled) {
      final candidates = _habitCandidates(habitStreaks, todayHabitTypes);
      if (candidates.isNotEmpty) {
        return candidates[_random.nextInt(candidates.length)];
      }
    }

    // 2. Activity lines
    final activityCandidates = _activityCandidates(recentEntries);
    if (activityCandidates.isNotEmpty) {
      return activityCandidates[_random.nextInt(activityCandidates.length)];
    }

    // 3. General fallback
    const general = NudgeMessages.generalLines;
    return general[_random.nextInt(general.length)];
  }

  // ── Habit candidates ──────────────────────────────────────────────────────

  static List<NudgeMessage> _habitCandidates(
    Map<HabitType, int> streaks,
    Set<HabitType> loggedToday,
  ) {
    final results = <NudgeMessage>[];

    for (final entry in NudgeMessages.habitLines.entries) {
      final habit = entry.key;
      final streak = streaks[habit] ?? 0;
      final logged = loggedToday.contains(habit);

      for (final line in entry.value) {
        // Skip streak-based lines when streak is 0
        if (line.text.contains('{streak}') && streak == 0) continue;
        // Skip prompt-only lines when already logged today
        if (line.promptOnly && logged) continue;

        final resolved = line.text.replaceAll('{streak}', '$streak');
        // Emoji comes from the HabitType enum, not from the line (DRY)
        results.add((text: resolved, emoji: habit.emoji));
      }
    }

    return results;
  }

  // ── Activity candidates ───────────────────────────────────────────────────

  static List<NudgeMessage> _activityCandidates(List<EmissionEntry> entries) {
    final results = <NudgeMessage>[];

    final carCount = entries
        .where((e) =>
            e.category == EmissionCategory.transport &&
            (e.transportMode?.isCarMode ?? false))
        .length;

    final busCount = entries
        .where((e) =>
            e.category == EmissionCategory.transport &&
            _isPublicTransport(e.subCategory))
        .length;

    final hasRedMeat = entries.any((e) =>
        e.category == EmissionCategory.food &&
        e.subCategory == MealType.redMeat.name);

    final hasPlantBased = entries.any((e) =>
        e.category == EmissionCategory.food &&
        e.subCategory == MealType.plantBased.name);

    final hasCycle = entries.any((e) =>
        e.category == EmissionCategory.transport &&
        e.subCategory == TransportMode.cycling.name);

    for (final msg in NudgeMessages.activityLines) {
      if (msg.text.contains('drove') && carCount > 0) {
        results.add((
          text: msg.text.replaceAll('{days}', '$carCount'),
          emoji: msg.emoji,
        ));
      } else if (msg.text.contains('public transport') && busCount > 0) {
        results.add((
          text: msg.text.replaceAll('{days}', '$busCount'),
          emoji: msg.emoji,
        ));
      } else if (msg.text.contains('Plant-based') && hasPlantBased) {
        results.add(msg);
      } else if (msg.text.contains('Red meat') && hasRedMeat) {
        results.add(msg);
      } else if (msg.text.contains('Cycled') && hasCycle) {
        results.add(msg);
      }
    }

    return results;
  }

  static bool _isPublicTransport(String subCategory) {
    final mode = TransportMode.values.where((m) => m.name == subCategory).firstOrNull;
    if (mode == null) return false;
    return mode == TransportMode.bus ||
        mode == TransportMode.train ||
        mode == TransportMode.subway ||
        mode == TransportMode.ferry;
  }
}
