import 'package:flutter/material.dart';
import '../config/design_tokens.dart';

/// Signals that descendants are inside an expanding bottom sheet.
/// VoetjeScreenShell reads this to decide standalone vs embedded mode.
class EmbeddedSheetScope extends InheritedWidget {
  const EmbeddedSheetScope({super.key, required super.child});

  static bool of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<EmbeddedSheetScope>() != null;
  }

  @override
  bool updateShouldNotify(EmbeddedSheetScope oldWidget) => false;
}

/// A shared screen wrapper that provides consistent layout across the app.
///
/// When [embedded] is true (inside expanding bottom sheet), skips the Scaffold
/// and SafeArea top padding. When false (standalone screen), wraps in Scaffold
/// with AppBar.
///
/// Usage:
/// ```dart
/// VoetjeScreenShell(
///   title: 'Log a Meal',
///   child: MyFormContent(),
/// )
/// ```
class VoetjeScreenShell extends StatelessWidget {
  const VoetjeScreenShell({
    super.key,
    this.title,
    this.embedded = false,
    this.showBackButton = true,
    this.horizontalPadding = VoetjeSpacing.screenEdge,
    required this.child,
  });

  /// Screen title shown in AppBar. If null, no AppBar is shown.
  final String? title;

  /// True when rendered inside the expanding bottom sheet.
  /// Skips Scaffold wrapper and SafeArea top inset.
  final bool embedded;

  /// Whether to show a back button in the AppBar.
  final bool showBackButton;

  /// Horizontal padding for the content area.
  final double horizontalPadding;

  /// The screen content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Auto-detect embedded mode from ancestor EmbeddedSheetScope
    final isEmbedded = embedded || EmbeddedSheetScope.of(context);

    if (isEmbedded) {
      // Inside sheet — no Scaffold, no status bar padding
      return Material(
        color: VoetjeColors.background,
        child: Column(
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 20, 16, 0),
                child: Row(
                  children: [
                    if (showBackButton)
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        color: VoetjeColors.textPrimary,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    if (!showBackButton) const SizedBox(width: 16),
                    Text(title!, style: VoetjeTypography.pageTitle()),
                  ],
                ),
              ),
            Expanded(
              child: SafeArea(
                top: false,
                child: child,
              ),
            ),
          ],
        ),
      );
    }

    // Standalone screen — full Scaffold with AppBar
    return Scaffold(
      backgroundColor: VoetjeColors.background,
      appBar: title != null
          ? AppBar(
              title: Text(title!, style: VoetjeTypography.pageTitle()),
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: showBackButton ? const BackButton() : null,
            )
          : null,
      body: SafeArea(
        top: false,
        child: child,
      ),
    );
  }
}
