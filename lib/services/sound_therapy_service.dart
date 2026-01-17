import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:glowmind/models/models.dart';
import 'package:glowmind/models/music_models.dart';
import 'package:glowmind/services/freesound_service.dart';

/// Service for loading and managing curated sound therapy playlists
class SoundTherapyService {
  static final SoundTherapyService _instance = SoundTherapyService._internal();
  factory SoundTherapyService() => _instance;
  SoundTherapyService._internal();

  final FreesoundService _freesoundService = FreesoundService();
  
  // Cache for loaded playlists
  Map<GlowMood, Playlist>? _cachedPlaylists;
  Map<String, dynamic>? _curatedData;

  /// Load curated sound playlist data from JSON asset
  Future<Map<String, dynamic>> _loadCuratedData() async {
    if (_curatedData != null) return _curatedData!;
    
    try {
      final jsonString = await rootBundle.loadString('assets/curated_sound_playlists.json');
      _curatedData = json.decode(jsonString) as Map<String, dynamic>;
      debugPrint('SoundTherapyService: Curated data loaded successfully');
      return _curatedData!;
    } catch (e) {
      debugPrint('SoundTherapyService: Failed to load curated data: $e');
      rethrow;
    }
  }

  /// Get playlist for a specific GlowMood
  Future<Playlist?> getPlaylistForMood(GlowMood mood, String userId) async {
    try {
      debugPrint('SoundTherapyService: Getting playlist for mood: ${mood.name}');
      
      // Check cache first
      if (_cachedPlaylists != null && _cachedPlaylists!.containsKey(mood)) {
        debugPrint('SoundTherapyService: Returning cached playlist');
        return _cachedPlaylists![mood];
      }

      // Load curated data
      final data = await _loadCuratedData();
      final playlists = data['playlists'] as Map<String, dynamic>;
      final moodData = playlists[mood.name] as Map<String, dynamic>?;

      if (moodData == null) {
        debugPrint('SoundTherapyService: No playlist found for mood: ${mood.name}');
        return null;
      }

      // Convert tracks from JSON to Track objects
      final tracks = <Track>[];
      final tracksJson = moodData['tracks'] as List<dynamic>;
      
      debugPrint('SoundTherapyService: Loading ${tracksJson.length} tracks...');

      for (final trackJson in tracksJson) {
        final trackData = trackJson as Map<String, dynamic>;
        final soundId = trackData['id'] as int;
        
        try {
          // Get the preview URL from FreeSound API via edge function
          final downloadInfo = await _freesoundService.getDownloadUrl(soundId);
          
          if (downloadInfo.bestStreamUrl != null) {
            final track = Track(
              id: 'freesound_$soundId',
              name: trackData['name'] as String,
              url: downloadInfo.bestStreamUrl!,
              source: 'freesound',
              freesoundId: soundId,
              durationSeconds: (trackData['duration'] as num?)?.toInt(),
              attribution: 'Sound "${trackData['name']}" from FreeSound.org',
            );
            tracks.add(track);
            debugPrint('SoundTherapyService: Loaded track: ${track.name}');
          }
        } catch (e) {
          debugPrint('SoundTherapyService: Failed to load sound $soundId: $e');
          // Continue with next track
        }
      }

      if (tracks.isEmpty) {
        debugPrint('SoundTherapyService: No tracks could be loaded');
        return null;
      }

      // Create playlist
      final playlist = Playlist(
        id: 'sound_therapy_${mood.name}_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        mood: _mapGlowMoodToMusicMood(mood),
        name: moodData['name'] as String,
        tracks: tracks,
        createdAt: DateTime.now(),
        isDefault: true,
      );

      // Cache the playlist
      _cachedPlaylists ??= {};
      _cachedPlaylists![mood] = playlist;

      debugPrint('SoundTherapyService: Playlist created with ${tracks.length} tracks');
      return playlist;

    } catch (e) {
      debugPrint('SoundTherapyService: getPlaylistForMood error: $e');
      return null;
    }
  }

  /// Get all available sound therapy playlists
  Future<Map<GlowMood, Playlist>> getAllPlaylists(String userId) async {
    final playlists = <GlowMood, Playlist>{};
    
    for (final mood in GlowMood.values) {
      final playlist = await getPlaylistForMood(mood, userId);
      if (playlist != null) {
        playlists[mood] = playlist;
      }
    }
    
    return playlists;
  }

  /// Map GlowMood to MoodType for audio service compatibility
  MoodType _mapGlowMoodToMusicMood(GlowMood mood) {
    switch (mood) {
      case GlowMood.balanced:
        return MoodType.meditate;
      case GlowMood.anxious:
        return MoodType.sleep;
      case GlowMood.burnoutRisk:
        return MoodType.sleep;
    }
  }

  /// Get quick preview tracks (first 3) for a mood without full loading
  Future<List<Track>> getQuickPreview(GlowMood mood) async {
    try {
      final data = await _loadCuratedData();
      final playlists = data['playlists'] as Map<String, dynamic>;
      final moodData = playlists[mood.name] as Map<String, dynamic>?;

      if (moodData == null) return [];

      final tracksJson = moodData['tracks'] as List<dynamic>;
      final previewTracks = tracksJson.take(3).toList();
      
      final tracks = <Track>[];
      for (final trackJson in previewTracks) {
        final trackData = trackJson as Map<String, dynamic>;
        tracks.add(Track(
          id: 'preview_${trackData['id']}',
          name: trackData['name'] as String,
          url: '', // Will be loaded on demand
          source: 'freesound',
          freesoundId: trackData['id'] as int,
          durationSeconds: (trackData['duration'] as num?)?.toInt(),
        ));
      }
      
      return tracks;
    } catch (e) {
      debugPrint('SoundTherapyService: getQuickPreview error: $e');
      return [];
    }
  }

  /// Clear cached playlists (useful for refreshing)
  void clearCache() {
    _cachedPlaylists = null;
    debugPrint('SoundTherapyService: Cache cleared');
  }

  /// Test if FreeSound API is accessible
  Future<bool> testConnection() async {
    try {
      return await _freesoundService.testConnection();
    } catch (e) {
      debugPrint('SoundTherapyService: Connection test failed: $e');
      return false;
    }
  }
}
