// lib/data/nudge_messages.dart
import 'package:flutter/material.dart';
import 'package:carbon_tracker/models/waste_setup.dart';

/// A single nudge line. [icon] is displayed separately from [text]
/// so the screen can size and position them independently.
typedef NudgeMessage = ({String text, IconData icon});

/// A habit-specific nudge line.
/// [promptOnly] — if true, suppress this line once the habit is logged today.
typedef HabitLine = ({String text, bool promptOnly});

/// All nudge copy lives here. Edit this file to add, remove, or tweak messages.
///
/// Three pools:
///  - [habitLines]    — require habit data; may contain '{streak}' placeholder.
///                     Icon comes from HabitType.icon — do not duplicate it here.
///  - [activityLines] — require recent entry data; may contain '{days}' placeholder
///  - [generalLines]  — standalone; always available as fallback
class NudgeMessages {
  NudgeMessages._();

  // ── Habit-aware ────────────────────────────────────────────────────────────
  // Keyed by HabitType. Icon is NOT stored here — the picker uses habit.icon.
  // Template: {streak} = current streak count (int).
  // promptOnly: true  → suppress once the habit is logged today
  // promptOnly: false → show regardless of today's state

  static const Map<HabitType, List<HabitLine>> habitLines = {
    HabitType.reusableBottle: [
      (text: 'Your reusable bottle is literally right there. Judging you.', promptOnly: true),
      (text: 'Day {streak} with the reusable bottle. The tap water appreciates you.', promptOnly: false),
    ],
    HabitType.reusableCup: [
      (text: 'Day {streak} with the reusable cup. The barista noticed.', promptOnly: false),
      (text: 'No reusable cup logged yet today. Somewhere a barista is disappointed.', promptOnly: true),
    ],
    HabitType.reusableBag: [
      (text: 'Reusable bag streak: {streak}. The plastic bags are nervous.', promptOnly: false),
      (text: 'Bag it with the reusable today. You know where it is.', promptOnly: true),
    ],
  };

  // ── Activity-aware ─────────────────────────────────────────────────────────
  // Template: {days} = count of matching entries in the recent 10.

  static const List<NudgeMessage> activityLines = [
    (text: 'You drove {days} times recently. Your bike filed a complaint.', icon: Icons.directions_bike),
    (text: '{days} trips by public transport recently. Quietly heroic.', icon: Icons.directions_bus),
    (text: 'Plant-based yesterday? Your stomach and the planet both said thanks.', icon: Icons.eco),
    (text: 'Red meat a few times this week. Just saying.', icon: Icons.lunch_dining),
    (text: 'Cycled recently. We saw that.', icon: Icons.directions_bike),
  ];

  // ── General tips ───────────────────────────────────────────────────────────

  static const List<NudgeMessage> generalLines = [
    (text: 'Did you know? Cycling 5 km instead of driving saves ~1.2 kg CO₂.', icon: Icons.directions_bike),
    (text: 'One fewer red meat meal a week = ~3 kg CO₂ saved. That\'s just maths.', icon: Icons.lunch_dining),
    (text: 'The planet doesn\'t need you to be perfect. Just slightly less car-shaped.', icon: Icons.public),
    (text: 'A reusable cup pays back its carbon cost after ~20 uses. You\'ve probably hit that.', icon: Icons.coffee_outlined),
    (text: 'Short flights are disproportionately bad. Trains exist and they have snacks.', icon: Icons.train),
    (text: 'Washing clothes at 30°C uses ~40% less energy. Your clothes don\'t notice.', icon: Icons.local_laundry_service_outlined),
    (text: 'The best carbon offset is the one you didn\'t emit.', icon: Icons.eco),
  ];
}
