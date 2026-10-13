import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/tracking_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  double _userWeight = 65.0;

  final List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.gps_fixed,
      'title': '精准 GPS 轨迹追踪',
      'subtitle': '秒级卫星硬件直连',
      'desc': '内置火星坐标(GCJ-02)高精度纠偏算法，完美契合国内道路，精准记录你的每一次脚步与路线。',
      'accent': AppTheme.primaryGreen,
    },
    {
      'icon': Icons.record_voice_over_outlined,
      'title': '离线语音智能助教',
      'subtitle': '跑步无需频繁低头',
      'desc': '每跑满 1 公里自动语音播报用时与配速，调用手机原生系统引擎，全程离线且零网络流量消耗。',
      'accent': AppTheme.accentOrange,
    },
    {
      'icon': Icons.insights,
      'title': '数据复盘与 GPX 导出',
      'subtitle': '全开源 · 零付费门槛',
      'desc': '每公里分段配速柱状图、周跑量走势总览，支持一键免费导出 GPX 标准轨迹文件，数据全在本地。',
      'accent': const Color(0xFF00B0FF),
    },
  ];

  void _finishWelcome() async {
    final tracker = Provider.of<TrackingService>(context, listen: false);
    tracker.userWeightKg = _userWeight;
    await DatabaseService.instance.setUserWeight(_userWeight);
    await DatabaseService.instance.markWelcomeSeen();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (ctx) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // 顶部跳过按钮
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finishWelcome,
                child: const Text('跳过', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
              ),
            ),

            // 1. 动态 App Logo 展示
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.35),
                      blurRadius: 28,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    color: AppTheme.cardDark,
                    child: const Icon(Icons.directions_run, color: AppTheme.primaryGreen, size: 52),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // App 标题
            const Text(
              'RUN TRACKER',
              style: TextStyle(
                color: AppTheme.textLight,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '超越自我 · 每一步都算数',
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),

            const SizedBox(height: 24),

            // 2. 轮播内容卡片
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _features.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final item = _features[index];
                  final Color accent = item['accent'] as Color;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.12),
                            shape: BoxShape.circle,
                            border: Border.all(color: accent.withOpacity(0.3)),
                          ),
                          child: Icon(item['icon'] as IconData, size: 48, color: accent),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          item['title'] as String,
                          style: const TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['subtitle'] as String,
                          style: TextStyle(
                            color: accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          item['desc'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 3. 分页圆点指示器
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _features.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppTheme.primaryGreen
                        : Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 4. 轻量体重设置（最后一页或通底展示，用于精准卡路里）
            if (_currentPage == 2)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          '初始体重设定 (用于热量计算):',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18),
                            color: AppTheme.textLight,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              if (_userWeight > 35) setState(() => _userWeight -= 1);
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '${_userWeight.toInt()} kg',
                              style: const TextStyle(
                                color: AppTheme.primaryGreen,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            color: AppTheme.textLight,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              if (_userWeight < 150) setState(() => _userWeight += 1);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              const SizedBox(height: 48),

            const SizedBox(height: 24),

            // 5. 底部主操作按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _features.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _finishWelcome();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentPage == _features.length - 1 ? '开启跑步之旅' : '下一页',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
