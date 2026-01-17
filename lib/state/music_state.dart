import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:glowmind/models/music_models.dart';
import 'package:glowmind/services/audio_service.dart';
import 'package:glowmind/services/music_storage.dart';

/// State management for music playback and mood navigation
class MusicState extends ChangeNotifier {
  final AudioService _audioService;
  final MusicStorage _storage;

  // Current state
  MoodType _currentMood = MoodType.sleep;
  Playlist? _currentPlaylist;
  Track? _currentTrack;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration? _duration;
  double _volume = 0.7;
  bool _shuffle = false;
  LoopMode _loopMode = LoopMode.all;
  SleepTimer? _sleepTimer;
  UserMusicPreferences? _preferences;
  bool _isLoading = false;
  String? _userId;

  // Playlists cache
  final Map<MoodType, List<Playlist>> _playlistsCache = {};

  // Stream subscriptions
  StreamSubscription? _playlistSub;
  StreamSubscription? _trackSub;
  StreamSubscription? _isPlayingSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _sleepTimerSub;

  // Getters
  MoodType get currentMood => _currentMood;
  Playlist? get currentPlaylist => _currentPlaylist;
  Track? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration? get duration => _duration;
  double get volume => _volume;
  bool get shuffle => _shuffle;
  LoopMode get loopMode => _loopMode;
  SleepTimer? get sleepTimer => _sleepTimer;
  bool get isLoading => _isLoading;
  UserMusicPreferences? get preferences => _preferences;

  MusicState({
    required AudioService audioService,
    required MusicStorage storage,
  })  : _audioService = audioService,
        _storage = storage {
    _init();
  }

