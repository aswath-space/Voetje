import 'package:flutter/material.dart';
import 'package:carbon_tracker/services/shopping_calculator.dart';

class SecondHandCelebrationScreen extends StatelessWidget {
  final String itemName;
  final double savedCO2;
  final double lifetimeSavings;

  const SecondHandCelebrationScreen({
    super.key,
    required this.itemName,
    required this.savedCO2,
    required this.lifetimeSavings,
  });

  @override
  Widget build(BuildContext context) {
    final drivingEquiv = ShoppingCalculator.drivingEquivalent(savedCO2);

    return Scaffold(
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.green.shade50, Colors.green.shade100],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.celebration, size: 80, color: Colors.green),
              const SizedBox(height: 24),
              Text(
                'You saved ${savedCO2.toStringAsFixed(1)} kg CO₂',
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const Text('by buying second-hand!',
                  style: TextStyle(fontSize: 20)),
              const SizedBox(height: 8),
              Text(
                'That\'s like taking ${drivingEquiv.toStringAsFixed(0)} km of driving off the road.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.green, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(children: [
                  const Text('Lifetime second-hand savings:',
                      style: TextStyle(color: Colors.grey)),
                  Text(
                    '${lifetimeSavings.toStringAsFixed(1)} kg CO₂',
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                  const Icon(Icons.eco, size: 24, color: Colors.green),
                ]),
              ),
              const SizedBox(height: 48),
              const Text('Tap anywhere to continue',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
