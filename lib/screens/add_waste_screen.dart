import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carbon_tracker/config/design_tokens.dart';
import 'package:carbon_tracker/models/emission_entry.dart';
import 'package:carbon_tracker/models/waste_setup.dart';
import 'package:carbon_tracker/providers/emission_provider.dart';
import 'package:carbon_tracker/screens/waste_setup_screen.dart';
import 'package:carbon_tracker/services/waste_calculator.dart';
import 'package:carbon_tracker/widgets/screen_shell.dart';

class AddWasteScreen extends StatefulWidget {
  const AddWasteScreen({super.key});

  @override
  State<AddWasteScreen> createState() => _AddWasteScreenState();
}

class _AddWasteScreenState extends State<AddWasteScreen> {
  // fill fractions for own-bin users (0.0–1.0)
  final Map<BinType, double> _fills = {};
  // bag counts for communal-bin users
  final Map<BinType, double> _bags = {};

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmissionProvider>();
    final setup = provider.wasteSetup;

    if (setup == null || setup.enabledBins.isEmpty) {
      return VoetjeScreenShell(
        title: 'Log Waste',
        child: _SetupPrompt(),
      );
    }

    final bins = setup.enabledBins;
    final isOwn = setup.housingType == HousingType.ownBins;
    final totalCO2 = _computeTotalCO2(bins, isOwn);

    return VoetjeScreenShell(
      title: 'Log Waste',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(VoetjeSpacing.screenEdge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How full are your bins this week?',
              style: VoetjeTypography.sectionHeader(),
            ),
            const SizedBox(height: 4),
            Text(
              isOwn
                  ? 'Drag the slider to match your bin level.'
                  : 'Enter how many bags you put out this week.',
              style: VoetjeTypography.body().copyWith(
                  color: VoetjeColors.textMutedOf(context)),
            ),
            const SizedBox(height: 20),
            ...bins.map((bin) => isOwn
                ? _BinSlider(
                    bin: bin,
                    fill: _fills[bin] ?? 0.0,
                    onChanged: (v) => setState(() => _fills[bin] = v),
                  )
                : _BagCounter(
                    bin: bin,
                    count: _bags[bin]?.toInt() ?? 0,
                    onChanged: (v) =>
                        setState(() => _bags[bin] = v.toDouble()),
                  )),
            const SizedBox(height: 24),
            if (totalCO2 != 0) ...[
              _CO2PreviewCard(
                  totalCO2: totalCO2,
                  setup: setup,
                  fills: _fills,
                  bags: _bags,
                  isOwn: isOwn),
              const SizedBox(height: 24),
            ],
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _hasAnyInput(bins, isOwn)
                    ? () => _save(context, setup)
                    : null,
                icon: const Icon(Icons.check, color: Colors.white),
                label: Text(
                  'Save This Week',
                  style: VoetjeTypography.buttonLabel(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: VoetjeColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      VoetjeColors.disabledButtonOf(context),
                  elevation: 2,
                  shadowColor:
                      VoetjeColors.primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(VoetjeRadius.card),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  bool _hasAnyInput(List<BinType> bins, bool isOwn) {
    if (isOwn) return bins.any((b) => (_fills[b] ?? 0) > 0);
    return bins.any((b) => (_bags[b] ?? 0) > 0);
  }

  double _computeTotalCO2(List<BinType> bins, bool isOwn) {
    double total = 0;
    for (final bin in bins) {
      if (isOwn) {
        total += WasteCalculator.co2ForFill(bin, _fills[bin] ?? 0);
      } else {
        total += WasteCalculator.co2ForBags(bin, _bags[bin] ?? 0);
      }
    }
    return total;
  }

  Future<void> _save(BuildContext context, WasteSetup setup) async {
    final provider = context.read<EmissionProvider>();
    final isOwn = setup.housingType == HousingType.ownBins;
    final now = DateTime.now();

    // Check for existing waste entries this week — mirrors the energy screen pattern.
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart =
        todayStart.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final existingThisWeek = await provider.db.getEntries(
      startDate: weekStart,
      endDate: weekEnd,
      category: EmissionCategory.waste,
    );

    if (existingThisWeek.isNotEmpty) {
      if (!context.mounted) return;
      final replace = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Replace this week\'s waste?'),
          content: const Text(
            'You\'ve already logged waste for this week. Replace it?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Replace'),
            ),
          ],
        ),
      );
      if (replace != true) return;
    }

    final idsToDelete = existingThisWeek
        .where((e) => e.id != null)
        .map((e) => e.id!)
        .toList();

    final entriesToInsert = <EmissionEntry>[];
    for (final bin in setup.enabledBins) {
      final kg = isOwn
          ? WasteCalculator.kgFromFillFraction(_fills[bin] ?? 0)
          : WasteCalculator.kgFromBagCount(_bags[bin] ?? 0);
      if (kg <= 0) continue;
      entriesToInsert.add(
          EmissionEntry.waste(date: now, binType: bin, kgWeight: kg));
    }

    await provider.batchReplace(
      idsToDelete: idsToDelete,
      entriesToInsert: entriesToInsert,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waste logged for this week'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }
}

