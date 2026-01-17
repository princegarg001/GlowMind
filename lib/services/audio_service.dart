import 'dart:async';
import 'dart:math';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:glowmind/models/music_models.dart';
import 'package:just_audio/just_audio.dart' hide LoopMode;
import 'package:rxdart/rxdart.dart';

/// Service for audio playback, playlist management, and sleep timer
class AudioService {
  // Singleton instance
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  
  AudioPlayer? _player; // Recreated as needed for web compatibility
  final Random _random = Random();
  bool _isInitialized = false;
  bool _isDisposed = false;
  
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _sleepTimerSubscription;
  Timer? _fadeOutTimer;

  // Track loading state to prevent duplicate loads
  String? _loadingTrackId;
  int _failedTrackCount = 0;
  static const int _maxConsecutiveFailures = 3;
  static const Duration _loadTimeout = Duration(seconds: 10);

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
  final _errorController = StreamController<String>.broadcast();

  // Getters
  Stream<Playlist?> get playlistStream => _playlistController.stream;
  Stream<Track?> get trackStream => _trackController.stream;
  Stream<bool> get isPlayingStream => _isPlayingController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration?> get durationStream => _durationController.stream;
  Stream<SleepTimer?> get sleepTimerStream => _sleepTimerController.stream;
  Stream<String> get errorStream => _errorController.stream;

  Playlist? get currentPlaylist => _currentPlaylist;
  Track? get currentTrack => _currentPlaylist?.tracks.isNotEmpty == true
      ? _currentPlaylist!.tracks[_getCurrentTrackIndex()]
      : null;
  bool get isPlaying => _player?.playing ?? false;
  Duration get position => _player?.position ?? Duration.zero;
  Duration? get duration => _player?.duration;
  bool get shuffle => _shuffle;
  LoopMode get loopMode => _loopMode;
  SleepTimer? get sleepTimer => _sleepTimer;

  // Private constructor for singleton
  AudioService._internal() {
    _initPlayer();
  }

  /// Initialize the audio player (called once)
  Future<void> _initPlayer() async {
    if (_isDisposed || _isInitialized) return;
    
    try {
      debugPrint('AudioService: Initializing player');
      
      // Configure audio session for background playback
      if (!kIsWeb) {
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
      }

      await _ensurePlayerExists();
      
      _isInitialized = true;
      debugPrint('AudioService: Player initialized successfully');
    } catch (e) {
      debugPrint('AudioService: Player init error: $e');
      _isInitialized = false;
    }
  }

  /// Ensure player exists and is subscribed
  Future<void> _ensurePlayerExists() async {
    if (_player != null) return;
    
    _player = AudioPlayer();
    
    // Listen to player state changes with error handling
    _playerStateSubscription = _player!.playerStateStream.listen(
      (state) {
        if (_isDisposed || _player == null) return;
        try {
          _isPlayingController.add(state.playing);
          
          // Handle track completion
          if (state.processingState == ProcessingState.completed) {
            _onTrackCompleted();
          }
        } catch (e) {
          debugPrint('AudioService: Player state error: $e');
        }
      },
      onError: (e) => debugPrint('AudioService: Player state stream error: $e'),
    );

    // Listen to position changes (throttled for performance) with error handling
    _positionSubscription = _player!.positionStream
        .throttleTime(const Duration(milliseconds: 200))
        .listen(
      (position) {
        if (_isDisposed || _player == null) return;
        try {
          _positionController.add(position);
        } catch (e) {
          debugPrint('AudioService: Position error: $e');
        }
      },
      onError: (e) => debugPrint('AudioService: Position stream error: $e'),
    );

    // Listen to duration changes with error handling
    _player!.durationStream.listen(
      (duration) {
        if (_isDisposed || _player == null) return;
        try {
          _durationController.add(duration);
        } catch (e) {
          debugPrint('AudioService: Duration error: $e');
        }
      },
      onError: (e) => debugPrint('AudioService: Duration stream error: $e'),
    );
  }

