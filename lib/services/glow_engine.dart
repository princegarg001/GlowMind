import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:glowmind/models/models.dart';

/// Computes the ambient glow state from passive signals
class GlowEngine {
  GlowState computeGlow({required List<NoteEntry> notes, required SleepProfile? sleep}) {
    // Basic heuristics:
    // - Frequency of notes: too many negative days or long gaps => burnoutRisk (grey, low intensity)
    // - Recent note with anxious keywords => anxious (faster pulse)
    // - Otherwise balanced (purple/blue with calm pulse)
    final now = DateTime.now();
    notes = [...notes]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Time gap in days between now and last note
    final gapDays = notes.isEmpty ? 999.0 : now.difference(notes.first.createdAt).inHours / 24.0;

    // Simple tone cues
    final negativeWords = ['tired', 'exhausted', 'burnout', 'sad', 'down', 'drained'];
    final anxiousWords = ['anxious', 'panic', 'overwhelmed', 'worry', 'nervous'];
    int negHits = 0;
    int anxHits = 0;
    for (final n in notes.take(10)) {
      final t = n.text.toLowerCase();
      for (final w in negativeWords) {
        if (t.contains(w)) negHits++;
      }
      for (final w in anxiousWords) {
        if (t.contains(w)) anxHits++;
      }
    }

    // Sleep consistency: difference between bed and wake hours (target 7-9h)
    double sleepScore = 0.5;
    if (sleep != null) {
      final dur = _sleepDurationHours(sleep);
      // 8h => score 1.0, <5 or >10 => score 0
      sleepScore = 1 - (min((dur - 8).abs(), 5) / 5);
    }

    // Compose signals
    bool burnout = gapDays >= 5 || (negHits >= 4 && sleepScore < 0.3);
    bool anxious = anxHits >= 2 && gapDays < 5;

    if (burnout) {
      return const GlowState(intensity: 0.25, pulse: 0.15, mood: GlowMood.burnoutRisk);
    }
    if (anxious) {
      return const GlowState(intensity: 0.8, pulse: 1.2, mood: GlowMood.anxious);
    }
    // Balanced varies with sleepScore and gapDays
    final intensity = (0.5 + sleepScore * 0.4).clamp(0.2, 1.0);
    final pulse = (0.2 + (1 / (1 + gapDays))).clamp(0.15, 0.6);
    return GlowState(intensity: intensity, pulse: pulse, mood: GlowMood.balanced);
  }

  double _sleepDurationHours(SleepProfile s) {
    final b = s.bedtime;
    final w = s.wakeTime;
    int bedMin = b.hour * 60 + b.minute;
    int wakeMin = w.hour * 60 + w.minute;
    if (wakeMin <= bedMin) wakeMin += 24 * 60;
    return (wakeMin - bedMin) / 60.0;
  }
}
