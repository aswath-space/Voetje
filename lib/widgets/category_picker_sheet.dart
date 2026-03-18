import 'package:flutter/material.dart';
import 'package:carbon_tracker/config/design_tokens.dart';
import 'package:carbon_tracker/screens/add_entry_screen.dart';
import 'package:carbon_tracker/screens/add_food_screen.dart';
import 'package:carbon_tracker/screens/add_energy_screen.dart';
import 'package:carbon_tracker/screens/add_shopping_screen.dart';
import 'package:carbon_tracker/screens/add_waste_screen.dart';
import 'package:carbon_tracker/models/meal_type.dart';

/// A Duolingo-style expanding bottom sheet for logging emissions.
///
/// Opens at ~45% height showing a category grid. When the user taps a category
/// the sheet smoothly expands to ~95% height and cross-fades into the form.
/// Back navigation inside the sheet collapses back to the grid.
///
/// Show via [showExpandingLogSheet].
Future<void> showExpandingLogSheet(
  BuildContext context, {
  required bool foodEnabled,
  required bool energyEnabled,
  required bool shoppingEnabled,
  required bool wasteEnabled,
  String? initialCategory,
  MealSlot? initialMealSlot,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ExpandingLogSheet(
      foodEnabled: foodEnabled,
      energyEnabled: energyEnabled,
      shoppingEnabled: shoppingEnabled,
      wasteEnabled: wasteEnabled,
      initialCategory: initialCategory,
      initialMealSlot: initialMealSlot,
    ),
  );
}

// ── Main expanding sheet widget ──────────────────────────────────────────────

class _ExpandingLogSheet extends StatefulWidget {
  final bool foodEnabled;
  final bool energyEnabled;
  final bool shoppingEnabled;
  final bool wasteEnabled;
  final String? initialCategory;
  final MealSlot? initialMealSlot;

  const _ExpandingLogSheet({
    required this.foodEnabled,
    required this.energyEnabled,
    required this.shoppingEnabled,
    required this.wasteEnabled,
    this.initialCategory,
    this.initialMealSlot,
  });

  @override
  State<_ExpandingLogSheet> createState() => _ExpandingLogSheetState();
}

class _ExpandingLogSheetState extends State<_ExpandingLogSheet> {
  bool _showingForm = false;
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final _SheetNavigatorObserver _observer;

