import 'package:flutter/material.dart';
import 'package:carbon_tracker/config/design_tokens.dart';

/// Lightweight "About our data" screen accessible from Settings.
/// Shows what sources we use and when they were last verified.
class DataSourcesScreen extends StatelessWidget {
  const DataSourcesScreen({super.key});

  static const _lastVerified = '2026-03-18';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bodyStyle = theme.textTheme.bodyMedium;
    final captionStyle = theme.textTheme.bodySmall?.copyWith(
      color: Colors.grey.shade600,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('About Our Data')),
      body: ListView(
        padding: const EdgeInsets.all(VoetjeSpacing.screenEdge),
        children: [
          Text(
            'Where do the numbers come from?',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Every CO\u2082 estimate in Voetje is based on published, peer-reviewed '
            'or government-issued emission factors. We do not make up numbers.',
            style: bodyStyle,
          ),
          const SizedBox(height: 4),
          Text('Last verified: $_lastVerified', style: captionStyle),
          const SizedBox(height: 20),

          const _SourceCard(
            icon: Icons.bolt,
            title: 'Electricity & Gas',
            body: 'Grid carbon intensity per country and state/province. '
                'Household consumption averages for energy estimates.',
            sources: [
              'IEA Emissions Factors 2024 (150 countries)',
              'EPA eGRID 2023 (US states)',
              'DEFRA 2024 Conversion Factors (UK)',
              'Australian NGA Factors 2024 (AU states)',
              'Canadian provincial emission reports',
            ],
            note: '24 countries, 25 state/province overrides for US, Canada, and Australia.',
          ),
          const SizedBox(height: 12),

          const _SourceCard(
            icon: Icons.directions_car,
            title: 'Transport',
            body: 'CO\u2082 per km for 16 transport modes, from walking to long-haul flights.',
            sources: [
              'UK DEFRA 2023 Conversion Factors',
              'EPA GHG Equivalencies Calculator',
            ],
            note: 'Electric car uses your local grid intensity, not a fixed number. '
                'Flights include the DEFRA radiative forcing uplift.',
          ),
          const SizedBox(height: 12),

          const _SourceCard(
            icon: Icons.restaurant,
            title: 'Food',
            body: 'CO\u2082 per meal by type (plant-based to red meat).',
            sources: [
              'Poore & Nemecek 2018 (Science, via Our World in Data)',
              'DEFRA 2023 supplementary factors',
            ],
            note: 'Values represent average meals, not specific dishes.',
          ),
          const SizedBox(height: 12),

          const _SourceCard(
            icon: Icons.shopping_bag,
            title: 'Shopping',
            body: 'CO\u2082 per item purchased. Manufacture + supply chain only '
                '(use-phase excluded).',
            sources: [
              'Vendor environmental reports (Apple, Samsung, Dell)',
              'WRAP UK textile research',
              'Textile Exchange industry data',
            ],
            note: 'Second-hand and repaired items use reduced multipliers.',
          ),
          const SizedBox(height: 12),

          const _SourceCard(
            icon: Icons.delete_outline,
            title: 'Waste & Recycling',
            body: 'CO\u2082 per kg by disposal method. Recycling counts as a net saving.',
            sources: [
              'EPA WARM Model',
              'DEFRA 2023 waste factors',
            ],
            note: null,
          ),
          const SizedBox(height: 20),

          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transparency',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All emission factors, sources, and methodology decisions are '
                    'documented in the project repository (dev/data-sources.md). '
                    'If you think a number is wrong, I want to know.',
                    style: bodyStyle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Data is reviewed annually against IEA, DEFRA, EPA, and national '
                    'statistics. Grid intensities can change significantly year to year '
                    'as countries add renewables.',
                    style: captionStyle,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final List<String> sources;
  final String? note;

  const _SourceCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.sources,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            Text(body, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            ...sources.map((s) => Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('\u2022 ', style: TextStyle(color: Colors.grey.shade600)),
                  Expanded(
                    child: Text(s, style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    )),
                  ),
                ],
              ),
            )),
            if (note != null) ...[
              const SizedBox(height: 6),
              Text(note!, style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade500,
              )),
            ],
          ],
        ),
      ),
    );
  }
}
