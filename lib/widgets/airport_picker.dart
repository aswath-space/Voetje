import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carbon_tracker/config/design_tokens.dart';
import 'package:carbon_tracker/services/airport_service.dart';

/// Single-airport picker used in the transport form for flight entries.
///
/// Shows a text field; fuzzy-search results appear in an overlay dropdown
/// as the user types. When an airport is confirmed, [onSelected] is called.
/// When the field is cleared, [onSelected] is called with null.
///
/// [service] is optional — pass [AirportService.forTesting] in tests;
/// production code defaults to [AirportService.instance].
class AirportPicker extends StatefulWidget {
  final String label;
  final Airport? initialValue;
  final void Function(Airport?) onSelected;
  final AirportService? service;

  const AirportPicker({
    super.key,
    required this.label,
    required this.onSelected,
    this.initialValue,
    this.service,
  });

  @override
  State<AirportPicker> createState() => _AirportPickerState();
}

class _AirportPickerState extends State<AirportPicker> {
  late final TextEditingController _controller;
  late final AirportService _service;
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;

  Airport? _selected;
  List<Airport> _results = [];

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AirportService.instance;
    _selected = widget.initialValue;
    _controller = TextEditingController(
      text: widget.initialValue?.iata ?? '',
    );
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(AirportPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync when parent restores a saved airport (e.g., after lazy pref load)
    if (widget.initialValue != oldWidget.initialValue && !_focusNode.hasFocus) {
      _selected = widget.initialValue;
      _controller.text = widget.initialValue?.iata ?? '';
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
      // If user typed but didn't pick, restore last confirmed value
      if (_selected != null) {
        _controller.text = _selected!.iata;
      } else {
        _controller.clear();
      }
    }
  }

  void _onTextChanged(String value) {
    if (_selected != null && value != _selected!.iata) {
      // User is editing — clear confirmed selection
      setState(() => _selected = null);
      widget.onSelected(null);
    }

    final query = value.trim();
    if (query.isEmpty) {
      _results = [];
      _removeOverlay();
      return;
    }

    _results = _service.search(query);
    if (_results.isEmpty) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _pick(Airport airport) {
    _results = [];
    _removeOverlay();
    _focusNode.unfocus();
    setState(() => _selected = airport);
    _controller.text = airport.iata;
    widget.onSelected(airport);
  }

  void _showOverlay() {
    if (_overlay != null) {
      // Refresh existing entry in-place — no alloc/insert per keystroke
      _overlay!.markNeedsBuild();
      return;
    }
    _overlay = OverlayEntry(builder: (context) => _buildDropdown());
    Overlay.of(context).insert(_overlay!);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  Widget _buildDropdown() {
    // Width adapts to screen — take the full field width minus outer margins.
    // We don't have MediaQuery here (overlay context may differ), so use a
    // LayoutBuilder-safe approach: fill available width via Positioned.fill
    // in a later step. For now anchor to the transform target width naturally.
    return CompositedTransformFollower(
      link: _layerLink,
      showWhenUnlinked: false,
      offset: const Offset(0, 52),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 200, maxWidth: 380, maxHeight: 240),
          child: Material(
            elevation: 4,
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(VoetjeRadius.input),
            child: Builder(
              builder: (ctx) => Container(
                decoration: BoxDecoration(
                  color: VoetjeColors.surfaceOf(ctx),
                  borderRadius: BorderRadius.circular(VoetjeRadius.input),
                  border: Border.all(color: VoetjeColors.borderOf(ctx)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(VoetjeRadius.input),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _results.length,
                    itemBuilder: (context, i) {
                      final a = _results[i];
                      return ListTile(
                        dense: true,
                        leading: Text(
                          a.iata,
                          style: GoogleFonts.robotoMono(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: VoetjeColors.textPrimaryOf(context),
                          ),
                        ),
                        title: Text(
                          a.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: VoetjeTypography.caption().copyWith(
                            color: VoetjeColors.textPrimaryOf(context),
                          ),
                        ),
                        subtitle: Text(
                          '${a.city}, ${a.country}',
                          style: VoetjeTypography.caption().copyWith(
                            fontSize: 12,
                            color: VoetjeColors.captionColorOf(context),
                          ),
                        ),
                        onTap: () => _pick(a),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _selected != null
        ? '${_selected!.name}, ${_selected!.country}'
        : null;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            textCapitalization: TextCapitalization.characters,
            maxLength: 3,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: 'e.g. LHR',
              counterText: '',
              prefixIcon: const Icon(Icons.flight),
              suffixIcon: _selected != null
                  ? const Icon(Icons.check_circle, color: VoetjeColors.primaryLight)
                  : null,
            ),
            onChanged: _onTextChanged,
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 2),
              child: Text(
                subtitle,
                style: VoetjeTypography.caption().copyWith(
                  color: VoetjeColors.captionColorOf(context),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