  void _init() {
    // Subscribe to audio service streams
    _playlistSub = _audioService.playlistStream.listen((playlist) {
      _currentPlaylist = playlist;
      notifyListeners();
    });

    _trackSub = _audioService.trackStream.listen((track) {
      _currentTrack = track;
      notifyListeners();
    });

    _isPlayingSub = _audioService.isPlayingStream.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
    });

    _positionSub = _audioService.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _durationSub = _audioService.durationStream.listen((dur) {
      _duration = dur;
      notifyListeners();
    });

    _sleepTimerSub = _audioService.sleepTimerStream.listen((timer) {
      _sleepTimer = timer;
      notifyListeners();
    });
  }

  /// Initialize music state for a user
  Future<void> initForUser(String userId) async {
    try {
      debugPrint('MusicState: Initializing for user: $userId');
      _isLoading = true;
      _userId = userId;
      notifyListeners();

      // Load preferences from local storage first
      _preferences = await _storage.loadLocalPreferences(userId);
      debugPrint('MusicState: Local preferences loaded: ${_preferences != null}');
      
      // Try to load from Supabase (but don't fail if unavailable)
      try {
        final supabasePrefs = await _storage.loadSupabasePreferences(userId);
        if (supabasePrefs != null) {
          _preferences = supabasePrefs;
          await _storage.saveLocalPreferences(supabasePrefs);
          debugPrint('MusicState: Supabase preferences loaded');
        }
      } catch (e) {
        debugPrint('MusicState: Supabase preferences not available: $e');
      }
      
      // Create default preferences if none exist (with autoPlay enabled)
      if (_preferences == null) {
        _preferences = UserMusicPreferences(
          userId: userId,
          autoPlay: true, // Enable auto-play by default
          volume: 0.7,
        );
        await _storage.saveLocalPreferences(_preferences!);
        debugPrint('MusicState: Created default preferences with autoPlay=true');
      }

      // Apply preferences
      _volume = _preferences!.volume;
      _shuffle = _preferences!.shuffle;
      _loopMode = _preferences!.loopMode;
      await _audioService.setVolume(_volume);
      _audioService.setShuffle(_shuffle);
      _audioService.setLoopMode(_loopMode);
      debugPrint('MusicState: Applied preferences - volume: $_volume, autoPlay: ${_preferences!.autoPlay}');

      // Load last mood or default to sleep
      final targetMood = _preferences!.lastMood ?? MoodType.sleep;
      debugPrint('MusicState: Loading mood: ${targetMood.name}');
      await changeMood(targetMood, forceAutoPlay: true);
      
    } catch (e) {
      debugPrint('MusicState: initForUser error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if default playlists exist for user
  Future<bool> _checkDefaultPlaylists(String userId) async {
    try {
      final playlists = await _storage.loadPlaylists(userId, MoodType.sleep);
      return playlists.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Change current mood
  Future<void> changeMood(MoodType mood, {bool forceAutoPlay = false}) async {
    try {
      debugPrint('MusicState: Changing mood to ${mood.name}, forceAutoPlay: $forceAutoPlay');
      _currentMood = mood;
      notifyListeners();

      // Save last mood to preferences
      if (_userId != null && _preferences != null) {
        _preferences = _preferences!.copyWith(lastMood: mood);
        await _storage.saveLocalPreferences(_preferences!);
        // Async save to Supabase (don't await, may fail if tables don't exist)
        try {
          _storage.saveSupabasePreferences(_preferences!);
        } catch (e) {
          debugPrint('MusicState: Could not save to Supabase: $e');
        }
      }

      // Load playlists for this mood
      await _loadMoodPlaylists(mood);
      debugPrint('MusicState: Playlists loaded: ${_playlistsCache[mood]?.length ?? 0}');

      // Load default or last played playlist
      if (_playlistsCache[mood]?.isNotEmpty == true) {
        final defaultPlaylist = _playlistsCache[mood]!
            .firstWhere((p) => p.isDefault, orElse: () => _playlistsCache[mood]!.first);
        
        debugPrint('MusicState: Loading playlist "${defaultPlaylist.name}" with ${defaultPlaylist.tracks.length} tracks');
        
        if (defaultPlaylist.tracks.isEmpty) {
          debugPrint('MusicState: Warning - playlist has no tracks!');
          return;
        }

        await _audioService.loadPlaylist(defaultPlaylist);
        
        // Auto-play if enabled or forced (for initial login)
        final shouldAutoPlay = forceAutoPlay || (_preferences?.autoPlay == true);
        debugPrint('MusicState: Should auto-play: $shouldAutoPlay');
        
        if (shouldAutoPlay) {
          debugPrint('MusicState: Starting playback...');
          await _audioService.play();
        }
      } else {
        debugPrint('MusicState: No playlists available for mood ${mood.name}');
      }
    } catch (e) {
      debugPrint('MusicState: changeMood error: $e');
    }
  }

  /// Load playlists for a specific mood
  Future<void> _loadMoodPlaylists(MoodType mood) async {
    if (_userId == null) return;
    
    try {
      if (!_playlistsCache.containsKey(mood)) {
        final playlists = await _storage.loadPlaylists(_userId!, mood);
        _playlistsCache[mood] = playlists;
      }
    } catch (e) {
      debugPrint('_loadMoodPlaylists error: $e');
    }
  }

  /// Get playlists for current mood
  List<Playlist> getCurrentMoodPlaylists() {
    return _playlistsCache[_currentMood] ?? [];
  }

  /// Play a specific playlist
  Future<void> playPlaylist(Playlist playlist) async {
    try {
      await _audioService.loadPlaylist(playlist);
      await _audioService.play();
    } catch (e) {
      debugPrint('playPlaylist error: $e');
    }
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    await _audioService.togglePlayPause();
  }

  /// Skip to next track
  Future<void> next() async {
    await _audioService.next();
  }

  /// Skip to previous track
  Future<void> previous() async {
    await _audioService.previous();
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    await _audioService.seek(position);
  }

  /// Set volume
  Future<void> setVolume(double volume) async {
    _volume = volume;
    await _audioService.setVolume(volume);
    
    // Save to preferences (fire and forget)
    if (_userId != null && _preferences != null) {
      _preferences = _preferences!.copyWith(volume: volume);
      await _storage.saveLocalPreferences(_preferences!);
      // Async save to Supabase (don't await, use unawaited pattern)
      unawaited(_storage.saveSupabasePreferences(_preferences!));
    }
    
    notifyListeners();
  }

  /// Toggle shuffle
  void toggleShuffle() {
    _shuffle = !_shuffle;
    _audioService.setShuffle(_shuffle);
    
    // Save to preferences (fire and forget)
    if (_userId != null && _preferences != null) {
      _preferences = _preferences!.copyWith(shuffle: _shuffle);
      _storage.saveLocalPreferences(_preferences!);
      // Async save to Supabase (don't await, use unawaited pattern)
      unawaited(_storage.saveSupabasePreferences(_preferences!));
    }
    
    notifyListeners();
  }

  /// Cycle loop mode
  void cycleLoopMode() {
    _audioService.cycleLoopMode();
    _loopMode = _audioService.loopMode;
    
    // Save to preferences (fire and forget)
    if (_userId != null && _preferences != null) {
      _preferences = _preferences!.copyWith(loopMode: _loopMode);
      _storage.saveLocalPreferences(_preferences!);
      // Async save to Supabase (don't await, use unawaited pattern)
      unawaited(_storage.saveSupabasePreferences(_preferences!));
    }
    
    notifyListeners();
  }

  /// Start sleep timer
  void startSleepTimer(Duration duration) {
    _audioService.startSleepTimer(duration);
  }

  /// Cancel sleep timer
  void cancelSleepTimer() {
    _audioService.cancelSleepTimer();
  }

  /// Add a playlist
  Future<void> addPlaylist(Playlist playlist) async {
    try {
      final saved = await _storage.savePlaylist(playlist);
      if (saved != null) {
        _playlistsCache[playlist.mood] = [
          ..._playlistsCache[playlist.mood] ?? [],
          saved,
        ];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('addPlaylist error: $e');
    }
  }

  /// Update a playlist
  Future<void> updatePlaylist(Playlist playlist) async {
    try {
      final saved = await _storage.savePlaylist(playlist);
      if (saved != null) {
        final playlists = _playlistsCache[playlist.mood] ?? [];
        final index = playlists.indexWhere((p) => p.id == playlist.id);
        if (index >= 0) {
          playlists[index] = saved;
          _playlistsCache[playlist.mood] = playlists;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('updatePlaylist error: $e');
    }
  }

  /// Delete a playlist
  Future<void> deletePlaylist(String playlistId) async {
    try {
      await _storage.deletePlaylist(playlistId);
      
      // Remove from cache
      for (final mood in _playlistsCache.keys) {
        _playlistsCache[mood] = _playlistsCache[mood]!
            .where((p) => p.id != playlistId)
            .toList();
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('deletePlaylist error: $e');
    }
  }

  @override
  void dispose() {
    _playlistSub?.cancel();
    _trackSub?.cancel();
    _isPlayingSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _sleepTimerSub?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}
