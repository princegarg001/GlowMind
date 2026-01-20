import 'package:flutter/foundation.dart';
import 'package:glowmind/models/music_models.dart';
import 'package:glowmind/services/freesound_service.dart';
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
          debugPrint(
              'MusicStorage: Loaded ${playlists.length} playlists from Supabase');
          return playlists;
        }
      }

      // 4. Try Freesound API
      debugPrint('MusicStorage: Trying Freesound API for mood: ${mood.name}');
      try {
        final freesoundPlaylist = await _loadFromFreesound(userId, mood);
        if (freesoundPlaylist != null && freesoundPlaylist.tracks.isNotEmpty) {
          debugPrint(
              'MusicStorage: Loaded ${freesoundPlaylist.tracks.length} tracks from Freesound');
          return [freesoundPlaylist];
        }
      } catch (e) {
        debugPrint('MusicStorage: Freesound API failed: $e');
      }

      // 5. Fall back to hardcoded URLs (last resort)
      debugPrint('MusicStorage: Using hardcoded fallback playlist');
      return _getLocalDefaultPlaylist(userId, mood);
    } catch (e) {
      debugPrint(
          'MusicStorage: loadPlaylists error: $e - falling back to local');
      return _getLocalDefaultPlaylist(userId, mood);
    }
  }

  /// Load playlist from Freesound API
  Future<Playlist?> _loadFromFreesound(String userId, MoodType mood) async {
    try {
      final freesoundService = FreesoundService();
      final searchResponse =
          await freesoundService.searchByMood(mood, pageSize: 10);

      if (searchResponse.results.isNotEmpty) {
        final tracks = searchResponse.results
            .where((sound) => sound.bestPreviewUrl != null)
            .map((sound) {
          return Track(
            id: 'freesound_${sound.id}',
            name: sound.name,
            url: sound.bestPreviewUrl!,
            source: 'freesound',
            freesoundId: sound.id,
            durationSeconds: sound.duration.toInt(),
            attribution: sound.attribution,
          );
        }).toList();

        if (tracks.isNotEmpty) {
          return Playlist(
            id: '${userId}_${mood.name}_freesound',
            userId: userId,
            mood: mood,
            name: '${mood.displayName} Mix',
            isDefault: true,
            tracks: tracks,
            createdAt: DateTime.now(),
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('MusicStorage: _loadFromFreesound error: $e');
      return null;
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
    debugPrint(
        'MusicStorage: Created local playlist with ${playlist.tracks.length} tracks');
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

  /// Get default tracks for a mood (using CORS-friendly URLs)
  /// These are reliable streaming URLs that work for audio playback
  List<Track> _getDefaultTracks(MoodType mood) {
    switch (mood) {
      case MoodType.sleep:
        return [
          const Track(
            id: 'sleep_1',
            name: 'Relaxing Piano',
            url:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
            source: 'url',
          ),
          const Track(
            id: 'sleep_2',
            name: 'Peaceful Dreams',
            url:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
            source: 'url',
          ),
          const Track(
            id: 'sleep_3',
            name: 'Night Ambience',
            url:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
            source: 'url',
          ),
          const Track(
            id: 'sleep_4',
            name: 'Soft Lullaby',
            url:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
            source: 'url',
          ),
          const Track(
            id: 'sleep_5',
            name: 'Calm Night',
            url:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
            source: 'url',
          ),
        ];
      case MoodType.study:
        return [
          const Track(
            id: 'study_1',
            name: 'Focus Beat',
            url:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
            source: 'url',
          ),
          const Track(
            id: 'study_2',
            name: 'Study Session',
            url:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
            source: 'url',
          ),
          const Track(
            id: 'study_3',
            name: 'Concentration',
            url:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
            source: 'url',
          ),
          const Track(
            id: 'study_4',
            name: 'Deep Work',
            url:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3',
            source: 'url',
          ),
          const Track(
            id: 'study_5',
            name: 'Brain Power',
            url:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3',
            source: 'url',
          ),
        ];
      case MoodType.party:
        return [
          const Track(
            id: 'party_1',
            name: 'Dance Beat',
            url:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-11.mp3',
            source: 'url',
          ),
          const Track(
            id: 'party_2',
            name: 'Energy Boost',
            url:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-12.mp3',
            source: 'url',
          ),
          const Track(
            id: 'party_3',
            name: 'Club Vibes',
            url:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-13.mp3',
            source: 'url',
          ),
          const Track(
            id: 'party_4',
            name: 'Get Moving',
            url:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-14.mp3',
            source: 'url',
          ),
          const Track(
            id: 'party_5',
            name: 'Fun Times',
            url:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-15.mp3',
            source: 'url',
          ),
        ];
      case MoodType.meditate:
        return [
          const Track(
            id: 'meditate_1',
            name: 'Inner Peace',
            url:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-16.mp3',
            source: 'url',
          ),
          const Track(
            id: 'meditate_2',
            name: 'Zen Flow',
            url:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
            source: 'url',
          ),
          const Track(
            id: 'meditate_3',
            name: 'Mindfulness',
            url:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
            source: 'url',
          ),
          const Track(
            id: 'meditate_4',
            name: 'Tranquility',
            url:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
            source: 'url',
          ),
          const Track(
            id: 'meditate_5',
            name: 'Calm Mind',
            url:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
            source: 'url',
          ),
        ];
      case MoodType.deepFocus:
        return [
          const Track(
            id: 'focus_1',
            name: 'Flow State',
            url:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
            source: 'url',
          ),
          const Track(
            id: 'focus_2',
            name: 'Productivity',
            url:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
            source: 'url',
          ),
          const Track(
            id: 'focus_3',
            name: 'Deep Think',
            url:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
            source: 'url',
          ),
          const Track(
            id: 'focus_4',
            name: 'Zone In',
            url:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
            source: 'url',
          ),
          const Track(
            id: 'focus_5',
            name: 'Mental Clarity',
            url:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3',
            source: 'url',
          ),
        ];
      case MoodType.nature:
        return [
          const Track(
            id: 'nature_1',
            name: 'Forest Walk',
            url:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3',
            source: 'url',
          ),
          const Track(
            id: 'nature_2',
            name: 'River Flow',
            url:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-11.mp3',
            source: 'url',
          ),
          const Track(
            id: 'nature_3',
            name: 'Bird Songs',
            url:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-12.mp3',
            source: 'url',
          ),
          const Track(
            id: 'nature_4',
            name: 'Ocean Breeze',
            url:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-13.mp3',
            source: 'url',
          ),
          const Track(
            id: 'nature_5',
            name: 'Mountain Air',
            url:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-14.mp3',
            source: 'url',
          ),
        ];
    }
  }
}
