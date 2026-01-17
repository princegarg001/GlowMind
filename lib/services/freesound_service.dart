import 'package:flutter/foundation.dart';
import 'package:glowmind/models/freesound_models.dart';
import 'package:glowmind/models/music_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for interacting with Freesound API via Supabase Edge Function
class FreesoundService {
  static final FreesoundService _instance = FreesoundService._internal();
  factory FreesoundService() => _instance;
  FreesoundService._internal();

  SupabaseClient get _supabase => Supabase.instance.client;

  /// Test the Freesound API connection
  Future<bool> testConnection() async {
    try {
      debugPrint('FreesoundService: Testing API connection...');
      final response = await _supabase.functions.invoke(
        'freesound-api',
        body: {
          'action': 'search',
          'query': 'ambient',
          'pageSize': 1,
        },
      );
      
      debugPrint('FreesoundService: Response status: ${response.status}');
      debugPrint('FreesoundService: Response data: ${response.data}');
      
      if (response.status == 200) {
        debugPrint('FreesoundService: API connection successful!');
        return true;
      } else {
        debugPrint('FreesoundService: API returned status ${response.status}');
        return false;
      }
    } catch (e) {
      debugPrint('FreesoundService: Connection test failed: $e');
      return false;
    }
  }

  /// Search sounds by mood
  Future<FreesoundSearchResponse> searchByMood(
    MoodType mood, {
    int page = 1,
    int pageSize = 15,
  }) async {
    try {
      debugPrint('FreesoundService: Searching for mood: ${mood.name}, page: $page, pageSize: $pageSize');
      
      final response = await _supabase.functions.invoke(
        'freesound-api',
        body: {
          'action': 'search',
          'mood': mood.name,
          'page': page,
          'pageSize': pageSize,
        },
      );

      debugPrint('FreesoundService: Response status: ${response.status}');
      debugPrint('FreesoundService: Response data: ${response.data}');

      if (response.status != 200) {
        final error = response.data['error'] ?? 'Unknown error';
        debugPrint('FreesoundService: API error: $error');
        throw Exception('Failed to search sounds: $error');
      }

      final searchResponse = FreesoundSearchResponse.fromJson(response.data);
      debugPrint('FreesoundService: Found ${searchResponse.results.length} sounds');
      return searchResponse;
    } catch (e) {
      debugPrint('FreesoundService.searchByMood error: $e');
      rethrow;
    }
  }

