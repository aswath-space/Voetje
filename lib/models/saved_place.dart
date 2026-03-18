class SavedPlace {
  final int? id;
  final String name;
  final double latitude;
  final double longitude;
  final DateTime createdAt;

  SavedPlace({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'created_at': createdAt.toIso8601String(),
      };

  factory SavedPlace.fromMap(Map<String, dynamic> map) => SavedPlace(
        id: map['id'] as int?,
        name: map['name'] as String,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
