import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:glowmind/widgets/orbs/base_orb.dart';

/// Nature Orb for Nature mood
/// Features: Organic leaves, floating spores, and natural energy
class NatureOrb extends BaseOrb {
  const NatureOrb({
    super.key,
    super.size = 280,
    super.intensity = 1.0,
  });

  @override
  State<NatureOrb> createState() => _NatureOrbState();
}

class _NatureOrbState extends State<NatureOrb> with TickerProviderStateMixin {
  late AnimationController _leafController;
  late AnimationController _breathController;
  late AnimationController _sporeController;
  final List<_FloatingLeaf> _leaves = [];
  final List<_Spore> _spores = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _leafController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);

    _sporeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _initializeLeaves();
    _initializeSpores();
  }

  void _initializeLeaves() {
    for (int i = 0; i < 8; i++) {
      _leaves.add(_FloatingLeaf(
        angle: (i / 8) * 2 * pi,
        distance: 0.4 + _random.nextDouble() * 0.15,
        size: 0.08 + _random.nextDouble() * 0.04,
        rotationSpeed: 0.5 + _random.nextDouble() * 0.5,
        floatSpeed: 0.3 + _random.nextDouble() * 0.4,
        phase: _random.nextDouble() * 2 * pi,
      ));
    }
  }

  void _initializeSpores() {
    for (int i = 0; i < 20; i++) {
      _spores.add(_Spore(
        startAngle: _random.nextDouble() * 2 * pi,
        orbitRadius: 0.25 + _random.nextDouble() * 0.2,
        size: 2 + _random.nextDouble() * 3,
        speed: 0.2 + _random.nextDouble() * 0.3,
        phase: _random.nextDouble() * 2 * pi,
        verticalOffset: _random.nextDouble() * 0.3,
      ));
    }
  }

  @override
  void dispose() {
    _leafController.dispose();
    _breathController.dispose();
    _sporeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_leafController, _breathController, _sporeController]),
      builder: (context, child) {
        final breath = sin(_breathController.value * pi) * 0.5 + 0.5;
        final leaf = _leafController.value;
        final spore = _sporeController.value;

        return SizedBox(
          width: widget.size * 1.5,
          height: widget.size * 1.5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Natural ambient glow
              Container(
                width: widget.size * 1.4,
                height: widget.size * 1.4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF84CC16).withValues(alpha: 0.2 + breath * 0.12),
                      blurRadius: 70 + breath * 25,
                      spreadRadius: 15,
                    ),
                    BoxShadow(
                      color: const Color(0xFFA3E635).withValues(alpha: 0.12 + breath * 0.08),
                      blurRadius: 110 + breath * 35,
                      spreadRadius: 30,
                    ),
                  ],
                ),
              ),
              // Floating spores background
              CustomPaint(
                size: Size(widget.size * 1.4, widget.size * 1.4),
                painter: _SporePainter(
                  spores: _spores,
                  time: spore,
                  breath: breath,
                ),
              ),
              // Floating leaves
              CustomPaint(
                size: Size(widget.size * 1.3, widget.size * 1.3),
                painter: _LeafPainter(
                  leaves: _leaves,
                  time: leaf,
                  breath: breath,
                ),
              ),
              // Core orb - living earth
              Container(
                width: widget.size * (0.85 + breath * 0.05),
                height: widget.size * (0.85 + breath * 0.05),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.2, -0.3),
                    radius: 0.9,
                    colors: [
                      const Color(0xFFA3E635).withValues(alpha: 0.3),
                      const Color(0xFF84CC16).withValues(alpha: 0.5),
                      const Color(0xFF3F6212).withValues(alpha: 0.75),
                      const Color(0xFF1F3108).withValues(alpha: 0.9),
                      const Color(0xFF0F1A04),
                    ],
                    stops: const [0.0, 0.2, 0.45, 0.7, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF84CC16).withValues(alpha: 0.4 + breath * 0.2),
                      blurRadius: 25 + breath * 12,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: CustomPaint(
                    size: Size(widget.size * 0.85, widget.size * 0.85),
                    painter: _OrganicTexturePainter(
                      time: leaf,
                      breath: breath,
                    ),
                  ),
                ),
              ),
              // Vine tendrils
              CustomPaint(
                size: Size(widget.size * 1.1, widget.size * 1.1),
                painter: _VinePainter(
                  time: leaf,
                  breath: breath,
                ),
              ),
              // Morning dew highlight
              Positioned(
                top: widget.size * 0.22,
                left: widget.size * 0.38,
                child: Container(
                  width: widget.size * 0.15,
                  height: widget.size * 0.08,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.size * 0.04),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.4 + breath * 0.15),
                        const Color(0xFFA3E635).withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Life energy core
              Container(
                width: widget.size * 0.12,
                height: widget.size * 0.12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.9),
                      const Color(0xFFA3E635).withValues(alpha: 0.7),
                      const Color(0xFF84CC16).withValues(alpha: 0.4),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFA3E635).withValues(alpha: 0.5 + breath * 0.3),
                      blurRadius: 12 + breath * 8,
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

class _FloatingLeaf {
  final double angle;
  final double distance;
  final double size;
  final double rotationSpeed;
  final double floatSpeed;
  final double phase;

  _FloatingLeaf({
    required this.angle,
    required this.distance,
    required this.size,
    required this.rotationSpeed,
    required this.floatSpeed,
    required this.phase,
  });
}

class _Spore {
  final double startAngle;
  final double orbitRadius;
  final double size;
  final double speed;
  final double phase;
  final double verticalOffset;