  @override
  void initState() {
    super.initState();
    _observer = _SheetNavigatorObserver(
      onPush: () {
        if (mounted) setState(() => _showingForm = true);
      },
      onPopToRoot: () {
        if (mounted) setState(() => _showingForm = false);
      },
    );

    // If an initial category was provided, push the form after the first frame.
    if (widget.initialCategory != null) {
      _showingForm = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pushForm(widget.initialCategory!);
      });
    }
  }

  void _pushForm(String category) {
    final screen = switch (category) {
      'food' => AddFoodScreen(initialSlot: widget.initialMealSlot),
      'energy' => const AddEnergyScreen(),
      'shopping' => const AddShoppingScreen(),
      'waste' => const AddWasteScreen(),
      _ => const AddTransportScreen() as Widget,
    };

    _navigatorKey.currentState?.push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;

    // Grid height: enough for the content (~45% of screen, min 320)
    // Form height: nearly full screen, leaving status bar visible
    final gridHeight = (screenHeight * 0.45).clamp(320.0, screenHeight * 0.55);
    final formHeight = screenHeight - topPadding - 8;

    return PopScope(
      canPop: !_showingForm,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _showingForm) {
          if (_navigatorKey.currentState?.canPop() ?? false) {
            _navigatorKey.currentState!.pop();
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        height: _showingForm ? formHeight : gridHeight,
        decoration: const BoxDecoration(
          color: VoetjeColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Navigator(
          key: _navigatorKey,
          observers: [_observer],
          onGenerateRoute: (_) => MaterialPageRoute(
            builder: (_) => _CategoryGrid(
              foodEnabled: widget.foodEnabled,
              energyEnabled: widget.energyEnabled,
              shoppingEnabled: widget.shoppingEnabled,
              wasteEnabled: widget.wasteEnabled,
              onCategoryTap: (category) => _pushForm(category),
              onDismiss: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Navigator observer ───────────────────────────────────────────────────────

class _SheetNavigatorObserver extends NavigatorObserver {
  final VoidCallback onPush;
  final VoidCallback onPopToRoot;

  _SheetNavigatorObserver({required this.onPush, required this.onPopToRoot});

  int _routeCount = 0;

  @override
  void didPush(Route route, Route? previousRoute) {
    _routeCount++;
    if (_routeCount > 1) onPush();
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _routeCount--;
    if (_routeCount <= 1) onPopToRoot();
  }
}

// ── Category grid (initial view) ─────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  final bool foodEnabled;
  final bool energyEnabled;
  final bool shoppingEnabled;
  final bool wasteEnabled;
  final void Function(String category) onCategoryTap;
  final VoidCallback onDismiss;

  const _CategoryGrid({
    required this.foodEnabled,
    required this.energyEnabled,
    required this.shoppingEnabled,
    required this.wasteEnabled,
    required this.onCategoryTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final categories = <_Category>[
      const _Category(key: 'transport', label: 'Transport', icon: Icons.directions_bike),
      if (foodEnabled)
        const _Category(key: 'food', label: 'Food', icon: Icons.restaurant),
      if (energyEnabled)
        const _Category(key: 'energy', label: 'Energy', icon: Icons.bolt),
      if (shoppingEnabled)
        const _Category(key: 'shopping', label: 'Shopping', icon: Icons.shopping_bag),
      if (wasteEnabled)
        const _Category(key: 'waste', label: 'Waste', icon: Icons.recycling),
    ];

    // Use a plain Material to avoid a nested Scaffold in the grid view.
    return Material(
      color: VoetjeColors.background,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: VoetjeColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                'What are you logging?',
                style: VoetjeTypography.sectionHeader(),
              ),
              const SizedBox(height: 16),
              // 2-column grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: categories.map((cat) {
                  return _CategoryTile(
                    category: cat,
                    onTap: () => onCategoryTap(cat.key),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data model & tile ────────────────────────────────────────────────────────

class _Category {
  final String key;
  final String label;
  final IconData icon;

  const _Category({required this.key, required this.label, required this.icon});
}

class _CategoryTile extends StatelessWidget {
  final _Category category;
  final VoidCallback onTap;

  const _CategoryTile({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final iconBg = VoetjeColors.categoryBackground(category.key);
    final iconColor = VoetjeColors.categoryColor(category.key);

    return Material(
      color: VoetjeColors.surface,
      borderRadius: BorderRadius.circular(VoetjeRadius.input),
      child: InkWell(
        borderRadius: BorderRadius.circular(VoetjeRadius.input),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(VoetjeRadius.input),
            border: Border.all(color: VoetjeColors.border, width: 1.5),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: VoetjeIconSize.largeContainer,
                  height: VoetjeIconSize.largeContainer,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(VoetjeIconSize.largeRadius),
                  ),
                  child: Icon(category.icon, size: VoetjeIconSize.largeIcon, color: iconColor),
                ),
                const SizedBox(height: 10),
                Text(
                  category.label,
                  style: VoetjeTypography.body().copyWith(
                    fontWeight: FontWeight.w600,
                    color: VoetjeColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Legacy compatibility ─────────────────────────────────────────────────────
// Keep the old class name so existing imports don't break, but it now redirects
// to the expanding sheet approach.

class CategoryPickerSheet extends StatelessWidget {
  final bool foodEnabled;
  final bool energyEnabled;
  final bool shoppingEnabled;
  final bool wasteEnabled;

  const CategoryPickerSheet({
    super.key,
    required this.foodEnabled,
    required this.energyEnabled,
    required this.shoppingEnabled,
    required this.wasteEnabled,
  });

  @override
  Widget build(BuildContext context) {
    // This is kept for backward compatibility but shouldn't normally be used
    // directly. Prefer [showExpandingLogSheet].
    return _ExpandingLogSheet(
      foodEnabled: foodEnabled,
      energyEnabled: energyEnabled,
      shoppingEnabled: shoppingEnabled,
      wasteEnabled: wasteEnabled,
    );
  }
}
