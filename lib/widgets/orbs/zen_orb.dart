import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:glowmind/widgets/orbs/base_orb.dart';

/// Zen Orb for Meditate mood
/// Features: Calm water ripples with lotus petal energy emanating outward
class ZenOrb extends BaseOrb {
  const ZenOrb({
    super.key,
    super.size = 280,
    super.intensity = 1.0,
  });

  @override
  State<ZenOrb> createState() => _ZenOrbState();
}

class _ZenOrbState extends State<ZenOrb> with TickerProviderStateMixin {
  late AnimationController _rippleController;
  late AnimationController _breathController;
  late AnimationController _petalController;
  final List<_WaterRipple> _ripples = [];

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat(reverse: true);

    _petalController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _initializeRipples();
  }

  void _initializeRipples() {
    for (int i = 0; i < 4; i++) {
      _ripples.add(_WaterRipple(
        delay: i * 0.25,
        maxRadius: 0.9 + (i * 0.05),
      ));
    }
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _breathController.dispose();
    _petalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rippleController, _breathController, _petalController]),
      builder: (context, child) {
        final breath = sin(_breathController.value * pi) * 0.5 + 0.5;
        final ripple = _rippleController.value;
        final petal = _petalController.value;

        return SizedBox(
          width: widget.size * 1.5,
          height: widget.size * 1.5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Soft ambient glow
              Container(
                width: widget.size * 1.4,
                height: widget.size * 1.4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2 + breath * 0.1),
                      blurRadius: 80 + breath * 20,
                      spreadRadius: 20,
                    ),
                    BoxShadow(
                      color: const Color(0xFF34D399).withValues(alpha: 0.12 + breath * 0.08),
                      blurRadius: 120 + breath * 30,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
              // Water ripples
              CustomPaint(
                size: Size(widget.size * 1.4, widget.size * 1.4),
                painter: _WaterRipplePainter(
                  ripples: _ripples,
                  time: ripple,
                  breath: breath,
                ),
              ),
              // Lotus petals energy
              CustomPaint(
                size: Size(widget.size * 1.2, widget.size * 1.2),
                painter: _LotusPetalPainter(
                  time: petal,
                  breath: breath,
                ),
              ),
              // Core orb - water drop appearance
              Container(
                width: widget.size * (0.85 + breath * 0.05),
                height: widget.size * (0.85 + breath * 0.05),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.25, -0.35),
                    radius: 0.85,
                    colors: [
                      Colors.white.withValues(alpha: 0.35),
                      const Color(0xFF34D399).withValues(alpha: 0.4),
                      const Color(0xFF10B981).withValues(alpha: 0.6),
                      const Color(0xFF064E3B).withValues(alpha: 0.85),
                      const Color(0xFF022C22),
                    ],
                    stops: const [0.0, 0.2, 0.4, 0.7, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.4 + breath * 0.2),
                      blurRadius: 25 + breath * 15,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: CustomPaint(
                    size: Size(widget.size * 0.85, widget.size * 0.85),
                    painter: _ZenWaterPainter(
                      time: ripple,
                      breath: breath,
                    ),
                  ),
                ),
              ),
              // Glass highlight
              Positioned(
                top: widget.size * 0.2,
                left: widget.size * 0.35,
                child: Container(
                  width: widget.size * 0.18,
                  height: widget.size * 0.08,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.size * 0.04),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.4 + breath * 0.1),
                        Colors.white.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Inner zen symbol (Om-inspired)
              CustomPaint(
                size: Size(widget.size * 0.25, widget.size * 0.25),
                painter: _ZenSymbolPainter(
                  breath: breath,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WaterRipple {
  final double delay;
  final double maxRadius;

  _WaterRipple({required this.delay, required this.maxRadius});
}

class _WaterRipplePainter extends CustomPainter {
  final List<_WaterRipple> ripples;
  final double time;
  final double breath;

  _WaterRipplePainter({
    required this.ripples,
    required this.time,
    required this.breath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (var ripple in ripples) {
      final progress = (time + ripple.delay) % 1.0;
      final radius = size.width * 0.2 + progress * size.width * ripple.maxRadius * 0.3;
      final alpha = (1.0 - progress) * (0.4 + breath * 0.2);

      final paint = Paint()
        ..color = const Color(0xFF34D399).withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * (1 - progress * 0.5);

      canvas.drawCircle(center, radius, paint);

      // Secondary inner ripple
      if (progress > 0.1) {
        final innerPaint = Paint()
          ..color = const Color(0xFF10B981).withValues(alpha: alpha * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 * (1 - progress * 0.5);
        canvas.drawCircle(center, radius * 0.85, innerPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WaterRipplePainter oldDelegate) =>
      time != oldDelegate.time || breath != oldDelegate.breath;
}

class _LotusPetalPainter extends CustomPainter {
  final double time;
  final double breath;

  _LotusPetalPainter({required this.time, required this.breath});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final petalCount = 8;

    for (int i = 0; i < petalCount; i++) {
      final angle = (i / petalCount) * 2 * pi + time * 0.5 * pi;
      final openness = 0.7 + breath * 0.3;

      final path = Path();
      final baseRadius = size.width * 0.25;
      final petalLength = size.width * 0.15 * openness;

      // Petal shape using bezier curves
      final start = Offset(
        center.dx + cos(angle) * baseRadius,
        center.dy + sin(angle) * baseRadius,
      );

      final tip = Offset(
        center.dx + cos(angle) * (baseRadius + petalLength),
        center.dy + sin(angle) * (baseRadius + petalLength),
      );

      final ctrl1 = Offset(
        center.dx + cos(angle - 0.2) * (baseRadius + petalLength * 0.7),
        center.dy + sin(angle - 0.2) * (baseRadius + petalLength * 0.7),
      );

      final ctrl2 = Offset(
        center.dx + cos(angle + 0.2) * (baseRadius + petalLength * 0.7),
        center.dy + sin(angle + 0.2) * (baseRadius + petalLength * 0.7),
      );

      path.moveTo(start.dx, start.dy);
      path.quadraticBezierTo(ctrl1.dx, ctrl1.dy, tip.dx, tip.dy);
      path.quadraticBezierTo(ctrl2.dx, ctrl2.dy, start.dx, start.dy);

      final alpha = 0.15 + sin(time * 2 * pi + i) * 0.1 + breath * 0.1;

      final paint = Paint()
        ..shader = ui.Gradient.linear(
          start,
          tip,
          [
            const Color(0xFF34D399).withValues(alpha: alpha),
            const Color(0xFF10B981).withValues(alpha: alpha * 0.5),
          ],
        )
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, paint);

      // Petal edge glow
      final edgePaint = Paint()
        ..color = const Color(0xFF6EE7B7).withValues(alpha: alpha * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawPath(path, edgePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LotusPetalPainter oldDelegate) =>
      time != oldDelegate.time || breath != oldDelegate.breath;
}

class _ZenWaterPainter extends CustomPainter {
  final double time;
  final double breath;

  _ZenWaterPainter({required this.time, required this.breath});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Inner water waves
    for (int wave = 0; wave < 4; wave++) {
      final path = Path();
      final yOffset = size.height * (0.3 + wave * 0.15);
      final amplitude = 8 + breath * 4;
      final phase = time * 2 * pi + wave * pi / 4;

      path.moveTo(0, yOffset);

      for (double x = 0; x <= size.width; x += 5) {
        final y = yOffset + sin(x / 30 + phase) * amplitude;
        path.lineTo(x, y);
      }

      final paint = Paint()
        ..color = const Color(0xFF34D399).withValues(alpha: 0.08 + breath * 0.04)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawPath(path, paint);
    }

    // Floating particles
    for (int p = 0; p < 12; p++) {
      final angle = (p / 12) * 2 * pi + time * pi;
      final radius = size.width * 0.2 * (0.3 + sin(time * 3 * pi + p) * 0.4);
      final particleAlpha = 0.3 + sin(time * 4 * pi + p) * 0.2;

      final particlePaint = Paint()
        ..color = const Color(0xFF6EE7B7).withValues(alpha: particleAlpha * breath);

      canvas.drawCircle(
        Offset(center.dx + cos(angle) * radius, center.dy + sin(angle) * radius),
        2 + breath,
        particlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ZenWaterPainter oldDelegate) =>
      time != oldDelegate.time || breath != oldDelegate.breath;
}

class _ZenSymbolPainter extends CustomPainter {
  final double breath;

  _ZenSymbolPainter({required this.breath});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    // Simple enso (zen circle) that's slightly open
    final paint = Paint()
      ..color = const Color(0xFF6EE7B7).withValues(alpha: 0.4 + breath * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi * 0.1,
      pi * 1.8,
      false,
      paint,
    );

    // Center dot
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6 + breath * 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 3 + breath * 2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _ZenSymbolPainter oldDelegate) =>
      breath != oldDelegate.breath;
}
