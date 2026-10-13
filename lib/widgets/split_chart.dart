import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

class SplitChart extends StatelessWidget {
  final List<double> splits;

  const SplitChart({super.key, required this.splits});

  String _formatPace(double sec) {
    final m = (sec ~/ 60);
    final s = (sec % 60).toInt();
    return "$m'${s.toString().padLeft(2, '0')}\"";
  }

  @override
  Widget build(BuildContext context) {
    if (splits.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Text(
            '尚未完成整公里分段',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    // 计算最慢配速用于Y轴上限
    final maxSec = splits.reduce((a, b) => a > b ? a : b);
    final maxY = (maxSec * 1.2).ceilToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '每公里分段配速',
          style: TextStyle(
            color: AppTheme.textLight,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final km = value.toInt() + 1;
                      if (km <= splits.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '$km km',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              barGroups: List.generate(splits.length, (index) {
                final pace = splits[index];
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: pace,
                      color: AppTheme.primaryGreen,
                      width: 16,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ],
                  showingTooltipIndicators: [0],
                );
              }),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppTheme.cardDark,
                  tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  tooltipMargin: 4,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      _formatPace(rod.toY),
                      const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
