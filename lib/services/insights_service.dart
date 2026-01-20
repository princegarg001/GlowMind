import 'package:flutter/foundation.dart';
import 'package:glowmind/services/local_store.dart';
import 'package:glowmind/supabase/supabase_config.dart';

/// Service to manage mood history with Supabase sync and local caching
class InsightsService {
  static final InsightsService _instance = InsightsService._internal();
  factory InsightsService() => _instance;
  InsightsService._internal();

  final _client = SupabaseConfig.client;
  final _localStore = LocalStore();
  String? _currentUserId;

  /// Initialize for a specific user
  Future<void> initForUser(String userId) async {
    _currentUserId = userId;
    await _localStore.init();

    // Sync local data to Supabase for non-guest users
    if (userId != 'guest') {
      await _syncToSupabase(userId);
    }
  }

  /// Save a mood entry
  Future<void> saveMoodEntry(MoodHistoryEntry entry) async {
    final userId = _currentUserId;
    if (userId == null) return;

    // Always save locally first
    await _localStore.saveMoodEntryForUser(userId, entry);

    // Sync to Supabase for non-guest users
    if (userId != 'guest') {
      try {
        await _client.from('mood_history').insert({
          'user_id': userId,
          'mood': entry.mood,
          'timestamp': entry.timestamp.toIso8601String(),
          'duration_seconds': entry.durationSeconds,
        });
      } catch (e) {
        debugPrint('InsightsService: Failed to save to Supabase: $e');
        // Data is still saved locally, will sync later
      }
    }
  }

  /// Update duration of the last mood entry
  Future<void> updateLastMoodDuration(int durationSeconds) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final history = await loadMoodHistory();
    if (history.isEmpty) return;

    final lastEntry = history.last;
    final updatedEntry = MoodHistoryEntry(
      mood: lastEntry.mood,
      timestamp: lastEntry.timestamp,
      durationSeconds: durationSeconds,
    );

    // Update locally
    await _localStore.updateLastMoodEntryForUser(userId, updatedEntry);

