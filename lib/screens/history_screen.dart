import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:carbon_tracker/config/design_tokens.dart';
import 'package:carbon_tracker/models/emission_entry.dart';
import 'package:carbon_tracker/providers/emission_provider.dart';
import 'package:carbon_tracker/services/database_service.dart';
import 'package:carbon_tracker/widgets/entry_tile.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<EmissionEntry> _entries = [];
  bool _isLoading = false;
  int _offset = 0;
  static const _pageSize = 30;
  bool _hasMore = true;
  String? _selectedCategory;

  // Track last-seen recentEntries to avoid reload on every isLoading toggle.
  List<EmissionEntry> _lastSeenRecent = const [];

  static const _categories = [
    'All',
    'Transport',
    'Food',
    'Energy',
    'Shopping',
    'Waste',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<EmissionProvider>();
    if (!provider.isLoading && _lastSeenRecent != provider.recentEntries) {
      _lastSeenRecent = provider.recentEntries;
      _loadEntries(refresh: true);
    }
  }

  Future<void> _loadEntries({bool refresh = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    if (refresh) {
      _offset = 0;
      _entries = [];
      _hasMore = true;
    }

    final provider = context.read<EmissionProvider>();
    final category = _selectedCategory != null
        ? EmissionCategory.values.firstWhere(
            (c) => c.name.toLowerCase() == _selectedCategory!.toLowerCase(),
            orElse: () => EmissionCategory.transport,
          )
        : null;

    final newEntries = await provider.getHistoryEntries(
      limit: _pageSize,
      offset: _offset,
    );

    // Filter by category client-side when a filter is active.
    final filtered = category == null
        ? newEntries
        : newEntries.where((e) => e.category == category).toList();

    setState(() {
      _entries.addAll(filtered);
      _offset += newEntries.length; // advance by raw page size
      _hasMore = newEntries.length == _pageSize;
      _isLoading = false;
    });
  }

  void _onCategorySelected(String label) {
    final next = label == 'All' ? null : label.toLowerCase();
    if (next == _selectedCategory) return;
    setState(() => _selectedCategory = next);
    _loadEntries(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmissionProvider>();

    return Scaffold(
      backgroundColor: VoetjeColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadEntries(refresh: true),
          child: CustomScrollView(
            slivers: [
              // ── Page title ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                  child: Text('History', style: VoetjeTypography.pageTitle()),
                ),
              ),

              // ── Weekly summary card ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _WeeklySummaryCard(
                    weekCO2: provider.weekCO2,
                    previousWeekCO2: provider.previousWeekCO2,
                    chartData: provider.weeklyChart,
                  ),
                ),
              ),

              // ── Category filter chips ────────────────────────────────────
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final label = _categories[i];
                      final isSelected = label == 'All'
                          ? _selectedCategory == null
                          : _selectedCategory == label.toLowerCase();
                      return _FilterChip(
                        label: label,
                        selected: isSelected,
                        onTap: () => _onCategorySelected(label),
                      );
                    },
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // ── Entry list ───────────────────────────────────────────────
              if (_entries.isEmpty && !_isLoading)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history, size: 48,
                            color: VoetjeColors.border),
                        const SizedBox(height: 12),
                        Text(
                          'No entries logged yet',
                          style: VoetjeTypography.caption().copyWith(
                                color: VoetjeColors.textMuted,
                              ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == _entries.length) {
                          _loadEntries();
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final entry = _entries[index];
                        final showDate = index == 0 ||
                            !_isSameDay(_entries[index - 1].date, entry.date);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showDate)
                              Padding(
                                padding: const EdgeInsets.only(top: 12, bottom: 6),
                                child: Text(
                                  _formatDateHeader(entry.date),
                                  style: VoetjeTypography.sectionLabel(),
                                ),
                              ),
                            EntryTile(
                              key: Key('entry_${entry.id}'),
                              title: _titleForEntry(entry, provider),
                              subtitle: _subtitleForEntry(entry, provider),
                              kgValue: '${entry.co2Kg.toStringAsFixed(2)} kg',
                              category: entry.category.name,
                              icon: _iconForCategory(entry),
                              onDismissed: entry.id != null
                                  ? () {
                                      provider.deleteEntry(entry.id!);
                                      setState(() => _entries.removeAt(index));
                                    }
                                  : null,
                            ),
                            const SizedBox(height: 6),
                          ],
                        );
                      },
                      childCount: _entries.length + (_hasMore ? 1 : 0),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDay = DateTime(date.year, date.month, date.day);
    if (entryDay == today) return 'TODAY';
    if (entryDay == today.subtract(const Duration(days: 1))) return 'YESTERDAY';
    return DateFormat('EEEE, MMM d').format(date).toUpperCase();
  }

  String _titleForEntry(EmissionEntry entry, EmissionProvider provider) {
    switch (entry.category) {
      case EmissionCategory.food:
        return entry.mealType?.label ?? entry.subCategory;
      case EmissionCategory.energy:
        return entry.note ?? entry.subCategory;
      case EmissionCategory.waste:
        return entry.binType?.label ?? entry.subCategory;
      case EmissionCategory.shopping:
        final details = entry.shoppingDetails;
        return details != null ? details.$1 : entry.subCategory;
      default:
        return entry.transportMode?.label ?? entry.subCategory;
    }
  }

  String? _subtitleForEntry(EmissionEntry entry, EmissionProvider provider) {
    switch (entry.category) {
      case EmissionCategory.food:
        return entry.note;
      case EmissionCategory.energy:
        return entry.subCategory;
      case EmissionCategory.waste:
        return '${entry.value.toStringAsFixed(1)} kg waste';
      case EmissionCategory.shopping:
        final details = entry.shoppingDetails;
        if (details != null) {
          return details.$2.name.replaceAllMapped(
            RegExp(r'[A-Z]'),
            (m) => ' ${m.group(0)!.toLowerCase()}',
          ).trim();
        }
        return entry.note;
      default:
        return '${provider.convertDistance(entry.value).toStringAsFixed(1)} ${provider.unitLabel}';
    }
  }

  IconData _iconForCategory(EmissionEntry entry) {
    switch (entry.category) {
      case EmissionCategory.transport:
        return entry.transportMode?.icon ?? Icons.directions_car;
      case EmissionCategory.food:
        return entry.mealType?.icon ?? Icons.restaurant;
      case EmissionCategory.energy:
        return Icons.bolt;
      case EmissionCategory.shopping:
        return Icons.shopping_bag;
      case EmissionCategory.waste:
        return Icons.recycling;
    }
  }
}

