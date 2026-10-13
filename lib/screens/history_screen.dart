import 'package:flutter/material.dart';
import '../models/run_record.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/run_card.dart';
import 'run_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<RunRecord>> _runsFuture;

  @override
  void initState() {
    super.initState();
    _loadRuns();
  }

  void _loadRuns() {
    setState(() {
      _runsFuture = DatabaseService.instance.getAllRuns();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('跑步历史'),
      ),
      body: FutureBuilder<List<RunRecord>>(
        future: _runsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
          }

          if (snapshot.hasError) {
            return Center(child: Text('加载失败: ${snapshot.error}'));
          }

          final runs = snapshot.data ?? [];

          if (runs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_run, size: 64, color: AppTheme.textMuted.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  const Text(
                    '暂无跑步记录',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '迈开腿，去跑第一公里吧！',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppTheme.primaryGreen,
            onRefresh: () async {
              _loadRuns();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: runs.length,
              itemBuilder: (context, index) {
                final run = runs[index];
                return RunCard(
                  record: run,
                  onTap: () async {
                    final deleted = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => RunDetailScreen(record: run),
                      ),
                    );
                    if (deleted == true) {
                      _loadRuns();
                    }
                  },
                  onDelete: () async {
                    if (run.id != null) {
                      await DatabaseService.instance.deleteRun(run.id!);
                      _loadRuns();
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
