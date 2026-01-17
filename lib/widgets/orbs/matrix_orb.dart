import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:glowmind/widgets/orbs/base_orb.dart';

/// Matrix Orb for Study mood
/// Features: Digital rain cascading effect with glowing code streams
class MatrixOrb extends BaseOrb {
  const MatrixOrb({
    super.key,
    super.size = 280,
    super.intensity = 1.0,
  });

  @override
  State<MatrixOrb> createState() => _MatrixOrbState();
}

class _MatrixOrbState extends State<MatrixOrb> with TickerProviderStateMixin {
  late AnimationController _rainController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  final List<_CodeStream> _streams = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _rainController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _initializeStreams();
  }

  void _initializeStreams() {
    for (int i = 0; i < 16; i++) {
      _streams.add(_CodeStream(
        angle: (i / 16) * 2 * pi,
        speed: 0.3 + _random.nextDouble() * 0.4,
        length: 0.4 + _random.nextDouble() * 0.3,
        phase: _random.nextDouble(),
        charCount: 4 + _random.nextInt(6),
      ));
    }
  }

  @override
  void dispose() {
    _rainController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rainController, _pulseController, _rotationController]),
      builder: (context, child) {
        final pulse = sin(_pulseController.value * pi) * 0.5 + 0.5;
        final rain = _rainController.value;
        final rotation = _rotationController.value * 2 * pi;

        return SizedBox(
          width: widget.size * 1.4,
          height: widget.size * 1.4,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer digital glow
              Container(
                width: widget.size * 1.3,
                height: widget.size * 1.3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.25 + pulse * 0.15),
                      blurRadius: 70 + pulse * 25,
                      spreadRadius: 15,
                    ),
                    BoxShadow(
                      color: const Color(0xFF22D3EE).withValues(alpha: 0.15 + pulse * 0.1),
                      blurRadius: 100 + pulse * 35,
                      spreadRadius: 30,
                    ),
                  ],
                ),
              ),
              // Rotating code streams
              Transform.rotate(
                angle: rotation * 0.1,
                child: CustomPaint(
                  size: Size(widget.size * 1.3, widget.size * 1.3),
                  painter: _MatrixStreamPainter(
                    streams: _streams,
                    time: rain,
                    pulse: pulse,
                  ),
                ),
              ),
              // Core sphere with digital texture
              Container(
                width: widget.size * (0.88 + pulse * 0.04),
                height: widget.size * (0.88 + pulse * 0.04),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.2, -0.3),
                    radius: 0.85,
                    colors: [
                      const Color(0xFF60A5FA).withValues(alpha: 0.25),
                      const Color(0xFF1E3A8A).withValues(alpha: 0.7),
                      const Color(0xFF0F172A).withValues(alpha: 0.9),
                      const Color(0xFF020617),
                    ],
                    stops: const [0.0, 0.3, 0.65, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.5 + pulse * 0.2),
                      blurRadius: 20 + pulse * 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: CustomPaint(
                    size: Size(widget.size * 0.88, widget.size * 0.88),
                    painter: _DigitalGridPainter(
                      time: rain,
                      pulse: pulse,
                      rotation: rotation,
                    ),
                  ),
                ),
              ),
              // Holographic highlight
              Positioned(
                top: widget.size * 0.18,
                left: widget.size * 0.3,
                child: Container(
                  width: widget.size * 0.22,
                  height: widget.size * 0.08,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.size * 0.05),
                    gradient: LinearGradient(
                      colors: [
                        Colors.cyan.withValues(alpha: 0.25 + pulse * 0.1),
                        Colors.blue.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // Center data core
              Container(
                width: widget.size * 0.15,
                height: widget.size * 0.15,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.9),
                      const Color(0xFF60A5FA).withValues(alpha: 0.7),
                      const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF60A5FA).withValues(alpha: 0.6 + pulse * 0.3),
                      blurRadius: 15 + pulse * 10,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CodeStream {
  final double angle;
  final double speed;
  final double length;
  final double phase;
  final int charCount;

  _CodeStream({
    required this.angle,
    required this.speed,
    required this.length,
    required this.phase,
    required this.charCount,
  });
}

class _MatrixStreamPainter extends CustomPainter {
  final List<_CodeStream> streams;
  final double time;
  final double pulse;

  _MatrixStreamPainter({
    required this.streams,
    required this.time,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.34;

    for (var stream in streams) {
      final progress = (time * stream.speed + stream.phase) % 1.0;
      
      for (int i = 0; i < stream.charCount; i++) {
        final charProgress = (progress + i * 0.08) % 1.0;
        final radius = baseRadius + charProgress * size.width * stream.length * 0.25;
        
        if (radius > size.width * 0.48) continue;

        final alpha = (1.0 - charProgress) * (i == 0 ? 1.0 : 0.6);
        final charSize = 4.0 + (1 - charProgress) * 4;

        final x = center.dx + cos(stream.angle) * radius;
        final y = center.dy + sin(stream.angle) * radius;

        final paint = Paint()
          ..color = Color.lerp(
            const Color(0xFF22D3EE),
            const Color(0xFF3B82F6),
            charProgress,
          )!.withValues(alpha: alpha * (0.6 + pulse * 0.4))
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(x, y), charSize, paint);

        // Glow trail
        if (i == 0) {
          final glowPaint = Paint()
            ..color = const Color(0xFF60A5FA).withValues(alpha: 0.3 * alpha)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
          canvas.drawCircle(Offset(x, y), charSize * 2, glowPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MatrixStreamPainter oldDelegate) =>
      time != oldDelegate.time || pulse != oldDelegate.pulse;
}

class _DigitalGridPainter extends CustomPainter {
  final double time;
  final double pulse;
  final double rotation;

  _DigitalGridPainter({
    required this.time,
    required this.pulse,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.45;

    // Draw concentric data rings
    for (int ring = 0; ring < 5; ring++) {
      final ringRadius = maxRadius * (0.2 + ring * 0.18);
      final segments = 12 + ring * 4;
      final ringRotation = rotation * (ring.isEven ? 1 : -1) * 0.5;

      for (int seg = 0; seg < segments; seg++) {
        final startAngle = (seg / segments) * 2 * pi + ringRotation;
        final sweepAngle = (1 / segments) * 2 * pi * 0.7;
        final brightness = sin(time * 4 * pi + seg + ring) * 0.5 + 0.5;

        final paint = Paint()
          ..color = const Color(0xFF3B82F6).withValues(alpha: 0.1 + brightness * 0.2 * pulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: ringRadius),
          startAngle,
          sweepAngle,
          false,
          paint,
        );
      }
    }

    // Radial scan lines
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * pi + time * pi;
      final alpha = sin(time * 6 * pi + i) * 0.3 + 0.3;

      final paint = Paint()
        ..shader = ui.Gradient.linear(
          center,
          Offset(
            center.dx + cos(angle) * maxRadius,
            center.dy + sin(angle) * maxRadius,
          ),
          [
            const Color(0xFF60A5FA).withValues(alpha: 0),
            const Color(0xFF60A5FA).withValues(alpha: alpha * pulse),
            const Color(0xFF60A5FA).withValues(alpha: 0),
          ],
          [0.0, 0.5, 1.0],
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawLine(
        center,
        Offset(center.dx + cos(angle) * maxRadius, center.dy + sin(angle) * maxRadius),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DigitalGridPainter oldDelegate) =>
      time != oldDelegate.time || pulse != oldDelegate.pulse || rotation != oldDelegate.rotation;
}