  _Spore({
    required this.startAngle,
    required this.orbitRadius,
    required this.size,
    required this.speed,
    required this.phase,
    required this.verticalOffset,
  });
}

class _SporePainter extends CustomPainter {
  final List<_Spore> spores;
  final double time;
  final double breath;

  _SporePainter({
    required this.spores,
    required this.time,
    required this.breath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (var spore in spores) {
      final angle = spore.startAngle + time * spore.speed * 2 * pi;
      final radius = size.width * spore.orbitRadius;
      final verticalWobble = sin(time * 3 * pi + spore.phase) * size.height * spore.verticalOffset * 0.1;

      final x = center.dx + cos(angle) * radius;
      final y = center.dy + sin(angle) * radius + verticalWobble;

      final alpha = 0.3 + sin(time * 4 * pi + spore.phase) * 0.2;

      final paint = Paint()
        ..color = const Color(0xFFA3E635).withValues(alpha: alpha * breath);

      canvas.drawCircle(Offset(x, y), spore.size, paint);

      // Soft glow
      final glowPaint = Paint()
        ..color = const Color(0xFFA3E635).withValues(alpha: alpha * 0.3 * breath)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(x, y), spore.size * 2, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SporePainter oldDelegate) =>
      time != oldDelegate.time || breath != oldDelegate.breath;
}

class _LeafPainter extends CustomPainter {
  final List<_FloatingLeaf> leaves;
  final double time;
  final double breath;

  _LeafPainter({
    required this.leaves,
    required this.time,
    required this.breath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (var leaf in leaves) {
      final floatOffset = sin(time * leaf.floatSpeed * 2 * pi + leaf.phase) * 10;
      final angle = leaf.angle + time * 0.2 * pi;
      final radius = size.width * leaf.distance;

      final leafCenter = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius + floatOffset,
      );

      final rotation = time * leaf.rotationSpeed * 2 * pi;

      canvas.save();
      canvas.translate(leafCenter.dx, leafCenter.dy);
      canvas.rotate(rotation);

      // Draw leaf shape
      final leafSize = size.width * leaf.size;
      final path = Path();

      path.moveTo(0, -leafSize);
      path.quadraticBezierTo(leafSize * 0.7, -leafSize * 0.3, 0, leafSize);
      path.quadraticBezierTo(-leafSize * 0.7, -leafSize * 0.3, 0, -leafSize);

      final leafPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, -leafSize),
          Offset(0, leafSize),
          [
            const Color(0xFFA3E635).withValues(alpha: 0.6 + breath * 0.2),
            const Color(0xFF84CC16).withValues(alpha: 0.5 + breath * 0.2),
            const Color(0xFF3F6212).withValues(alpha: 0.4 + breath * 0.1),
          ],
        )
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, leafPaint);

      // Leaf vein
      final veinPaint = Paint()
        ..color = const Color(0xFF65A30D).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawLine(Offset(0, -leafSize * 0.8), Offset(0, leafSize * 0.8), veinPaint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _LeafPainter oldDelegate) =>
      time != oldDelegate.time || breath != oldDelegate.breath;
}

class _VinePainter extends CustomPainter {
  final double time;
  final double breath;

  _VinePainter({required this.time, required this.breath});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.35;

    for (int vine = 0; vine < 5; vine++) {
      final startAngle = (vine / 5) * 2 * pi + time * 0.3 * pi;
      final path = Path();

      final startPoint = Offset(
        center.dx + cos(startAngle) * baseRadius,
        center.dy + sin(startAngle) * baseRadius,
      );
      path.moveTo(startPoint.dx, startPoint.dy);

      for (double t = 0; t <= 1; t += 0.05) {
        final curl = sin(t * 4 * pi + time * 2 * pi + vine) * 15 * t;
        final angle = startAngle + t * 0.5;
        final r = baseRadius + t * size.width * 0.12;

        path.lineTo(
          center.dx + cos(angle) * r + curl,
          center.dy + sin(angle) * r + curl * 0.5,
        );
      }

      final vinePaint = Paint()
        ..color = const Color(0xFF84CC16).withValues(alpha: 0.25 + breath * 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(path, vinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _VinePainter oldDelegate) =>
      time != oldDelegate.time || breath != oldDelegate.breath;
}

class _OrganicTexturePainter extends CustomPainter {
  final double time;
  final double breath;

  _OrganicTexturePainter({required this.time, required this.breath});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Organic cell-like patterns
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * pi + time * 0.5 * pi;
      final radius = size.width * 0.15 * (0.5 + sin(time * 2 * pi + i) * 0.5);
      final cellCenter = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );

      final cellPaint = Paint()
        ..shader = ui.Gradient.radial(
          cellCenter,
          size.width * 0.15,
          [
            const Color(0xFFA3E635).withValues(alpha: 0.15 * breath),
            const Color(0xFF84CC16).withValues(alpha: 0.08 * breath),
            Colors.transparent,
          ],
        );

      canvas.drawCircle(cellCenter, size.width * 0.15, cellPaint);
    }

    // Central energy flow
    for (int ring = 0; ring < 3; ring++) {
      final ringRadius = size.width * (0.1 + ring * 0.1);
      final alpha = 0.1 + sin(time * 3 * pi + ring) * 0.05;

      final ringPaint = Paint()
        ..color = const Color(0xFFA3E635).withValues(alpha: alpha * breath)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawCircle(center, ringRadius, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrganicTexturePainter oldDelegate) =>
      time != oldDelegate.time || breath != oldDelegate.breath;
}
