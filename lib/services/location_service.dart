import 'package:geolocator/geolocator.dart';

typedef LatLon = ({double lat, double lon});

/// Thin wrapper around geolocator for a single GPS fix.
/// Returns null if permission is denied or location unavailable.
/// Never called in background — only on explicit user tap.
class LocationService {
  static Future<LatLon?> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return (lat: pos.latitude, lon: pos.longitude);
    } catch (_) {
      return null;
    }
  }
}
