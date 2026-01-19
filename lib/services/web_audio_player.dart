import 'package:flutter/foundation.dart';

// Stub for non-web platforms
class WebAudioPlayer {
  static bool get isSupported => kIsWeb;
  
  static Future<void> play(String url, {Function? onComplete}) async {
    // This is a stub - actual implementation uses dart:html
    debugPrint('WebAudioPlayer: Stub called on non-web platform');
  }
  
  static Future<void> stop() async {
    debugPrint('WebAudioPlayer: Stub stop called');
  }
  
  static void setVolume(double volume) {
    debugPrint('WebAudioPlayer: Stub setVolume called');
  }
}
