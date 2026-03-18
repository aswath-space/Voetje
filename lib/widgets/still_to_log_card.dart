import 'package:flutter/material.dart';
import '../config/design_tokens.dart';

class StillToLogCard extends StatelessWidget {
  const StillToLogCard({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(VoetjeRadius.input),
      child: Container(
        decoration: BoxDecoration(
          color: VoetjeColors.stillToLogBg,
          border: Border.all(
            color: VoetjeColors.dashedBorder,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(VoetjeRadius.input),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: VoetjeIconSize.mediumContainer,
              height: VoetjeIconSize.mediumContainer,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(VoetjeIconSize.mediumRadius),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: VoetjeIconSize.mediumIcon,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: VoetjeTypography.caption().copyWith(
                    color: VoetjeColors.textMuted,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
