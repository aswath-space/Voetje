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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(VoetjeRadius.iconContainer),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 20,
                color: color,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: VoetjeTypography.body().copyWith(
                    color: VoetjeColors.textMuted,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
