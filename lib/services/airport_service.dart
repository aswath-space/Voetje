import 'dart:convert';
import 'package:flutter/services.dart';

class Airport {
  final String iata;
  final String name;
  final String city;
  final String country;
  final double lat;
  final double lon;

  const Airport({
    required this.iata,
    required this.name,
    required this.city,
    required this.country,
    required this.lat,
    required this.lon,
  });

  factory Airport.fromJson(Map<String, dynamic> j) => Airport(
        iata: j['iata'] as String,
        name: j['name'] as String,
        city: j['city'] as String,
        country: j['country'] as String,
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
      );
}

/// Loads and fuzzy-searches the bundled airports.json.
///
/// Use [AirportService.instance] in production.
/// Use [AirportService.forTesting(list)] in widget/unit tests.
class AirportService {
  static AirportService? _instance;

  List<Airport>? _cache;
  // O(1) lookup by IATA code; built alongside _cache.
  Map<String, Airport>? _iataIndex;

  AirportService._();

  AirportService.forTesting(List<Airport> airports) {
    _cache = airports;
    _iataIndex = {for (final a in airports) a.iata: a};
  }

  static AirportService get instance => _instance ??= AirportService._();

  Future<List<Airport>> _load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/airports.json');
    final list = (jsonDecode(raw) as List)
        .map((j) => Airport.fromJson(j as Map<String, dynamic>))
        .toList();
    _cache = list;
    _iataIndex = {for (final a in list) a.iata: a};
    return list;
  }

  /// Returns up to 8 airports matching [query].
  /// Matches IATA code prefix first, then city name, then airport name.
  /// Returns empty list for blank queries.
  List<Airport> search(String query) {
    if (query.trim().isEmpty || _cache == null) return [];
    // IATA codes are stored uppercase; compare directly without lowercasing.
    final qUpper = query.trim().toUpperCase();
    final qLower = query.trim().toLowerCase();
    final iataMatches = <Airport>[];
    final cityMatches = <Airport>[];
    final nameMatches = <Airport>[];
    for (final a in _cache!) {
      if (a.iata.startsWith(qUpper)) {
        iataMatches.add(a);
      } else if (a.city.toLowerCase().contains(qLower)) {
        cityMatches.add(a);
      } else if (a.name.toLowerCase().contains(qLower)) {
        nameMatches.add(a);
      }
    }
    return [...iataMatches, ...cityMatches, ...nameMatches].take(8).toList();
  }

  /// O(1) lookup — uses the IATA HashMap built at load time.
  Airport? findByIata(String iata) =>
      _iataIndex?[iata.toUpperCase()];

  /// Call once before showing airport pickers to warm the cache.
  Future<void> load() => _load();
}
