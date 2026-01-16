import 'package:flutter/foundation.dart';

/// Authentication status in the app
enum AuthStatus { signedOut, guest, signedIn }

/// User model linked to Supabase auth
class AppUser {
  final String id;
  final String? email;
  final String? name;
  final bool isGuest;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AppUser({
    required this.id,
    this.email,
    this.name,
    this.isGuest = false,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'is_guest': isGuest,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  static AppUser fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        email: json['email'] as String?,
        name: json['name'] as String?,
        isGuest: json['is_guest'] as bool? ?? false,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      );
}

/// Note captured by the user; used for tone analysis
class NoteEntry {
  final String id;
  final String userId;
  final String text;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const NoteEntry({
    required this.id,
    required this.userId,
    required this.text,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'text': text,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  static NoteEntry? fromJson(Map<String, dynamic> json) {
    try {
      return NoteEntry(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        text: json['text'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      );
    } catch (e) {
      debugPrint('Failed to parse NoteEntry: $e');
      return null;
    }
  }
}

/// Sleep profile manually entered by the user
class SleepProfile {
  final String id;
  final String userId;
  final TimeOfDaySimple bedtime;
  final TimeOfDaySimple wakeTime;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SleepProfile({
    required this.id,
    required this.userId,
    required this.bedtime,
    required this.wakeTime,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'bedtime_hour': bedtime.hour,
        'bedtime_minute': bedtime.minute,
        'wake_hour': wakeTime.hour,
        'wake_minute': wakeTime.minute,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  static SleepProfile? fromJson(Map<String, dynamic> json) {
    try {
      return SleepProfile(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        bedtime: TimeOfDaySimple(hour: json['bedtime_hour'] as int, minute: json['bedtime_minute'] as int),
        wakeTime: TimeOfDaySimple(hour: json['wake_hour'] as int, minute: json['wake_minute'] as int),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      );
    } catch (e) {
      debugPrint('Failed to parse SleepProfile: $e');
      return null;
    }
  }
}

/// Compact representation of a time of day
class TimeOfDaySimple {
  final int hour;
  final int minute;
  const TimeOfDaySimple({required this.hour, required this.minute});

  Map<String, dynamic> toJson() => {'hour': hour, 'minute': minute};
  static TimeOfDaySimple fromJson(Map<String, dynamic> json) =>
      TimeOfDaySimple(hour: json['hour'] as int, minute: json['minute'] as int);
}

/// Computed glow state for the ambient background
class GlowState {
  final double intensity; // 0..1
  final double pulse; // pulses per second
  final GlowMood mood;
  const GlowState({required this.intensity, required this.pulse, required this.mood});
}

enum GlowMood { balanced, burnoutRisk, anxious }
