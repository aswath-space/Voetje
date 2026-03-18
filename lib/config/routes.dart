import 'package:flutter/material.dart';
import 'package:carbon_tracker/screens/add_entry_screen.dart';
import 'package:carbon_tracker/screens/history_screen.dart';
import 'package:carbon_tracker/screens/settings_screen.dart';
import 'package:carbon_tracker/screens/support_screen.dart';
import 'package:carbon_tracker/screens/onboarding_screen.dart';
import 'package:carbon_tracker/screens/saved_places_screen.dart';

class AppRoutes {
  static const home = '/';
  static const addEntry = '/add';
  static const history = '/history';
  static const settings = '/settings';
  static const support = '/support';
  static const onboarding = '/onboarding';
  static const savedPlaces = '/saved-places';

  static Map<String, WidgetBuilder> get routes => {
        addEntry: (_) => const AddTransportScreen(),
        history: (_) => const HistoryScreen(),
        settings: (_) => const SettingsScreen(),
        support: (_) => const SupportScreen(),
        onboarding: (_) => const OnboardingScreen(),
        savedPlaces: (_) => const SavedPlacesScreen(),
      };
}