  /// Load and play a playlist
  Future<void> loadPlaylist(Playlist playlist, {int startIndex = 0}) async {
    try {
      debugPrint('AudioService: Loading playlist "${playlist.name}" with ${playlist.tracks.length} tracks');
      
      if (playlist.tracks.isEmpty) {
        debugPrint('AudioService: Cannot load empty playlist');
        _errorController.add('Playlist is empty');
        return;
      }

      // Ensure player is initialized
      if (!_isInitialized) {
        await _initPlayer();
      }

      // Reset failure count for new playlist
      _failedTrackCount = 0;
      
      _currentPlaylist = playlist;
      _currentTrackIndex = startIndex.clamp(0, playlist.tracks.length - 1);
      _generateShuffleOrder();

      _playlistController.add(_currentPlaylist);
      await _loadCurrentTrack();
      debugPrint('AudioService: Playlist loaded successfully');
    } catch (e) {
      debugPrint('AudioService: loadPlaylist error: $e');
      _errorController.add('Failed to load playlist');
    }
  }

  /// Load the current track into the player with timeout and retry logic
  Future<void> _loadCurrentTrack() async {
    final track = currentTrack;
    if (track == null) {
      debugPrint('AudioService: No current track to load');
      return;
    }
    
    // Prevent duplicate loading
    if (_loadingTrackId == track.id) {
      debugPrint('AudioService: Already loading track ${track.id}');
      return;
    }

    _loadingTrackId = track.id;

    try {
      debugPrint('AudioService: Loading track "${track.name}"');
      debugPrint('AudioService: Track URL: ${track.url}');
      _trackController.add(track);
      
      // On web, recreate player for each track to avoid "player already exists" error
      if (kIsWeb) {
        await _recreatePlayerForWeb();
      } else {
        // On mobile, just stop current playback
        await _player?.stop();
      }
      
      await _ensurePlayerExists();
      
      // Load audio with timeout and retry on web-specific errors
      await _loadAudioSource(track);
      
      // Reset failure count on success
      _failedTrackCount = 0;
      debugPrint('AudioService: Track loaded successfully');
    } catch (e) {
      debugPrint('AudioService: _loadCurrentTrack error: $e');
      _failedTrackCount++;
      
      // Determine error type for better user feedback
      String errorMsg = 'Unable to load track';
      if (e.toString().contains('403') || e.toString().contains('Forbidden')) {
        errorMsg = 'Track access denied. URL may be expired or restricted.';
      } else if (e.toString().contains('404')) {
        errorMsg = 'Track not found.';
      } else if (e.toString().contains('Timeout')) {
        errorMsg = 'Track loading timed out.';
      }
      
      // Skip to next track if this one fails, but prevent infinite loop
      if (_failedTrackCount < _maxConsecutiveFailures && 
          _currentPlaylist != null && 
          _currentPlaylist!.tracks.length > 1) {
        debugPrint('AudioService: Skipping failed track (${_failedTrackCount}/$_maxConsecutiveFailures failures)');
        _loadingTrackId = null; // Reset to allow loading next track
        await _skipToNextTrackSilently();
      } else {
        debugPrint('AudioService: Too many consecutive failures, stopping');
        _errorController.add('All tracks failed to load. The audio URLs may be expired or blocked. Please try different playlists.');
        _failedTrackCount = 0;
      }
    } finally {
      _loadingTrackId = null;
    }
  }

