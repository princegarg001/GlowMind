import 'package:flutter/foundation.dart';
import 'package:glowmind/models/models.dart';
import 'package:glowmind/supabase/supabase_config.dart';

class SupabaseDataService {
  final _client = SupabaseConfig.client;

  // Notes operations
  Future<List<NoteEntry>> loadNotes(String userId) async {
    try {
      final data = await _client.from('notes').select().eq('user_id', userId).order('created_at', ascending: false);
      return data.map((json) => NoteEntry.fromJson(json)).whereType<NoteEntry>().toList();
    } catch (e) {
      debugPrint('loadNotes error: $e');
      return [];
    }
  }

  Future<NoteEntry?> addNote(String userId, String text) async {
    try {
      final data = {
        'user_id': userId,
        'text': text,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      final result = await _client.from('notes').insert(data).select().single();
      return NoteEntry.fromJson(result);
    } catch (e) {
      debugPrint('addNote error: $e');
      return null;
    }
  }

  Future<bool> deleteNote(String noteId) async {
    try {
      await _client.from('notes').delete().eq('id', noteId);
      return true;
    } catch (e) {
      debugPrint('deleteNote error: $e');
      return false;
    }
  }

  // Sleep profile operations
  Future<SleepProfile?> loadSleepProfile(String userId) async {
    try {
      final data = await _client.from('sleep_profiles').select().eq('user_id', userId).maybeSingle();
      if (data == null) return null;
      return SleepProfile.fromJson(data);
    } catch (e) {
      debugPrint('loadSleepProfile error: $e');
      return null;
    }
  }

  Future<SleepProfile?> saveSleepProfile(String userId, TimeOfDaySimple bedtime, TimeOfDaySimple wakeTime) async {
    try {
      final existing = await _client.from('sleep_profiles').select().eq('user_id', userId).maybeSingle();
      
      final data = {
        'user_id': userId,
        'bedtime_hour': bedtime.hour,
        'bedtime_minute': bedtime.minute,
        'wake_hour': wakeTime.hour,
        'wake_minute': wakeTime.minute,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (existing != null) {
        final result = await _client.from('sleep_profiles').update(data).eq('user_id', userId).select().single();
        return SleepProfile.fromJson(result);
      } else {
        data['created_at'] = DateTime.now().toIso8601String();
        final result = await _client.from('sleep_profiles').insert(data).select().single();
        return SleepProfile.fromJson(result);
      }
    } catch (e) {
      debugPrint('saveSleepProfile error: $e');
      return null;
    }
  }

  // User operations
  Future<AppUser?> loadUser(String userId) async {
    try {
      final data = await _client.from('users').select().eq('id', userId).maybeSingle();
      if (data == null) return null;
      return AppUser.fromJson(data);
    } catch (e) {
      debugPrint('loadUser error: $e');
      return null;
    }
  }
}