// ─── Bin slider widget (own-bin users) ───────────────────────────────────────

class _BinSlider extends StatelessWidget {
  final BinType bin;
  final double fill;
  final ValueChanged<double> onChanged;

  static const _fillLabels = ['Empty', '¼ full', '½ full', '¾ full', 'Full'];
  static const _fillValues = [0.0, 0.25, 0.5, 0.75, 1.0];

  const _BinSlider({
    required this.bin,
    required this.fill,
    required this.onChanged,
  });

  String get _fillLabel {
    final idx = (_fillValues.indexOf(_fillValues.reduce(
        (a, b) => (a - fill).abs() < (b - fill).abs() ? a : b)));
    return idx >= 0
        ? _fillLabels[idx]
        : '${(fill * 100).toStringAsFixed(0)}%';
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = fill > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: VoetjeColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(VoetjeRadius.card),
          border: Border.all(
            color: isSelected
                ? VoetjeColors.primaryMediumOf(context)
                : VoetjeColors.borderOf(context),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: VoetjeColors.shadowLight,
              blurRadius: 3,
              offset: Offset(0, 1),
            )
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(bin.icon, size: VoetjeIconSize.mediumIcon, color: _binColor(bin)),
              const SizedBox(width: 10),
              Text(bin.label,
                  style: VoetjeTypography.caption().copyWith(
                        fontWeight: FontWeight.w700,
                        color: VoetjeColors.textPrimaryOf(context),
                      )),
              const Spacer(),
              _BinIcon(fill: fill, color: _binColor(bin)),
            ]),
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _binColor(bin),
                thumbColor: _binColor(bin),
                inactiveTrackColor: VoetjeColors.borderOf(context),
                overlayColor:
                    _binColor(bin).withValues(alpha: 0.12),
              ),
              child: Slider(
                value: fill,
                min: 0,
                max: 1,
                divisions: 4,
                label: _fillLabel,
                onChanged: onChanged,
              ),
            ),
            Center(
              child: Text(
                _fillLabel,
                style: VoetjeTypography.caption(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _binColor(BinType bin) {
    return switch (bin) {
      BinType.generalWaste => Colors.grey.shade600,
      BinType.recycling => Colors.blue,
      BinType.foodWaste => Colors.amber.shade700,
      BinType.compost => Colors.green,
    };
  }
}

// ─── Bag counter widget (communal-bin users) ─────────────────────────────────

class _BagCounter extends StatelessWidget {
  final BinType bin;
  final int count;
  final ValueChanged<int> onChanged;

  const _BagCounter({
    required this.bin,
    required this.count,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = count > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: VoetjeColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(VoetjeRadius.card),
          border: Border.all(
            color: isSelected
                ? VoetjeColors.primaryMediumOf(context)
                : VoetjeColors.borderOf(context),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: VoetjeColors.shadowLight,
              blurRadius: 3,
              offset: Offset(0, 1),
            )
          ],
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(bin.icon, size: VoetjeIconSize.mediumIcon, color: VoetjeColors.textMutedOf(context)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bin.label,
                      style: VoetjeTypography.caption().copyWith(
                            fontWeight: FontWeight.w700,
                            color: VoetjeColors.textPrimaryOf(context),
                          )),
                  Text(
                      '≈ ${WasteCalculator.kgFromBagCount(count.toDouble()).toStringAsFixed(0)} kg',
                      style: VoetjeTypography.caption()),
                ],
              ),
            ),
            IconButton(
              onPressed: count > 0 ? () => onChanged(count - 1) : null,
              icon: Icon(Icons.remove_circle_outline,
                  color: VoetjeColors.primaryMediumOf(context)),
            ),
            Text('$count',
                style: VoetjeTypography.pageQuestion().copyWith(
                      fontSize: 22,
                      color: VoetjeColors.textPrimaryOf(context),
                    )),
            IconButton(
              onPressed:
                  count < 20 ? () => onChanged(count + 1) : null,
              icon: Icon(Icons.add_circle_outline,
                  color: VoetjeColors.primaryMediumOf(context)),
            ),
            const SizedBox(width: 4),
            Text('bags', style: VoetjeTypography.caption()),
          ],
        ),
      ),
    );
  }
}