  /// Load audio source with retry logic for web platform issues
  Future<void> _loadAudioSource(Track track, {int retryCount = 0}) async {
    const maxRetries = 3;
    
    try {
      final loadFuture = track.source == 'bundled'
          ? _player!.setAsset(track.url)
          : _player!.setUrl(track.url);
          
      await loadFuture.timeout(
        _loadTimeout,
        onTimeout: () {
          throw TimeoutException('Track loading timed out after ${_loadTimeout.inSeconds}s');
        },
      );
    } catch (e) {
      // Check if this is the "player already exists" error on web
      if (kIsWeb && 
          retryCount < maxRetries && 
          e.toString().contains('already exists')) {
        debugPrint('AudioService: Player conflict detected, retrying (${retryCount + 1}/$maxRetries)...');
        
        // Force recreate player and retry with increasing delay
        await _recreatePlayerForWeb();
        await Future.delayed(Duration(milliseconds: 200 * (retryCount + 1)));
        await _ensurePlayerExists();
        
        return _loadAudioSource(track, retryCount: retryCount + 1);
      }
      rethrow;
    }
  }

  /// Recreate player for web to avoid platform player ID conflicts
  Future<void> _recreatePlayerForWeb() async {
    if (_player != null) {
      debugPrint('AudioService: Disposing player for web reload');
      
      // Cancel all subscriptions first
      await _positionSubscription?.cancel();
      await _playerStateSubscription?.cancel();
      _positionSubscription = null;
      _playerStateSubscription = null;
      
      try {
        // Stop playback before disposal
        try {
          await _player!.stop();
        } catch (e) {
          // Ignore stop errors
        }
        
        // Dispose and wait longer for web platform cleanup
        await _player!.dispose();
        _player = null;
        
        // Give web platform more time to fully clean up
        await Future.delayed(const Duration(milliseconds: 150));
      } catch (e) {
        debugPrint('AudioService: Error disposing player: $e');
        _player = null;
        // Still wait even if disposal failed
        await Future.delayed(const Duration(milliseconds: 150));
      }
    }
  }
  
  /// Skip to next track without triggering play (for error recovery)
  Future<void> _skipToNextTrackSilently() async {
    if (_currentPlaylist == null || _currentPlaylist!.tracks.isEmpty) return;
    
    final tracksCount = _currentPlaylist!.tracks.length;
    _currentTrackIndex = (_currentTrackIndex + 1) % tracksCount;
    
    // Don't loop back if we've tried all tracks
    if (_currentTrackIndex == 0) {
      debugPrint('AudioService: Tried all tracks, stopping');
      return;
    }
    
    await _loadCurrentTrack();
  }

  /// Play or resume playback
  Future<void> play() async {
    try {
      debugPrint('AudioService: Starting playback...');
      await _ensurePlayerExists();
      await _player!.play();
      debugPrint('AudioService: Playback started, isPlaying: ${_player!.playing}');
    } catch (e) {
      debugPrint('AudioService: play error: $e');
      _errorController.add('Failed to start playback');
    }
  }

  /// Pause playback
  Future<void> pause() async {
    try {
      await _player?.pause();
    } catch (e) {
      debugPrint('pause error: $e');
    }
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (isPlaying) {
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
      await _player?.seek(Duration.zero);
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
    if (position.inSeconds > 3) {
      await _player?.seek(Duration.zero);
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
      await _player?.seek(position);
    } catch (e) {
      debugPrint('seek error: $e');
    }
  }

  /// Set volume (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    try {
      await _player?.setVolume(volume.clamp(0.0, 1.0));
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
      await _player?.stop();
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
    final initialVolume = _player?.volume ?? 1.0;
    const steps = 30; // Fade in 30 steps
    // Ensure stepDuration is at least 100ms to prevent division by zero
    final stepDuration = (duration.inMilliseconds ~/ steps).clamp(100, 10000);
    var currentStep = 0;

    _fadeOutTimer?.cancel();
    _fadeOutTimer = Timer.periodic(Duration(milliseconds: stepDuration), (timer) {
      currentStep++;
      final newVolume = initialVolume * (1 - currentStep / steps);
      _player?.setVolume(newVolume.clamp(0.0, 1.0));

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
    _isDisposed = true;
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
    _errorController.close();
    _player?.dispose();
  }
}
