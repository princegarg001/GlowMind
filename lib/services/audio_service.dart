import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:glowmind/models/music_models.dart';
import 'package:rxdart/rxdart.dart';

/// Service for audio playback, playlist management, and sleep timer
class AudioService {
  final AudioPlayer _player = AudioPlayer();
  final Random _random = Random();
  
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _sleepTimerSubscription;
  Timer? _fadeOutTimer;

  // Current state
  Playlist? _currentPlaylist;
  int _currentTrackIndex = 0;
  bool _shuffle = false;
  LoopMode _loopMode = LoopMode.all;
  SleepTimer? _sleepTimer;
  List<int> _shuffleOrder = [];

  // Streams
  final _playlistController = StreamController<Playlist?>.broadcast();
  final _trackController = StreamController<Track?>.broadcast();
  final _isPlayingController = StreamController<bool>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _sleepTimerController = StreamController<SleepTimer?>.broadcast();

  // Getters
  Stream<Playlist?> get playlistStream => _playlistController.stream;
  Stream<Track?> get trackStream => _trackController.stream;
  Stream<bool> get isPlayingStream => _isPlayingController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration?> get durationStream => _durationController.stream;
  Stream<SleepTimer?> get sleepTimerStream => _sleepTimerController.stream;

  Playlist? get currentPlaylist => _currentPlaylist;
  Track? get currentTrack => _currentPlaylist?.tracks.isNotEmpty == true
      ? _currentPlaylist!.tracks[_getCurrentTrackIndex()]
      : null;
  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  bool get shuffle => _shuffle;
  LoopMode get loopMode => _loopMode;
  SleepTimer? get sleepTimer => _sleepTimer;

  AudioService() {
    _init();
  }

  Future<void> _init() async {
    try {
      // Configure audio session for background playback
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ));

      // Listen to player state changes
      _playerStateSubscription = _player.playerStateStream.listen((state) {
        _isPlayingController.add(state.playing);
        
        // Handle track completion
        if (state.processingState == ProcessingState.completed) {
          _onTrackCompleted();
        }
      });

      // Listen to position changes
      _positionSubscription = _player.positionStream.listen((position) {
        _positionController.add(position);
      });

