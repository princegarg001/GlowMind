// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';

/// Web-specific audio player using HTML5 Audio element
class WebAudioPlayer {
  static html.AudioElement? _audio;
  static StreamSubscription? _endedSubscription;
  static StreamSubscription? _errorSubscription;
  static StreamSubscription? _canPlaySubscription;
  
  static bool get isSupported => kIsWeb;
  
  /// Play audio from a URL (supports blob: URLs)
  static Future<void> play(String url, {Function? onComplete}) async {
    try {
      // Stop any existing playback
      await stop();
      
      _audio = html.AudioElement();
      _audio!.src = url;
      _audio!.volume = 1.0;
      _audio!.preload = 'auto';
      
      // Add error listener for debugging
      _errorSubscription = _audio!.onError.listen((event) {
        debugPrint('WebAudioPlayer: Error event - ${_audio?.error?.code}: ${_audio?.error?.message}');
      });
      
      // Wait for the audio to be ready to play
      final completer = Completer<void>();
      
      _canPlaySubscription = _audio!.onCanPlay.listen((_) {
        debugPrint('WebAudioPlayer: Audio can play, duration: ${_audio!.duration}');
        if (!completer.isCompleted) {
          completer.complete();
        }
      });
      
      // Also listen for loadeddata as fallback
      _audio!.onLoadedData.listen((_) {
        debugPrint('WebAudioPlayer: Audio data loaded');
      });
      
      _audio!.onLoadedMetadata.listen((_) {
        debugPrint('WebAudioPlayer: Audio metadata loaded, duration: ${_audio!.duration}');
      });
      
      // Load the audio
      _audio!.load();
      
      debugPrint('WebAudioPlayer: Loading $url');
      
      // Wait for canplay or timeout after 5 seconds
      await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('WebAudioPlayer: Timeout waiting for canplay, trying to play anyway');
        },
      );
      
      // Set up completion listener
      if (onComplete != null) {
        _endedSubscription = _audio!.onEnded.listen((_) {
          debugPrint('WebAudioPlayer: Playback ended');
          onComplete();
        });
      }
      
      debugPrint('WebAudioPlayer: Starting play, readyState: ${_audio!.readyState}');
      await _audio!.play();
      debugPrint('WebAudioPlayer: Play started, volume: ${_audio!.volume}, duration: ${_audio!.duration}');
    } catch (e) {
      debugPrint('WebAudioPlayer: Error playing audio: $e');
      rethrow;
    }
  }
  
  /// Stop current playback
  static Future<void> stop() async {
    try {
      _endedSubscription?.cancel();
      _endedSubscription = null;
      _errorSubscription?.cancel();
      _errorSubscription = null;
      _canPlaySubscription?.cancel();
      _canPlaySubscription = null;
      
      if (_audio != null) {
        _audio!.pause();
        _audio!.currentTime = 0;
        _audio = null;
      }
      debugPrint('WebAudioPlayer: Stopped');
    } catch (e) {
      debugPrint('WebAudioPlayer: Error stopping: $e');
    }
  }
  
  /// Set volume (0.0 - 1.0)
  static void setVolume(double volume) {
    if (_audio != null) {
      _audio!.volume = volume.clamp(0.0, 1.0);
    }
  }
}
