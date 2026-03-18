import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carbon_tracker/config/design_tokens.dart';
import 'package:carbon_tracker/providers/emission_provider.dart';
import 'package:carbon_tracker/services/food_calculator.dart';

class DietProfileScreen extends StatefulWidget {
  const DietProfileScreen({super.key});

  @override
  State<DietProfileScreen> createState() => _DietProfileScreenState();
}

class _DietProfileScreenState extends State<DietProfileScreen> {
  late int _plant, _chicken, _red, _fast;

  int get _between => FoodCalculator.remainingMeals(
        plant: _plant,
        chicken: _chicken,
        between: 0,
        red: _red,
        fast: _fast,
      );

  double get _weeklyCO2 => FoodCalculator.weeklyProfileCO2(
        plantBased: _plant,
        chickenOrFish: _chicken,
        inBetween: _between,
        redMeat: _red,
        fastFood: _fast,
      );

  @override
  void initState() {
    super.initState();
    final p = context.read<EmissionProvider>();
    _plant = p.dietPlant;
    _chicken = p.dietChicken;
    _red = p.dietRed;
    _fast = p.dietFast;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Diet Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('In a typical week, how many of your 21 meals have...'),
          const SizedBox(height: 16),
          _StepperRow(
            icon: Icons.eco,
            label: 'Plant-based',
            value: _plant,
            onChanged: (v) => setState(() => _plant = v),
          ),
          _StepperRow(
            icon: Icons.set_meal,
            label: 'Chicken or fish',
            value: _chicken,
            onChanged: (v) => setState(() => _chicken = v),
          ),
          _StepperRow(
            icon: Icons.lunch_dining,
            label: 'Red meat',
            value: _red,
            onChanged: (v) => setState(() => _red = v),
          ),
          _StepperRow(
            icon: Icons.fastfood,
            label: 'Fast food',
            value: _fast,
            onChanged: (v) => setState(() => _fast = v),
          ),
          const Divider(),
          ListTile(
            title: Text('Remaining: $_between meals'),
            subtitle: const Text('(counted as "in between" — 1.5 kg each)'),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Your food estimate:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '~${_weeklyCO2.toStringAsFixed(1)} kg CO₂/week',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text('≈ ${(_weeklyCO2 / 7).toStringAsFixed(1)} kg/day'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              final provider = context.read<EmissionProvider>();
              final nav = Navigator.of(context);
              await provider.saveDietProfile(
                    plant: _plant,
                    chicken: _chicken,
                    between: _between,
                    red: _red,
                    fast: _fast,
                  );
              if (mounted) nav.pop();
            },
            child: const Text('Save Profile'),
          ),
        ],
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _StepperRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, size: VoetjeIconSize.mediumIcon),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: value < 21 ? () => onChanged(value + 1) : null,
        ),
      ]),
    );
  }
}
