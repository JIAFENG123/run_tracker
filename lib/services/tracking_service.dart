import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/location_point.dart';
import '../models/run_record.dart';
import 'coord_converter.dart';
import 'database_service.dart';
import 'tts_service.dart';

enum RunState { idle, countdown, running, paused, finished }

class TrackingService extends ChangeNotifier {
  RunState _state = RunState.idle;
  RunState get state => _state;

  DateTime? _startTime;
  DateTime? _endTime;
  int _durationSeconds = 0;
  double _distanceMeters = 0.0;
  int _calories = 0;
  int _currentPaceSeconds = 0; // 最近配速 (秒/公里)
  int _avgPaceSeconds = 0;

  // 用户参数
  double userWeightKg = 65.0; // 默认65kg

  final List<LocationPoint> _points = [];
  final List<double> _splits = []; // 每公里用时 (秒)
  int _lastKilometerMark = 0;
  int _lastKilometerTime = 0;

  Position? _initialPosition;
  Position? get initialPosition => _initialPosition;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _timer;
  int _countdownValue = 3;

  // 模拟跑步模式 (供模拟器/电脑端调试用)
  bool isSimulation = false;
  Timer? _simTimer;

  void toggleSimulation() {
    if (_state == RunState.idle) {
      isSimulation = !isSimulation;
      notifyListeners();
    }
  }

  // Getters
  int get durationSeconds => _durationSeconds;
  double get distanceMeters => _distanceMeters;
  double get distanceKm => _distanceMeters / 1000.0;
  int get calories => _calories;
  int get currentPaceSeconds => _currentPaceSeconds;
  int get avgPaceSeconds => _avgPaceSeconds;
  List<LocationPoint> get points => List.unmodifiable(_points);
  
  // 经纬度统一经过火星坐标系(GCJ-02)校准，完美对齐高德地图瓦片
  List<LatLng> get routeCoordinates => _points
      .map((p) => CoordConverter.wgs84ToGcj02(p.latitude, p.longitude))
      .toList();
      
  List<double> get splits => List.unmodifiable(_splits);
  int get countdownValue => _countdownValue;
  
  LatLng? get currentLatLng {
    if (_points.isNotEmpty) {
      return CoordConverter.wgs84ToGcj02(_points.last.latitude, _points.last.longitude);
    }
    if (_initialPosition != null) {
      return CoordConverter.wgs84ToGcj02(_initialPosition!.latitude, _initialPosition!.longitude);
    }
    return null;
  }

  String get formattedDuration {
    final hours = _durationSeconds ~/ 3600;
    final minutes = (_durationSeconds % 3600) ~/ 60;
    final seconds = _durationSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String formatPace(int paceSec) {
    if (paceSec <= 0 || paceSec > 3600) return "--'--\"";
    final min = paceSec ~/ 60;
    final sec = paceSec % 60;
    return "$min'${sec.toString().padLeft(2, '0')}\"";
  }

  String get formattedCurrentPace => formatPace(_currentPaceSeconds);
  String get formattedAvgPace => formatPace(_avgPaceSeconds);

  Future<bool> checkAndRequestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkAndRequestPermissions();
      if (!hasPermission) return null;

      // 1. 优先获取系统缓存的已知位置 (毫秒级响应，立刻确定当前城市与街道)
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _initialPosition = lastKnown;
        notifyListeners();
      }

