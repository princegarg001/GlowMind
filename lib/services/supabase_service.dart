import 'package:flutter/foundation.dart';
import 'package:glowmind/models/models.dart';
import 'package:glowmind/supabase/supabase_config.dart';

/// Static helper class for generic Supabase operations
class SupabaseService {
  static final _client = SupabaseConfig.client;

  /// Select multiple rows from a table
  static Future<List<Map<String, dynamic>>> select(
    String table, {
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
  }) async {
    try {
      var query = _client.from(table).select();
      
      if (filters != null) {
        for (final entry in filters.entries) {
          query = query.eq(entry.key, entry.value);
        }
      }
      
      List<dynamic> data;
      if (orderBy != null) {
        data = await query.order(orderBy, ascending: ascending);
      } else {
        data = await query;
      }
      
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('SupabaseService.select error ($table): $e');
      return [];
    }
  }

  /// Select a single row from a table
  static Future<Map<String, dynamic>?> selectSingle(
    String table, {
    required Map<String, dynamic> filters,
  }) async {
    try {
      var query = _client.from(table).select();
      
      for (final entry in filters.entries) {
        query = query.eq(entry.key, entry.value);
      }
      
      final data = await query.maybeSingle();
      return data;
    } catch (e) {
      debugPrint('SupabaseService.selectSingle error ($table): $e');
      return null;
    }
  }

  /// Insert a row into a table
  static Future<List<Map<String, dynamic>>> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await _client.from(table).insert(data).select();
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('SupabaseService.insert error ($table): $e');
      return [];
    }
  }

  /// Insert multiple rows into a table
  static Future<List<Map<String, dynamic>>> insertMultiple(
    String table,
    List<Map<String, dynamic>> data,
  ) async {
    try {
      if (data.isEmpty) return [];
      final result = await _client.from(table).insert(data).select();
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('SupabaseService.insertMultiple error ($table): $e');
      return [];
    }
  }

  /// Update rows in a table
  static Future<List<Map<String, dynamic>>> update(
    String table,
    Map<String, dynamic> data, {
    required Map<String, dynamic> filters,
  }) async {
    try {
      var query = _client.from(table).update(data);
      
      for (final entry in filters.entries) {
        query = query.eq(entry.key, entry.value);
      }
      
      final result = await query.select();
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('SupabaseService.update error ($table): $e');
      return [];
    }
  }

  /// Delete rows from a table
  static Future<void> delete(
    String table, {
    required Map<String, dynamic> filters,
  }) async {
    try {
      var query = _client.from(table).delete();
      
      for (final entry in filters.entries) {
        query = query.eq(entry.key, entry.value);
      }
      
      await query;
    } catch (e) {
      debugPrint('SupabaseService.delete error ($table): $e');
    }
  }
}

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
