import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Service for recording and playing voice affirmations
/// Uses a simple audio recording approach without external dependencies
class AudioRecorderService {
  static bool _isRecording = false;
  static bool _isPlaying = false;
  static String? _currentRecordingPath;

  static bool get isRecording => _isRecording;
  static bool get isPlaying => _isPlaying;

  /// Get the directory for storing affirmation recordings
  static Future<String> _getAffirmationsDirectory() async {
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

  /// Simulate starting a recording (placeholder for actual implementation)
  /// In production, use the 'record' package
  static Future<String?> startRecording(String affirmationId) async {
    try {
      _currentRecordingPath = await getRecordingPath(affirmationId);
      _isRecording = true;
      debugPrint('Started recording to: $_currentRecordingPath');
      return _currentRecordingPath;
    } catch (e) {
      debugPrint('Error starting recording: $e');
      return null;
    }
  }

  /// Simulate stopping a recording
  static Future<String?> stopRecording() async {
    try {
      final path = _currentRecordingPath;
      _isRecording = false;
      _currentRecordingPath = null;
      debugPrint('Stopped recording');
      return path;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Cancel the current recording
  static Future<void> cancelRecording() async {
    try {
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      _isRecording = false;
      _currentRecordingPath = null;
    } catch (e) {
      debugPrint('Error canceling recording: $e');
      _isRecording = false;
    }
  }

  /// Play an audio file (placeholder)
  static Future<void> playAudio(String path) async {
    try {
      _isPlaying = true;
      debugPrint('Playing audio: $path');
      // In production, use audioplayers package
      await Future.delayed(const Duration(seconds: 2));
      _isPlaying = false;
    } catch (e) {
      debugPrint('Error playing audio: $e');
      _isPlaying = false;
    }
  }

  /// Stop audio playback
  static Future<void> stopPlayback() async {
    try {
      _isPlaying = false;
    } catch (e) {
      debugPrint('Error stopping playback: $e');
    }
  }

  /// Delete a recording file
  static Future<void> deleteRecording(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting recording: $e');
    }
  }

  /// Check if a recording exists
  static Future<bool> recordingExists(String path) async {
    try {
      final file = File(path);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get all saved recordings
  static Future<List<String>> getAllRecordings() async {
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
      debugPrint('Error getting recordings: $e');
      return [];
    }
  }

  /// Clean up resources
  static void dispose() {
    _isRecording = false;
    _isPlaying = false;
    _currentRecordingPath = null;
  }
}
