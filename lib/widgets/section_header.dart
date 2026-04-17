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
          style: VoetjeTypography.sectionLabel().copyWith(
            color: VoetjeColors.labelColorOf(context),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: VoetjeTypography.caption().copyWith(
                    fontWeight: FontWeight.w600,
                    color: VoetjeColors.primaryMediumOf(context),
                  ),
            ),
          ),
      ],
    );
  }
}
