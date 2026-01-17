import 'package:flutter/material.dart';
import 'package:glowmind/models/music_models.dart';
import 'package:glowmind/widgets/mood_orb.dart';

/// Single mood page with animated orb only - controls moved to navigator overlay
class MoodPage extends StatelessWidget {
  final MoodType mood;

  const MoodPage({
    super.key,
    required this.mood,
  });

  /// Get background gradient colors for the mood
  List<Color> _getBackgroundColors() {
    switch (mood) {
      case MoodType.sleep:
        return [const Color(0xFF2D1B4E), const Color(0xFF1A0F3D)];
      case MoodType.study:
        return [const Color(0xFF1E3A8A), const Color(0xFF0F172A)];
      case MoodType.party:
        return [const Color(0xFF831843), const Color(0xFF3F0F1F)];
      case MoodType.meditate:
        return [const Color(0xFF064E3B), const Color(0xFF022C22)];
      case MoodType.deepFocus:
        return [const Color(0xFF164E63), const Color(0xFF0C2D3A)];
      case MoodType.nature:
        return [const Color(0xFF3F6212), const Color(0xFF1F3108)];
    }
  }

  /// Get pulse speed for the mood (heartbeat rate)
  double _getPulseSpeed() {
    switch (mood) {
      case MoodType.sleep:
        return 0.4; // Very slow, calm heartbeat
      case MoodType.study:
        return 0.7; // Steady, focused
      case MoodType.party:
        return 1.4; // Fast, energetic
      case MoodType.meditate:
        return 0.3; // Slowest, deeply relaxed
      case MoodType.deepFocus:
        return 0.5; // Minimal, steady
      case MoodType.nature:
        return 0.6; // Gentle, natural rhythm
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColors = _getBackgroundColors();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: bgColors,
        ),
      ),
      child: Center(
        child: MoodOrb(
          mood: mood,
          size: 280,
          pulseSpeed: _getPulseSpeed(),
        ),
      ),
    );
  }
}
