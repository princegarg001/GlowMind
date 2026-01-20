import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart' as just_audio;

import '../models/affirmation.dart';
import '../services/affirmation_service.dart';
import '../services/audio_recorder_service.dart';
import '../services/notification_service.dart';
import '../services/web_audio_player_web.dart'
    if (dart.library.io) '../services/web_audio_player.dart';

/// State management for affirmations
class AffirmationState extends ChangeNotifier {
  final AffirmationService service;
  final AudioRecorderService audioRecorder;

  AffirmationState({
    required this.service,
    required this.audioRecorder,
  });

  // Audio player for playback
  final just_audio.AudioPlayer _audioPlayer = just_audio.AudioPlayer();

  List<Affirmation> _affirmations = [];
  List<Affirmation> _favorites = [];
  List<Affirmation> _voiceAffirmations = [];
  AffirmationSettings _settings = const AffirmationSettings();
  Affirmation? _dailyAffirmation;
  bool _isLoading = false;
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentPlayingPath;
  String? _currentRecordingPath;
  String? _error;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  bool _notificationsEnabled = false;

  // Getters
  List<Affirmation> get affirmations => _affirmations;
  List<Affirmation> get favorites => _favorites;
  List<Affirmation> get voiceAffirmations => _voiceAffirmations;
  AffirmationSettings get settings => _settings;
  Affirmation? get dailyAffirmation => _dailyAffirmation;
  bool get isLoading => _isLoading;
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String? get currentPlayingPath => _currentPlayingPath;
  Duration get recordingDuration => _recordingDuration;
  String? get error => _error;
  bool get notificationsEnabled => _notificationsEnabled;

  /// Initialize the affirmation state
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _loadAll();
      await _loadDailyAffirmation();