    // Update in Supabase for non-guest users
    if (userId != 'guest') {
      try {
        await _client
            .from('mood_history')
            .update({'duration_seconds': durationSeconds})
            .eq('user_id', userId)
            .eq('timestamp', lastEntry.timestamp.toIso8601String());
      } catch (e) {
        debugPrint('InsightsService: Failed to update Supabase: $e');
      }
    }
  }

  /// Load mood history for current user
  Future<List<MoodHistoryEntry>> loadMoodHistory() async {
    final userId = _currentUserId;
    if (userId == null) return [];

    // For guest users, only use local storage
    if (userId == 'guest') {
      return await _localStore.loadMoodHistoryForUser(userId);
    }

    // Try to load from Supabase first
    try {
      final data = await _client
          .from('mood_history')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false)
          .limit(1000);

      if (data.isNotEmpty) {
        final entries = (data as List).map((json) {
          return MoodHistoryEntry(
            mood: json['mood'] as String,
            timestamp: DateTime.parse(json['timestamp'] as String),
            durationSeconds: json['duration_seconds'] as int? ?? 0,
          );
        }).toList();

        // Cache locally
        await _localStore.saveMoodHistoryForUser(userId, entries);
        return entries;
      }
    } catch (e) {
      debugPrint('InsightsService: Failed to load from Supabase: $e');
    }

    // Fall back to local storage
    return await _localStore.loadMoodHistoryForUser(userId);
  }

  /// Get mood counts for a time period
  Future<Map<String, int>> getMoodCounts({int? daysBack}) async {
    final history = await loadMoodHistory();
    final now = DateTime.now();
    final cutoff =
        daysBack != null ? now.subtract(Duration(days: daysBack)) : null;

    final counts = <String, int>{};
    for (final entry in history) {
      if (cutoff != null && entry.timestamp.isBefore(cutoff)) continue;
      counts[entry.mood] = (counts[entry.mood] ?? 0) + 1;
    }
    return counts;
  }

  /// Get mood trend data for charts
  Future<List<Map<String, dynamic>>> getMoodTrend({int days = 7}) async {
    final history = await loadMoodHistory();
    final now = DateTime.now();
    final result = <Map<String, dynamic>>[];

    for (int i = days - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      final nextDate = date.add(const Duration(days: 1));

      int count = 0;
      for (final entry in history) {
        if (entry.timestamp.isAfter(date) &&
            entry.timestamp.isBefore(nextDate)) {
          count++;
        }
      }
      result.add({'date': date, 'count': count});
    }
    return result;
  }

  /// Get total time spent in each mood
  Future<Map<String, Duration>> getMoodDurations({int? daysBack}) async {
    final history = await loadMoodHistory();
    final now = DateTime.now();
    final cutoff =
        daysBack != null ? now.subtract(Duration(days: daysBack)) : null;

    final durations = <String, Duration>{};
    for (final entry in history) {
      if (cutoff != null && entry.timestamp.isBefore(cutoff)) continue;
      final current = durations[entry.mood] ?? Duration.zero;
      durations[entry.mood] =
          current + Duration(seconds: entry.durationSeconds);
    }
    return durations;
  }

  /// Get most used mood
  Future<String?> getMostUsedMood({int? daysBack}) async {
    final counts = await getMoodCounts(daysBack: daysBack);
    if (counts.isEmpty) return null;

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  /// Get streak of consecutive days with mood entries
  Future<int> getCurrentStreak() async {
    final history = await loadMoodHistory();
    if (history.isEmpty) return 0;

    // Sort by timestamp descending
    final sorted = history.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    int streak = 0;
    DateTime? lastDate;

    for (final entry in sorted) {
      final entryDate = DateTime(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      );

      if (lastDate == null) {
        // First entry - check if it's today or yesterday
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        final yesterdayDate = todayDate.subtract(const Duration(days: 1));

        if (entryDate == todayDate || entryDate == yesterdayDate) {
          streak = 1;
          lastDate = entryDate;
        } else {
          break; // Streak broken
        }
      } else {
        final expectedDate = lastDate.subtract(const Duration(days: 1));
        if (entryDate == expectedDate) {
          streak++;
          lastDate = entryDate;
        } else if (entryDate == lastDate) {
          // Same day, continue
          continue;
        } else {
          break; // Streak broken
        }
      }
    }

    return streak;
  }

  /// Clear all mood history for current user
  Future<void> clearMoodHistory() async {
    final userId = _currentUserId;
    if (userId == null) return;

    await _localStore.clearMoodHistoryForUser(userId);

    if (userId != 'guest') {
      try {
        await _client.from('mood_history').delete().eq('user_id', userId);
      } catch (e) {
        debugPrint('InsightsService: Failed to clear Supabase: $e');
      }
    }
  }

  /// Sync local data to Supabase
  Future<void> _syncToSupabase(String userId) async {
    try {
      final localHistory = await _localStore.loadMoodHistoryForUser(userId);
      if (localHistory.isEmpty) return;

      // Check what's already in Supabase
      final existing = await _client
          .from('mood_history')
          .select('timestamp')
          .eq('user_id', userId);

      final existingTimestamps =
          (existing as List).map((e) => e['timestamp'] as String).toSet();

      // Upload entries that don't exist in Supabase
      final toUpload = localHistory.where((entry) {
        return !existingTimestamps.contains(entry.timestamp.toIso8601String());
      }).toList();

      if (toUpload.isNotEmpty) {
        final batch = toUpload
            .map((entry) => {
                  'user_id': userId,
                  'mood': entry.mood,
                  'timestamp': entry.timestamp.toIso8601String(),
                  'duration_seconds': entry.durationSeconds,
                })
            .toList();

        await _client.from('mood_history').insert(batch);
        debugPrint(
            'InsightsService: Synced ${toUpload.length} entries to Supabase');
      }
    } catch (e) {
      debugPrint('InsightsService: Sync to Supabase failed: $e');
    }
  }
}