// ── Weekly summary card ──────────────────────────────────────────────────────

class _WeeklySummaryCard extends StatelessWidget {
  final double weekCO2;
  final double previousWeekCO2;
  final List<DailyCO2> chartData;

  const _WeeklySummaryCard({
    required this.weekCO2,
    required this.previousWeekCO2,
    required this.chartData,
  });

  @override
  Widget build(BuildContext context) {
    // Trend badge
    Widget? trendBadge;
    if (previousWeekCO2 > 0) {
      final pct = ((weekCO2 - previousWeekCO2) / previousWeekCO2 * 100).abs();
      final isDown = weekCO2 < previousWeekCO2;
      trendBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isDown
              ? const Color(0xFFE8F5E9)
              : const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(VoetjeRadius.chip),
        ),
        child: Text(
          '${isDown ? '↓' : '↑'} ${pct.toStringAsFixed(0)}%',
          style: VoetjeTypography.caption().copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDown
                    ? VoetjeColors.primaryMedium
                    : VoetjeColors.trackAmberText,
              ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: VoetjeColors.surface,
        borderRadius: BorderRadius.circular(VoetjeRadius.card + 2),
        boxShadow: const [
          BoxShadow(
            color: VoetjeColors.shadowMedium,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Text('THIS WEEK', style: VoetjeTypography.sectionLabel()),
              const Spacer(),
              ?trendBadge,
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${weekCO2.toStringAsFixed(1)} kg CO₂',
            style: VoetjeTypography.sectionHeader().copyWith(
                  color: VoetjeColors.primaryMedium,
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: _MiniBarChart(data: chartData),
          ),
        ],
      ),
    );
  }
}

// ── Mini bar chart ────────────────────────────────────────────────────────────

class _MiniBarChart extends StatelessWidget {
  final List<DailyCO2> data;

  const _MiniBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      return DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - i));
    });

    final dayMap = <String, double>{};
    for (final d in data) {
      dayMap[DateFormat('yyyy-MM-dd').format(d.day)] = d.totalCO2;
    }

    final maxRaw = data.isEmpty
        ? 5.0
        : data.map((d) => d.totalCO2).reduce((a, b) => a > b ? a : b);
    final maxY = (maxRaw * 1.25).clamp(1.0, double.infinity);
    // Budget threshold line at ~4 kg/day (rough daily target)
    const budgetThreshold = 4.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (_, _, rod, _) => BarTooltipItem(
              '${rod.toY.toStringAsFixed(1)} kg',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
                final isToday = idx == days.length - 1;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    isToday ? 'Today' : DateFormat('E').format(days[idx]),
                    style: VoetjeTypography.caption().copyWith(
                          fontSize: 11,
                          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                          color: isToday
                              ? VoetjeColors.primary
                              : VoetjeColors.textMuted,
                        ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(days.length, (i) {
          final key = DateFormat('yyyy-MM-dd').format(days[i]);
          final value = dayMap[key] ?? 0;
          final isToday = i == days.length - 1;
          final overBudget = value > budgetThreshold;
          final Color barColor;
          if (isToday) {
            barColor = VoetjeColors.primaryMedium;
          } else if (overBudget) {
            barColor = VoetjeColors.trackAmberText;
          } else {
            barColor = VoetjeColors.progressTrack;
          }
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: value,
                color: barColor,
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? VoetjeColors.primary : VoetjeColors.surface,
          borderRadius: BorderRadius.circular(VoetjeRadius.chip),
          border: Border.all(
            color: selected
                ? VoetjeColors.primary
                : VoetjeColors.border,
          ),
        ),
        child: Text(
          label,
          style: VoetjeTypography.caption().copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? VoetjeColors.surface : VoetjeColors.textMuted,
              ),
        ),
      ),
    );
  }
}