      // Initialize notifications
      await _initializeNotifications();
    } catch (e) {
      _error = 'Failed to load affirmations: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Initialize notification service and schedule notifications
  Future<void> _initializeNotifications() async {
    try {
      await NotificationService.instance.initialize();
      _notificationsEnabled =
          await NotificationService.instance.areNotificationsEnabled();

      // Schedule notifications based on current settings
      if (_notificationsEnabled &&
          (_settings.morningEnabled || _settings.eveningEnabled)) {
        await NotificationService.instance
            .scheduleAffirmationNotifications(_settings);
        debugPrint('Affirmation notifications scheduled');
      }
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
    }
  }

  /// Request notification permissions
  Future<bool> requestNotificationPermissions() async {
    final granted = await NotificationService.instance.requestPermissions();
    _notificationsEnabled = granted;
    notifyListeners();

    if (granted) {
      await _scheduleNotifications();
    }

    return granted;
  }

  /// Schedule notifications with current settings
  Future<void> _scheduleNotifications() async {
    if (_settings.morningEnabled || _settings.eveningEnabled) {
      await NotificationService.instance
          .scheduleAffirmationNotifications(_settings);
    }
  }

  /// Send a test notification
  Future<void> sendTestNotification({bool isMorning = true}) async {
    await NotificationService.instance
        .showTestNotification(isMorning: isMorning);
  }

  Future<void> _loadAll() async {
    _affirmations = await AffirmationService.loadAffirmations();
    _favorites = _affirmations.where((a) => a.isFavorite).toList();
    _voiceAffirmations = _affirmations
        .where((a) => a.type == AffirmationType.userRecorded)
        .toList();
    _settings = await AffirmationService.loadSettings();
  }

  Future<void> _loadDailyAffirmation() async {
    _dailyAffirmation = await AffirmationService.getDailyAffirmation();
  }

  /// Generate a new personalized affirmation
  Future<Affirmation> generateNewAffirmation({
    required Map<String, int> moodCounts,
    String? currentMood,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final affirmation =
          await AffirmationService.generatePersonalizedAffirmation(
        moodCounts: moodCounts,
        currentMood: currentMood,
      );

      await AffirmationService.saveAffirmation(affirmation);
      await AffirmationService.saveDailyAffirmation(affirmation);

      _affirmations.insert(0, affirmation);
      _dailyAffirmation = affirmation;

      return affirmation;
    } catch (e) {
      _error = 'Failed to generate affirmation: $e';
      debugPrint(_error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Generate affirmation for a specific category
  Future<Affirmation> generateForCategory(AffirmationCategory category) async {
    _isLoading = true;
    notifyListeners();

    try {
      final affirmation =
          AffirmationService.getAffirmationForCategory(category);
      await AffirmationService.saveAffirmation(affirmation);
      _affirmations.insert(0, affirmation);

      return affirmation;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(Affirmation affirmation) async {
    final updated = affirmation.copyWith(isFavorite: !affirmation.isFavorite);
    await AffirmationService.updateAffirmation(updated);

    final index = _affirmations.indexWhere((a) => a.id == affirmation.id);
    if (index != -1) {
      _affirmations[index] = updated;
    }

    _favorites = _affirmations.where((a) => a.isFavorite).toList();

    if (_dailyAffirmation?.id == affirmation.id) {
      _dailyAffirmation = updated;
    }

    notifyListeners();
  }

  /// Delete an affirmation
  Future<void> deleteAffirmation(Affirmation affirmation) async {
    await AffirmationService.deleteAffirmation(affirmation.id);

    if (affirmation.audioPath != null) {
      await AudioRecorderService.deleteRecording(affirmation.audioPath!);
    }

    _affirmations.removeWhere((a) => a.id == affirmation.id);
    _favorites.removeWhere((a) => a.id == affirmation.id);
    _voiceAffirmations.removeWhere((a) => a.id == affirmation.id);

    notifyListeners();
  }

  // Voice Recording Methods

  /// Start recording a new voice affirmation
  Future<void> startRecording() async {
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentRecordingPath = await AudioRecorderService.startRecording(tempId);
    _isRecording = _currentRecordingPath != null;
    _recordingDuration = Duration.zero;

    // Start timer for recording duration
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _recordingDuration += const Duration(seconds: 1);
      notifyListeners();
    });

    notifyListeners();
  }

  /// Stop recording and save the voice affirmation
  Future<Affirmation?> stopRecordingAndSave({
    required String text,
    required AffirmationCategory category,
  }) async {
    _recordingTimer?.cancel();
    final path = await AudioRecorderService.stopRecording();
    _isRecording = false;

    if (path != null) {
      final affirmation = Affirmation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        type: AffirmationType.userRecorded,
        category: category,
        audioPath: path,
        createdAt: DateTime.now(),
      );

      await AffirmationService.saveAffirmation(affirmation);
      _affirmations.insert(0, affirmation);
      _voiceAffirmations.insert(0, affirmation);

      notifyListeners();
      return affirmation;
    }

    notifyListeners();
    return null;
  }

  /// Add a custom text affirmation (no recording)
  Future<void> addCustomAffirmation({
    required String text,
    required AffirmationCategory category,
  }) async {
    final affirmation = Affirmation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      type: AffirmationType.custom,
      category: category,
      createdAt: DateTime.now(),
    );

    await AffirmationService.saveAffirmation(affirmation);
    _affirmations.insert(0, affirmation);
    notifyListeners();
  }

  /// Cancel the current recording
  Future<void> cancelRecording() async {
    await AudioRecorderService.cancelRecording();
    _isRecording = false;
    _currentRecordingPath = null;
    notifyListeners();
  }

  /// Play a voice affirmation
  Future<void> playAffirmation(String path) async {
    debugPrint('AffirmationState: playAffirmation called with path: $path');
    try {
      // Stop any currently playing audio
      if (_isPlaying) {
        await stopPlayback();
      }

      _currentPlayingPath = path;
      _isPlaying = true;
      notifyListeners();

      // Use HTML5 Audio for web blob URLs (just_audio has issues with blob URLs)
      if (kIsWeb && path.startsWith('blob:')) {
        debugPrint('AffirmationState: Using WebAudioPlayer for blob URL');
        await WebAudioPlayer.play(path, onComplete: () {
          debugPrint('AffirmationState: WebAudioPlayer playback completed');
          _isPlaying = false;
          _currentPlayingPath = null;
          notifyListeners();
        });
        debugPrint('AffirmationState: WebAudioPlayer started');
        return;
      }

      // Ensure volume is set
      await _audioPlayer.setVolume(1.0);

      // Handle both file paths and http URLs
      if (path.startsWith('http')) {
        debugPrint('AffirmationState: Using setUrl for: $path');
        await _audioPlayer.setUrl(path);
      } else {
        debugPrint('AffirmationState: Using setFilePath for: $path');
        await _audioPlayer.setFilePath(path);
      }

      // Get duration to verify audio loaded correctly
      final duration = _audioPlayer.duration;
      debugPrint('AffirmationState: Audio duration: $duration');

      debugPrint('AffirmationState: Audio source set, starting playback...');
      await _audioPlayer.play();
      debugPrint(
          'AffirmationState: Playback started, volume: ${_audioPlayer.volume}');

      // Listen for completion
      _audioPlayer.playerStateStream.listen((state) {
        debugPrint('AffirmationState: Player state: ${state.processingState}');
        if (state.processingState == just_audio.ProcessingState.completed) {
          _isPlaying = false;
          _currentPlayingPath = null;
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('AffirmationState: Error playing audio: $e');
      _isPlaying = false;
      _currentPlayingPath = null;
      notifyListeners();
    }
  }

  /// Stop audio playback
  Future<void> stopPlayback() async {
    try {
      // Stop WebAudioPlayer if on web
      if (kIsWeb) {
        await WebAudioPlayer.stop();
      }
      await _audioPlayer.stop();
      _isPlaying = false;
      _currentPlayingPath = null;
      notifyListeners();
    } catch (e) {
      debugPrint('AffirmationState: Error stopping playback: $e');
    }
  }

  /// Toggle play/pause for a voice affirmation
  Future<void> togglePlayback(String path) async {
    if (_isPlaying && _currentPlayingPath == path) {
      await stopPlayback();
    } else {
      await playAffirmation(path);
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    _recordingTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Settings Methods

  /// Update affirmation settings with optional named parameters
  Future<void> updateSettings({
    bool? morningNotifications,
    bool? eveningNotifications,
    TimeOfDay? morningTime,
    TimeOfDay? eveningTime,
    List<AffirmationCategory>? preferredCategories,
  }) async {
    _settings = _settings.copyWith(
      morningEnabled: morningNotifications,
      eveningEnabled: eveningNotifications,
      morningTime: morningTime,
      eveningTime: eveningTime,
      preferredCategories: preferredCategories,
    );
    await AffirmationService.saveSettings(_settings);

    // Reschedule notifications with new settings
    await _scheduleNotifications();

    notifyListeners();
  }

  /// Toggle morning notification
  Future<void> toggleMorningNotification(bool enabled) async {
    await updateSettings(morningNotifications: enabled);
  }

  /// Toggle evening notification
  Future<void> toggleEveningNotification(bool enabled) async {
    await updateSettings(eveningNotifications: enabled);
  }

  /// Update morning notification time
  Future<void> setMorningTime(TimeOfDay time) async {
    await updateSettings(morningTime: time);
  }

  /// Update evening notification time
  Future<void> setEveningTime(TimeOfDay time) async {
    await updateSettings(eveningTime: time);
  }

  /// Toggle voice affirmations preference
  Future<void> toggleVoiceAffirmations(bool enabled) async {
    _settings = _settings.copyWith(useVoiceAffirmations: enabled);
    await AffirmationService.saveSettings(_settings);
    notifyListeners();
  }

  /// Clear all affirmation data
  Future<void> clearAllData() async {
    await AffirmationService.clearAllAffirmations();
    await NotificationService.instance.cancelAllNotifications();
    _affirmations = [];
    _favorites = [];
    _voiceAffirmations = [];
    _dailyAffirmation = null;
    notifyListeners();
  }

  /// Refresh affirmations from storage
  Future<void> refresh() async {
    await _loadAll();
    await _loadDailyAffirmation();
    notifyListeners();
  }
}
