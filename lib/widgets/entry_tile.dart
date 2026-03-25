import 'package:flutter/material.dart';
import '../config/design_tokens.dart';

class EntryTile extends StatelessWidget {
  const EntryTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.kgValue,
    required this.category,
    required this.icon,
    this.onTap,
    this.onDismissed,
  });

  final String title;
  final String? subtitle;
  final String kgValue;
  final String category;
  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onDismissed;

  Widget _buildTile(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: VoetjeColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(VoetjeRadius.input),
          boxShadow: const [
            BoxShadow(
              color: VoetjeColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: VoetjeIconSize.smallContainer,
              height: VoetjeIconSize.smallContainer,
              decoration: BoxDecoration(
                color: VoetjeColors.categoryBackgroundOf(context, category),
                borderRadius: BorderRadius.circular(VoetjeIconSize.smallRadius),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: VoetjeIconSize.smallIcon,
                color: VoetjeColors.categoryColor(category),
              ),
            ),
            const SizedBox(width: VoetjeSpacing.iconTextGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: VoetjeTypography.bodyEmphasis().copyWith(
                      color: VoetjeColors.textPrimaryOf(context),
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: VoetjeTypography.caption().copyWith(
                            color: VoetjeColors.captionColorOf(context),
                          ),
                    ),
                ],
              ),
            ),
            Text(
              kgValue,
              style: VoetjeTypography.bodyEmphasis().copyWith(
                    color: VoetjeColors.textSecondaryOf(context),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (onDismissed != null) {
      return Dismissible(
        key: key ?? UniqueKey(),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: VoetjeColors.destructive,
            borderRadius: BorderRadius.circular(VoetjeRadius.input),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
        ),
        onDismissed: (_) => onDismissed!(),
        child: _buildTile(context),
      );
    }
    return _buildTile(context);
  }
}
