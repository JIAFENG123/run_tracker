import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/tracking_service.dart';
import '../theme/app_theme.dart';
import 'run_detail_screen.dart';

class ActiveRunScreen extends StatefulWidget {
  const ActiveRunScreen({super.key});

  @override
  State<ActiveRunScreen> createState() => _ActiveRunScreenState();
}

class _ActiveRunScreenState extends State<ActiveRunScreen> {
  final MapController _mapController = MapController();
  bool _autoFollow = true;

  @override
  Widget build(BuildContext context) {
    final tracker = Provider.of<TrackingService>(context);

    // 监听坐标更新，若开启跟随则移动镜头
    if (_autoFollow && tracker.currentLatLng != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(tracker.currentLatLng!, _mapController.camera.zoom);
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. 地图背景
          _buildMap(tracker),

          // 2. 顶部工具栏 (模拟模式切换、GPS状态)
          _buildTopBar(context, tracker),

          // 3. 底部悬浮运动数据看板与控制区
          _buildBottomDashboard(context, tracker),

          // 4. 倒计时遮罩
          if (tracker.state == RunState.countdown) _buildCountdownOverlay(tracker),
        ],
      ),
    );
  }

  Widget _buildMap(TrackingService tracker) {
    final currentPos = tracker.currentLatLng;
    if (currentPos == null) {
      return Container(
        color: AppTheme.darkBackground,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryGreen),
              SizedBox(height: 16),
              Text(
                '正在锁定当前卫星定位...',
                style: TextStyle(
                  color: AppTheme.textLight,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                '首次搜星请在开阔室外或窗边以获得最佳 GPS 信号',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final routePoints = tracker.routeCoordinates;

    return FlutterMap(
      key: ValueKey('${currentPos.latitude}_${currentPos.longitude}'),
      mapController: _mapController,
      options: MapOptions(
        initialCenter: currentPos,
        initialZoom: 16.5,
        minZoom: 4,
        maxZoom: 18,
        onPositionChanged: (camera, hasGesture) {
          if (hasGesture && _autoFollow) {
            setState(() {
              _autoFollow = false;
            });
          }
        },
      ),
      children: [
        // 开源免Key高速高德瓦片
        TileLayer(
          urlTemplate: 'https://webrd0{s}.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=1&style=8&x={x}&y={y}&z={z}',
          subdomains: const ['1', '2', '3', '4'],
          userAgentPackageName: 'com.running.tracker',
        ),

        // 轨迹路线 Polyline
        if (routePoints.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                strokeWidth: 6.0,
                color: AppTheme.primaryGreen,
              ),
            ],
          ),

        // 起点与当前点标记 Marker
        MarkerLayer(
          markers: [
            // 起点
            if (routePoints.isNotEmpty)
              Marker(
                point: routePoints.first,
                width: 24,
                height: 24,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryGreen, width: 4),
                  ),
                ),
              ),

            // 当前实时位置 (发光脉冲点)
            if (tracker.currentLatLng != null)
              Marker(
                point: tracker.currentLatLng!,
                width: 32,
                height: 32,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(0.6),
                        blurRadius: 10,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.navigation, color: Colors.black, size: 16),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context, TrackingService tracker) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 返回/收起
            CircleAvatar(
              backgroundColor: AppTheme.cardDark.withOpacity(0.85),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  if (tracker.state == RunState.running || tracker.state == RunState.paused) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppTheme.cardDark,
                        title: const Text('正在跑步中'),
                        content: const Text('是否放弃本次运动记录？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('继续跑步'),
                          ),
                          TextButton(
                            onPressed: () {
                              tracker.cancelRun();
                              Navigator.pop(ctx);
                              Navigator.pop(context);
                            },
                            child: const Text('确认放弃', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    );
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
            ),

            // 状态胶囊 & 模拟模式切换
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.cardDark.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: tracker.isSimulation ? Colors.orangeAccent : AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tracker.isSimulation ? '模拟测试' : 'GPS良好',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (tracker.state == RunState.idle) {
                        tracker.toggleSimulation();
                      }
                    },
                    child: Icon(
                      tracker.isSimulation ? Icons.tune : Icons.sim_card_outlined,
                      size: 16,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // 重新居中按钮
            CircleAvatar(
              backgroundColor: AppTheme.cardDark.withOpacity(0.85),
              child: IconButton(
                icon: Icon(
                  _autoFollow ? Icons.my_location : Icons.location_searching,
                  color: _autoFollow ? AppTheme.primaryGreen : Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _autoFollow = true;
                  });
                  if (tracker.currentLatLng != null) {
                    _mapController.move(tracker.currentLatLng!, 16.5);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomDashboard(BuildContext context, TrackingService tracker) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        decoration: BoxDecoration(
          color: AppTheme.darkBackground.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 大字距离显示
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  tracker.distanceKm.toStringAsFixed(2),
                  style: const TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
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

            const SizedBox(height: 16),

            // 核心三参数 (用时、实时配速、平均配速、卡路里)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricColumn('用时', tracker.formattedDuration),
                _buildMetricColumn('实时配速', tracker.formattedCurrentPace),
                _buildMetricColumn('平均配速', tracker.formattedAvgPace),
                _buildMetricColumn('热量', '${tracker.calories} kcal'),
              ],
            ),

            const SizedBox(height: 24),

            // 控制按钮栏
            _buildControls(context, tracker),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textLight,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildControls(BuildContext context, TrackingService tracker) {
    if (tracker.state == RunState.running) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 暂停按钮
          GestureDetector(
            onTap: () => tracker.pauseRun(),
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppTheme.accentOrange,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentOrange.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.pause, color: Colors.white, size: 36),
            ),
          ),
        ],
      );
    } else if (tracker.state == RunState.paused) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 恢复跑步
          GestureDetector(
            onTap: () => tracker.resumeRun(),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Icon(Icons.play_arrow, color: Colors.black, size: 36),
            ),
          ),

          // 长按结束 (防手抖误触)
          GestureDetector(
            onLongPress: () async {
              final record = await tracker.finishRun();
              if (!mounted) return;
              if (record != null) {
                Navigator.of(this.context).pushReplacement(
                  MaterialPageRoute(
                    builder: (ctx) => RunDetailScreen(record: record),
                  ),
                );
              } else {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('运动距离过短，未保存记录')),
                );
                Navigator.of(this.context).pop();
              }
            },
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withOpacity(0.4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stop, color: Colors.white, size: 28),
                  Text(
                    '长按结束',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCountdownOverlay(TrackingService tracker) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Text(
          '${tracker.countdownValue}',
          style: const TextStyle(
            color: AppTheme.primaryGreen,
            fontSize: 120,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
