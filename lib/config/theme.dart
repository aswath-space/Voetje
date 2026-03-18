import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carbon_tracker/config/design_tokens.dart';

// ignore_for_file: deprecated_member_use_from_same_package

/// Legacy color constants kept for incremental migration of existing screens.
/// Migrate usages to [VoetjeColors] and remove this class once all screens
/// have been updated.
@Deprecated('Use VoetjeColors from design_tokens.dart instead')
class AppColors {
  static const primary = Color(0xFF2E7D32);
  static const primaryLight = Color(0xFF60AD5E);
  static const primaryDark = Color(0xFF005005);
  static const secondary = Color(0xFF558B2F);
  static const accent = Color(0xFFFFA726);
  static const background = Color(0xFFF5F9F3);
  static const surface = Colors.white;
  static const error = Color(0xFFD32F2F);

  // Emission level colors
  static const lowEmission = Color(0xFF4CAF50);
  static const mediumEmission = Color(0xFFFFC107);
  static const highEmission = Color(0xFFFF5722);

  // Transport mode colors
  static const walking = Color(0xFF4CAF50);
  static const cycling = Color(0xFF66BB6A);
  static const publicTransport = Color(0xFF42A5F5);
  static const car = Color(0xFFFF7043);
  static const flight = Color(0xFFEF5350);

  // Dark theme
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkCard = Color(0xFF2C2C2C);
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: VoetjeColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
          surface: VoetjeColors.surface,
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: VoetjeColors.primary,
          titleTextStyle: VoetjeTypography.pageTitle(),
        ),
        cardTheme: CardThemeData(
          elevation: 0.5,
          color: VoetjeColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VoetjeRadius.card),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: VoetjeColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(VoetjeRadius.input),
            borderSide: const BorderSide(color: VoetjeColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(VoetjeRadius.input),
            borderSide: const BorderSide(color: VoetjeColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(VoetjeRadius.input),
            borderSide:
                const BorderSide(color: VoetjeColors.primaryMedium, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        chipTheme: ChipThemeData(
          selectedColor: VoetjeColors.primary,
          shape: const StadiumBorder(),
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        switchTheme: SwitchThemeData(
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return VoetjeColors.primaryMedium;
            }
            return VoetjeColors.border;
          }),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          elevation: 0,
          backgroundColor: VoetjeColors.surface,
          selectedItemColor: VoetjeColors.primary,
          unselectedItemColor: VoetjeColors.inactiveNav,
          type: BottomNavigationBarType.fixed,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: VoetjeColors.darkBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.dark,
          surface: VoetjeColors.darkSurface,
        ).copyWith(
          primary: VoetjeColors.darkAccent,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: VoetjeColors.darkTextPrimary,
        ),
        cardTheme: CardThemeData(
          elevation: 0.5,
          color: VoetjeColors.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VoetjeRadius.card),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: VoetjeColors.darkSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(VoetjeRadius.input),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        switchTheme: SwitchThemeData(
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return VoetjeColors.darkAccent;
            }
            return VoetjeColors.darkTrack;
          }),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          elevation: 0,
          backgroundColor: VoetjeColors.darkSurface,
          selectedItemColor: VoetjeColors.darkAccent,
          unselectedItemColor: VoetjeColors.darkTextMuted,
          type: BottomNavigationBarType.fixed,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
      );
}
