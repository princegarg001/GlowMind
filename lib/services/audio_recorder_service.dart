import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Service for recording and playing voice affirmations
class AudioRecorderService {
  static final AudioRecorder _recorder = AudioRecorder();
  static bool _isRecording = false;
  static bool _isPlaying = false;
  static String? _currentRecordingPath;

  static bool get isRecording => _isRecording;
  static bool get isPlaying => _isPlaying;
  static AudioRecorder get recorder => _recorder;

  /// Get the directory for storing affirmation recordings
  static Future<String> _getAffirmationsDirectory() async {
    if (kIsWeb) {
      return 'affirmations';
    }
    final dir = await getApplicationDocumentsDirectory();
    final affirmationsDir = Directory('${dir.path}/affirmations');
    if (!await affirmationsDir.exists()) {
      await affirmationsDir.create(recursive: true);
    }
    return affirmationsDir.path;
  }

  /// Get the file path for a recording
  static Future<String> getRecordingPath(String id) async {
    final dir = await _getAffirmationsDirectory();
    return '$dir/affirmation_$id.m4a';
  }

  /// Check if recording permission is granted
  static Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  /// Start recording a voice affirmation
  static Future<String?> startRecording(String affirmationId) async {
    try {
      // Check permissions
      if (!await hasPermission()) {
        debugPrint('AudioRecorderService: Microphone permission denied');
        return null;
      }

      _currentRecordingPath = await getRecordingPath(affirmationId);
      
      // Configure recording settings
      // For web, use WAV which is universally supported by browsers
      // opus creates webm container which may have playback issues
      final config = kIsWeb 
          ? const RecordConfig(
              encoder: AudioEncoder.wav,
              sampleRate: 44100,
              numChannels: 1,
            )
          : const RecordConfig(
              encoder: AudioEncoder.aacLc,
              sampleRate: 44100,
              bitRate: 128000,
            );

      await _recorder.start(config, path: _currentRecordingPath!);
      _isRecording = true;
      debugPrint('AudioRecorderService: Started recording to: $_currentRecordingPath (encoder: ${config.encoder})');
      return _currentRecordingPath;
    } catch (e) {
      debugPrint('AudioRecorderService: Error starting recording: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Stop recording and return the file path
  static Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        debugPrint('AudioRecorderService: Not currently recording');
        return null;
      }

      final path = await _recorder.stop();
      _isRecording = false;
      _currentRecordingPath = null;
      debugPrint('AudioRecorderService: Stopped recording, saved to: $path');
      return path;
    } catch (e) {
      debugPrint('AudioRecorderService: Error stopping recording: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Cancel the current recording
  static Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
      }
      if (_currentRecordingPath != null && !kIsWeb) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      _isRecording = false;
      _currentRecordingPath = null;
    } catch (e) {
      debugPrint('AudioRecorderService: Error canceling recording: $e');
      _isRecording = false;
    }
  }

  /// Get audio amplitude for visualization
  static Future<double> getAmplitude() async {
    try {
      final amplitude = await _recorder.getAmplitude();
      // Normalize amplitude to 0-1 range
      // dBFS typically ranges from -160 to 0
      final normalized = (amplitude.current + 60) / 60;
      return normalized.clamp(0.0, 1.0);
    } catch (e) {
      return 0.0;
    }
  }

  /// Play an audio file (placeholder - use just_audio in state)
  static Future<void> playAudio(String path) async {
    try {
      _isPlaying = true;
      debugPrint('AudioRecorderService: Playing audio: $path');
      // Actual playback is handled by AudioService/just_audio
    } catch (e) {
      debugPrint('AudioRecorderService: Error playing audio: $e');
      _isPlaying = false;
    }
  }

  /// Stop audio playback
  static Future<void> stopPlayback() async {
    try {
      _isPlaying = false;
    } catch (e) {
      debugPrint('AudioRecorderService: Error stopping playback: $e');
    }
  }

  /// Delete a recording file
  static Future<void> deleteRecording(String path) async {
    if (kIsWeb) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        debugPrint('AudioRecorderService: Deleted recording: $path');
      }
    } catch (e) {
      debugPrint('AudioRecorderService: Error deleting recording: $e');
    }
  }

  /// Check if a recording exists
  static Future<bool> recordingExists(String path) async {
    if (kIsWeb) return false;
    try {
      final file = File(path);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get all saved recordings
  static Future<List<String>> getAllRecordings() async {
    if (kIsWeb) return [];
    try {
      final dir = await _getAffirmationsDirectory();
      final directory = Directory(dir);
      if (!await directory.exists()) return [];

      final files = await directory.list().toList();
      return files
          .where((f) => f.path.endsWith('.m4a'))
          .map((f) => f.path)
          .toList();
    } catch (e) {
      debugPrint('AudioRecorderService: Error getting recordings: $e');
      return [];
    }
  }

  /// Clean up resources
  static Future<void> dispose() async {
    if (_isRecording) {
      await _recorder.stop();
    }
    await _recorder.dispose();
    _isRecording = false;
    _isPlaying = false;
    _currentRecordingPath = null;
  }
}
