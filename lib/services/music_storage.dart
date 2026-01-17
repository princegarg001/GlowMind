import 'package:flutter/foundation.dart';
import 'package:glowmind/models/music_models.dart';
import 'package:glowmind/supabase/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// Load playlists for a specific mood from Supabase (with fallback chain)
  /// Priority: 1. User playlists → 2. Global defaults → 3. Local hardcoded
  Future<List<Playlist>> loadPlaylists(String userId, MoodType mood) async {
    try {
      debugPrint('MusicStorage: Loading playlists for mood: ${mood.name}');
      
      // 1. Try to load user's playlists
      List<Map<String, dynamic>> data = [];
      try {
        data = await SupabaseService.select(
          'playlists',
          filters: {'user_id': userId, 'mood': mood.name},
          orderBy: 'created_at',
          ascending: false,
        );
      } catch (e) {
        debugPrint('MusicStorage: User playlists query failed: $e');
      }

      // 2. If no user playlists, try global defaults
      if (data.isEmpty) {
        debugPrint('MusicStorage: No user playlists, trying global defaults');
        try {
          data = await SupabaseService.select(
            'playlists',
            filters: {'user_id': 'global', 'mood': mood.name},
            orderBy: 'created_at',
            ascending: false,
          );
        } catch (e) {
          debugPrint('MusicStorage: Global playlists query failed: $e');
        }
      }

      // 3. Parse and load tracks for found playlists
      if (data.isNotEmpty) {
        final playlists = <Playlist>[];
        for (final item in data) {
          final playlist = Playlist.fromJson(item);
          if (playlist != null) {
            final tracks = await loadPlaylistTracks(playlist.id);
            if (tracks.isNotEmpty) {
              playlists.add(playlist.copyWith(tracks: tracks));
            }
          }
        }
        
        if (playlists.isNotEmpty) {
          debugPrint('MusicStorage: Loaded ${playlists.length} playlists from Supabase');
          return playlists;
        }
      }

      // 4. Fall back to local defaults
      debugPrint('MusicStorage: Using local default playlist');
      return _getLocalDefaultPlaylist(userId, mood);
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

  /// Get default tracks for a mood (using CORS-friendly Pixabay URLs)
  List<Track> _getDefaultTracks(MoodType mood) {
    switch (mood) {
      case MoodType.sleep:
        return [
          const Track(
            id: 'sleep_1',
            name: 'Peaceful Rain',
            url: 'https://cdn.pixabay.com/audio/2022/05/27/audio_1808fbf07a.mp3',
            source: 'url',
          ),
          const Track(
            id: 'sleep_2',
            name: 'Soft Piano Dreams',
            url: 'https://cdn.pixabay.com/audio/2022/02/23/audio_ea70ad08e3.mp3',
            source: 'url',
          ),
          const Track(
            id: 'sleep_3',
            name: 'Ocean Lullaby',
            url: 'https://cdn.pixabay.com/audio/2022/06/07/audio_b9bd4170e4.mp3',
            source: 'url',
          ),
        ];
      case MoodType.study:
        return [
          const Track(
            id: 'study_1',
            name: 'Lo-fi Study Beat',
            url: 'https://cdn.pixabay.com/audio/2022/10/25/audio_946b0939c5.mp3',
            source: 'url',
          ),
          const Track(
            id: 'study_2',
            name: 'Focus Ambient',
            url: 'https://cdn.pixabay.com/audio/2022/03/15/audio_8cb749d484.mp3',
            source: 'url',
          ),
          const Track(
            id: 'study_3',
            name: 'Calm Concentration',
            url: 'https://cdn.pixabay.com/audio/2023/07/30/audio_e5e5d61a5e.mp3',
            source: 'url',
          ),
        ];
      case MoodType.party:
        return [
          const Track(
            id: 'party_1',
            name: 'Upbeat Electronic',
            url: 'https://cdn.pixabay.com/audio/2022/03/10/audio_d89c289308.mp3',
            source: 'url',
          ),
          const Track(
            id: 'party_2',
            name: 'Dance Energy',
            url: 'https://cdn.pixabay.com/audio/2022/11/22/audio_3676e5c8e9.mp3',
            source: 'url',
          ),
          const Track(
            id: 'party_3',
            name: 'EDM Vibes',
            url: 'https://cdn.pixabay.com/audio/2023/09/04/audio_de5f4a2c92.mp3',
            source: 'url',
          ),
        ];
      case MoodType.meditate:
        return [
          const Track(
            id: 'meditate_1',
            name: 'Tibetan Bowls',
            url: 'https://cdn.pixabay.com/audio/2022/02/07/audio_3c1e8b9e15.mp3',
            source: 'url',
          ),
          const Track(
            id: 'meditate_2',
            name: 'Zen Garden',
            url: 'https://cdn.pixabay.com/audio/2022/01/26/audio_d1718ab41b.mp3',
            source: 'url',
          ),
          const Track(
            id: 'meditate_3',
            name: 'Deep Breathing',
            url: 'https://cdn.pixabay.com/audio/2022/03/12/audio_b4f3c4519e.mp3',
            source: 'url',
          ),
        ];
      case MoodType.deepFocus:
        return [
          const Track(
            id: 'focus_1',
            name: 'Binaural Focus',
            url: 'https://cdn.pixabay.com/audio/2022/08/23/audio_3b8e68f90d.mp3',
            source: 'url',
          ),
          const Track(
            id: 'focus_2',
            name: 'Concentration Mode',
            url: 'https://cdn.pixabay.com/audio/2022/05/17/audio_407815a5b6.mp3',
            source: 'url',
          ),
          const Track(
            id: 'focus_3',
            name: 'Ambient Flow',
            url: 'https://cdn.pixabay.com/audio/2022/03/24/audio_7a0ba7a7aa.mp3',
            source: 'url',
          ),
        ];
      case MoodType.nature:
        return [
          const Track(
            id: 'nature_1',
            name: 'Forest Ambience',
            url: 'https://cdn.pixabay.com/audio/2022/08/04/audio_2dde668d05.mp3',
            source: 'url',
          ),
          const Track(
            id: 'nature_2',
            name: 'Birds Chirping',
            url: 'https://cdn.pixabay.com/audio/2021/09/06/audio_0917bff64a.mp3',
            source: 'url',
          ),
          const Track(
            id: 'nature_3',
            name: 'Waterfall Stream',
            url: 'https://cdn.pixabay.com/audio/2022/02/17/audio_cc63d1d5ad.mp3',
            source: 'url',
          ),
        ];
    }
  }
}
