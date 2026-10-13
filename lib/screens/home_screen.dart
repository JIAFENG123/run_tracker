import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/run_record.dart';
import '../services/database_service.dart';
import '../services/tracking_service.dart';
import '../theme/app_theme.dart';
import '../widgets/run_card.dart';
import 'active_run_screen.dart';
import 'history_screen.dart';
import 'run_detail_screen.dart';
import 'statistics_screen.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<RunRecord> _recentRuns = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TrackingService>(context, listen: false).fetchInitialPosition();
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final runs = await DatabaseService.instance.getAllRuns();
    final stats = await DatabaseService.instance.getTotalStats();
    if (mounted) {
      setState(() {
        _recentRuns = runs.take(3).toList();
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  void _startRun(BuildContext context) async {
    final tracker = Provider.of<TrackingService>(context, listen: false);

    // 如果不是模拟模式，先检查系统GPS权限
    if (!tracker.isSimulation) {
      final hasPermission = await tracker.checkAndRequestPermissions();
      if (!hasPermission) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.cardDark,
            title: const Text('需要定位权限'),
            content: const Text('跑步记录需要使用手机 GPS 定位权限以绘制路线。您也可以在右上角临时开启“模拟测试”模式进行体验。'),
            actions: [
              TextButton(
                onPressed: () {
                  tracker.isSimulation = true;
                  Navigator.pop(ctx);
                  _launchActiveRun(context, tracker);
                },
                child: const Text('开启模拟测试体验'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('确定'),
              ),
            ],
          ),
        );
        return;
      }

      // 如果尚未锁定物理定位，快速获取定位
      if (tracker.currentLatLng == null) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(
            child: Card(
              color: AppTheme.cardDark,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryGreen),
                    SizedBox(width: 16),
                    Text(
                      '正在锁定当前 GPS 定位...',
                      style: TextStyle(color: AppTheme.textLight, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tracker.getCurrentPosition();

        if (context.mounted) {
          Navigator.pop(context);
        }
      }
    }

    if (!context.mounted) return;
    _launchActiveRun(context, tracker);
  }

  void _launchActiveRun(BuildContext context, TrackingService tracker) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const ActiveRunScreen()),
    ).then((_) {
      _loadDashboardData();
    });

    tracker.startCountdown(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomeFeed(context),
      const HistoryScreen(),
      const StatisticsScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: AppTheme.darkBackground,
          selectedItemColor: AppTheme.primaryGreen,
          unselectedItemColor: AppTheme.textMuted,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            if (index == 0) _loadDashboardData();
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: '首页',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: '记录',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: '统计',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeFeed(BuildContext context) {
    final totalDistanceKm = ((_stats['total_distance_meters'] as double?) ?? 0.0) / 1000.0;
    final totalRuns = (_stats['total_runs'] as int?) ?? 0;
    final tracker = Provider.of<TrackingService>(context);

    return SafeArea(
      child: RefreshIndicator(
        color: AppTheme.primaryGreen,
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部标题与模式切换
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryGreen.withOpacity(0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              color: AppTheme.cardDark,
                              child: const Icon(Icons.directions_run, color: AppTheme.primaryGreen),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'RUN TRACKER',
                                style: TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              SizedBox(height: 1),
                              Text(
                                '今日跑步状态',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppTheme.textLight,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.help_outline, color: AppTheme.textMuted, size: 20),
                        tooltip: '功能指引与欢迎页',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (ctx) => const WelcomeScreen()),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      // 模拟跑步开关 (方便在电脑和虚拟机免运动测试)
                      InkWell(
                        onTap: () {
                          tracker.toggleSimulation();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(tracker.isSimulation ? '已切换为模拟运动路线' : '已切换为真实 GPS 定位'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.cardDark,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: tracker.isSimulation ? Colors.orangeAccent : Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                tracker.isSimulation ? Icons.tune : Icons.gps_fixed,
                                size: 14,
                                color: tracker.isSimulation ? Colors.orangeAccent : AppTheme.primaryGreen,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                tracker.isSimulation ? '模拟模式' : 'GPS模式',
                                style: TextStyle(
                                  color: tracker.isSimulation ? Colors.orangeAccent : AppTheme.primaryGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 跑量速览面板
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('总跑步里程', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              totalDistanceKm.toStringAsFixed(1),
                              style: const TextStyle(
                                color: AppTheme.textLight,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('km', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    Container(width: 1, height: 40, color: Colors.white.withOpacity(0.08)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('累计运动', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$totalRuns',
                              style: const TextStyle(
                                color: AppTheme.textLight,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('次', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // 🚀 核心大按钮：GO 开跑
              Center(
                child: GestureDetector(
                  onTap: () => _startRun(context),
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          AppTheme.primaryGreen,
                          Color(0xFF00B0FF),
                        ],
                        center: Alignment(0.2, -0.2),
                        radius: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 6,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_run, color: Colors.black, size: 38),
                          SizedBox(height: 2),
                          Text(
                            'GO',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // 最近运动记录
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '最近运动',
                    style: TextStyle(
                      color: AppTheme.textLight,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_recentRuns.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _currentIndex = 1;
                        });
                      },
                      child: const Text('查看全部', style: TextStyle(color: AppTheme.primaryGreen)),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                  ),
                )
              else if (_recentRuns.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.terrain_outlined, size: 40, color: AppTheme.textMuted),
                        SizedBox(height: 8),
                        Text('还没有跑步记录，点击上方 GO 出发吧！', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                )
              else
                ..._recentRuns.map(
                  (run) => RunCard(
                    record: run,
                    onTap: () async {
                      final deleted = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => RunDetailScreen(record: run),
                        ),
                      );
                      if (deleted == true) {
                        _loadDashboardData();
                      }
                    },
                    onDelete: () async {
                      if (run.id != null) {
                        await DatabaseService.instance.deleteRun(run.id!);
                        _loadDashboardData();
                      }
                    },
                  ),
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
