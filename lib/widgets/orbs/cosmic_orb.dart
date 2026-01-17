import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:glowmind/widgets/orbs/base_orb.dart';

/// Cosmic Orb for Deep Focus mood
/// Features: Swirling nebula, twinkling stars, and cosmic dust
class CosmicOrb extends BaseOrb {
  const CosmicOrb({
    super.key,
    super.size = 280,
    super.intensity = 1.0,
  });

  @override
  State<CosmicOrb> createState() => _CosmicOrbState();
}

class _CosmicOrbState extends State<CosmicOrb> with TickerProviderStateMixin {
  late AnimationController _nebulaController;
  late AnimationController _starController;
  late AnimationController _pulseController;
  final List<_CosmicStar> _stars = [];
  final List<_NebulaCloud> _clouds = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _nebulaController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);

    _initializeStars();
    _initializeClouds();
  }

  void _initializeStars() {
    for (int i = 0; i < 30; i++) {
      _stars.add(_CosmicStar(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 1 + _random.nextDouble() * 2.5,
        twinkleSpeed: 1 + _random.nextDouble() * 2,
        phase: _random.nextDouble() * 2 * pi,
        color: [
          Colors.white,
          const Color(0xFF22D3EE),
          const Color(0xFF60A5FA),
          const Color(0xFFA78BFA),
        ][_random.nextInt(4)],
      ));
    }
  }

  void _initializeClouds() {
    for (int i = 0; i < 5; i++) {
      _clouds.add(_NebulaCloud(
        angle: (i / 5) * 2 * pi,
        radius: 0.15 + _random.nextDouble() * 0.25,
        size: 0.3 + _random.nextDouble() * 0.2,
        speed: 0.3 + _random.nextDouble() * 0.3,
        color: [
          const Color(0xFF06B6D4),
          const Color(0xFF3B82F6),
          const Color(0xFF8B5CF6),
          const Color(0xFFA855F7),
        ][_random.nextInt(4)],
      ));
    }
  }

  @override
  void dispose() {
    _nebulaController.dispose();
    _starController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_nebulaController, _starController, _pulseController]),
      builder: (context, child) {
        final pulse = sin(_pulseController.value * pi) * 0.5 + 0.5;
        final nebula = _nebulaController.value;
        final star = _starController.value;

        return SizedBox(
          width: widget.size * 1.4,
          height: widget.size * 1.4,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Cosmic ambient glow
              Container(
                width: widget.size * 1.35,
                height: widget.size * 1.35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.2 + pulse * 0.1),
                      blurRadius: 70 + pulse * 25,
                      spreadRadius: 15,
                    ),
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.15 + pulse * 0.08),
                      blurRadius: 110 + pulse * 35,
                      spreadRadius: 30,
                    ),
                  ],
                ),
              ),
              // Nebula clouds layer
              CustomPaint(
                size: Size(widget.size * 1.3, widget.size * 1.3),
                painter: _NebulaPainter(
                  clouds: _clouds,
                  time: nebula,
                  pulse: pulse,
                ),
              ),
              // Core orb - deep space
              Container(
                width: widget.size * (0.88 + pulse * 0.04),
                height: widget.size * (0.88 + pulse * 0.04),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.2, -0.3),
                    radius: 0.9,
                    colors: [
                      const Color(0xFF22D3EE).withValues(alpha: 0.15),
                      const Color(0xFF164E63).withValues(alpha: 0.5),
                      const Color(0xFF0C2D3A).withValues(alpha: 0.8),
                      const Color(0xFF030712),
                    ],
                    stops: const [0.0, 0.25, 0.6, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.4 + pulse * 0.2),
                      blurRadius: 25 + pulse * 12,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Stack(
                    children: [
                      // Stars inside the orb
                      CustomPaint(
                        size: Size(widget.size * 0.88, widget.size * 0.88),
                        painter: _StarfieldPainter(
                          stars: _stars,
                          time: star,
                          pulse: pulse,
                        ),
                      ),
                      // Swirling galaxy
                      CustomPaint(
                        size: Size(widget.size * 0.88, widget.size * 0.88),
                        painter: _GalaxySwirlPainter(
                          time: nebula,
                          pulse: pulse,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Orbiting ring
              Transform.rotate(
                angle: nebula * 2 * pi,
                child: Container(
                  width: widget.size * 1.05,
                  height: widget.size * 0.15,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.size),
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        const Color(0xFF22D3EE).withValues(alpha: 0.2 + pulse * 0.1),
                        const Color(0xFF06B6D4).withValues(alpha: 0.4 + pulse * 0.2),
                        const Color(0xFF22D3EE).withValues(alpha: 0.2 + pulse * 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Glass highlight
              Positioned(
                top: widget.size * 0.18,
                left: widget.size * 0.32,
                child: Container(
                  width: widget.size * 0.2,
                  height: widget.size * 0.07,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.size * 0.04),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.3 + pulse * 0.1),
                        Colors.cyan.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Bright center star
              Container(
                width: widget.size * 0.08,
                height: widget.size * 0.08,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white,
                      const Color(0xFF22D3EE).withValues(alpha: 0.8),
                      const Color(0xFF06B6D4).withValues(alpha: 0.3),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF22D3EE).withValues(alpha: 0.6 + pulse * 0.3),
                      blurRadius: 12 + pulse * 8,
                      spreadRadius: 2,
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

class _CosmicStar {
  final double x;
  final double y;
  final double size;
  final double twinkleSpeed;
  final double phase;
  final Color color;

  _CosmicStar({
    required this.x,
    required this.y,
    required this.size,
    required this.twinkleSpeed,
    required this.phase,
    required this.color,
  });
}

class _NebulaCloud {
  final double angle;
  final double radius;
  final double size;
  final double speed;
  final Color color;

  _NebulaCloud({
    required this.angle,
    required this.radius,
    required this.size,
    required this.speed,
    required this.color,
  });
}

class _NebulaPainter extends CustomPainter {
  final List<_NebulaCloud> clouds;
  final double time;
  final double pulse;

  _NebulaPainter({
    required this.clouds,
    required this.time,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (var cloud in clouds) {
      final angle = cloud.angle + time * cloud.speed * 2 * pi;
      final radius = size.width * cloud.radius;
      final cloudCenter = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );

      final paint = Paint()
        ..shader = ui.Gradient.radial(
          cloudCenter,
          size.width * cloud.size,
          [
            cloud.color.withValues(alpha: 0.2 + pulse * 0.1),
            cloud.color.withValues(alpha: 0.08 + pulse * 0.04),
            Colors.transparent,
          ],
          [0.0, 0.5, 1.0],
        );

      canvas.drawCircle(cloudCenter, size.width * cloud.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NebulaPainter oldDelegate) =>
      time != oldDelegate.time || pulse != oldDelegate.pulse;
}

class _StarfieldPainter extends CustomPainter {
  final List<_CosmicStar> stars;
  final double time;
  final double pulse;

  _StarfieldPainter({
    required this.stars,
    required this.time,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var star in stars) {
      final twinkle = (sin(time * star.twinkleSpeed * 2 * pi + star.phase) + 1) / 2;
      final alpha = 0.3 + twinkle * 0.7;
      final starSize = star.size * (0.7 + twinkle * 0.3);

      final paint = Paint()
        ..color = star.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      final position = Offset(star.x * size.width, star.y * size.height);
      canvas.drawCircle(position, starSize, paint);

      // Star glow
      if (starSize > 2) {
        final glowPaint = Paint()
          ..color = star.color.withValues(alpha: alpha * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(position, starSize * 2, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) =>
      time != oldDelegate.time || pulse != oldDelegate.pulse;
}

class _GalaxySwirlPainter extends CustomPainter {
  final double time;
  final double pulse;

  _GalaxySwirlPainter({required this.time, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Spiral arms
    for (int arm = 0; arm < 3; arm++) {
      final path = Path();
      final baseAngle = (arm / 3) * 2 * pi + time * pi * 0.3;

      for (double t = 0; t <= 1; t += 0.02) {
        final spiralAngle = baseAngle + t * 3 * pi;
        final radius = t * size.width * 0.35;
        final x = center.dx + cos(spiralAngle) * radius;
        final y = center.dy + sin(spiralAngle) * radius;

        if (t == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      final paint = Paint()
        ..shader = ui.Gradient.linear(
          center,
          Offset(center.dx + size.width * 0.35, center.dy),
          [
            const Color(0xFF22D3EE).withValues(alpha: 0.3 * pulse),
            const Color(0xFF8B5CF6).withValues(alpha: 0.2 * pulse),
            Colors.transparent,
          ],
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GalaxySwirlPainter oldDelegate) =>
      time != oldDelegate.time || pulse != oldDelegate.pulse;
}
