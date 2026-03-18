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

  Widget _buildTile() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: VoetjeColors.surface,
          borderRadius: BorderRadius.circular(VoetjeRadius.input),
          boxShadow: const [
            BoxShadow(
              color: VoetjeColors.shadowLight,
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: VoetjeColors.categoryBackground(category),
                borderRadius: BorderRadius.circular(VoetjeRadius.iconContainer),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 18,
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
                    style: VoetjeTypography.bodyEmphasis(),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: VoetjeTypography.caption().copyWith(
                            color: VoetjeColors.captionColor,
                          ),
                    ),
                ],
              ),
            ),
            Text(
              kgValue,
              style: VoetjeTypography.bodyEmphasis().copyWith(
                    color: VoetjeColors.textSecondary,
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
          child: const Icon(Icons.delete_outline, color: VoetjeColors.surface, size: 20),
        ),
        onDismissed: (_) => onDismissed!(),
        child: _buildTile(),
      );
    }
    return _buildTile();
  }
}
