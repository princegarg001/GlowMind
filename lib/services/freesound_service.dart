import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glowmind/models/freesound_models.dart';
import 'package:glowmind/models/music_models.dart';

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
      final response = await _supabase.functions.invoke(
        'freesound-api',
        body: {
          'action': 'search',
          'mood': mood.name,
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
      final response = await searchByMood(mood, pageSize: trackCount);
      
      final tracks = response.results
          .where((sound) => sound.bestPreviewUrl != null)
          .map((sound) => soundToTrack(sound))
          .toList();

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
