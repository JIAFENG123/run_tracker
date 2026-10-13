class LocationPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double speed; // m/s
  final double altitude; // meters

  LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.speed = 0.0,
    this.altitude = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'speed': speed,
      'altitude': altitude,
    };
  }

  factory LocationPoint.fromMap(Map<String, dynamic> map) {
    return LocationPoint(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      speed: (map['speed'] as num?)?.toDouble() ?? 0.0,
      altitude: (map['altitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
