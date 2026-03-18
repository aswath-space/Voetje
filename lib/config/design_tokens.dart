import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VoetjeColors {
  // Backgrounds
  static const Color background = Color(0xFFE4F0E2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFFAFAFA);
  static const Color stillToLogBg = Color(0x99FFFFFF);

  // Brand
  static const Color primary = Color(0xFF1B5E20);
  static const Color primaryMedium = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF66BB6A);

  // Category identity — transport
  static const Color transport = Color(0xFF42A5F5);
  static const Color transportBg = Color(0xFFE3F2FD);

  // Category identity — food
  static const Color food = Color(0xFFFF8A65);
  static const Color foodBg = Color(0xFFFBE9E7);

  // Category identity — energy
  static const Color energy = Color(0xFF9575CD);
  static const Color energyBg = Color(0xFFEDE7F6);

  // Category identity — shopping
  static const Color shopping = Color(0xFFFFA726);
  static const Color shoppingBg = Color(0xFFFFF3E0);

  // Category identity — waste
  static const Color waste = Color(0xFF26A69A);
  static const Color wasteBg = Color(0xFFE0F2F1);

  // Ring threshold track colors
  static const Color trackNeutral = Color(0xFFE8E8E8);
  static const Color trackAmber = Color(0xFFFFE082);
  static const Color trackCoral = Color(0xFFEF9A9A);
  static const Color trackAmberText = Color(0xFFF9A825);
  static const Color trackCoralText = Color(0xFFEF5350);

  // Neutrals
  static const Color textPrimary = Color(0xFF1A2E1A);
  static const Color textSecondary = Color(0xFF4A5E4A);
  static const Color textMuted = Color(0xFF6B8A6B);
  static const Color labelColor = Color(0xFF85A085);
  static const Color captionColor = Color(0xFF93AB93);
  static const Color inactiveNav = Color(0xFFA0B8A0);
  static const Color border = Color(0xFFC8DAC4);
  static const Color dashedBorder = Color(0xFFA8C4A4);
  static const Color divider = Color(0xFFF0F4EE);

  // Shadows
  static const Color shadowLight = Color(0x12000000);
  static const Color shadowMedium = Color(0x1A000000);

  // Progress bar track
  static const Color progressTrack = Color(0xFFC6DAC2);

  // Destructive
  static const Color destructive = Color(0xFFEF5350);

  // Dark mode variants
  static const Color darkBackground = Color(0xFF1A2E1A);
  static const Color darkSurface = Color(0xFF1E2E1E);
  static const Color darkTrack = Color(0xFF2A2A2A);
  static const Color darkTextPrimary = Color(0xFFE8E8E8);
  static const Color darkTextSecondary = Color(0xFFA0A0A0);
  static const Color darkTextMuted = Color(0xFF6A6A6A);
  static const Color darkAccent = Color(0xFF66BB6A);

  // Helper methods
  static Color categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'transport':
        return transport;
      case 'food':
        return food;
      case 'energy':
        return energy;
      case 'shopping':
        return shopping;
      case 'waste':
        return waste;
      default:
        return primaryMedium;
    }
  }

  static Color categoryBackground(String category) {
    switch (category.toLowerCase()) {
      case 'transport':
        return transportBg;
      case 'food':
        return foodBg;
      case 'energy':
        return energyBg;
      case 'shopping':
        return shoppingBg;
      case 'waste':
        return wasteBg;
      default:
        return background;
    }
  }
}

class VoetjeSpacing {
  static const double screenEdge = 24;
  static const double cardPadding = 14;
  static const double cardGap = 8;
  static const double sectionGap = 14;
  static const double iconTextGap = 12;
  static const double chipGap = 6;
}

class VoetjeRadius {
  static const double card = 16;
  static const double chip = 20;
  static const double iconContainer = 10;
  static const double iconContainerMedium = 12;
  static const double iconContainerLarge = 14;
  static const double input = 14;
  static const double button = 20;
  static const double appFrame = 28;
}

/// Standardized icon container sizes.
/// Each size defines a container dimension, icon dimension, and border radius.
/// The icon-to-container ratio is consistently ~55%.
class VoetjeIconSize {
  // Small — entry tiles, list items, inline icons
  static const double smallContainer = 36;
  static const double smallIcon = 20;
  static const double smallRadius = VoetjeRadius.iconContainer; // 10

  // Medium — still-to-log cards, settings category rows, form option cards
  static const double mediumContainer = 44;
  static const double mediumIcon = 24;
  static const double mediumRadius = VoetjeRadius.iconContainerMedium; // 12

  // Large — category picker tiles, meal type cards, prominent selections
  static const double largeContainer = 52;
  static const double largeIcon = 28;
  static const double largeRadius = VoetjeRadius.iconContainerLarge; // 14

  // XLarge — onboarding illustrations, empty states, celebration screens
  static const double xlargeContainer = 72;
  static const double xlargeIcon = 40;
  static const double xlargeRadius = 18;

  /// Builds a standard icon container with category-colored background.
  static Widget container({
    required IconData icon,
    required Color color,
    double containerSize = mediumContainer,
    double iconSize = mediumIcon,
    double radius = mediumRadius,
    Color? backgroundColor,
  }) {
    return Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}

class VoetjeTypography {
  static TextStyle heroNumber() => GoogleFonts.plusJakartaSans(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: VoetjeColors.textPrimary,
      );

  static TextStyle pageTitle() => GoogleFonts.plusJakartaSans(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: VoetjeColors.primary,
      );

  static TextStyle sectionHeader() => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: VoetjeColors.textPrimary,
      );

  static TextStyle sectionLabel() => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: VoetjeColors.labelColor,
      );

  static TextStyle body() => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: VoetjeColors.textPrimary,
      );

  static TextStyle caption() => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: VoetjeColors.captionColor,
      );

  static TextStyle bodyEmphasis() => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: VoetjeColors.textPrimary,
      );

  static TextStyle pageQuestion() => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: VoetjeColors.primary,
      );

  static TextStyle buttonLabel() => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      );
}
