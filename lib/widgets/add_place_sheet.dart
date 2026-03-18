import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carbon_tracker/models/saved_place.dart';
import 'package:carbon_tracker/providers/emission_provider.dart';
import 'package:carbon_tracker/services/location_service.dart';

class AddPlaceSheet extends StatefulWidget {
  final SavedPlace? editing;
  const AddPlaceSheet({super.key, this.editing});

  @override
  State<AddPlaceSheet> createState() => _AddPlaceSheetState();
}

class _AddPlaceSheetState extends State<AddPlaceSheet> {
  late final TextEditingController _nameController;
  double? _lat;
  double? _lon;
  bool _locating = false;
  String? _locationError;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.editing?.name ?? '');
    _lat = widget.editing?.latitude;
    _lon = widget.editing?.longitude;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = _lat != null && _lon != null;
    final canSave = _nameController.text.trim().isNotEmpty && hasLocation;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isEditing ? 'Edit Place' : 'Add Place',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. Home, Office, Gym',
              prefixIcon: Icon(Icons.label_outline),
            ),
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _locating ? null : _captureLocation,
            icon: _locating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(hasLocation ? Icons.check_circle_outline : Icons.my_location),
            label: Text(
              hasLocation
                  ? (_isEditing ? 'Location refreshed' : 'Location captured')
                  : 'Use my location',
            ),
          ),
          if (_locationError != null) ...[
            const SizedBox(height: 8),
            Text(
              _locationError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: canSave ? _save : null,
            child: Text(_isEditing ? 'Save changes' : 'Add place'),
          ),
        ],
      ),
    );
  }

  Future<void> _captureLocation() async {
    setState(() {
      _locating = true;
      _locationError = null;
    });

    final pos = await LocationService.getCurrentPosition();

    if (!mounted) return;
    if (pos == null) {
      setState(() {
        _locating = false;
        _locationError =
            "Couldn't get location. Check location permissions in Settings.";
      });
    } else {
      setState(() {
        _locating = false;
        _lat = pos.lat;
        _lon = pos.lon;
      });
    }
  }

  Future<void> _save() async {
    // M-3: guard against corrupted GPS fixes before persisting.
    final lat = _lat!;
    final lon = _lon!;
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid coordinates — please try capturing again.'),
        ),
      );
      return;
    }
    final place = SavedPlace(
      id: widget.editing?.id,
      name: _nameController.text.trim(),
      latitude: lat,
      longitude: lon,
    );
    await context.read<EmissionProvider>().savePlace(place);
    if (mounted) Navigator.pop(context);
  }
}
