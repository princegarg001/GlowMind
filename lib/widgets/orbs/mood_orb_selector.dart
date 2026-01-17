import 'package:flutter/material.dart';
import 'package:glowmind/models/music_models.dart';
import 'package:glowmind/widgets/orbs/magnetic_ink_orb.dart';
import 'package:glowmind/widgets/orbs/matrix_orb.dart';
import 'package:glowmind/widgets/orbs/plasma_orb.dart';
import 'package:glowmind/widgets/orbs/zen_orb.dart';
import 'package:glowmind/widgets/orbs/cosmic_orb.dart';
import 'package:glowmind/widgets/orbs/nature_orb.dart';

/// Factory widget that returns the appropriate orb for a given mood
class MoodOrbSelector extends StatelessWidget {
  final MoodType mood;
  final double size;
  final double intensity;

  const MoodOrbSelector({
    super.key,
    required this.mood,
    this.size = 280,
    this.intensity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: _buildOrb(),
    );
  }

  Widget _buildOrb() {
    switch (mood) {
      case MoodType.sleep:
        return MagneticInkOrb(
          key: const ValueKey('sleep'),
          size: size,
          intensity: intensity,
        );
      case MoodType.study:
        return MatrixOrb(
          key: const ValueKey('study'),
          size: size,
          intensity: intensity,
        );
      case MoodType.party:
        return PlasmaOrb(
          key: const ValueKey('party'),
          size: size,
          intensity: intensity,
        );
      case MoodType.meditate:
        return ZenOrb(
          key: const ValueKey('meditate'),
          size: size,
          intensity: intensity,
        );
      case MoodType.deepFocus:
        return CosmicOrb(
          key: const ValueKey('deepFocus'),
          size: size,
          intensity: intensity,
        );
      case MoodType.nature:
        return NatureOrb(
          key: const ValueKey('nature'),
          size: size,
          intensity: intensity,
        );
    }
  }
}

/// Information about each mood's orb style
class MoodOrbInfo {
  final String name;
  final String description;
  final List<Color> colors;

  const MoodOrbInfo({
    required this.name,
    required this.description,
    required this.colors,
  });

  static MoodOrbInfo getInfo(MoodType mood) {
    switch (mood) {
      case MoodType.sleep:
        return const MoodOrbInfo(
          name: 'Magnetic Ink',
          description: 'Fluid ferrofluid tendrils for deep rest',
          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1), Color(0xFF4C1D95)],
        );
      case MoodType.study:
        return const MoodOrbInfo(
          name: 'Matrix',
          description: 'Digital streams for focused learning',
          colors: [Color(0xFF3B82F6), Color(0xFF60A5FA), Color(0xFF22D3EE)],
        );
      case MoodType.party:
        return const MoodOrbInfo(
          name: 'Plasma',
          description: 'Energetic electric arcs for celebration',
          colors: [Color(0xFFEC4899), Color(0xFFF43F5E), Color(0xFFA855F7)],
        );
      case MoodType.meditate:
        return const MoodOrbInfo(
          name: 'Zen',
          description: 'Calm water ripples for inner peace',
          colors: [Color(0xFF10B981), Color(0xFF34D399), Color(0xFF6EE7B7)],
        );
      case MoodType.deepFocus:
        return const MoodOrbInfo(
          name: 'Cosmic',
          description: 'Swirling nebula for deep concentration',
          colors: [Color(0xFF06B6D4), Color(0xFF22D3EE), Color(0xFF8B5CF6)],
        );
      case MoodType.nature:
        return const MoodOrbInfo(
          name: 'Nature',
          description: 'Organic energy for natural harmony',
          colors: [Color(0xFF84CC16), Color(0xFFA3E635), Color(0xFF65A30D)],
        );
    }
  }
}
