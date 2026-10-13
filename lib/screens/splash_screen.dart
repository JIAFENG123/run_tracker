import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/tracking_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _animController.forward();
    _checkNextScreen();
  }

  Future<void> _checkNextScreen() async {
    // 预加载配置与用户习惯体重
    final hasSeen = await DatabaseService.instance.hasSeenWelcome();
    final weight = await DatabaseService.instance.getUserWeight();

    if (mounted) {
      final tracker = Provider.of<TrackingService>(context, listen: false);
      tracker.userWeightKg = weight;
      // 预先静默获取一次位置
      tracker.fetchInitialPosition();
    }

    await Future.delayed(const Duration(milliseconds: 1800));

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (ctx, anim1, anim2) =>
            hasSeen ? const HomeScreen() : const WelcomeScreen(),
        transitionsBuilder: (ctx, anim1, anim2, child) {
          return FadeTransition(opacity: anim1, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 呼吸发光 Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(0.4),
                        blurRadius: 36,
                        spreadRadius: 4,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      color: AppTheme.cardDark,
                      child: const Icon(Icons.directions_run, color: AppTheme.primaryGreen, size: 64),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'RUN TRACKER',
                  style: TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.0,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'POWER YOUR RUN',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
