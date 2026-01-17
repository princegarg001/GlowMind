import 'dart:math';
import 'package:flutter/material.dart';

/// Base class for all mood orbs providing common functionality
abstract class BaseOrb extends StatefulWidget {
  final double size;
  final double intensity;

  const BaseOrb({
    super.key,
    this.size = 280,
    this.intensity = 1.0,
  });
}

/// Utility class for orb calculations and common effects
class OrbUtils {
  static final Random random = Random();

  /// Generate smooth noise value
  static double smoothNoise(double t, double seed) {
    return sin(t * 2.1 + seed) * 0.3 +
        sin(t * 3.7 + seed * 1.3) * 0.2 +
        sin(t * 5.3 + seed * 0.7) * 0.1;
  }

  /// Create 3D sphere shading gradient
  static RadialGradient create3DGradient({
    required Color primaryColor,
    required Color secondaryColor,
    Alignment center = const Alignment(-0.3, -0.4),
    double highlightIntensity = 0.4,
  }) {
    return RadialGradient(
      center: center,
      radius: 0.85,
      colors: [
        Colors.white.withValues(alpha: highlightIntensity),
        primaryColor.withValues(alpha: 0.9),
        secondaryColor.withValues(alpha: 0.7),
        primaryColor.withValues(alpha: 0.4),
        Colors.black.withValues(alpha: 0.3),
      ],
      stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
    );
  }

  /// Create inner glow effect
  static BoxShadow innerGlow(Color color, double intensity, double blur) {
    return BoxShadow(
      color: color.withValues(alpha: intensity),
      blurRadius: blur,
      spreadRadius: blur * 0.3,
    );
  }

  /// Create outer glow layers
  static List<BoxShadow> outerGlowLayers(
    Color primary,
    Color secondary,
    double pulse,
  ) {
    return [
      BoxShadow(
        color: primary.withValues(alpha: 0.5 + pulse * 0.3),
        blurRadius: 30 + pulse * 20,
        spreadRadius: 5 + pulse * 5,
      ),
      BoxShadow(
        color: secondary.withValues(alpha: 0.3 + pulse * 0.2),
        blurRadius: 60 + pulse * 30,
        spreadRadius: 10 + pulse * 10,
      ),
      BoxShadow(
        color: primary.withValues(alpha: 0.15 + pulse * 0.1),
        blurRadius: 100 + pulse * 40,
        spreadRadius: 20 + pulse * 15,
      ),
    ];
  }
}

/// Particle data for particle-based orbs
class OrbParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double alpha;
  double life;
  Color color;

  OrbParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.alpha,
    required this.life,
    required this.color,
  });

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    life -= dt * 0.5;
    alpha = (life).clamp(0.0, 1.0);
  }

  bool get isDead => life <= 0;
}
