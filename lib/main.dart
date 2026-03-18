import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:carbon_tracker/providers/emission_provider.dart';
import 'package:carbon_tracker/app.dart';

void main() async {
  if (kDebugMode) {
    MarionetteBinding.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }
  runApp(
    ChangeNotifierProvider(
      create: (_) => EmissionProvider()..initialize(),
      child: const CarbonTrackerApp(),
    ),
  );
}
