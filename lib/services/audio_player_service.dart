import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

/// Playback mode for the audio player
enum PlaybackMode {
  single,      // Play once and stop
  loopOne,     // Loop current track
  loopAll,     // Loop entire playlist
  shuffle,     // Shuffle playlist
}

/// Current playback state
enum PlayerState {
  stopped,
  playing,
  paused,
  loading,
}

/// Service to manage audio playback
class AudioPlayerService {
  static AudioPlayerService? _instance;
  final AudioPlayer _player = AudioPlayer();
  
  PlayerState _state = PlayerState.stopped;
  PlaybackMode _mode = PlaybackMode.single;
  List<String> _playlist = [];
  int _currentIndex = 0;
  String? _currentTrackUrl;
  String? _currentTrackName;
  
  final StreamController<PlayerState> _stateController = StreamController<PlayerState>.broadcast();
  final StreamController<int> _indexController = StreamController<int>.broadcast();
  final StreamController<Duration> _positionController = StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();

  AudioPlayerService._() {
    _initializePlayer();
  }

  /// Get singleton instance
  static AudioPlayerService get instance {
    _instance ??= AudioPlayerService._();
    return _instance!;
  }

  void _initializePlayer() {
    // Listen to player state changes
    _player.onPlayerStateChanged.listen((state) {
      switch (state) {
        case audioplayers.PlayerState.playing:
          _updateState(PlayerState.playing);
          break;
        case audioplayers.PlayerState.paused:
          _updateState(PlayerState.paused);
          break;
        case audioplayers.PlayerState.stopped:
          _updateState(PlayerState.stopped);
          break;
        case audioplayers.PlayerState.completed:
          _onTrackCompleted();
          break;
        default:
          break;
      }
    });

    // Listen to position updates
    _player.onPositionChanged.listen((position) {
      _positionController.add(position);
    });

    // Listen to duration updates
    _player.onDurationChanged.listen((duration) {
      _durationController.add(duration);
    });
  }

  /// Play a single track
  Future<void> playTrack(String url, String name) async {
    try {
      _updateState(PlayerState.loading);
      _currentTrackUrl = url;
      _currentTrackName = name;
      
      debugPrint('AudioPlayerService: Playing track: $name');
      await _player.play(UrlSource(url));
    } catch (e) {
      debugPrint('AudioPlayerService: Error playing track - $e');
      _updateState(PlayerState.stopped);
    }
  }

  /// Play from a playlist
  Future<void> playFromPlaylist(List<String> urls, List<String> names, int startIndex) async {
    if (urls.isEmpty || startIndex >= urls.length) return;
    
    _playlist = urls;
    _currentIndex = startIndex;
    await playTrack(urls[startIndex], names[startIndex]);
  }

  /// Pause playback
  Future<void> pause() async {
    await _player.pause();
  }

  /// Resume playback
  Future<void> resume() async {
    await _player.resume();
  }

  /// Stop playback
  Future<void> stop() async {
    await _player.stop();
    _currentTrackUrl = null;
    _currentTrackName = null;
    _updateState(PlayerState.stopped);
  }

  /// Play next track in playlist
  Future<void> playNext() async {
    if (_playlist.isEmpty) return;
    
    if (_mode == PlaybackMode.shuffle) {
      _currentIndex = DateTime.now().millisecondsSinceEpoch % _playlist.length;
    } else {
      _currentIndex = (_currentIndex + 1) % _playlist.length;
    }
    
    _indexController.add(_currentIndex);
    await playTrack(_playlist[_currentIndex], 'Track ${_currentIndex + 1}');
  }

  /// Play previous track in playlist
  Future<void> playPrevious() async {
    if (_playlist.isEmpty) return;
    
    _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    _indexController.add(_currentIndex);
    await playTrack(_playlist[_currentIndex], 'Track ${_currentIndex + 1}');
  }

  /// Set playback mode
  void setPlaybackMode(PlaybackMode mode) {
    _mode = mode;
    debugPrint('AudioPlayerService: Playback mode set to ${mode.name}');
  }

  /// Handle track completion
  void _onTrackCompleted() {
    debugPrint('AudioPlayerService: Track completed');
    
    switch (_mode) {
      case PlaybackMode.single:
        stop();
        break;
      case PlaybackMode.loopOne:
        if (_currentTrackUrl != null && _currentTrackName != null) {
          playTrack(_currentTrackUrl!, _currentTrackName!);
        }
        break;
      case PlaybackMode.loopAll:
      case PlaybackMode.shuffle:
        playNext();
        break;
    }
  }

  /// Update state and notify listeners
  void _updateState(PlayerState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
    }
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  // Getters
  PlayerState get state => _state;
  PlaybackMode get mode => _mode;
  String? get currentTrackName => _currentTrackName;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _state == PlayerState.playing;
  bool get isPaused => _state == PlayerState.paused;
  bool get isStopped => _state == PlayerState.stopped;
  bool get isLoading => _state == PlayerState.loading;

  // Streams
  Stream<PlayerState> get stateStream => _stateController.stream;
  Stream<int> get indexStream => _indexController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration> get durationStream => _durationController.stream;

  /// Dispose resources
  void dispose() {
    _player.dispose();
    _stateController.close();
    _indexController.close();
    _positionController.close();
    _durationController.close();
  }
}