  /// Search sounds with custom query
  Future<FreesoundSearchResponse> searchCustom(
    String query, {
    int page = 1,
    int pageSize = 15,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'freesound-api',
        body: {
          'action': 'search',
          'query': query,
          'page': page,
          'pageSize': pageSize,
        },
      );

      if (response.status != 200) {
        final error = response.data['error'] ?? 'Unknown error';
        throw Exception('Failed to search sounds: $error');
      }

      return FreesoundSearchResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('FreesoundService.searchCustom error: $e');
      rethrow;
    }
  }

  /// Get sound details by ID
  Future<FreesoundSoundDetail> getSoundDetails(int soundId) async {
    try {
      final response = await _supabase.functions.invoke(
        'freesound-api',
        body: {
          'action': 'getSoundDetails',
          'soundId': soundId,
        },
      );

      if (response.status != 200) {
        final error = response.data['error'] ?? 'Unknown error';
        throw Exception('Failed to get sound details: $error');
      }

      return FreesoundSoundDetail.fromJson(response.data);
    } catch (e) {
      debugPrint('FreesoundService.getSoundDetails error: $e');
      rethrow;
    }
  }

  /// Get download/stream URL for a sound
  Future<FreesoundDownloadInfo> getDownloadUrl(int soundId) async {
    try {
      final response = await _supabase.functions.invoke(
        'freesound-api',
        body: {
          'action': 'getDownloadUrl',
          'soundId': soundId,
        },
      );

      if (response.status != 200) {
        final error = response.data['error'] ?? 'Unknown error';
        throw Exception('Failed to get download URL: $error');
      }

      return FreesoundDownloadInfo.fromJson(response.data);
    } catch (e) {
      debugPrint('FreesoundService.getDownloadUrl error: $e');
      rethrow;
    }
  }

  /// Get similar sounds
  Future<List<FreesoundSound>> getSimilarSounds(
    int soundId, {
    int pageSize = 10,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'freesound-api',
        body: {
          'action': 'getSimilarSounds',
          'soundId': soundId,
          'pageSize': pageSize,
        },
      );

      if (response.status != 200) {
        final error = response.data['error'] ?? 'Unknown error';
        throw Exception('Failed to get similar sounds: $error');
      }

      final results = response.data['results'] as List<dynamic>;
      return results
          .map((e) => FreesoundSound.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('FreesoundService.getSimilarSounds error: $e');
      rethrow;
    }
  }

  /// Convert a Freesound sound to a Track for AudioService
  Track soundToTrack(FreesoundSound sound) {
    return Track(
      id: 'freesound_${sound.id}',
      name: sound.name,
      url: sound.bestPreviewUrl ?? '',
      source: 'freesound',
      freesoundId: sound.id,
      durationSeconds: sound.duration.toInt(),
      attribution: sound.attribution,
    );
  }

  /// Create a playlist from Freesound sounds
  Future<Playlist> createMoodPlaylist(
    MoodType mood,
    String userId, {
    int trackCount = 10,
  }) async {
    try {
      // First try mood-based search
      var response = await searchByMood(mood, pageSize: trackCount);
      
      // If mood search returns nothing, try generic search
      if (response.results.isEmpty) {
        debugPrint('FreesoundService: Mood search returned 0 results, trying generic search');
        response = await searchCustom('ambient music relaxing', pageSize: trackCount);
      }
      
      // If still empty, try another generic query
      if (response.results.isEmpty) {
        debugPrint('FreesoundService: Generic search failed, trying broader search');
        response = await searchCustom('music', pageSize: trackCount);
      }
      
      final tracks = response.results
          .where((sound) => sound.bestPreviewUrl != null)
          .map((sound) => soundToTrack(sound))
          .toList();

      if (tracks.isEmpty) {
        throw Exception('No playable sounds found. Please try again later.');
      }

      return Playlist(
        id: 'freesound_${mood.name}_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        mood: mood,
        name: '${mood.displayName} Sounds',
        tracks: tracks,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('FreesoundService.createMoodPlaylist error: $e');
      rethrow;
    }
  }

  /// Create a random/surprise playlist without mood dependency
  Future<Playlist> createRandomPlaylist(
    String userId, {
    int trackCount = 10,
  }) async {
    // Random search queries for variety
    final queries = [
      'ambient music relaxing',
      'electronic chill',
      'acoustic guitar peaceful',
      'piano calm',
      'nature sounds ambient',
      'lo-fi beats',
      'meditation peaceful',
      'soft instrumental',
    ];
    
    final randomQuery = queries[DateTime.now().millisecondsSinceEpoch % queries.length];
    
    try {
      debugPrint('FreesoundService: Creating random playlist with query: $randomQuery');
      final response = await searchCustom(randomQuery, pageSize: trackCount);
      
      if (response.results.isEmpty) {
        // Fallback to a very generic query
        final fallbackResponse = await searchCustom('music', pageSize: trackCount);
        if (fallbackResponse.results.isEmpty) {
          throw Exception('No sounds available. Please try again later.');
        }
        
        final tracks = fallbackResponse.results
            .where((sound) => sound.bestPreviewUrl != null)
            .map((sound) => soundToTrack(sound))
            .toList();
        
        return Playlist(
          id: 'freesound_random_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          mood: MoodType.study, // Default mood
          name: 'Surprise Mix',
          tracks: tracks,
          createdAt: DateTime.now(),
        );
      }
      
      final tracks = response.results
          .where((sound) => sound.bestPreviewUrl != null)
          .map((sound) => soundToTrack(sound))
          .toList();

      return Playlist(
        id: 'freesound_random_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        mood: MoodType.study, // Default mood
        name: 'Surprise Mix',
        tracks: tracks,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('FreesoundService.createRandomPlaylist error: $e');
      rethrow;
    }
  }

  /// Search and get a quick playlist for immediate playback
  Future<List<Track>> getQuickPlaylist(
    MoodType mood, {
    int count = 5,
  }) async {
    try {
      final response = await searchByMood(mood, pageSize: count);
      
      return response.results
          .where((sound) => sound.bestPreviewUrl != null)
          .map((sound) => soundToTrack(sound))
          .toList();
    } catch (e) {
      debugPrint('FreesoundService.getQuickPlaylist error: $e');
      return [];
    }
  }
}
