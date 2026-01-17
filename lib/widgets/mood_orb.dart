import 'dart:math';
import 'package:flutter/material.dart';
import 'package:glowmind/models/music_models.dart';

/// Enhanced heartbeat mood orb with realistic pulse animation
class MoodOrb extends StatefulWidget {
  final MoodType mood;
  final double size;
  final double pulseSpeed;

  const MoodOrb({
    super.key,
    required this.mood,
    this.size = 280,
    this.pulseSpeed = 1.0,
  });

  @override
  State<MoodOrb> createState() => _MoodOrbState();
}

class _MoodOrbState extends State<MoodOrb> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (2000 / widget.pulseSpeed).round()),
    )..repeat();
  }

  @override
  void didUpdateWidget(MoodOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pulseSpeed != widget.pulseSpeed) {
      _controller.duration = Duration(milliseconds: (2000 / widget.pulseSpeed).round());
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
        return const Color(0xFF8B5CF6);
      case MoodType.study:
        return const Color(0xFF3B82F6);
      case MoodType.party:
        return const Color(0xFFEC4899);
      case MoodType.meditate:
        return const Color(0xFF10B981);
      case MoodType.deepFocus:
        return const Color(0xFF06B6D4);
      case MoodType.nature:
        return const Color(0xFF84CC16);
    }
  }

  /// Get secondary color for gradient
  Color _getSecondaryColor() {
    switch (widget.mood) {
      case MoodType.sleep:
        return const Color(0xFF6366F1);
      case MoodType.study:
        return const Color(0xFF60A5FA);
      case MoodType.party:
        return const Color(0xFFF43F5E);
      case MoodType.meditate:
        return const Color(0xFF34D399);
      case MoodType.deepFocus:
        return const Color(0xFF22D3EE);
      case MoodType.nature:
        return const Color(0xFFA3E635);
    }
  }

  /// Heartbeat-like sine wave pattern
  double _heartbeatPulse(double t) {
    // Creates a heartbeat pattern: quick pulse, brief pause, quick pulse, longer pause
    final phase = (t * 2 * pi) % (2 * pi);
    
    // First beat
    if (phase < pi * 0.3) {
      return sin(phase / 0.3 * pi) * 0.8;
    }
    // Brief pause
    if (phase < pi * 0.5) {
      return 0;
    }
    // Second beat (slightly smaller)
    if (phase < pi * 0.8) {
      return sin((phase - pi * 0.5) / 0.3 * pi) * 0.5;
    }
    // Rest period
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _getMoodColor();
    final secondaryColor = _getSecondaryColor();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = _heartbeatPulse(_controller.value);
        final scale = 1.0 + (pulse * 0.08);
        final glowIntensity = 0.4 + (pulse * 0.4);
        final size = widget.size * scale;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.2, -0.2),
              radius: 0.8,
              colors: [
                primaryColor.withValues(alpha: 0.7 + pulse * 0.2),
                secondaryColor.withValues(alpha: 0.4 + pulse * 0.1),
                primaryColor.withValues(alpha: 0.2),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            boxShadow: [
              // Inner glow
              BoxShadow(
                color: primaryColor.withValues(alpha: glowIntensity),
                blurRadius: 40 + 30 * pulse,
                spreadRadius: 5 + 10 * pulse,
              ),
              // Outer glow
              BoxShadow(
                color: secondaryColor.withValues(alpha: glowIntensity * 0.6),
                blurRadius: 80 + 40 * pulse,
                spreadRadius: 10 + 20 * pulse,
              ),
              // Ambient glow
              BoxShadow(
                color: primaryColor.withValues(alpha: glowIntensity * 0.3),
                blurRadius: 120 + 60 * pulse,
                spreadRadius: 20 + 30 * pulse,
              ),
            ],
          ),
          child: Container(
            margin: EdgeInsets.all(size * 0.15),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.3),
                radius: 0.7,
                colors: [
                  Colors.white.withValues(alpha: 0.3 + pulse * 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