// ─── Visual bin fill illustration ────────────────────────────────────────────

class _BinIcon extends StatelessWidget {
  final double fill;
  final Color color;

  const _BinIcon({required this.fill, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 44,
      child: CustomPaint(painter: _BinPainter(fill: fill, color: color)),
    );
  }
}

class _BinPainter extends CustomPainter {
  final double fill;
  final Color color;

  _BinPainter({required this.fill, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final fill_ = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final rect =
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(4));
    final fillHeight = size.height * fill;
    final fillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
          0, size.height - fillHeight, size.width, fillHeight),
      const Radius.circular(4),
    );

    canvas.drawRRect(fillRect, fill_);
    canvas.drawRRect(rect, outline);
  }

  @override
  bool shouldRepaint(_BinPainter old) =>
      old.fill != fill || old.color != color;
}

// ─── CO2 preview card ─────────────────────────────────────────────────────────

class _CO2PreviewCard extends StatelessWidget {
  final double totalCO2;
  final WasteSetup setup;
  final Map<BinType, double> fills;
  final Map<BinType, double> bags;
  final bool isOwn;

  const _CO2PreviewCard({
    required this.totalCO2,
    required this.setup,
    required this.fills,
    required this.bags,
    required this.isOwn,
  });

  @override
  Widget build(BuildContext context) {
    final allKgs = setup.enabledBins.map((bin) {
      final kg = isOwn
          ? WasteCalculator.kgFromFillFraction(fills[bin] ?? 0)
          : WasteCalculator.kgFromBagCount(bags[bin] ?? 0);
      return (bin, kg);
    }).where((t) => t.$2 > 0).toList();

    final totalKg = allKgs.fold(0.0, (s, t) => s + t.$2);
    final divertedKg = allKgs
        .where((t) => t.$1.isRecycling)
        .fold(0.0, (s, t) => s + t.$2);
    final rate = totalKg > 0
        ? (divertedKg / totalKg * 100).clamp(0.0, 100.0)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: VoetjeColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(VoetjeRadius.card),
        border: Border.all(
            color: VoetjeColors.primaryMediumOf(context), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: VoetjeColors.shadowLight,
            blurRadius: 3,
            offset: Offset(0, 1),
          )
        ],
      ),
      padding: const EdgeInsets.all(VoetjeSpacing.cardPadding + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.recycling, color: VoetjeColors.primaryMediumOf(context)),
            const SizedBox(width: 8),
            Text(
              '${totalCO2.toStringAsFixed(2)} kg CO\u2082 this week',
              style: VoetjeTypography.caption().copyWith(
                    fontWeight: FontWeight.w700,
                    color: VoetjeColors.primaryMediumOf(context),
                  ),
            ),
          ]),
          if (setup.hasRecycling) ...[
            const SizedBox(height: 6),
            Text(
              'Recycling rate: ${rate.toStringAsFixed(0)}%',
              style: VoetjeTypography.body(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Prompt when waste hasn't been set up yet ─────────────────────────────────

class _SetupPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.recycling, size: VoetjeIconSize.xlargeIcon, color: VoetjeColors.primaryMediumOf(context)),
            const SizedBox(height: 16),
            Text(
              'Set up Waste tracking first',
              style: VoetjeTypography.sectionHeader().copyWith(fontSize: 17),
            ),
            const SizedBox(height: 8),
            Text(
              'Tell us which bins you use — takes 30 seconds.',
              textAlign: TextAlign.center,
              style: VoetjeTypography.body()
                  .copyWith(color: VoetjeColors.textMutedOf(context)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const WasteSetupScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: VoetjeColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(VoetjeRadius.card),
                  ),
                ),
                child: Text(
                  'Set up now',
                  style: VoetjeTypography.buttonLabel(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
