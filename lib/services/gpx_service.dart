import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/run_record.dart';

class GpxService {
  static String generateGpx(RunRecord record) {
    final isoDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(record.startTime.toUtc());
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<gpx version="1.1" creator="RunTracker" xmlns="http://www.topografix.com/GPX/1/1">');
    buffer.writeln('  <metadata>');
    buffer.writeln('    <name>Run Track - ${DateFormat('yyyy-MM-dd HH:mm').format(record.startTime)}</name>');
    buffer.writeln('    <time>$isoDate</time>');
    buffer.writeln('  </metadata>');
    buffer.writeln('  <trk>');
    buffer.writeln('    <name>Run</name>');
    buffer.writeln('    <type>running</type>');
    buffer.writeln('    <trkseg>');

    for (final point in record.points) {
      final pointIso = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(point.timestamp.toUtc());
      buffer.writeln('      <trkpt lat="${point.latitude}" lon="${point.longitude}">');
      buffer.writeln('        <ele>${point.altitude.toStringAsFixed(1)}</ele>');
      buffer.writeln('        <time>$pointIso</time>');
      buffer.writeln('      </trkpt>');
    }

    buffer.writeln('    </trkseg>');
    buffer.writeln('  </trk>');
    buffer.writeln('</gpx>');

    return buffer.toString();
  }

  static Future<void> exportAndShareGpx(RunRecord record) async {
    final gpxContent = generateGpx(record);
    final tempDir = await getTemporaryDirectory();
    final fileName = 'run_${DateFormat('yyyyMMdd_HHmmss').format(record.startTime)}.gpx';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(gpxContent);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: '我的跑步轨迹 (${(record.distanceKm).toStringAsFixed(2)} 公里, 用时 ${record.formattedDuration})',
        subject: '跑步轨迹备份 - RunTracker',
      ),
    );
  }
}
