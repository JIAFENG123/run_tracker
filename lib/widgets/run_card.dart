import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/run_record.dart';
import '../theme/app_theme.dart';

class RunCard extends StatelessWidget {
  final RunRecord record;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const RunCard({
    super.key,
    required this.record,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy年MM月dd日 HH:mm').format(record.startTime);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.directions_run,
                        color: AppTheme.primaryGreen,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.more_horiz, color: AppTheme.textMuted, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: AppTheme.cardDark,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (ctx) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                title: const Text('删除此记录', style: TextStyle(color: Colors.redAccent)),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  onDelete!();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  record.distanceKm.toStringAsFixed(2),
                  style: const TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'km',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStat('用时', record.formattedDuration),
                _buildStat('平均配速', record.formattedPace),
                _buildStat('消耗热量', '${record.calories} kcal'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textLight,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
