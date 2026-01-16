import 'dart:math';
import 'package:flutter/material.dart';
import 'package:glowmind/models/models.dart';
import 'package:glowmind/theme.dart';

/// Ambient animated gradient background responding to GlowState
class GlowBackground extends StatefulWidget {
  final GlowState glow;
  final Widget child;
  const GlowBackground({super.key, required this.glow, required this.child});

  @override
  State<GlowBackground> createState() => _GlowBackgroundState();
}

class _GlowBackgroundState extends State<GlowBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Color a;
    Color b;
    switch (widget.glow.mood) {
      case GlowMood.balanced:
        a = AppGlowColors.purple; b = AppGlowColors.blue;
        break;
      case GlowMood.burnoutRisk:
        a = AppGlowColors.blueGrey; b = AppGlowColors.grey;
        break;
      case GlowMood.anxious:
        a = AppGlowColors.purpleAccent; b = AppGlowColors.blueAccent;
        break;
    }

    final intensity = widget.glow.intensity.clamp(0.0, 1.0);
    final pulse = widget.glow.pulse.clamp(0.05, 2.0);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        // Pulsing opacity between 0.7 and 1.0 scaled by intensity
        final pulsePhase = 0.85 + 0.15 * sin(2 * pi * pulse * t);
        final op = (0.6 + 0.4 * intensity) * pulsePhase;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.0, -0.3),
              radius: 1.2,
              colors: [
                a.withValues(alpha: op),
                b.withValues(alpha: op * 0.8),
                scheme.surface,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}
