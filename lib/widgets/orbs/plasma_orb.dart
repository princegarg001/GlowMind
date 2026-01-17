import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:glowmind/widgets/orbs/base_orb.dart';

/// Plasma Orb for Party mood
/// Features: Energetic, colorful plasma tendrils with electric arcs
class PlasmaOrb extends BaseOrb {
  const PlasmaOrb({
    super.key,
    super.size = 280,
    super.intensity = 1.0,
  });

  @override
  State<PlasmaOrb> createState() => _PlasmaOrbState();
}

class _PlasmaOrbState extends State<PlasmaOrb> with TickerProviderStateMixin {
  late AnimationController _plasmaController;
  late AnimationController _pulseController;
  late AnimationController _colorController;
  final List<_PlasmaTendril> _tendrils = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _plasmaController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _initializeTendrils();
  }

  void _initializeTendrils() {
    for (int i = 0; i < 12; i++) {
      _tendrils.add(_PlasmaTendril(
        baseAngle: (i / 12) * 2 * pi,
        amplitude: 0.3 + _random.nextDouble() * 0.3,
        frequency: 2 + _random.nextDouble() * 2,
        phase: _random.nextDouble() * 2 * pi,
        thickness: 4 + _random.nextDouble() * 4,
      ));
    }
  }

  @override
  void dispose() {
    _plasmaController.dispose();
    _pulseController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Color _getPlasmaColor(double t) {
    final colors = [
      const Color(0xFFEC4899), // Pink
      const Color(0xFFF43F5E), // Rose
      const Color(0xFFF97316), // Orange
      const Color(0xFFEAB308), // Yellow
      const Color(0xFFA855F7), // Purple
      const Color(0xFFEC4899), // Pink (loop)
    ];

    final index = (t * (colors.length - 1)).floor();
    final localT = (t * (colors.length - 1)) - index;
    return Color.lerp(colors[index], colors[(index + 1) % colors.length], localT)!;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_plasmaController, _pulseController, _colorController]),
      builder: (context, child) {
        final pulse = sin(_pulseController.value * pi) * 0.5 + 0.5;
        final plasma = _plasmaController.value;
        final colorPhase = _colorController.value;
        final currentColor = _getPlasmaColor(colorPhase);

        return SizedBox(
          width: widget.size * 1.5,
          height: widget.size * 1.5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer electric glow
              Container(
                width: widget.size * 1.4,
                height: widget.size * 1.4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: currentColor.withValues(alpha: 0.3 + pulse * 0.2),
                      blurRadius: 60 + pulse * 30,
                      spreadRadius: 10,
                    ),
                    BoxShadow(
                      color: const Color(0xFFF43F5E).withValues(alpha: 0.2 + pulse * 0.15),
                      blurRadius: 100 + pulse * 40,
                      spreadRadius: 25,
                    ),
                    BoxShadow(
                      color: const Color(0xFFA855F7).withValues(alpha: 0.15 + pulse * 0.1),
                      blurRadius: 140 + pulse * 50,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
              // Plasma tendrils
              CustomPaint(
                size: Size(widget.size * 1.4, widget.size * 1.4),
                painter: _PlasmaTendrilPainter(
                  tendrils: _tendrils,
                  time: plasma,
                  pulse: pulse,
                  colorPhase: colorPhase,
                ),
              ),
              // Core orb with plasma effect
              Container(
                width: widget.size * (0.82 + pulse * 0.08),
                height: widget.size * (0.82 + pulse * 0.08),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.15, -0.25),
                    radius: 0.9,
                    colors: [
                      Colors.white.withValues(alpha: 0.3),
                      currentColor.withValues(alpha: 0.6),
                      const Color(0xFF831843).withValues(alpha: 0.8),
                      const Color(0xFF3F0F1F),
                    ],
                    stops: const [0.0, 0.25, 0.6, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: currentColor.withValues(alpha: 0.6 + pulse * 0.3),
                      blurRadius: 25 + pulse * 15,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: CustomPaint(
                    size: Size(widget.size * 0.82, widget.size * 0.82),
                    painter: _PlasmaCorePainter(
                      time: plasma,
                      pulse: pulse,
                      colorPhase: colorPhase,
                    ),
                  ),
                ),
              ),
              // Hot spot highlights
              ...List.generate(3, (i) {
                final angle = plasma * 2 * pi + (i / 3) * 2 * pi;
                final radius = widget.size * 0.32;
                return Positioned(
                  left: widget.size * 0.75 + cos(angle) * radius - 8,
                  top: widget.size * 0.75 + sin(angle) * radius - 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.8 * pulse),
                          currentColor.withValues(alpha: 0.4 * pulse),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              }),
              // Center bright core
              Container(
                width: widget.size * 0.12,
                height: widget.size * 0.12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white,
                      Colors.white.withValues(alpha: 0.8),
                      currentColor.withValues(alpha: 0.5),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.5 + pulse * 0.3),
                      blurRadius: 15 + pulse * 10,
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

class _PlasmaTendril {
  final double baseAngle;
  final double amplitude;
  final double frequency;
  final double phase;
  final double thickness;

  _PlasmaTendril({
    required this.baseAngle,
    required this.amplitude,
    required this.frequency,
    required this.phase,
    required this.thickness,
  });
}

class _PlasmaTendrilPainter extends CustomPainter {
  final List<_PlasmaTendril> tendrils;
  final double time;
  final double pulse;
  final double colorPhase;

  _PlasmaTendrilPainter({
    required this.tendrils,
    required this.time,
    required this.pulse,
    required this.colorPhase,
  });

  Color _getColor(double t) {
    final colors = [
      const Color(0xFFEC4899),
      const Color(0xFFF43F5E),
      const Color(0xFFF97316),
      const Color(0xFFEAB308),
      const Color(0xFFA855F7),
      const Color(0xFFEC4899),
    ];
    final index = (t * (colors.length - 1)).floor();
    final localT = (t * (colors.length - 1)) - index;
    return Color.lerp(colors[index], colors[(index + 1) % colors.length], localT)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.3;

    for (var i = 0; i < tendrils.length; i++) {
      final tendril = tendrils[i];
      final path = Path();
      final color = _getColor((colorPhase + i * 0.1) % 1.0);

      path.moveTo(
        center.dx + cos(tendril.baseAngle) * baseRadius,
        center.dy + sin(tendril.baseAngle) * baseRadius,
      );

      for (double t = 0; t <= 1; t += 0.02) {
        final wobble = sin(t * tendril.frequency * pi + time * 4 * pi + tendril.phase) * 
                       tendril.amplitude * (1 - t);
        final angle = tendril.baseAngle + wobble;
        final radius = baseRadius + t * size.width * 0.2;

        path.lineTo(
          center.dx + cos(angle) * radius,
          center.dy + sin(angle) * radius,
        );
      }

      // Main tendril
      final paint = Paint()
        ..color = color.withValues(alpha: 0.7 * (0.7 + pulse * 0.3))
        ..style = PaintingStyle.stroke
        ..strokeWidth = tendril.thickness * (0.8 + pulse * 0.4)
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, paint);

      // Glow effect
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.25 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = tendril.thickness * 2.5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawPath(path, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PlasmaTendrilPainter oldDelegate) =>
      time != oldDelegate.time || pulse != oldDelegate.pulse || colorPhase != oldDelegate.colorPhase;
}

class _PlasmaCorePainter extends CustomPainter {
  final double time;
  final double pulse;
  final double colorPhase;

  _PlasmaCorePainter({
    required this.time,
    required this.pulse,
    required this.colorPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Swirling plasma clouds
    for (int i = 0; i < 5; i++) {
      final angle = (i / 5) * 2 * pi + time * 3 * pi;
      final radius = size.width * 0.25 * sin(time * 2 * pi + i);

      final cloudPaint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(center.dx + cos(angle) * radius, center.dy + sin(angle) * radius),
          size.width * 0.3,
          [
            const Color(0xFFEC4899).withValues(alpha: 0.2 * pulse),
            const Color(0xFFF43F5E).withValues(alpha: 0.1 * pulse),
            Colors.transparent,
          ],
          [0.0, 0.5, 1.0], // Required colorStops
        );

      canvas.drawCircle(
        Offset(center.dx + cos(angle) * radius, center.dy + sin(angle) * radius),
        size.width * 0.25,
        cloudPaint,
      );
    }

    // Electric arcs
    for (int arc = 0; arc < 6; arc++) {
      final startAngle = (arc / 6) * 2 * pi + time * 5 * pi;
      final arcPath = Path();
      arcPath.moveTo(center.dx, center.dy);

      for (double t = 0; t <= 1; t += 0.1) {
        final jitter = (sin(t * 20 + time * 30 + arc) * 8 + cos(t * 15 + time * 25) * 5);
        final r = t * size.width * 0.35;
        arcPath.lineTo(
          center.dx + cos(startAngle + t * 0.3) * r + jitter,
          center.dy + sin(startAngle + t * 0.3) * r + jitter,
        );
      }

      final arcPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.4 * pulse * ((arc % 2 == 0) ? 1 : 0.5))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(arcPath, arcPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PlasmaCorePainter oldDelegate) =>
      time != oldDelegate.time || pulse != oldDelegate.pulse;
}
