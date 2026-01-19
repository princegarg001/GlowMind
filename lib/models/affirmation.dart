import 'package:flutter/material.dart';

/// Types of affirmations
enum AffirmationType {
  generated,      // AI/system generated
  custom,         // User-typed custom affirmation
  voice,          // User voice recorded (alias for userRecorded)
  userRecorded,   // User voice recorded
  curated,        // Pre-curated from library
}

/// Categories for affirmations mapped to moods
enum AffirmationCategory {
  confidence,
  calm,
  motivation,
  selfLove,
  gratitude,
  resilience,
  focus,
  joy;

  String get displayName {
    switch (this) {
      case AffirmationCategory.confidence:
        return 'Confidence';
      case AffirmationCategory.calm:
        return 'Calm';
      case AffirmationCategory.motivation:
        return 'Motivation';
      case AffirmationCategory.selfLove:
        return 'Self Love';
      case AffirmationCategory.gratitude:
        return 'Gratitude';
      case AffirmationCategory.resilience:
        return 'Resilience';
      case AffirmationCategory.focus:
        return 'Focus';
      case AffirmationCategory.joy:
        return 'Joy';
    }
  }

  Color get color {
    switch (this) {
      case AffirmationCategory.confidence:
        return const Color(0xFFEC4899);
      case AffirmationCategory.calm:
        return const Color(0xFF6366F1);
      case AffirmationCategory.motivation:
        return const Color(0xFFF59E0B);
      case AffirmationCategory.selfLove:
        return const Color(0xFFEF4444);
      case AffirmationCategory.gratitude:
        return const Color(0xFF10B981);
      case AffirmationCategory.resilience:
        return const Color(0xFF8B5CF6);
      case AffirmationCategory.focus:
        return const Color(0xFF06B6D4);
      case AffirmationCategory.joy:
        return const Color(0xFFFBBF24);
    }
  }

  IconData get icon {
    switch (this) {
      case AffirmationCategory.confidence:
        return Icons.star;
      case AffirmationCategory.calm:
        return Icons.spa;
      case AffirmationCategory.motivation:
        return Icons.bolt;
      case AffirmationCategory.selfLove:
        return Icons.favorite;
      case AffirmationCategory.gratitude:
        return Icons.volunteer_activism;
      case AffirmationCategory.resilience:
        return Icons.shield;
      case AffirmationCategory.focus:
        return Icons.center_focus_strong;
      case AffirmationCategory.joy:
        return Icons.celebration;
    }
  }
}

/// Represents a single affirmation
class Affirmation {
  final String id;
  final String text;
  final AffirmationType type;
  final AffirmationCategory category;
  final String? audioPath;
  final DateTime createdAt;
  final bool isFavorite;
  final int timesShown;
  final String? basedOnMood;

  const Affirmation({
    required this.id,
    required this.text,
    required this.type,
    required this.category,
    this.audioPath,
    required this.createdAt,
    this.isFavorite = false,
    this.timesShown = 0,
    this.basedOnMood,
  });

  Affirmation copyWith({
    String? id,
    String? text,
    AffirmationType? type,
    AffirmationCategory? category,
    String? audioPath,
    DateTime? createdAt,
    bool? isFavorite,
    int? timesShown,
    String? basedOnMood,
  }) {
    return Affirmation(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      category: category ?? this.category,
      audioPath: audioPath ?? this.audioPath,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      timesShown: timesShown ?? this.timesShown,
      basedOnMood: basedOnMood ?? this.basedOnMood,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'type': type.name,
        'category': category.name,
        'audioPath': audioPath,
        'createdAt': createdAt.toIso8601String(),
        'isFavorite': isFavorite,
        'timesShown': timesShown,
        'basedOnMood': basedOnMood,
      };

  factory Affirmation.fromJson(Map<String, dynamic> json) => Affirmation(
        id: json['id'] as String,
        text: json['text'] as String,
        type: AffirmationType.values.byName(json['type'] as String),
        category: AffirmationCategory.values.byName(json['category'] as String),
        audioPath: json['audioPath'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isFavorite: json['isFavorite'] as bool? ?? false,
        timesShown: json['timesShown'] as int? ?? 0,
        basedOnMood: json['basedOnMood'] as String?,
      );
}

/// Settings for affirmation notifications
class AffirmationSettings {
  final bool morningEnabled;
  final TimeOfDay morningTime;
  final bool eveningEnabled;
  final TimeOfDay eveningTime;
  final bool useVoiceAffirmations;
  final List<AffirmationCategory> preferredCategories;

  const AffirmationSettings({
    this.morningEnabled = true,
    this.morningTime = const TimeOfDay(hour: 8, minute: 0),
    this.eveningEnabled = true,
    this.eveningTime = const TimeOfDay(hour: 21, minute: 0),
    this.useVoiceAffirmations = false,
    this.preferredCategories = const [],
  });

  // Aliases for UI compatibility
  bool get morningNotifications => morningEnabled;
  bool get eveningNotifications => eveningEnabled;

  AffirmationSettings copyWith({
    bool? morningEnabled,
    TimeOfDay? morningTime,
    bool? eveningEnabled,
    TimeOfDay? eveningTime,
    bool? useVoiceAffirmations,
    List<AffirmationCategory>? preferredCategories,
  }) {
    return AffirmationSettings(
      morningEnabled: morningEnabled ?? this.morningEnabled,
      morningTime: morningTime ?? this.morningTime,
      eveningEnabled: eveningEnabled ?? this.eveningEnabled,
      eveningTime: eveningTime ?? this.eveningTime,
      useVoiceAffirmations: useVoiceAffirmations ?? this.useVoiceAffirmations,
      preferredCategories: preferredCategories ?? this.preferredCategories,
    );
  }

  Map<String, dynamic> toJson() => {
        'morningEnabled': morningEnabled,
        'morningHour': morningTime.hour,
        'morningMinute': morningTime.minute,
        'eveningEnabled': eveningEnabled,
        'eveningHour': eveningTime.hour,
        'eveningMinute': eveningTime.minute,
        'useVoiceAffirmations': useVoiceAffirmations,
        'preferredCategories': preferredCategories.map((c) => c.name).toList(),
      };

  factory AffirmationSettings.fromJson(Map<String, dynamic> json) =>
      AffirmationSettings(
        morningEnabled: json['morningEnabled'] as bool? ?? true,
        morningTime: TimeOfDay(
          hour: json['morningHour'] as int? ?? 8,
          minute: json['morningMinute'] as int? ?? 0,
        ),
        eveningEnabled: json['eveningEnabled'] as bool? ?? true,
        eveningTime: TimeOfDay(
          hour: json['eveningHour'] as int? ?? 21,
          minute: json['eveningMinute'] as int? ?? 0,
        ),
        useVoiceAffirmations: json['useVoiceAffirmations'] as bool? ?? false,
        preferredCategories: (json['preferredCategories'] as List?)
                ?.map((c) => AffirmationCategory.values.byName(c as String))
                .toList() ??
            [],
      );
}