      // Listen to duration changes
      _player.durationStream.listen((duration) {
        _durationController.add(duration);
      });
    } catch (e) {
      debugPrint('AudioService init error: $e');
    }
  }

  /// Load and play a playlist
  Future<void> loadPlaylist(Playlist playlist, {int startIndex = 0}) async {
    try {
      if (playlist.tracks.isEmpty) {
        debugPrint('Cannot load empty playlist');
        return;
      }

      _currentPlaylist = playlist;
      _currentTrackIndex = startIndex.clamp(0, playlist.tracks.length - 1);
      _generateShuffleOrder();

      _playlistController.add(_currentPlaylist);
      await _loadCurrentTrack();
    } catch (e) {
      debugPrint('loadPlaylist error: $e');
    }
  }

  /// Load the current track into the player
  Future<void> _loadCurrentTrack() async {
    final track = currentTrack;
    if (track == null) return;

    try {
      _trackController.add(track);
      
      // Load audio from URL or asset
      if (track.source == 'bundled') {
        await _player.setAsset(track.url);
      } else {
        await _player.setUrl(track.url);
      }
    } catch (e) {
      debugPrint('_loadCurrentTrack error: $e');
      // Try next track if this one fails
      await next();
    }
  }

  /// Play or resume playback
  Future<void> play() async {
    try {
      await _player.play();
    } catch (e) {
      debugPrint('play error: $e');
    }
  }

  /// Pause playback
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      debugPrint('pause error: $e');
    }
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  /// Skip to next track
  Future<void> next() async {
    if (_currentPlaylist == null || _currentPlaylist!.tracks.isEmpty) return;

    final tracksCount = _currentPlaylist!.tracks.length;
    
    if (_loopMode == LoopMode.one) {
      // Restart current track
      await _player.seek(Duration.zero);
      await play();
      return;
    }

    // Move to next track
    _currentTrackIndex = (_currentTrackIndex + 1) % tracksCount;

    // Check if we've completed the playlist
    if (_currentTrackIndex == 0 && _loopMode == LoopMode.off) {
      await stop();
      return;
    }

    await _loadCurrentTrack();
    await play();
  }

  /// Skip to previous track
  Future<void> previous() async {
    if (_currentPlaylist == null || _currentPlaylist!.tracks.isEmpty) return;

    // If more than 3 seconds into the track, restart it
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }

    final tracksCount = _currentPlaylist!.tracks.length;
    _currentTrackIndex = (_currentTrackIndex - 1) % tracksCount;
    if (_currentTrackIndex < 0) {
      _currentTrackIndex = tracksCount - 1;
    }

    await _loadCurrentTrack();
    await play();
  }

  /// Seek to a specific position
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      debugPrint('seek error: $e');
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      await _player.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('setVolume error: $e');
    }
  }

  /// Toggle shuffle mode
  void toggleShuffle() {
    _shuffle = !_shuffle;
    if (_shuffle) {
      _generateShuffleOrder();
    }
  }

  /// Set shuffle mode
  void setShuffle(bool shuffle) {
    _shuffle = shuffle;
    if (_shuffle) {
      _generateShuffleOrder();
    }
  }

  /// Cycle through loop modes
  void cycleLoopMode() {
    switch (_loopMode) {
      case LoopMode.off:
        _loopMode = LoopMode.all;
        break;
      case LoopMode.all:
        _loopMode = LoopMode.one;
        break;
      case LoopMode.one:
        _loopMode = LoopMode.off;
        break;
    }
  }

  /// Set loop mode
  void setLoopMode(LoopMode mode) {
    _loopMode = mode;
  }

  /// Stop playback
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('stop error: $e');
    }
  }

  /// Start sleep timer
  void startSleepTimer(Duration duration) {
    cancelSleepTimer();

    _sleepTimer = SleepTimer(
      duration: duration,
      startTime: DateTime.now(),
      fadeOut: true,
    );
    _sleepTimerController.add(_sleepTimer);

    // Schedule timer to fade out and stop
    final fadeStartDuration = duration - const Duration(seconds: 30);
    if (fadeStartDuration.isNegative || fadeStartDuration.inMilliseconds < 100) {
      // If duration is less than 30 seconds, start fading immediately
      _startFadeOut(duration);
    } else {
      // Start fade out 30 seconds before timer expires
      _fadeOutTimer = Timer(fadeStartDuration, () {
        _startFadeOut(const Duration(seconds: 30));
      });
    }

    // Schedule final stop
    _sleepTimerSubscription = Stream.periodic(Duration.zero).take(1).delay(duration).listen((_) async {
      await stop();
      cancelSleepTimer();
    });
  }

  /// Start fade out effect
  void _startFadeOut(Duration duration) {
    final initialVolume = _player.volume;
    final steps = 30; // Fade in 30 steps
    // Ensure stepDuration is at least 100ms to prevent division by zero
    final stepDuration = (duration.inMilliseconds ~/ steps).clamp(100, 10000);
    var currentStep = 0;

    _fadeOutTimer?.cancel();
    _fadeOutTimer = Timer.periodic(Duration(milliseconds: stepDuration), (timer) {
      currentStep++;
      final newVolume = initialVolume * (1 - currentStep / steps);
      _player.setVolume(newVolume.clamp(0.0, 1.0));

      if (currentStep >= steps) {
        timer.cancel();
        _fadeOutTimer = null;
      }
    });
  }

  /// Cancel sleep timer
  void cancelSleepTimer() {
    _sleepTimerSubscription?.cancel();
    _fadeOutTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerController.add(null);
  }

  /// Handle track completion
  void _onTrackCompleted() {
    next();
  }

  /// Generate shuffle order
  void _generateShuffleOrder() {
    if (_currentPlaylist == null) return;
    
    final count = _currentPlaylist!.tracks.length;
    _shuffleOrder = List.generate(count, (i) => i);
    
    if (_shuffle) {
      _shuffleOrder.shuffle(_random);
    }
  }

  /// Get current track index considering shuffle
  int _getCurrentTrackIndex() {
    if (_shuffle && _shuffleOrder.isNotEmpty) {
      return _shuffleOrder[_currentTrackIndex % _shuffleOrder.length];
    }
    return _currentTrackIndex;
  }

  /// Dispose resources
  void dispose() {
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _sleepTimerSubscription?.cancel();
    _fadeOutTimer?.cancel();
    _playlistController.close();
    _trackController.close();
    _isPlayingController.close();
    _positionController.close();
    _durationController.close();
    _sleepTimerController.close();
    _player.dispose();
  }
}
