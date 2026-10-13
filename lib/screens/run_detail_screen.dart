import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../models/run_record.dart';
import '../services/gpx_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/metric_card.dart';
import '../services/coord_converter.dart';
import '../widgets/split_chart.dart';

class RunDetailScreen extends StatelessWidget {
  final RunRecord record;

  const RunDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final routePoints = record.points
        .map((p) => CoordConverter.wgs84ToGcj02(p.latitude, p.longitude))
        .toList();
    final center = routePoints.isNotEmpty
        ? routePoints[routePoints.length ~/ 2]
        : const LatLng(31.2304, 121.4737);

    final dateStr = DateFormat('yyyy年MM月dd日 HH:mm').format(record.startTime);

    return Scaffold(
      appBar: AppBar(
        title: const Text('跑步战报'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppTheme.primaryGreen),
            tooltip: '导出 GPX 轨迹',
            onPressed: () => GpxService.exportAndShareGpx(record),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: '删除记录',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.cardDark,
                  title: const Text('确认删除'),
                  content: const Text('确定要删除本次跑步记录吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final nav = Navigator.of(context);
                        Navigator.pop(ctx);
                        if (record.id != null) {
                          await DatabaseService.instance.deleteRun(record.id!);
                        }
                        nav.pop(true);
                      },
                      child: const Text('删除', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 地图轨迹展示区
            Container(
              height: 280,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              clipBehavior: Clip.antiAlias,
              child: routePoints.isEmpty
                  ? const Center(
                      child: Text('无轨迹数据', style: TextStyle(color: AppTheme.textMuted)),
                    )
                  : FlutterMap(
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: 15.0,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://webrd0{s}.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=1&style=8&x={x}&y={y}&z={z}',
                          subdomains: const ['1', '2', '3', '4'],
                          userAgentPackageName: 'com.running.tracker',
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: routePoints,
                              strokeWidth: 5.0,
                              color: AppTheme.primaryGreen,
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            // 起点
                            Marker(
                              point: routePoints.first,
                              width: 20,
                              height: 20,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(Icons.trip_origin, size: 14, color: Colors.green),
                                ),
                              ),
                            ),
                            // 终点
                            Marker(
                              point: routePoints.last,
                              width: 22,
                              height: 22,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(Icons.flag, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),

            // 2. 运动总览概括卡片
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateStr,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        record.distanceKm.toStringAsFixed(2),
                        style: const TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '公里',
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. 四宫格核心数据指标
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.7,
                children: [
                  MetricCard(
                    icon: Icons.timer_outlined,
                    label: '总耗时',
                    value: record.formattedDuration,
                  ),
                  MetricCard(
                    icon: Icons.speed,
                    label: '平均配速',
                    value: record.formattedPace,
                    unit: '/km',
                  ),
                  MetricCard(
                    icon: Icons.local_fire_department,
                    label: '消耗热量',
                    value: '${record.calories}',
                    unit: 'kcal',
                    accentColor: AppTheme.accentOrange,
                  ),
                  MetricCard(
                    icon: Icons.location_on_outlined,
                    label: 'GPS记录点数',
                    value: '${record.points.length}',
                    unit: '点',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. 每公里分段图表
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: SplitChart(splits: record.splits),
              ),
            ),

            const SizedBox(height: 20),

            // 5. 导出与备份操作栏
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => GpxService.exportAndShareGpx(record),
                  icon: const Icon(Icons.file_download_outlined, color: Colors.black),
                  label: const Text('免费导出 GPX 标准轨迹文件'),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
