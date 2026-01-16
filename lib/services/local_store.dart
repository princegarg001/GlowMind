import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glowmind/models/models.dart';

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
}
