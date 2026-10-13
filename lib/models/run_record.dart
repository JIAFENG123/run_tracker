import 'dart:convert';
import 'location_point.dart';

class RunRecord {
  final int? id;
  final DateTime startTime;
  final DateTime endTime;
  final int durationSeconds;
  final double distanceMeters;
  final int calories;
  final int avgPaceSecondsPerKm;
  final List<LocationPoint> points;
  final List<double> splits; // 每公里用时（秒）

  RunRecord({
    this.id,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.distanceMeters,
    required this.calories,
    required this.avgPaceSecondsPerKm,
    required this.points,
    required this.splits,
  });

  double get distanceKm => distanceMeters / 1000.0;

  String get formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedPace {
    if (avgPaceSecondsPerKm <= 0 || avgPaceSecondsPerKm > 3600) return "--'--\"";
    final min = avgPaceSecondsPerKm ~/ 60;
    final sec = avgPaceSecondsPerKm % 60;
    return "$min'${sec.toString().padLeft(2, '0')}\"";
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime.millisecondsSinceEpoch,
      'duration_seconds': durationSeconds,
      'distance_meters': distanceMeters,
      'calories': calories,
      'avg_pace_seconds': avgPaceSecondsPerKm,
      'points_json': jsonEncode(points.map((p) => p.toMap()).toList()),
      'splits_json': jsonEncode(splits),
    };
  }

  factory RunRecord.fromMap(Map<String, dynamic> map) {
    List<LocationPoint> parsedPoints = [];
    if (map['points_json'] != null && map['points_json'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['points_json'] as String) as List<dynamic>;
        parsedPoints = decoded.map((e) => LocationPoint.fromMap(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    List<double> parsedSplits = [];
    if (map['splits_json'] != null && map['splits_json'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['splits_json'] as String) as List<dynamic>;
        parsedSplits = decoded.map((e) => (e as num).toDouble()).toList();
      } catch (_) {}
    }

    return RunRecord(
      id: map['id'] as int?,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
      endTime: DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int),
      durationSeconds: map['duration_seconds'] as int,
      distanceMeters: (map['distance_meters'] as num).toDouble(),
      calories: map['calories'] as int,
      avgPaceSecondsPerKm: map['avg_pace_seconds'] as int,
      points: parsedPoints,
      splits: parsedSplits,
    );
  }
}
