import 'package:flutter/material.dart';
import 'package:glowmind/models/music_models.dart';
import 'package:glowmind/widgets/orbs/mood_orb_selector.dart';

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
        return [const Color(0xFF1A0F2E), const Color(0xFF0D0620), const Color(0xFF050208)];
      case MoodType.study:
        return [const Color(0xFF0F1729), const Color(0xFF0A1628), const Color(0xFF030712)];
      case MoodType.party:
        return [const Color(0xFF2D0A1F), const Color(0xFF1A0612), const Color(0xFF0A0306)];
      case MoodType.meditate:
        return [const Color(0xFF042F22), const Color(0xFF021A14), const Color(0xFF010A08)];
      case MoodType.deepFocus:
        return [const Color(0xFF0A1E28), const Color(0xFF061218), const Color(0xFF020608)];
      case MoodType.nature:
        return [const Color(0xFF1A2808), const Color(0xFF0F1804), const Color(0xFF060A02)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColors = _getBackgroundColors();
    final screenSize = MediaQuery.of(context).size;
    final orbSize = screenSize.width < 400 ? 220.0 : 280.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: bgColors,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Center(
        child: MoodOrbSelector(
          mood: mood,
          size: orbSize,
        ),
      ),
    );
  }
}
