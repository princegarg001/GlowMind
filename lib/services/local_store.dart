import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:glowmind/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  SharedPreferences? _prefs;
  bool _ready = false;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _ready = true;
    } catch (e) {
      debugPrint('LocalStore init failed: $e');
      _ready = false;
    }
  }

  Future<void> _ensure() async {
    if (!_ready) await init();
  }

  static const _kAuth = 'auth_status';
  static const _kUser = 'user';
  static const _kNotes = 'notes';
  static const _kSleep = 'sleep_profile';
  static const _kMoodHistory = 'mood_history';

  Future<AuthStatus> loadAuthStatus() async {
    await _ensure();
    try {
      final raw = _prefs?.getString(_kAuth);
      if (raw == null) return AuthStatus.signedOut;
      return AuthStatus.values.firstWhere((e) => e.name == raw, orElse: () => AuthStatus.signedOut);
    } catch (e) {
      debugPrint('loadAuthStatus error: $e');
      return AuthStatus.signedOut;
    }
  }

  Future<void> saveAuthStatus(AuthStatus status) async {
    await _ensure();
    try {
      await _prefs?.setString(_kAuth, status.name);
    } catch (e) {
      debugPrint('saveAuthStatus error: $e');
    }
  }

  Future<AppUser?> loadUser() async {
    await _ensure();
    try {
      final raw = _prefs?.getString(_kUser);
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AppUser(id: map['id'] as String, email: map['email'] as String?, isGuest: map['isGuest'] as bool? ?? false);
    } catch (e) {
      debugPrint('loadUser error: $e');
      return null;
    }
  }

  Future<void> saveUser(AppUser user) async {
    await _ensure();
    try {
      final map = {'id': user.id, 'email': user.email, 'isGuest': user.isGuest};
      await _prefs?.setString(_kUser, jsonEncode(map));
    } catch (e) {
      debugPrint('saveUser error: $e');
    }
  }

  Future<void> clearUser() async {
    await _ensure();
    try {
      await _prefs?.remove(_kUser);
    } catch (e) {
      debugPrint('clearUser error: $e');
    }
  }

  Future<List<NoteEntry>> loadNotes() async {
    await _ensure();
    try {
      final raw = _prefs?.getString(_kNotes);
      if (raw == null) return [];
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      final parsed = <NoteEntry>[];
      for (final m in list) {
        final n = NoteEntry.fromJson(m);
        if (n != null) parsed.add(n);
      }
      // sanitize in case of corruption
      await saveNotes(parsed);
      return parsed;
    } catch (e) {
      debugPrint('loadNotes error: $e');
      return [];
    }
  }

  Future<void> saveNotes(List<NoteEntry> notes) async {
    await _ensure();
    try {
      final list = notes.map((e) => e.toJson()).toList();
      await _prefs?.setString(_kNotes, jsonEncode(list));
    } catch (e) {
      debugPrint('saveNotes error: $e');
    }
  }

  Future<SleepProfile?> loadSleepProfile() async {
    await _ensure();
    try {
      final raw = _prefs?.getString(_kSleep);
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return SleepProfile.fromJson(map);
    } catch (e) {
      debugPrint('loadSleepProfile error: $e');
      return null;
    }
  }

  Future<void> saveSleepProfile(SleepProfile profile) async {
    await _ensure();
    try {
      await _prefs?.setString(_kSleep, jsonEncode(profile.toJson()));
    } catch (e) {
      debugPrint('saveSleepProfile error: $e');
    }
  }

  /// Load mood history entries
  Future<List<MoodHistoryEntry>> loadMoodHistory() async {
    await _ensure();
    try {
      final raw = _prefs?.getString(_kMoodHistory);
      if (raw == null) return [];
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map((m) => MoodHistoryEntry.fromJson(m)).toList();
    } catch (e) {
      debugPrint('loadMoodHistory error: $e');
      return [];
    }
  }

  /// Save a mood entry to history
  Future<void> saveMoodEntry(MoodHistoryEntry entry) async {
    await _ensure();
    try {
      final history = await loadMoodHistory();
      history.add(entry);
      // Keep only the last 1000 entries to prevent excessive storage
      final trimmed = history.length > 1000 
          ? history.sublist(history.length - 1000) 
          : history;
      final list = trimmed.map((e) => e.toJson()).toList();
      await _prefs?.setString(_kMoodHistory, jsonEncode(list));
    } catch (e) {
      debugPrint('saveMoodEntry error: $e');
    }
  }

  /// Clear all mood history
  Future<void> clearMoodHistory() async {
    await _ensure();
    try {
      await _prefs?.remove(_kMoodHistory);
    } catch (e) {
      debugPrint('clearMoodHistory error: $e');
    }
  }
}

/// Represents a single mood selection event for insights tracking
class MoodHistoryEntry {
  final String mood;
  final DateTime timestamp;
  final int durationSeconds; // How long user stayed in this mood

  const MoodHistoryEntry({
    required this.mood,
    required this.timestamp,
    this.durationSeconds = 0,
  });

  Map<String, dynamic> toJson() => {
        'mood': mood,
        'timestamp': timestamp.toIso8601String(),
        'duration_seconds': durationSeconds,
      };

  static MoodHistoryEntry fromJson(Map<String, dynamic> json) => MoodHistoryEntry(
        mood: json['mood'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        durationSeconds: json['duration_seconds'] as int? ?? 0,
      );
}
