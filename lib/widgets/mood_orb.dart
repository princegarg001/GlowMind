import 'dart:math';
import 'package:flutter/material.dart';
import 'package:glowmind/models/music_models.dart';

/// Animated mood orb with color and pulse animation based on mood
class MoodOrb extends StatefulWidget {
  final MoodType mood;
  final double size;
  final double pulseSpeed;

  const MoodOrb({
    super.key,
    required this.mood,
    this.size = 220,
    this.pulseSpeed = 1.0,
  });

  @override
  State<MoodOrb> createState() => _MoodOrbState();
}

class _MoodOrbState extends State<MoodOrb> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (6000 / widget.pulseSpeed).round()),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(MoodOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pulseSpeed != widget.pulseSpeed) {
      _controller.duration = Duration(milliseconds: (6000 / widget.pulseSpeed).round());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Get primary color for the mood
  Color _getMoodColor() {
    switch (widget.mood) {
      case MoodType.sleep:
        return const Color(0xFF8B5CF6); // Purple
      case MoodType.study:
        return const Color(0xFF3B82F6); // Blue
      case MoodType.party:
        return const Color(0xFFEC4899); // Pink
      case MoodType.meditate:
        return const Color(0xFF10B981); // Green
      case MoodType.deepFocus:
        return const Color(0xFF06B6D4); // Cyan
      case MoodType.nature:
        return const Color(0xFF84CC16); // Earth green
    }
  }

  /// Get secondary color for gradient
  Color _getSecondaryColor() {
    switch (widget.mood) {
      case MoodType.sleep:
        return const Color(0xFF6366F1); // Indigo
      case MoodType.study:
        return const Color(0xFF60A5FA); // Light blue
      case MoodType.party:
        return const Color(0xFFF43F5E); // Red
      case MoodType.meditate:
        return const Color(0xFF34D399); // Light green
      case MoodType.deepFocus:
        return const Color(0xFF22D3EE); // Light cyan
      case MoodType.nature:
        return const Color(0xFFA3E635); // Lime
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _getMoodColor();
    final secondaryColor = _getSecondaryColor();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final scale = 0.85 + 0.15 * sin(_animation.value * pi);
        final size = widget.size * scale;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                primaryColor.withOpacity(0.6),
                secondaryColor.withOpacity(0.3),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.6 * _animation.value),
                blurRadius: 60 + 40 * _animation.value,
                spreadRadius: 10 + 10 * _animation.value,
              ),
              BoxShadow(
                color: secondaryColor.withOpacity(0.4 * _animation.value),
                blurRadius: 40 + 20 * _animation.value,
                spreadRadius: 5 + 5 * _animation.value,
              ),
            ],
          ),
        );
      },
    );
  }
}
