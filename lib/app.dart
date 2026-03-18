import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carbon_tracker/screens/splash_nudge_screen.dart';
import 'package:carbon_tracker/config/theme.dart';
import 'package:carbon_tracker/config/routes.dart';
import 'package:carbon_tracker/providers/emission_provider.dart';

class CarbonTrackerApp extends StatelessWidget {
  const CarbonTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voetje',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routes: AppRoutes.routes,
      // Selector rebuilds only home when initialized/isFirstLaunch change,
      // not on every notifyListeners() call from data refreshes.
      home: Selector<EmissionProvider, (bool, bool)>(
        selector: (_, p) => (p.initialized, p.isFirstLaunch),
        builder: (context, state, _) {
          return const SplashNudgeScreen();
        },
      ),
    );
  }
}
