import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/affirmation.dart';

/// Service for generating and managing affirmations
class AffirmationService {
  static const String _affirmationsKey = 'user_affirmations';
  static const String _settingsKey = 'affirmation_settings';
  static const String _dailyAffirmationKey = 'daily_affirmation';
  static const String _dailyAffirmationDateKey = 'daily_affirmation_date';

  /// Curated affirmations mapped to moods
  static final Map<String, List<String>> _moodAffirmations = {
    'sleep': [
      "I release the day and welcome peaceful rest.",
      "My mind is calm, my body is relaxed, sleep comes naturally.",
      "I deserve this rest and will wake up refreshed.",
      "Tonight I let go of worries and embrace serenity.",
      "My dreams will be peaceful and restorative.",
      "I am safe, I am calm, I am ready for deep sleep.",
    ],
    'study': [
      "My mind is sharp and ready to absorb new knowledge.",
      "I am capable of understanding complex concepts.",
      "Every moment of study brings me closer to my goals.",
      "I focus with ease and retain information effortlessly.",
      "Learning is a gift I give myself every day.",
      "I trust my ability to succeed in my studies.",
    ],
    'party': [
      "I radiate positive energy and attract joy.",
      "I am free to express myself and have fun.",
      "My happiness is contagious and uplifts others.",
      "I deserve to celebrate life and enjoy this moment.",
      "I connect authentically with those around me.",
      "Joy flows through me naturally and effortlessly.",
    ],
    'meditate': [
      "I am present in this moment, fully and completely.",
      "Peace flows through me with every breath.",
      "I release all tension and embrace stillness.",
      "My inner calm is unshakeable and ever-present.",
      "I am connected to a deep source of tranquility.",
      "In stillness, I find my true strength.",
    ],
    'deepFocus': [
      "My concentration is laser-focused and unwavering.",
      "I accomplish my goals with clarity and purpose.",
      "Distractions fade as I channel my full attention.",
      "I am in the flow state, achieving excellence.",
      "My mind is a powerful tool that serves me well.",
      "I complete tasks with efficiency and precision.",
    ],
    'nature': [
      "I am connected to the earth and all living things.",
      "Nature's beauty fills me with peace and wonder.",
      "I breathe in fresh energy and exhale stress.",
      "The natural world heals and restores my spirit.",
      "I am grounded, centered, and at one with nature.",
      "Every element of nature supports my wellbeing.",
    ],
  };

  /// Category-based affirmations
  static final Map<AffirmationCategory, List<String>> _categoryAffirmations = {
    AffirmationCategory.confidence: [
      "I believe in myself and my unique abilities.",
      "I am worthy of success and recognition.",
      "My confidence grows stronger every day.",
      "I face challenges with courage and determination.",
      "I am enough, exactly as I am right now.",
    ],
    AffirmationCategory.calm: [
      "I am at peace with where I am in my journey.",
      "Serenity flows through me with every breath.",
      "I release what I cannot control and embrace stillness.",
      "My mind is quiet, my heart is open, my soul is free.",
      "In this moment, all is well.",
    ],
    AffirmationCategory.motivation: [
      "I have the power to create positive change.",
      "My potential is limitless and I am unstoppable.",
      "Every step I take moves me toward greatness.",
      "I am driven by purpose and fueled by passion.",
      "Success is my natural state of being.",
    ],
    AffirmationCategory.selfLove: [
      "I love and accept myself unconditionally.",
      "I am worthy of love, respect, and kindness.",
      "I treat myself with compassion and understanding.",
      "My self-worth is not determined by others.",
      "I honor my needs and prioritize my wellbeing.",
    ],
    AffirmationCategory.gratitude: [
      "I am grateful for the abundance in my life.",
      "Every day brings new blessings to appreciate.",
      "I notice and celebrate the small joys around me.",
      "Gratitude fills my heart and attracts more good.",
      "I am thankful for who I am becoming.",
    ],
    AffirmationCategory.resilience: [
      "I am stronger than any challenge I face.",
      "Setbacks are setups for greater comebacks.",
      "I bend but never break under pressure.",
      "Every obstacle makes me wiser and stronger.",
      "I rise from difficulties with renewed purpose.",
    ],
    AffirmationCategory.focus: [
      "My attention is fully present in this moment.",
      "I direct my energy toward what truly matters.",
      "Clarity guides all my decisions and actions.",
      "I am centered, focused, and purposeful.",
      "My mind is clear and my vision is sharp.",
    ],
    AffirmationCategory.joy: [
      "Joy is my birthright and I claim it fully.",
      "I choose happiness in every situation.",
      "My life is filled with moments of pure delight.",
      "I spread joy wherever I go.",
      "Happiness flows to me and through me effortlessly.",
    ],
  };

