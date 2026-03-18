// lib/widgets/budget_ring.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/design_tokens.dart';

class BudgetRing extends StatefulWidget {
  final double totalCO2;
  final double budget;
  final Map<String, double> categoryBreakdown;
  final double size;

  const BudgetRing({
    super.key,
    required this.totalCO2,
    this.budget = 6.3,
    required this.categoryBreakdown,
    this.size = 150,
  });

  @override
  State<BudgetRing> createState() => _BudgetRingState();
}

class _BudgetRingState extends State<BudgetRing> {
  @override
  Widget build(BuildContext context) {
    final ratio = widget.budget > 0 ? widget.totalCO2 / widget.budget : 0.0;
    final remaining = widget.budget - widget.totalCO2;
    final overage = widget.totalCO2 - widget.budget;

    Widget centerContent;

    if (ratio >= 1.0) {
      // Over budget
      centerContent = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Over budget',
            style: VoetjeTypography.caption().copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: VoetjeColors.destructive,
                ),
          ),
          Text(
            '+${overage.toStringAsFixed(1)} kg',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: VoetjeColors.destructive,
            ),
          ),
          Text(
            '${widget.totalCO2.toStringAsFixed(1)} of ${widget.budget.toStringAsFixed(1)} kg',
            style: VoetjeTypography.caption().copyWith(
                  fontSize: 13,
                  color: VoetjeColors.captionColor,
                ),
          ),
        ],
      );
    } else if (ratio >= 0.9) {
      // 90–100%: coral warning
      centerContent = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.totalCO2.toStringAsFixed(1),
            style: VoetjeTypography.heroNumber(),
          ),
          Text(
            '${remaining.toStringAsFixed(1)} kg left',
            style: VoetjeTypography.caption().copyWith(
                  color: VoetjeColors.trackCoralText,
                ),
          ),
        ],
      );
    } else if (ratio >= 0.6) {
      // 60–90%: amber warning
      centerContent = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.totalCO2.toStringAsFixed(1),
            style: VoetjeTypography.heroNumber(),
          ),
          Text(
            '${remaining.toStringAsFixed(1)} kg left',
            style: VoetjeTypography.caption().copyWith(
                  color: VoetjeColors.trackAmberText,
                ),
          ),
        ],
      );
    } else {
      // < 60%: normal
      centerContent = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.totalCO2.toStringAsFixed(1),
            style: VoetjeTypography.heroNumber(),
          ),
          Text(
            'of ${widget.budget.toStringAsFixed(1)} kg',
            style: VoetjeTypography.caption().copyWith(
                  fontSize: 13,
                  color: VoetjeColors.captionColor,
                ),
          ),
        ],
      );
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, animValue, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _BudgetRingPainter(
                  totalCO2: widget.totalCO2,
                  budget: widget.budget,
                  categoryBreakdown: widget.categoryBreakdown,
                  ratio: ratio,
                  animationValue: animValue,
                ),
              );
            },
          ),
          centerContent,
        ],
      ),
    );
  }
}

class _BudgetRingPainter extends CustomPainter {
  final double totalCO2;
  final double budget;
  final Map<String, double> categoryBreakdown;
  final double ratio;
  final double animationValue;

  static const double strokeWidth = 11.0;
  static const double gapDegrees = 2.0;
  static const double gapRadians = gapDegrees * math.pi / 180.0;

  _BudgetRingPainter({
    required this.totalCO2,
    required this.budget,
    required this.categoryBreakdown,
    required this.ratio,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Determine track color based on ratio
    Color trackColor;
    if (ratio >= 1.0) {
      trackColor = Colors.transparent;
    } else if (ratio >= 0.9) {
      trackColor = VoetjeColors.trackCoral;
    } else if (ratio >= 0.6) {
      trackColor = VoetjeColors.trackAmber;
    } else {
      trackColor = VoetjeColors.trackNeutral;
    }

    // Draw subtle border rings (inner + outer edge of the track)
    final borderPaint = Paint()
      ..color = VoetjeColors.border.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius + strokeWidth / 2, borderPaint);
    canvas.drawCircle(center, radius - strokeWidth / 2, borderPaint);

    // Draw background track circle
    if (trackColor != Colors.transparent) {
      final trackPaint = Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(center, radius, trackPaint);
    }

    // Draw category segments on top
    if (categoryBreakdown.isEmpty || budget <= 0) return;

    final entries = categoryBreakdown.entries.toList();
    final segmentCount = entries.length;

    // Total sweep angle capped at 2*pi, scaled by animation value
    final totalSweep = math.min(
          (totalCO2 / budget) * 2 * math.pi,
          2 * math.pi,
        ) *
        animationValue;

    // Calculate gap total and available sweep
    final totalGap = segmentCount > 1 ? gapRadians * segmentCount : 0.0;
    final availableSweep = math.max(0.0, totalSweep - totalGap);

    double startAngle = -math.pi / 2; // start from top

    for (int i = 0; i < segmentCount; i++) {
      final entry = entries[i];
      final segmentValue = entry.value.clamp(0.0, budget);
      final segmentFraction =
          totalCO2 > 0 ? segmentValue / totalCO2 : 0.0;
      final sweepAngle = availableSweep * segmentFraction;

      if (sweepAngle <= 0) continue;

      final segmentPaint = Paint()
        ..color = VoetjeColors.categoryColor(entry.key)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepAngle, false, segmentPaint);
      startAngle += sweepAngle + (segmentCount > 1 ? gapRadians : 0.0);
    }
  }

  @override
  bool shouldRepaint(_BudgetRingPainter oldDelegate) {
    return oldDelegate.totalCO2 != totalCO2 ||
        oldDelegate.budget != budget ||
        oldDelegate.categoryBreakdown != categoryBreakdown ||
        oldDelegate.ratio != ratio ||
        oldDelegate.animationValue != animationValue;
  }
}
