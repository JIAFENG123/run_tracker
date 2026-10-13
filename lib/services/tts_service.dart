import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool isEnabled = true;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _tts.setLanguage("zh-CN");
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5);
      _isInitialized = true;
    } catch (_) {}
  }

  Future<void> speak(String text) async {
    if (!isEnabled) return;
    try {
      await init();
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
