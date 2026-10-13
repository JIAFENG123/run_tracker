import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/run_record.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/metric_card.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late Future<Map<String, dynamic>> _statsFuture;
  late Future<List<RunRecord>> _runsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _statsFuture = DatabaseService.instance.getTotalStats();
      _runsFuture = DatabaseService.instance.getAllRuns();
    });
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    return '$hours小时 $minutes分钟';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据统计'),
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryGreen,
        onRefresh: () async => _loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: FutureBuilder(
            future: Future.wait([_statsFuture, _runsFuture]),
            builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
              }

              final stats = (snapshot.data?[0] as Map<String, dynamic>?) ?? {};
              final runs = (snapshot.data?[1] as List<RunRecord>?) ?? [];

              final totalDistanceMeters = (stats['total_distance_meters'] as double?) ?? 0.0;
              final totalDistanceKm = totalDistanceMeters / 1000.0;
              final totalDurationSec = (stats['total_duration_seconds'] as int?) ?? 0;
              final totalRuns = (stats['total_runs'] as int?) ?? 0;
              final totalCalories = (stats['total_calories'] as int?) ?? 0;
              final maxDistanceMeters = (stats['max_distance_meters'] as double?) ?? 0.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 累计总跑量巨幅卡片
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryGreen.withOpacity(0.2),
                          AppTheme.cardDark,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '累计跑量',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              totalDistanceKm.toStringAsFixed(1),
                              style: const TextStyle(
                                color: AppTheme.textLight,
                                fontSize: 52,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.5,
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
                        const SizedBox(height: 12),
                        Text(
                          '共完成 $totalRuns 次跑步 · 消耗约 $totalCalories 千卡',
                          style: const TextStyle(color: AppTheme.textLight, fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. 指标网格
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.7,
                    children: [
                      MetricCard(
                        icon: Icons.timer,
                        label: '总运动时长',
                        value: _formatDuration(totalDurationSec),
                      ),
                      MetricCard(
                        icon: Icons.emoji_events_outlined,
                        label: '最长单次距离',
                        value: (maxDistanceMeters / 1000).toStringAsFixed(2),
                        unit: 'km',
                        accentColor: Colors.amberAccent,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 3. 近7天跑步趋势图表
                  _buildWeeklyTrendChart(runs),

                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyTrendChart(List<RunRecord> runs) {
    // 统计过去 7 天每天的跑量
    final now = DateTime.now();
    final Map<int, double> last7DaysKm = {};

    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dayKey = day.millisecondsSinceEpoch;
      last7DaysKm[dayKey] = 0.0;
    }

    for (final run in runs) {
      final runDay = DateTime(run.startTime.year, run.startTime.month, run.startTime.day);
      final key = runDay.millisecondsSinceEpoch;
      if (last7DaysKm.containsKey(key)) {
        last7DaysKm[key] = (last7DaysKm[key] ?? 0.0) + run.distanceKm;
      }
    }

    final dayKeys = last7DaysKm.keys.toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '近 7 日跑量走势 (km)',
            style: TextStyle(
              color: AppTheme.textLight,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < dayKeys.length) {
                          final date = DateTime.fromMillisecondsSinceEpoch(dayKeys[index]);
                          final label = DateFormat('MM/dd').format(date);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              label,
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(dayKeys.length, (index) {
                  final km = last7DaysKm[dayKeys[index]] ?? 0.0;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: km > 0 ? km : 0.2, // 最小高度展示柱脚
                        color: km > 0 ? AppTheme.primaryGreen : Colors.white.withOpacity(0.1),
                        width: 14,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
