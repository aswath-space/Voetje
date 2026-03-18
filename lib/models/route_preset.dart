class RoutePreset {
  final int? id;
  final int fromPlaceId;
  final int toPlaceId;
  final String? lastMode;
  final DateTime? lastUsedAt;

  const RoutePreset({
    this.id,
    required this.fromPlaceId,
    required this.toPlaceId,
    this.lastMode,
    this.lastUsedAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'from_place_id': fromPlaceId,
        'to_place_id': toPlaceId,
        if (lastMode != null) 'last_mode': lastMode,
        if (lastUsedAt != null) 'last_used_at': lastUsedAt!.toIso8601String(),
      };

  factory RoutePreset.fromMap(Map<String, dynamic> map) => RoutePreset(
        id: map['id'] as int?,
        fromPlaceId: map['from_place_id'] as int,
        toPlaceId: map['to_place_id'] as int,
        lastMode: map['last_mode'] as String?,
        lastUsedAt: map['last_used_at'] != null
            ? DateTime.parse(map['last_used_at'] as String)
            : null,
      );
}
