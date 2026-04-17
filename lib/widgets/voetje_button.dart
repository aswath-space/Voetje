import 'package:flutter/material.dart';
import '../config/design_tokens.dart';

/// Standard primary action button used across all entry forms and setup
/// wizards.
///
/// Shows a green glow shadow when enabled; collapses the shadow when
/// disabled so the disabled state is visually distinct. Use [label] for
/// text-only buttons or [icon] + [label] for icon buttons.
class VoetjeButton extends StatelessWidget {
  const VoetjeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;

  /// Optional leading icon shown before the label.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(VoetjeRadius.card),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: VoetjeColors.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: VoetjeColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: VoetjeColors.disabledButtonOf(context),
            disabledForegroundColor: VoetjeColors.disabledButtonFgOf(context),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(VoetjeRadius.card),
            ),
          ),
          child: icon != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: VoetjeIconSize.smallIcon,
                        color: enabled ? Colors.white : VoetjeColors.disabledButtonFgOf(context)),
                    const SizedBox(width: VoetjeSpacing.chipGap + 2),
                    Text(label, style: VoetjeTypography.buttonLabel()),
                  ],
                )
              : Text(label, style: VoetjeTypography.buttonLabel()),
        ),
      ),
    );
  }
}
