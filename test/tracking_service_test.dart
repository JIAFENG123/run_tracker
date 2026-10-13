import 'package:flutter_test/flutter_test.dart';
import 'package:run_tracker/models/location_point.dart';
import 'package:run_tracker/models/run_record.dart';
import 'package:run_tracker/services/gpx_service.dart';

void main() {
  group('RunRecord and GPX Tests', () {
    test('RunRecord pace and duration formatting', () {
      final record = RunRecord(
        id: 1,
        startTime: DateTime(2026, 10, 13, 8, 0, 0),
        endTime: DateTime(2026, 10, 13, 8, 30, 0),
        durationSeconds: 1800, // 30 minutes
        distanceMeters: 5000.0, // 5 km
        calories: 320,
        avgPaceSecondsPerKm: 360, // 6'00"
        points: [
          LocationPoint(
            latitude: 31.2304,
            longitude: 121.4737,
            timestamp: DateTime(2026, 10, 13, 8, 0, 0),
          ),
          LocationPoint(
            latitude: 31.2350,
            longitude: 121.4780,
            timestamp: DateTime(2026, 10, 13, 8, 30, 0),
          ),
        ],
        splits: [360.0, 355.0, 365.0, 358.0, 362.0],
      );

      expect(record.distanceKm, 5.0);
      expect(record.formattedDuration, '30:00');
      expect(record.formattedPace, "6'00\"");

      // Test GPX export
      final gpx = GpxService.generateGpx(record);
      expect(gpx.contains('<gpx version="1.1"'), isTrue);
      expect(gpx.contains('lat="31.2304"'), isTrue);
      expect(gpx.contains('lon="121.4737"'), isTrue);
      expect(gpx.contains('<trkpt'), isTrue);
    });
  });
}
