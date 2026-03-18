import 'dart:math';

/// Great-circle distance between two lat/lon coordinates.
/// Apply a road multiplier (e.g. × 1.3) at the call site for land routes.
/// No multiplier needed for flights (great-circle is correct).
class HaversineService {
  static const double _earthRadiusKm = 6371.0;

  static double distanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    if (lat1 == lat2 && lon1 == lon2) return 0.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return _earthRadiusKm * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _rad(double deg) => deg * pi / 180;
}
