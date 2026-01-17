import 'dart:math';
import 'package:flutter/material.dart';
import 'package:glowmind/models/music_models.dart';

/// High-performance animated background that responds to scroll position
/// Uses custom painter for smooth 60fps animations with color interpolation
class InteractiveGlowBackground extends StatefulWidget {
  final MoodType currentMood;
  final MoodType nextMood;
  final double scrollProgress; // 0.0 to 1.0

  const InteractiveGlowBackground({
    super.key,
    required this.currentMood,
    required this.nextMood,
    required this.scrollProgress,
  });

  @override
  State<InteractiveGlowBackground> createState() => _InteractiveGlowBackgroundState();
}

class _InteractiveGlowBackgroundState extends State<InteractiveGlowBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          return CustomPaint(
            painter: _GlowBackgroundPainter(
              currentMood: widget.currentMood,
              nextMood: widget.nextMood,
              scrollProgress: widget.scrollProgress,
              animationValue: _animController.value,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

/// Custom painter for performant gradient rendering
class _GlowBackgroundPainter extends CustomPainter {
  final MoodType currentMood;
  final MoodType nextMood;
  final double scrollProgress;
  final double animationValue;

  // Cached mood colors for performance
  static final Map<MoodType, _MoodColorPalette> _colorCache = {
    MoodType.sleep: _MoodColorPalette(
      primary: const Color(0xFF6B4BA3),
      secondary: const Color(0xFF2D1B4E),
      accent: const Color(0xFF1A0F3D),
      glow: const Color(0xFF8B6BC7),
    ),
    MoodType.study: _MoodColorPalette(
      primary: const Color(0xFF3B82F6),
      secondary: const Color(0xFF1E3A8A),
      accent: const Color(0xFF0F172A),
      glow: const Color(0xFF60A5FA),
    ),
    MoodType.party: _MoodColorPalette(
      primary: const Color(0xFFEC4899),
      secondary: const Color(0xFF831843),
      accent: const Color(0xFF3F0F1F),
      glow: const Color(0xFFF472B6),
    ),
    MoodType.meditate: _MoodColorPalette(
      primary: const Color(0xFF10B981),
      secondary: const Color(0xFF064E3B),
      accent: const Color(0xFF022C22),
      glow: const Color(0xFF34D399),
    ),
    MoodType.deepFocus: _MoodColorPalette(
      primary: const Color(0xFF06B6D4),
      secondary: const Color(0xFF164E63),
      accent: const Color(0xFF0C2D3A),
      glow: const Color(0xFF22D3EE),
    ),
    MoodType.nature: _MoodColorPalette(
      primary: const Color(0xFF84CC16),
      secondary: const Color(0xFF3F6212),
      accent: const Color(0xFF1F3108),
      glow: const Color(0xFFA3E635),
    ),
  };

  _GlowBackgroundPainter({
    required this.currentMood,
    required this.nextMood,
    required this.scrollProgress,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final currentPalette = _colorCache[currentMood]!;
    final nextPalette = _colorCache[nextMood]!;

    // Smooth easing for scroll interpolation
    final easedProgress = _easeInOutCubic(scrollProgress);

    // Blend colors based on scroll progress
    final blendedPrimary = Color.lerp(currentPalette.primary, nextPalette.primary, easedProgress)!;
    final blendedSecondary = Color.lerp(currentPalette.secondary, nextPalette.secondary, easedProgress)!;
    final blendedAccent = Color.lerp(currentPalette.accent, nextPalette.accent, easedProgress)!;
    final blendedGlow = Color.lerp(currentPalette.glow, nextPalette.glow, easedProgress)!;

    // Paint base gradient
    final baseGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [blendedSecondary, blendedAccent],
    );

    final basePaint = Paint()
      ..shader = baseGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    // Animated floating orbs with glow
    _drawAnimatedOrbs(canvas, size, blendedPrimary, blendedGlow, blendedSecondary);

    // Subtle noise/grain overlay for depth
    _drawSubtleVignette(canvas, size, blendedAccent);
  }

  void _drawAnimatedOrbs(Canvas canvas, Size size, Color primary, Color glow, Color secondary) {
    final centerX = size.width / 2;
    final centerY = size.height * 0.35;

    // Main ambient glow - breathing effect
    final breathPhase = sin(animationValue * 2 * pi) * 0.15 + 0.85;
    final mainGlowRadius = size.width * 0.8 * breathPhase;

    final mainGlowGradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        glow.withValues(alpha: 0.25 * breathPhase),
        glow.withValues(alpha: 0.1 * breathPhase),
        primary.withValues(alpha: 0.05),
        Colors.transparent,
      ],
      stops: const [0.0, 0.3, 0.6, 1.0],
    );

    final mainGlowPaint = Paint()
      ..shader = mainGlowGradient.createShader(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: mainGlowRadius),
      );

    canvas.drawCircle(Offset(centerX, centerY), mainGlowRadius, mainGlowPaint);

    // Secondary floating orbs - phase shifted animations
    _drawFloatingOrb(
      canvas: canvas,
      size: size,
      baseX: centerX - size.width * 0.25,
      baseY: centerY - size.height * 0.1,
      color: secondary,
      phase: animationValue,
      radius: size.width * 0.15,
      amplitude: 20,
    );

    _drawFloatingOrb(
      canvas: canvas,
      size: size,
      baseX: centerX + size.width * 0.3,
      baseY: centerY + size.height * 0.05,
      color: primary,
      phase: animationValue + 0.33,
      radius: size.width * 0.12,
      amplitude: 15,
    );

    _drawFloatingOrb(
      canvas: canvas,
      size: size,
      baseX: centerX,
      baseY: centerY + size.height * 0.2,
      color: glow,
      phase: animationValue + 0.66,
      radius: size.width * 0.1,
      amplitude: 25,
    );
  }

  void _drawFloatingOrb({
    required Canvas canvas,
    required Size size,
    required double baseX,
    required double baseY,
    required Color color,
    required double phase,
    required double radius,
    required double amplitude,
  }) {
    final offsetX = sin(phase * 2 * pi) * amplitude;
    final offsetY = cos(phase * 2 * pi * 0.7) * amplitude * 0.5;
    final pulseScale = 0.9 + sin(phase * 4 * pi) * 0.1;

    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        color.withValues(alpha: 0.15),
        color.withValues(alpha: 0.05),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(
          center: Offset(baseX + offsetX, baseY + offsetY),
          radius: radius * pulseScale,
        ),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawCircle(
      Offset(baseX + offsetX, baseY + offsetY),
      radius * pulseScale,
      paint,
    );
  }

  void _drawSubtleVignette(Canvas canvas, Size size, Color accent) {
    final vignetteGradient = RadialGradient(
      center: Alignment.center,
      radius: 1.2,
      colors: [
        Colors.transparent,
        accent.withValues(alpha: 0.3),
      ],
      stops: const [0.5, 1.0],
    );

    final vignettePaint = Paint()
      ..shader = vignetteGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vignettePaint);
  }

  double _easeInOutCubic(double t) {
    return t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2;
  }

  @override
  bool shouldRepaint(_GlowBackgroundPainter oldDelegate) =>
      currentMood != oldDelegate.currentMood ||
      nextMood != oldDelegate.nextMood ||
      scrollProgress != oldDelegate.scrollProgress ||
      animationValue != oldDelegate.animationValue;
}

/// Color palette for each mood
class _MoodColorPalette {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color glow;

  const _MoodColorPalette({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.glow,
  });
}
