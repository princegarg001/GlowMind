import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:glowmind/models/models.dart';

/// Represents a single track in a mood playlist
class MoodPlaylistItem {
  final String name;
  final String freesoundId;
  final String description;
  final int duration;
  final List<String> tags;

  const MoodPlaylistItem({
    required this.name,
    required this.freesoundId,
    required this.description,
    required this.duration,
    required this.tags,
  });

  factory MoodPlaylistItem.fromJson(Map<String, dynamic> json) {
    return MoodPlaylistItem(
      name: json['name'] as String,
      freesoundId: json['freesound_id'] as String,
      description: json['description'] as String,
      duration: json['duration'] as int,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'freesound_id': freesoundId,
        'description': description,
        'duration': duration,
        'tags': tags,
      };
}

/// Service to load and manage mood playlists
class MoodPlaylistService {
  static MoodPlaylistService? _instance;
  Map<String, List<MoodPlaylistItem>>? _playlists;

  MoodPlaylistService._();

  /// Get singleton instance
  static MoodPlaylistService get instance {
    _instance ??= MoodPlaylistService._();
    return _instance!;
  }

  /// Load playlists from JSON asset
  Future<void> loadPlaylists() async {
    if (_playlists != null) return; // Already loaded

    try {
      final String jsonString = await rootBundle.loadString('assets/mood_playlists.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      _playlists = {};
      for (final entry in jsonData.entries) {
        final List<dynamic> items = entry.value as List<dynamic>;
        _playlists![entry.key] = items
            .map((item) => MoodPlaylistItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      debugPrint('Loaded ${_playlists!.length} mood playlists');
    } catch (e) {
      debugPrint('Failed to load mood playlists: $e');
      _playlists = {};
    }
  }

  /// Get playlist for a specific mood
  List<MoodPlaylistItem> getPlaylistForMood(GlowMood mood) {
    final key = _moodToKey(mood);
    return _playlists?[key] ?? [];
  }

  /// Get all available moods
  List<String> get availableMoods => _playlists?.keys.toList() ?? [];

  /// Check if playlists are loaded
  bool get isLoaded => _playlists != null;

  /// Convert GlowMood enum to playlist key
  String _moodToKey(GlowMood mood) {
    switch (mood) {
      case GlowMood.balanced:
        return 'balanced';
      case GlowMood.anxious:
        return 'anxious';
      case GlowMood.burnoutRisk:
        return 'burnoutRisk';
    }
  }

  /// Get display name for mood
  static String getMoodDisplayName(GlowMood mood) {
    switch (mood) {
      case GlowMood.balanced:
        return 'Calming Sounds';
      case GlowMood.anxious:
        return 'Anxiety Relief';
      case GlowMood.burnoutRisk:
        return 'Deep Relaxation';
    }
  }
}