  /// Generate a personalized affirmation based on mood history
  static Future<Affirmation> generatePersonalizedAffirmation({
    required Map<String, int> moodCounts,
    String? currentMood,
  }) async {
    // Determine dominant mood from history
    String dominantMood = 'meditate';
    int maxCount = 0;
    moodCounts.forEach((mood, count) {
      if (count > maxCount) {
        maxCount = count;
        dominantMood = mood;
      }
    });

    final targetMood = currentMood ?? dominantMood;
    final category = _mapMoodToCategory(targetMood);
    final text = _generateSmartAffirmation(targetMood, moodCounts);

    return Affirmation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      type: AffirmationType.generated,
      category: category,
      createdAt: DateTime.now(),
      basedOnMood: targetMood,
    );
  }

  static AffirmationCategory _mapMoodToCategory(String mood) {
    return switch (mood) {
      'sleep' => AffirmationCategory.calm,
      'study' => AffirmationCategory.focus,
      'party' => AffirmationCategory.joy,
      'meditate' => AffirmationCategory.calm,
      'deepFocus' => AffirmationCategory.focus,
      'nature' => AffirmationCategory.gratitude,
      _ => AffirmationCategory.confidence,
    };
  }

  static String _generateSmartAffirmation(
    String mood,
    Map<String, int> moodCounts,
  ) {
    final random = Random();
    
    // Get mood-specific affirmations
    final moodAffirmations = _moodAffirmations[mood] ?? _moodAffirmations['meditate']!;
    
    // Get category affirmations
    final category = _mapMoodToCategory(mood);
    final categoryAffirmations = _categoryAffirmations[category] ?? [];
    
    // Combine and pick randomly
    final allAffirmations = [...moodAffirmations, ...categoryAffirmations];
    String base = allAffirmations[random.nextInt(allAffirmations.length)];

    // Add personalization based on usage patterns
    if (moodCounts.length > 2) {
      final personalPrefixes = [
        "Remember, ",
        "Today and always, ",
        "In this moment, ",
        "Take a breath and know that ",
        "With every heartbeat, ",
        "Deep within you, ",
      ];
      
      // 30% chance to add a prefix for variety
      if (random.nextDouble() < 0.3) {
        final prefix = personalPrefixes[random.nextInt(personalPrefixes.length)];
        base = prefix + base[0].toLowerCase() + base.substring(1);
      }
    }

    return base;
  }

  /// Get affirmation for a specific category
  static Affirmation getAffirmationForCategory(AffirmationCategory category) {
    final random = Random();
    final affirmations = _categoryAffirmations[category] ?? [];
    final text = affirmations.isNotEmpty 
        ? affirmations[random.nextInt(affirmations.length)]
        : "I am worthy of love and happiness.";

    return Affirmation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      type: AffirmationType.curated,
      category: category,
      createdAt: DateTime.now(),
    );
  }

  // Storage methods
  static Future<List<Affirmation>> loadAffirmations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_affirmationsKey);
      if (data == null) return [];

      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((j) => Affirmation.fromJson(j as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('loadAffirmations error: $e');
      return [];
    }
  }

  static Future<void> saveAffirmation(Affirmation affirmation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final affirmations = await loadAffirmations();
      affirmations.insert(0, affirmation);

      // Keep last 100 affirmations
      final trimmed = affirmations.take(100).toList();
      await prefs.setString(
        _affirmationsKey,
        jsonEncode(trimmed.map((a) => a.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('saveAffirmation error: $e');
    }
  }

  static Future<void> updateAffirmation(Affirmation updated) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final affirmations = await loadAffirmations();
      final index = affirmations.indexWhere((a) => a.id == updated.id);
      if (index != -1) {
        affirmations[index] = updated;
        await prefs.setString(
          _affirmationsKey,
          jsonEncode(affirmations.map((a) => a.toJson()).toList()),
        );
      }
    } catch (e) {
      debugPrint('updateAffirmation error: $e');
    }
  }

  static Future<void> deleteAffirmation(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final affirmations = await loadAffirmations();
      affirmations.removeWhere((a) => a.id == id);
      await prefs.setString(
        _affirmationsKey,
        jsonEncode(affirmations.map((a) => a.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('deleteAffirmation error: $e');
    }
  }

  static Future<AffirmationSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_settingsKey);
      if (data == null) return const AffirmationSettings();
      return AffirmationSettings.fromJson(jsonDecode(data) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('loadSettings error: $e');
      return const AffirmationSettings();
    }
  }

  static Future<void> saveSettings(AffirmationSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
    } catch (e) {
      debugPrint('saveSettings error: $e');
    }
  }

  /// Get or generate today's daily affirmation
  static Future<Affirmation?> getDailyAffirmation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateStr = prefs.getString(_dailyAffirmationDateKey);
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month}-${today.day}';

      if (dateStr == todayStr) {
        final data = prefs.getString(_dailyAffirmationKey);
        if (data != null) {
          return Affirmation.fromJson(jsonDecode(data) as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      debugPrint('getDailyAffirmation error: $e');
      return null;
    }
  }

  static Future<void> saveDailyAffirmation(Affirmation affirmation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month}-${today.day}';
      
      await prefs.setString(_dailyAffirmationKey, jsonEncode(affirmation.toJson()));
      await prefs.setString(_dailyAffirmationDateKey, todayStr);
    } catch (e) {
      debugPrint('saveDailyAffirmation error: $e');
    }
  }

  static Future<void> clearAllAffirmations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_affirmationsKey);
      await prefs.remove(_dailyAffirmationKey);
      await prefs.remove(_dailyAffirmationDateKey);
    } catch (e) {
      debugPrint('clearAllAffirmations error: $e');
    }
  }
}
