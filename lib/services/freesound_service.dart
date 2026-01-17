import 'package:flutter/foundation.dart';
import 'package:glowmind/supabase/supabase_config.dart';

/// Represents a FreeSound track with preview URL
class FreeSoundTrack {
  final String id;
  final String name;
  final String previewUrl;
  final int duration;
  final String description;
  final List<String> tags;

  const FreeSoundTrack({
    required this.id,
    required this.name,
    required this.previewUrl,
    required this.duration,
    required this.description,
    required this.tags,
  });

  factory FreeSoundTrack.fromJson(Map<String, dynamic> json) {
    return FreeSoundTrack(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Unknown',
      previewUrl: json['previews']?['preview-hq-mp3'] as String? ?? 
                  json['previews']?['preview-lq-mp3'] as String? ?? '',
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      description: json['description'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

/// Service to interact with FreeSound API through Supabase edge function
class FreeSoundService {
  static FreeSoundService? _instance;
  final Map<String, FreeSoundTrack> _cache = {};

  FreeSoundService._();

  /// Get singleton instance
  static FreeSoundService get instance {
    _instance ??= FreeSoundService._();
    return _instance!;
  }

  /// Get sound details and preview URL by ID
  Future<FreeSoundTrack?> getSound(String soundId) async {
    // Check cache first
    if (_cache.containsKey(soundId)) {
      debugPrint('FreeSoundService: Returning cached sound $soundId');
      return _cache[soundId];
    }

    try {
      debugPrint('FreeSoundService: Fetching sound $soundId from Supabase edge function');
      
      final response = await SupabaseConfig.client.functions.invoke(
        'freesound-proxy',
        body: {
          'action': 'get_sound',
          'sound_id': soundId,
        },
      );

      if (response.status == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final track = FreeSoundTrack.fromJson(data);
        
        // Cache the result
        _cache[soundId] = track;
        debugPrint('FreeSoundService: Successfully fetched sound $soundId');
        
        return track;
      } else {
        debugPrint('FreeSoundService: Failed to fetch sound $soundId - Status: ${response.status}');
        return null;
      }
    } catch (e) {
      debugPrint('FreeSoundService: Error fetching sound $soundId - $e');
      return null;
    }
  }

  /// Search for sounds (optional feature)
  Future<List<FreeSoundTrack>> searchSounds(String query) async {
    try {
      debugPrint('FreeSoundService: Searching for: $query');
      
      final response = await SupabaseConfig.client.functions.invoke(
        'freesound-proxy',
        body: {
          'action': 'search_sounds',
          'query': query,
        },
      );

      if (response.status == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];
        
        return results
            .map((item) => FreeSoundTrack.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        debugPrint('FreeSoundService: Search failed - Status: ${response.status}');
        return [];
      }
    } catch (e) {
      debugPrint('FreeSoundService: Error searching sounds - $e');
      return [];
    }
  }

  /// Clear cache (useful for testing or memory management)
  void clearCache() {
    _cache.clear();
    debugPrint('FreeSoundService: Cache cleared');
  }

  /// Get cache size
  int get cacheSize => _cache.length;
}
