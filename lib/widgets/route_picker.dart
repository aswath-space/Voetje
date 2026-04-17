import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carbon_tracker/config/design_tokens.dart';
import 'package:carbon_tracker/models/saved_place.dart';
import 'package:carbon_tracker/models/transport_mode.dart';
import 'package:carbon_tracker/providers/emission_provider.dart';
import 'package:carbon_tracker/services/haversine.dart';
import 'package:carbon_tracker/widgets/add_place_sheet.dart';

/// Callback fired when the user picks a (from, to) pair.
/// [distanceDisplay] is already converted to the user's preferred unit.
/// [lastMode] is the previously-used mode for this direction, or null.
/// [fromId] / [toId] are the saved-place IDs — pass them back to
/// [EmissionProvider.upsertRoutePreset] after the emission is saved.
typedef RouteSelectedCallback = void Function(
  double distanceDisplay,
  TransportMode? lastMode,
  int fromId,
  int toId,
);

/// Shown above the distance field in the transport form.
///
/// * When the user has < 2 saved places: shows an inline "+ Add place" button.
/// * When ≥ 2 places: shows From / To dropdowns and a small "+ Add" chip.
/// * Selecting both fires [onRouteSelected] with the computed distance and
///   the last-used mode for that direction.
class RoutePicker extends StatefulWidget {
  final RouteSelectedCallback onRouteSelected;

  const RoutePicker({super.key, required this.onRouteSelected});

  @override
  State<RoutePicker> createState() => _RoutePickerState();
}

class _RoutePickerState extends State<RoutePicker> {
  SavedPlace? _from;
  SavedPlace? _to;
  String? _routeSummary;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmissionProvider>();
    final places = provider.savedPlaces;

    if (places.length < 2) {
      return const _AddPlaceButton();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick route',
          style: VoetjeTypography.sectionHeader().copyWith(
            color: VoetjeColors.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _PlaceDropdown(
                label: 'From',
                places: places,
                value: _from,
                excluded: _to,
                onChanged: (p) => _onFromChanged(p, context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: VoetjeSpacing.chipGap),
              child: Icon(
                Icons.arrow_forward,
                size: VoetjeIconSize.smallIcon,
                color: VoetjeColors.textMutedOf(context),
              ),
            ),
            Expanded(
              child: _PlaceDropdown(
                label: 'To',
                places: places,
                value: _to,
                excluded: _from,
                onChanged: (p) => _onToChanged(p, context),
              ),
            ),
          ],
        ),
        if (_routeSummary != null) ...[
          const SizedBox(height: VoetjeSpacing.chipGap),
          Text(
            _routeSummary!,
            style: VoetjeTypography.caption().copyWith(
              color: VoetjeColors.captionColorOf(context),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ActionChip(
            avatar: const Icon(Icons.add, size: 16),
            label: const Text('+ Add'),
            visualDensity: VisualDensity.compact,
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => ChangeNotifierProvider.value(
                value: context.read<EmissionProvider>(),
                child: const AddPlaceSheet(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onFromChanged(SavedPlace? p, BuildContext context) {
    setState(() => _from = p);
    _resolveRoute(context);
  }

  void _onToChanged(SavedPlace? p, BuildContext context) {
    setState(() => _to = p);
    _resolveRoute(context);
  }

  // Fully synchronous: reads from the in-memory cache, no DB round-trip,
  // no async gap that could cause races on rapid dropdown changes.
  void _resolveRoute(BuildContext context) {
    final from = _from;
    final to = _to;
    if (from == null || to == null) return;

    final provider = context.read<EmissionProvider>();

    final km = HaversineService.distanceKm(
          from.latitude, from.longitude,
          to.latitude, to.longitude,
        ) *
        1.3; // road factor

    final distanceDisplay = provider.convertDistance(km);

    // cachedRoutePreset is a synchronous map lookup — no DB hit.
    final preset = provider.cachedRoutePreset(from.id!, to.id!);
    TransportMode? lastMode;
    if (preset?.lastMode != null) {
      try {
        lastMode = TransportMode.values
            .firstWhere((m) => m.name == preset!.lastMode);
      } catch (_) {
        lastMode = null;
      }
    }

    final label = provider.unitLabel;
    final modeNote = lastMode != null ? ' · ${lastMode.label} pre-selected' : '';
    setState(() {
      _routeSummary = '${distanceDisplay.toStringAsFixed(1)} $label$modeNote';
    });

    widget.onRouteSelected(distanceDisplay, lastMode, from.id!, to.id!);
  }
}

// ── Private helpers ──────────────────────────────────────────────────────────

class _AddPlaceButton extends StatelessWidget {
  const _AddPlaceButton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick route',
          style: VoetjeTypography.sectionHeader().copyWith(
            color: VoetjeColors.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Save places for quick distance fill',
          style: VoetjeTypography.caption().copyWith(
            color: VoetjeColors.captionColorOf(context),
          ),
        ),
        const SizedBox(height: 8),
        ActionChip(
          avatar: const Icon(Icons.add, size: 18),
          label: const Text('+ Add place'),
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => ChangeNotifierProvider.value(
              value: context.read<EmissionProvider>(),
              child: const AddPlaceSheet(),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlaceDropdown extends StatelessWidget {
  final String label;
  final List<SavedPlace> places;
  final SavedPlace? value;
  final SavedPlace? excluded;
  final void Function(SavedPlace?) onChanged;

  const _PlaceDropdown({
    required this.label,
    required this.places,
    required this.value,
    required this.excluded,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final available = excluded == null
        ? places
        : places.where((p) => p.id != excluded!.id).toList();

    // Clear stale value if it's been removed from the list
    final effective = (value != null && available.any((p) => p.id == value!.id))
        ? value
        : null;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: DropdownButton<SavedPlace>(
        value: effective,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        hint: Text(label, style: VoetjeTypography.caption().copyWith(
          color: VoetjeColors.captionColorOf(context),
        )),
        items: available
            .map((p) => DropdownMenuItem(
                  value: p,
                  child: Text(
                    p.name,
                    overflow: TextOverflow.ellipsis,
                    style: VoetjeTypography.body().copyWith(
                      color: VoetjeColors.textPrimaryOf(context),
                    ),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
