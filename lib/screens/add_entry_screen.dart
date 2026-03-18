import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carbon_tracker/config/design_tokens.dart';
import 'package:carbon_tracker/models/emission_entry.dart';
import 'package:carbon_tracker/models/transport_mode.dart';
import 'package:carbon_tracker/providers/emission_provider.dart';
import 'package:carbon_tracker/services/airport_service.dart';
import 'package:carbon_tracker/services/haversine.dart';
import 'package:carbon_tracker/widgets/airport_picker.dart';
import 'package:carbon_tracker/widgets/route_picker.dart';

class AddTransportScreen extends StatelessWidget {
  const AddTransportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoetjeColors.background,
      appBar: AppBar(
        title: Text(
          'Log a Trip',
          style: VoetjeTypography.sectionHeader(),
        ),
        backgroundColor: VoetjeColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: const _TransportBody(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Transport form body — used by AddTransportScreen above.
// ─────────────────────────────────────────────────────────────────

class _TransportBody extends StatefulWidget {
  const _TransportBody();

  @override
  State<_TransportBody> createState() => _TransportBodyState();
}

class _TransportBodyState extends State<_TransportBody> {
  TransportMode? _selectedMode;
  final _distanceController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int _passengers = 1;
  bool _showPassengers = false;

  // Route preset — set when user picks a (from, to) pair
  int? _routeFromId;
  int? _routeToId;

  // Airport pickers — used when a flight mode is selected
  Airport? _airportFrom;
  Airport? _airportTo;

  // IATA strings read from prefs; resolved to Airport objects lazily on first
  // flight-mode activation to avoid loading airports.json on every form open.
  String? _lastAirportFromIata;
  String? _lastAirportToIata;

  static const _kLastAirportFrom = 'last_airport_from';
  static const _kLastAirportTo = 'last_airport_to';

  bool get _isFlightMode =>
      _selectedMode == TransportMode.flightShort ||
      _selectedMode == TransportMode.flightLong;

  @override
  void initState() {
    super.initState();
    _loadLastAirportPrefs();
  }

  // Read IATA strings from prefs only — no JSON parse on form open.
  // Airports are resolved lazily inside _selectMode when flight mode is tapped.
  Future<void> _loadLastAirportPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _lastAirportFromIata = prefs.getString(_kLastAirportFrom);
    _lastAirportToIata = prefs.getString(_kLastAirportTo);
  }

  double get _distance {
    final text = _distanceController.text.trim();
    if (text.isEmpty) return 0;
    return double.tryParse(text) ?? 0;
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmissionProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: VoetjeSpacing.screenEdge,
        vertical: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDatePicker(context),
          const SizedBox(height: 20),

          Text(
            'HOW DID YOU TRAVEL?',
            style: VoetjeTypography.sectionLabel(),
          ),
          const SizedBox(height: 12),
          _ModeGrid(selectedMode: _selectedMode, onSelect: _selectMode),
          const SizedBox(height: 20),

          if (!_isFlightMode) ...[
            RoutePicker(
              onRouteSelected: (distanceDisplay, lastMode, fromId, toId) {
                setState(() {
                  _distanceController.text =
                      distanceDisplay.toStringAsFixed(1);
                  if (lastMode != null) _selectMode(lastMode);
                  _routeFromId = fromId;
                  _routeToId = toId;
                });
              },
            ),
            const SizedBox(height: 20),
          ],

          if (_isFlightMode) ...[
            _buildAirportPickers(),
            const SizedBox(height: 16),
          ] else ...[
            Text(
              'DISTANCE',
              style: VoetjeTypography.sectionLabel(),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: VoetjeColors.surface,
                borderRadius: BorderRadius.circular(VoetjeRadius.input),
                border: Border.all(color: VoetjeColors.border, width: 1.5),
              ),
              child: TextField(
                controller: _distanceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                style: VoetjeTypography.caption().copyWith(
                      fontSize: 13,
                      color: VoetjeColors.textPrimary,
                    ),
                decoration: InputDecoration(
                  hintText: 'Enter distance',
                  hintStyle: VoetjeTypography.caption().copyWith(
                        fontSize: 13,
                        color: VoetjeColors.textMuted,
                      ),
                  suffixText: provider.unitLabel,
                  suffixStyle: VoetjeTypography.caption().copyWith(
                        fontSize: 13,
                        color: VoetjeColors.labelColor,
                        fontWeight: FontWeight.w600,
                      ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: VoetjeSpacing.chipGap,
              runSpacing: VoetjeSpacing.chipGap,
              children: [5, 10, 25, 50, 100].map((d) {
                return GestureDetector(
                  onTap: () {
                    _distanceController.text = d.toString();
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: VoetjeColors.stillToLogBg,
                      borderRadius: BorderRadius.circular(VoetjeRadius.input),
                    ),
                    child: Text(
                      '$d ${provider.unitLabel}',
                      style: VoetjeTypography.caption().copyWith(
                            fontSize: 10,
                            color: VoetjeColors.textMuted,
                          ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          if (_showPassengers) ...[
            Text(
              'PASSENGERS (INCLUDING YOU)',
              style: VoetjeTypography.sectionLabel(),
            ),
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: VoetjeColors.surface,
                borderRadius: BorderRadius.circular(VoetjeRadius.input),
                border: Border.all(color: VoetjeColors.border, width: 1.5),
              ),
              child: Row(
                children: [
                  _PassengerButton(
                    icon: Icons.remove,
                    enabled: _passengers > 1,
                    onPressed: () => setState(() => _passengers--),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$_passengers',
                    style: VoetjeTypography.sectionHeader(),
                  ),
                  const SizedBox(width: 12),
                  _PassengerButton(
                    icon: Icons.add,
                    enabled: _passengers < 8,
                    onPressed: () => setState(() => _passengers++),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _passengers > 1
                          ? 'Emissions split $_passengers ways'
                          : 'Just you',
                      style: VoetjeTypography.caption().copyWith(
                            fontSize: 12,
                            color: VoetjeColors.textMuted,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Note field
          Container(
            decoration: BoxDecoration(
              color: VoetjeColors.surface,
              borderRadius: BorderRadius.circular(VoetjeRadius.input),
              border: Border.all(color: VoetjeColors.border, width: 1.5),
            ),
            child: TextField(
              controller: _noteController,
              style: VoetjeTypography.caption().copyWith(
                    fontSize: 13,
                    color: VoetjeColors.textPrimary,
                  ),
              decoration: InputDecoration(
                hintText: 'Add a note (optional)',
                hintStyle: VoetjeTypography.caption().copyWith(
                      fontSize: 13,
                      color: VoetjeColors.textMuted,
                    ),
                prefixIcon: const Icon(
                  Icons.note_alt_outlined,
                  color: VoetjeColors.textMuted,
                  size: 18,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 28),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: _canSave
                    ? [
                        BoxShadow(
                          color: VoetjeColors.primary.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canSave
                      ? VoetjeColors.primary
                      : VoetjeColors.border,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: _canSave ? _save : null,
                child: Text(
                  'Save Trip',
                  style: VoetjeTypography.buttonLabel().copyWith(fontSize: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) setState(() => _selectedDate = picked);
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: VoetjeColors.surface,
          borderRadius: BorderRadius.circular(VoetjeRadius.input),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              size: 18,
              color: VoetjeColors.textMuted,
            ),
            const SizedBox(width: 12),
            Text(
              DateFormat('EEEE, MMM d, y').format(_selectedDate),
              style: VoetjeTypography.caption().copyWith(
                    fontSize: 13,
                    color: VoetjeColors.textPrimary,
                  ),
            ),
            const Spacer(),
            if (_isToday)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: VoetjeColors.primaryMedium.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Today',
                  style: VoetjeTypography.caption().copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: VoetjeColors.primaryMedium,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  void _selectMode(TransportMode mode) {
    final wasFlightMode = _isFlightMode;
    setState(() {
      _selectedMode = mode;
      _showPassengers = mode.isCarMode;
      if (!_showPassengers) _passengers = 1;
    });

    final isNowFlight =
        mode == TransportMode.flightShort || mode == TransportMode.flightLong;
    if (isNowFlight && !wasFlightMode) {
      // Load airports.json once (cached after first call), then lazily resolve
      // the last-used IATA strings that were read from prefs in initState.
      AirportService.instance.load().then((_) {
        if (!mounted) return;
        _airportFrom ??= _lastAirportFromIata != null
            ? AirportService.instance.findByIata(_lastAirportFromIata!)
            : null;
        _airportTo ??= _lastAirportToIata != null
            ? AirportService.instance.findByIata(_lastAirportToIata!)
            : null;
        if (_airportFrom != null || _airportTo != null) {
          setState(() {}); // refresh picker display
        }
        if (_airportFrom != null && _airportTo != null) {
          _onBothAirportsSelected();
        }
      });
    }
    if (!isNowFlight && wasFlightMode) {
      // Leaving flight mode — clear distance so user enters it manually
      setState(() => _distanceController.clear());
    }
  }

  void _onBothAirportsSelected() {
    final from = _airportFrom;
    final to = _airportTo;
    if (from == null || to == null) return;

    final km = HaversineService.distanceKm(
        from.lat, from.lon, to.lat, to.lon);

    final provider = context.read<EmissionProvider>();
    final distanceDisplay = provider.convertDistance(km);
    _distanceController.text = distanceDisplay.toStringAsFixed(1);

    // Auto-resolve flight type
    final resolved =
        km < 1500 ? TransportMode.flightShort : TransportMode.flightLong;
    if (_selectedMode != resolved) {
      setState(() => _selectedMode = resolved);
    } else {
      setState(() {}); // refresh co2 estimate
    }

    // Persist for next time
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_kLastAirportFrom, from.iata);
      prefs.setString(_kLastAirportTo, to.iata);
    });
  }

  Widget _buildAirportPickers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FLIGHT ROUTE',
          style: VoetjeTypography.sectionLabel(),
        ),
        const SizedBox(height: 8),
        AirportPicker(
          label: 'From',
          initialValue: _airportFrom,
          onSelected: (airport) {
            setState(() => _airportFrom = airport);
            if (airport != null && _airportTo != null) {
              _onBothAirportsSelected();
            }
          },
        ),
        const SizedBox(height: 12),
        AirportPicker(
          label: 'To',
          initialValue: _airportTo,
          onSelected: (airport) {
            setState(() => _airportTo = airport);
            if (airport != null && _airportFrom != null) {
              _onBothAirportsSelected();
            }
          },
        ),
        if (_airportFrom != null && _airportTo != null && _distance > 0) ...[
          const SizedBox(height: 8),
          Text(
            '${_distanceController.text} ${context.read<EmissionProvider>().unitLabel}'
            ' \u00b7 ${_selectedMode?.label ?? ''}',
            style: VoetjeTypography.caption().copyWith(
                  fontSize: 11,
                  color: VoetjeColors.textMuted,
                ),
          ),
        ],
      ],
    );
  }

  bool get _canSave {
    if (_selectedMode == null) return false;
    if (_isFlightMode) {
      return _airportFrom != null && _airportTo != null && _distance > 0;
    }
    return _distance > 0;
  }

  Future<void> _save() async {
    if (!_canSave) return;

    // H-6: capture context-dependent values before any await gap so we never
    // call context.read after the widget might be unmounted or disposed.
    final provider = context.read<EmissionProvider>();
    final distanceKm = provider.toKm(_distance);
    final scaffoldMsg = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    final entry = EmissionEntry.transport(
      date: _selectedDate,
      mode: _selectedMode!,
      distanceKm: distanceKm,
      passengers: _passengers,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      countryCode: provider.energyProfile?.countryCode,
    );

    // C-1: wrap in try/catch so DB failures surface to the user rather than
    // silently leaving the screen open or crashing.
    try {
      await provider.addEntry(entry);

      if (_routeFromId != null && _routeToId != null) {
        await provider.upsertRoutePreset(
            _routeFromId!, _routeToId!, _selectedMode!);
      }

      if (mounted) {
        scaffoldMsg.showSnackBar(
          SnackBar(
            content: Text(
              'Logged ${entry.co2Kg.toStringAsFixed(2)} kg CO\u2082 for ${_selectedMode!.label}',
            ),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
        nav.pop();
      }
    } catch (e) {
      if (mounted) {
        scaffoldMsg.showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: VoetjeColors.destructive,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ── Passenger stepper button ─────────────────────────────────────────────────

class _PassengerButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _PassengerButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled
              ? VoetjeColors.primary.withValues(alpha: 0.1)
              : VoetjeColors.border.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? VoetjeColors.primary : VoetjeColors.textMuted,
        ),
      ),
    );
  }
}

// ── Mode grid ────────────────────────────────────────────────────────────────

/// Extracted to a StatelessWidget so Flutter can short-circuit diffing the
/// 14 ChoiceChips when unrelated state (distance, passengers, airports) changes.
class _ModeGrid extends StatelessWidget {
  final TransportMode? selectedMode;
  final void Function(TransportMode) onSelect;

  const _ModeGrid({required this.selectedMode, required this.onSelect});

  static const _groups = <String, List<TransportMode>>{
    'ZERO EMISSION': [
      TransportMode.walking,
      TransportMode.cycling,
      TransportMode.eBike
    ],
    'PUBLIC TRANSPORT': [
      TransportMode.bus,
      TransportMode.train,
      TransportMode.subway,
      TransportMode.ferry
    ],
    'CAR': [
      TransportMode.carSmall,
      TransportMode.carMedium,
      TransportMode.carLarge,
      TransportMode.carElectric,
      TransportMode.carHybrid
    ],
    'OTHER': [
      TransportMode.motorcycle,
      TransportMode.taxi,
      TransportMode.flightShort,
      TransportMode.flightLong
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _groups.entries.map((group) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Text(
                group.key,
                style: VoetjeTypography.sectionLabel(),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: group.value.map((mode) {
                final isSelected = selectedMode == mode;
                return GestureDetector(
                  onTap: () => onSelect(mode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? VoetjeColors.primary
                          : VoetjeColors.surface,
                      borderRadius: BorderRadius.circular(VoetjeRadius.chip),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: VoetjeColors.border, width: 1.5),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: VoetjeColors.primary
                                    .withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          mode.icon,
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : mode.color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          mode.label,
                          style: VoetjeTypography.caption().copyWith(
                                fontSize: 12,
                                color: isSelected
                                    ? VoetjeColors.surface
                                    : VoetjeColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }
}
