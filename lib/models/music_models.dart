import 'package:flutter/foundation.dart';

/// Mood types for music playback, aligned with GlowMind moods
enum MoodType {
  sleep,
  study,
  party,
  meditate,
  deepFocus,
  nature;

  String get displayName {
    switch (this) {
      case MoodType.sleep:
        return 'Sleep';
      case MoodType.study:
        return 'Study';
      case MoodType.party:
        return 'Party';
      case MoodType.meditate:
        return 'Meditate';
      case MoodType.deepFocus:
        return 'Deep Focus';
      case MoodType.nature:
        return 'Nature';
    }
  }

  String get assetPath {
    switch (this) {
      case MoodType.sleep:
        return 'sleep';
      case MoodType.study:
        return 'study';
      case MoodType.party:
        return 'party';
      case MoodType.meditate:
        return 'meditate';
      case MoodType.deepFocus:
        return 'focus';
      case MoodType.nature:
        return 'nature';
    }
  }
}

/// Represents a single audio track
class Track {
  final String id;
  final String name;
  final String url;
  final String source; // 'bundled', 'freesound', or 'url'
  final int? freesoundId;
  final int? durationSeconds;
  final String? attribution;

  const Track({
    required this.id,
    required this.name,
    required this.url,
    this.source = 'bundled',
    this.freesoundId,
    this.durationSeconds,
    this.attribution,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'source': source,
        'freesound_id': freesoundId,
        'duration_seconds': durationSeconds,
        'attribution': attribution,
      };

  static Track fromJson(Map<String, dynamic> json) => Track(
        id: json['id'] as String,
        name: json['name'] as String,
        url: json['url'] as String,
        source: json['source'] as String? ?? 'bundled',
        freesoundId: json['freesound_id'] as int?,
        durationSeconds: json['duration_seconds'] as int?,
        attribution: json['attribution'] as String?,
      );
}

/// Represents a playlist for a specific mood
class Playlist {
  final String id;
  final String userId;
  final MoodType mood;
  final String name;
  final bool isDefault;
  final List<Track> tracks;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Playlist({
    required this.id,
    required this.userId,
    required this.mood,
    required this.name,
    this.isDefault = false,
    this.tracks = const [],
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'mood': mood.name,
        'name': name,
        'is_default': isDefault,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  static Playlist? fromJson(Map<String, dynamic> json) {
    try {
      final moodStr = json['mood'] as String;
      final mood = MoodType.values.firstWhere((m) => m.name == moodStr);
      
      return Playlist(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        mood: mood,
        name: json['name'] as String,
        isDefault: json['is_default'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );
    } catch (e) {
      debugPrint('Failed to parse Playlist: $e');
      return null;
    }
  }

  Playlist copyWith({
    String? id,
    String? userId,
    MoodType? mood,
    String? name,
    bool? isDefault,
    List<Track>? tracks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mood: mood ?? this.mood,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      tracks: tracks ?? this.tracks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Loop mode for playlist playback
enum LoopMode {
  off,
  one,
  all;

  String get displayName {
    switch (this) {
      case LoopMode.off:
        return 'No Loop';
      case LoopMode.one:
        return 'Loop One';
      case LoopMode.all:
        return 'Loop All';
    }
  }
}

/// Sleep timer configuration
class SleepTimer {
  final Duration duration;
  final DateTime startTime;
  final bool fadeOut;

  const SleepTimer({
    required this.duration,
    required this.startTime,
    this.fadeOut = true,
  });

  DateTime get endTime => startTime.add(duration);
  
  Duration get remaining {
    final now = DateTime.now();
    final diff = endTime.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  bool get isExpired => DateTime.now().isAfter(endTime);

  Map<String, dynamic> toJson() => {
        'duration_seconds': duration.inSeconds,
        'start_time': startTime.toIso8601String(),
        'fade_out': fadeOut,
      };

  static SleepTimer fromJson(Map<String, dynamic> json) => SleepTimer(
        duration: Duration(seconds: json['duration_seconds'] as int),
        startTime: DateTime.parse(json['start_time'] as String),
        fadeOut: json['fade_out'] as bool? ?? true,
      );
}

/// User's music preferences
class UserMusicPreferences {
  final String userId;
  final MoodType? lastMood;
  final String? lastTrackId;
  final double volume;
  final bool autoPlay;
  final bool shuffle;
  final LoopMode loopMode;

  const UserMusicPreferences({
    required this.userId,
    this.lastMood,
    this.lastTrackId,
    this.volume = 0.7,
    this.autoPlay = true,
    this.shuffle = false,
    this.loopMode = LoopMode.all,
  });

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'last_mood': lastMood?.name,
        'last_track_id': lastTrackId,
        'volume': volume,
        'auto_play': autoPlay,
        'shuffle': shuffle,
        'loop_mode': loopMode.name,
      };

  static UserMusicPreferences? fromJson(Map<String, dynamic> json) {
    try {
      final lastMoodStr = json['last_mood'] as String?;
      final lastMood = lastMoodStr != null
          ? MoodType.values.firstWhere((m) => m.name == lastMoodStr)
          : null;

      final loopModeStr = json['loop_mode'] as String? ?? 'all';
      final loopMode = LoopMode.values.firstWhere(
        (m) => m.name == loopModeStr,
        orElse: () => LoopMode.all,
      );

      return UserMusicPreferences(
        userId: json['user_id'] as String,
        lastMood: lastMood,
        lastTrackId: json['last_track_id'] as String?,
        volume: (json['volume'] as num?)?.toDouble() ?? 0.7,
        autoPlay: json['auto_play'] as bool? ?? true,
        shuffle: json['shuffle'] as bool? ?? false,
        loopMode: loopMode,
      );
    } catch (e) {
      debugPrint('Failed to parse UserMusicPreferences: $e');
      return null;
    }
  }

  UserMusicPreferences copyWith({
    String? userId,
    MoodType? lastMood,
    String? lastTrackId,
    double? volume,
    bool? autoPlay,
    bool? shuffle,
    LoopMode? loopMode,
  }) {
    return UserMusicPreferences(
      userId: userId ?? this.userId,
      lastMood: lastMood ?? this.lastMood,
      lastTrackId: lastTrackId ?? this.lastTrackId,
      volume: volume ?? this.volume,
      autoPlay: autoPlay ?? this.autoPlay,
      shuffle: shuffle ?? this.shuffle,
      loopMode: loopMode ?? this.loopMode,
    );
  }
}
