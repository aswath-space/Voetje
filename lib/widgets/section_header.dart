import 'package:flutter/material.dart';
import '../config/design_tokens.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.label,
    this.actionLabel,
    this.onAction,
  });

  final String label;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label.toUpperCase(),
          style: VoetjeTypography.sectionLabel(),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: VoetjeTypography.caption().copyWith(
                    fontWeight: FontWeight.w600,
                    color: VoetjeColors.primaryMedium,
                  ),
            ),
          ),
      ],
    );
  }
}
