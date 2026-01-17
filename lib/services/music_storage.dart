import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glowmind/models/music_models.dart';
import 'package:glowmind/supabase/supabase_config.dart';

/// Service for persisting music state locally and syncing with Supabase
class MusicStorage {
  static const String _keyLastMood = 'music_last_mood';
  static const String _keyLastTrackId = 'music_last_track_id';
  static const String _keyVolume = 'music_volume';
  static const String _keyAutoPlay = 'music_auto_play';
  static const String _keyShuffle = 'music_shuffle';
  static const String _keyLoopMode = 'music_loop_mode';

  /// Load user music preferences from local storage
  Future<UserMusicPreferences?> loadLocalPreferences(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final lastMoodStr = prefs.getString(_keyLastMood);
      final lastMood = lastMoodStr != null
          ? MoodType.values.firstWhere(
              (m) => m.name == lastMoodStr,
              orElse: () => MoodType.sleep,
            )
          : null;

      final loopModeStr = prefs.getString(_keyLoopMode) ?? 'all';
      final loopMode = LoopMode.values.firstWhere(
        (m) => m.name == loopModeStr,
        orElse: () => LoopMode.all,
      );

      return UserMusicPreferences(
        userId: userId,
        lastMood: lastMood,
        lastTrackId: prefs.getString(_keyLastTrackId),
        volume: prefs.getDouble(_keyVolume) ?? 0.7,
        autoPlay: prefs.getBool(_keyAutoPlay) ?? true,
        shuffle: prefs.getBool(_keyShuffle) ?? false,
        loopMode: loopMode,
      );
    } catch (e) {
      debugPrint('loadLocalPreferences error: $e');
      return null;
    }
  }

  /// Save user music preferences to local storage
  Future<void> saveLocalPreferences(UserMusicPreferences prefs) async {
    try {
      final storage = await SharedPreferences.getInstance();
      
      if (prefs.lastMood != null) {
        await storage.setString(_keyLastMood, prefs.lastMood!.name);
      }
      
      if (prefs.lastTrackId != null) {
        await storage.setString(_keyLastTrackId, prefs.lastTrackId!);
      }
      
      await storage.setDouble(_keyVolume, prefs.volume);
      await storage.setBool(_keyAutoPlay, prefs.autoPlay);
      await storage.setBool(_keyShuffle, prefs.shuffle);
      await storage.setString(_keyLoopMode, prefs.loopMode.name);
    } catch (e) {
      debugPrint('saveLocalPreferences error: $e');
    }
  }

  /// Load user music preferences from Supabase
  Future<UserMusicPreferences?> loadSupabasePreferences(String userId) async {
    try {
      final data = await SupabaseService.selectSingle(
        'user_music_prefs',
        filters: {'user_id': userId},
      );

      if (data == null) return null;
      return UserMusicPreferences.fromJson(data);
    } catch (e) {
      debugPrint('loadSupabasePreferences error: $e');
      return null;
    }
  }

  /// Save user music preferences to Supabase
  Future<void> saveSupabasePreferences(UserMusicPreferences prefs) async {
    try {
      // Check if preferences exist
      final existing = await SupabaseService.selectSingle(
        'user_music_prefs',
        filters: {'user_id': prefs.userId},
      );

      if (existing == null) {
        // Insert new preferences
        await SupabaseService.insert('user_music_prefs', prefs.toJson());
      } else {
        // Update existing preferences
        await SupabaseService.update(
          'user_music_prefs',
          prefs.toJson(),
          filters: {'user_id': prefs.userId},
        );
      }
    } catch (e) {
      debugPrint('saveSupabasePreferences error: $e');
    }
  }

  /// Load playlists for a specific mood from Supabase (with local fallback)
  Future<List<Playlist>> loadPlaylists(String userId, MoodType mood) async {
    try {
      debugPrint('MusicStorage: Loading playlists for mood: ${mood.name}');
      
      final data = await SupabaseService.select(
        'playlists',
        filters: {'user_id': userId, 'mood': mood.name},
        orderBy: 'created_at',
        ascending: false,
      );

      if (data.isEmpty) {
        debugPrint('MusicStorage: No playlists in Supabase, using local default');
        return _getLocalDefaultPlaylist(userId, mood);
      }

      final playlists = <Playlist>[];
      for (final item in data) {
        final playlist = Playlist.fromJson(item);
        if (playlist != null) {
          // Load tracks for this playlist
          final tracks = await loadPlaylistTracks(playlist.id);
          playlists.add(playlist.copyWith(tracks: tracks));
        }
      }

      if (playlists.isEmpty || playlists.every((p) => p.tracks.isEmpty)) {
        debugPrint('MusicStorage: Empty playlists from Supabase, using local default');
        return _getLocalDefaultPlaylist(userId, mood);
      }

      debugPrint('MusicStorage: Loaded ${playlists.length} playlists from Supabase');
      return playlists;
    } catch (e) {
      debugPrint('MusicStorage: loadPlaylists error: $e - falling back to local');
      return _getLocalDefaultPlaylist(userId, mood);
    }
  }

  /// Get local default playlist for a mood (fallback when Supabase unavailable)
  List<Playlist> _getLocalDefaultPlaylist(String userId, MoodType mood) {
    final playlist = Playlist(
      id: '${userId}_${mood.name}_local',
      userId: userId,
      mood: mood,
      name: '${mood.displayName} Sounds',
      isDefault: true,
      tracks: _getDefaultTracks(mood),
      createdAt: DateTime.now(),
    );
    debugPrint('MusicStorage: Created local playlist with ${playlist.tracks.length} tracks');
    return [playlist];
  }

  /// Load tracks for a specific playlist from Supabase
  Future<List<Track>> loadPlaylistTracks(String playlistId) async {
    try {
      final data = await SupabaseService.select(
        'playlist_tracks',
        filters: {'playlist_id': playlistId},
        orderBy: 'order_index',
        ascending: true,
      );

      return data.map((item) {
        return Track(
          id: item['id'] as String,
          name: item['track_name'] as String,
          url: item['track_url'] as String,
          source: item['source'] as String? ?? 'bundled',
          freesoundId: item['freesound_id'] as int?,
          durationSeconds: item['duration_seconds'] as int?,
          attribution: item['attribution'] as String?,
        );
      }).toList();
    } catch (e) {
      debugPrint('loadPlaylistTracks error: $e');
      return [];
    }
  }

  /// Save a playlist to Supabase
  Future<Playlist?> savePlaylist(Playlist playlist) async {
    try {
      // Check if playlist exists
      final existing = await SupabaseService.selectSingle(
        'playlists',
        filters: {'id': playlist.id},
      );

      List<Map<String, dynamic>> result;
      if (existing == null) {
        // Insert new playlist
        result = await SupabaseService.insert('playlists', playlist.toJson());
      } else {
        // Update existing playlist
        result = await SupabaseService.update(
          'playlists',
          playlist.toJson(),
          filters: {'id': playlist.id},
        );
      }

      if (result.isNotEmpty) {
        // Save tracks
        await savePlaylistTracks(playlist.id, playlist.tracks);
        
        final savedPlaylist = Playlist.fromJson(result.first);
        return savedPlaylist?.copyWith(tracks: playlist.tracks);
      }

      return null;
    } catch (e) {
      debugPrint('savePlaylist error: $e');
      return null;
    }
  }

  /// Save tracks for a playlist to Supabase
  Future<void> savePlaylistTracks(String playlistId, List<Track> tracks) async {
    try {
      // Delete existing tracks
      await SupabaseService.delete(
        'playlist_tracks',
        filters: {'playlist_id': playlistId},
      );

      // Insert new tracks
      if (tracks.isEmpty) return;

      final tracksData = tracks.asMap().entries.map((entry) {
        final index = entry.key;
        final track = entry.value;
        return {
          'playlist_id': playlistId,
          'track_name': track.name,
          'track_url': track.url,
          'source': track.source,
          'freesound_id': track.freesoundId,
          'duration_seconds': track.durationSeconds,
          'attribution': track.attribution,
          'order_index': index,
        };
      }).toList();

      await SupabaseService.insertMultiple('playlist_tracks', tracksData);
    } catch (e) {
      debugPrint('savePlaylistTracks error: $e');
    }
  }

  /// Delete a playlist from Supabase
  Future<void> deletePlaylist(String playlistId) async {
    try {
      await SupabaseService.delete(
        'playlists',
        filters: {'id': playlistId},
      );
      // Tracks will be cascade deleted
    } catch (e) {
      debugPrint('deletePlaylist error: $e');
    }
  }

  /// Create default playlists for a user
  Future<void> createDefaultPlaylists(String userId) async {
    try {
      for (final mood in MoodType.values) {
        final playlist = Playlist(
          id: '${userId}_${mood.name}_default',
          userId: userId,
          mood: mood,
          name: '${mood.displayName} Playlist',
          isDefault: true,
          tracks: _getDefaultTracks(mood),
          createdAt: DateTime.now(),
        );

        await savePlaylist(playlist);
      }
    } catch (e) {
      debugPrint('createDefaultPlaylists error: $e');
    }
  }

  /// Get default tracks for a mood
  List<Track> _getDefaultTracks(MoodType mood) {
    switch (mood) {
      case MoodType.sleep:
        return [
          Track(
            id: 'sleep_1',
            name: 'Rain on Leaves',
            url: 'https://freesound.org/data/previews/346/346700_5121236-lq.mp3',
            source: 'url',
          ),
          Track(
            id: 'sleep_2',
            name: 'Soft Piano Lullaby',
            url: 'https://freesound.org/data/previews/527/527948_11567680-lq.mp3',
            source: 'url',
          ),
          Track(
            id: 'sleep_3',
            name: 'Ocean Waves',
            url: 'https://freesound.org/data/previews/345/345852_5121236-lq.mp3',
            source: 'url',
          ),
        ];
      case MoodType.study:
        return [
          Track(
            id: 'study_1',
            name: 'Lo-fi Study Beat',
            url: 'https://freesound.org/data/previews/513/513413_10393537-lq.mp3',
            source: 'url',
          ),
          Track(
            id: 'study_2',
            name: 'Focus Ambient',
            url: 'https://freesound.org/data/previews/198/198175_1015240-lq.mp3',
            source: 'url',
          ),
          Track(
            id: 'study_3',
            name: 'Coffee Shop Ambience',
            url: 'https://freesound.org/data/previews/536/536108_6988053-lq.mp3',
            source: 'url',
          ),
        ];
      case MoodType.party:
        return [
          Track(
            id: 'party_1',
            name: 'Upbeat Electronic',
            url: 'https://freesound.org/data/previews/442/442943_5121236-lq.mp3',
            source: 'url',
          ),
          Track(
            id: 'party_2',
            name: 'Party Vibes',
            url: 'https://freesound.org/data/previews/491/491495_10393537-lq.mp3',
            source: 'url',
          ),
          Track(
            id: 'party_3',
            name: 'Energetic Dance',
            url: 'https://freesound.org/data/previews/527/527410_10393537-lq.mp3',
            source: 'url',
          ),
        ];
      case MoodType.meditate:
        return [
          Track(
            id: 'meditate_1',
            name: 'Tibetan Bowls',
            url: 'https://freesound.org/data/previews/586/586252_1015240-lq.mp3',
            source: 'url',
          ),
          Track(
            id: 'meditate_2',
            name: 'Forest Meditation',
            url: 'https://freesound.org/data/previews/217/217506_2394245-lq.mp3',
            source: 'url',
          ),
          Track(
            id: 'meditate_3',
            name: 'Zen Garden',
            url: 'https://freesound.org/data/previews/237/237223_1015240-lq.mp3',
            source: 'url',
          ),
        ];
      case MoodType.deepFocus:
        return [
          Track(
            id: 'focus_1',
            name: 'Binaural Focus',
            url: 'https://freesound.org/data/previews/198/198175_1015240-lq.mp3',
            source: 'url',
          ),
          Track(
            id: 'focus_2',
            name: 'Deep Concentration',
            url: 'https://freesound.org/data/previews/133/133901_2394245-lq.mp3',
            source: 'url',
          ),
          Track(
            id: 'focus_3',
            name: 'White Noise',
            url: 'https://freesound.org/data/previews/160/160045_2394245-lq.mp3',
            source: 'url',
          ),
        ];
      case MoodType.nature:
        return [
          Track(
            id: 'nature_1',
            name: 'Forest Ambience',
            url: 'https://freesound.org/data/previews/217/217506_2394245-lq.mp3',
            source: 'url',
          ),
          Track(
            id: 'nature_2',
            name: 'Ocean Shore',
            url: 'https://freesound.org/data/previews/48/48412_22510-lq.mp3',
            source: 'url',
          ),
          Track(
            id: 'nature_3',
            name: 'Morning Birds',
            url: 'https://freesound.org/data/previews/135/135125_2394245-lq.mp3',
            source: 'url',
          ),
        ];
    }
  }
}
