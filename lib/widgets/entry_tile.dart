import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: VoetjeColors.categoryBackground(category),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 15,
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
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: VoetjeColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: VoetjeColors.captionColor,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              kgValue,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
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
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
        ),
        onDismissed: (_) => onDismissed!(),
        child: _buildTile(),
      );
    }
    return _buildTile();
  }
}