      // 2. 异步获取最新实时卫星定位
      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );
      _initialPosition = current;
      notifyListeners();
      return current;
    } catch (_) {
      return _initialPosition;
    }
  }

  void startCountdown(VoidCallback onCountdownFinished) {
    _state = RunState.countdown;
    _countdownValue = 3;
    notifyListeners();

    TtsService().speak("准备开始，三");

    Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdownValue--;
      if (_countdownValue == 2) {
        TtsService().speak("二");
      } else if (_countdownValue == 1) {
        TtsService().speak("一");
      }

      if (_countdownValue <= 0) {
        timer.cancel();
        _state = RunState.running;
        _startTracking();
        TtsService().speak("开始跑步，加油！");
        onCountdownFinished();
      }
      notifyListeners();
    });
  }

  void _startTracking() {
    _startTime = DateTime.now();
    _durationSeconds = 0;
    _distanceMeters = 0.0;
    _calories = 0;
    _points.clear();
    _splits.clear();
    _lastKilometerMark = 0;
    _lastKilometerTime = 0;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_state == RunState.running) {
        _durationSeconds++;
        _updateMetrics();
        notifyListeners();
      }
    });

    if (isSimulation) {
      _startSimulation();
    } else {
      _startGpsStream();
    }
  }

  Future<void> fetchInitialPosition() async {
    final pos = await getCurrentPosition();
    if (pos != null) {
      _initialPosition = pos;
      notifyListeners();
    }
  }

  void _startGpsStream() {
    // 立即锁定当前定位点，无需等待移动即可显示用户当前真实位置
    getCurrentPosition().then((pos) {
      if (pos != null && _state == RunState.running && _points.isEmpty) {
        _initialPosition = pos;
        _processNewPosition(
          pos.latitude,
          pos.longitude,
          pos.altitude,
          pos.speed,
        );
      }
    });

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 2, // 每移动2米更新一次
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (_state != RunState.running) return;

      // 过滤弱信号或精度过差的点 (大于 30 米)
      if (position.accuracy > 30.0) return;

      _processNewPosition(
        position.latitude,
        position.longitude,
        position.altitude,
        position.speed,
      );
    });
  }

  void _processNewPosition(double lat, double lng, double alt, double speed) {
    final now = DateTime.now();

    if (_points.isNotEmpty) {
      final lastPoint = _points.last;
      final stepDistance = Geolocator.distanceBetween(
        lastPoint.latitude,
        lastPoint.longitude,
        lat,
        lng,
      );

      final timeDiffSec = now.difference(lastPoint.timestamp).inSeconds;

      // 异常漂移过滤 (例如1秒漂移了50米，速度超过180km/h)
      if (timeDiffSec > 0 && (stepDistance / timeDiffSec) > 15.0) {
        return;
      }

      // 静止过滤 (小于 1.5 米视为原地踏步，不累计距离)
      if (stepDistance > 1.5) {
        _distanceMeters += stepDistance;

        // 计算即时配速
        if (speed > 0.8) {
          _currentPaceSeconds = (1000.0 / speed).round();
        } else if (timeDiffSec > 0) {
          final computedSpeed = stepDistance / timeDiffSec;
          if (computedSpeed > 0.8) {
            _currentPaceSeconds = (1000.0 / computedSpeed).round();
          }
        }

        // 检查整公里播报与分段记录
        _checkKilometerMilestone();
      }
    }

    _points.add(LocationPoint(
      latitude: lat,
      longitude: lng,
      timestamp: now,
      altitude: alt,
      speed: speed,
    ));

    _updateMetrics();
    notifyListeners();
  }

  void _updateMetrics() {
    // 计算平均配速
    if (_distanceMeters > 50 && _durationSeconds > 0) {
      final km = _distanceMeters / 1000.0;
      _avgPaceSeconds = (_durationSeconds / km).round();
    }

    // 计算消耗卡路里 (卡路里 = 公里数 * 体重kg * 1.036)
    _calories = (distanceKm * userWeightKg * 1.036).round();
  }

  void _checkKilometerMilestone() {
    final currentKm = (_distanceMeters / 1000.0).floor();
    if (currentKm > _lastKilometerMark) {
      final splitDuration = (_durationSeconds - _lastKilometerTime).toDouble();
      _splits.add(splitDuration);
      _lastKilometerMark = currentKm;
      _lastKilometerTime = _durationSeconds;

      // 语音播报
      final min = splitDuration ~/ 60;
      final sec = (splitDuration % 60).toInt();
      final speechText = "已完成 $currentKm 公里，本公里用时 $min 分 $sec 秒。";
      TtsService().speak(speechText);
    }
  }

  void pauseRun() {
    if (_state == RunState.running) {
      _state = RunState.paused;
      TtsService().speak("跑步已暂停");
      notifyListeners();
    }
  }

  void resumeRun() {
    if (_state == RunState.paused) {
      _state = RunState.running;
      TtsService().speak("跑步继续");
      notifyListeners();
    }
  }

  Future<RunRecord?> finishRun() async {
    _state = RunState.finished;
    _endTime = DateTime.now();

    _timer?.cancel();
    _simTimer?.cancel();
    await _positionSubscription?.cancel();

    // 补全最后一段不满 1 公里的分段
    final remainingTime = (_durationSeconds - _lastKilometerTime).toDouble();
    if (remainingTime > 10 && _distanceMeters > (_lastKilometerMark * 1000)) {
      _splits.add(remainingTime);
    }

    TtsService().speak("运动结束，已跑 ${(distanceKm).toStringAsFixed(2)} 公里。太棒了！");

    if (_distanceMeters < 50) {
      // 距离过短不存入历史
      _state = RunState.idle;
      notifyListeners();
      return null;
    }

    final record = RunRecord(
      startTime: _startTime ?? DateTime.now(),
      endTime: _endTime ?? DateTime.now(),
      durationSeconds: _durationSeconds,
      distanceMeters: _distanceMeters,
      calories: _calories,
      avgPaceSecondsPerKm: _avgPaceSeconds,
      points: List.from(_points),
      splits: List.from(_splits),
    );

    final id = await DatabaseService.instance.insertRun(record);
    final savedRecord = RunRecord(
      id: id,
      startTime: record.startTime,
      endTime: record.endTime,
      durationSeconds: record.durationSeconds,
      distanceMeters: record.distanceMeters,
      calories: record.calories,
      avgPaceSecondsPerKm: record.avgPaceSecondsPerKm,
      points: record.points,
      splits: record.splits,
    );

    _state = RunState.idle;
    notifyListeners();
    return savedRecord;
  }

  void cancelRun() {
    _state = RunState.idle;
    _timer?.cancel();
    _simTimer?.cancel();
    _positionSubscription?.cancel();
    _points.clear();
    _splits.clear();
    _distanceMeters = 0.0;
    _durationSeconds = 0;
    notifyListeners();
  }

  void _startSimulation() {
    // 优先使用当前手机所在位置为中心，若无则使用默认点
    double baseLat = _initialPosition?.latitude ?? (_points.isNotEmpty ? _points.last.latitude : 31.2304);
    double baseLng = _initialPosition?.longitude ?? (_points.isNotEmpty ? _points.last.longitude : 121.4737);
    double angle = 0.0;
    final random = Random();

    _simTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_state != RunState.running) return;

      angle += 0.04;
      // 模拟圆环加微小扰动的跑步路线 (速度约 10 km/h, 每秒移动约 2.8 米)
      final r = 0.0035 + 0.0004 * sin(angle * 2.5);
      final lat = baseLat + r * cos(angle);
      final lng = baseLng + (r * 1.2) * sin(angle);
      final speed = 2.6 + random.nextDouble() * 0.5; // ~2.8 m/s (~6分配速)

      _processNewPosition(lat, lng, 15.0 + random.nextDouble() * 2, speed);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _simTimer?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }
}
