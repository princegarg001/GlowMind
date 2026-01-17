import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:glowmind/widgets/orbs/base_orb.dart';

/// Magnetic Ink Orb for Sleep mood
/// Features: Dark, flowing ink particles that swirl like ferrofluid
class MagneticInkOrb extends BaseOrb {
  const MagneticInkOrb({
    super.key,
    super.size = 280,
    super.intensity = 1.0,
  });

  @override
  State<MagneticInkOrb> createState() => _MagneticInkOrbState();
}

class _MagneticInkOrbState extends State<MagneticInkOrb>
    with TickerProviderStateMixin {
  late AnimationController _flowController;
  late AnimationController _pulseController;
  late AnimationController _spikeController;
  final List<_InkSpike> _spikes = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _flowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _spikeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(_updateSpikes);
    _spikeController.repeat();

    _initializeSpikes();
  }

  void _initializeSpikes() {
    for (int i = 0; i < 24; i++) {
      _spikes.add(_InkSpike(
        angle: (i / 24) * 2 * pi,
        baseHeight: 0.15 + _random.nextDouble() * 0.1,
        speed: 0.5 + _random.nextDouble() * 0.5,
        phase: _random.nextDouble() * 2 * pi,
      ));
    }
  }

  void _updateSpikes() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _flowController.dispose();
    _pulseController.dispose();
    _spikeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_flowController, _pulseController]),
      builder: (context, child) {
        final pulse = sin(_pulseController.value * pi) * 0.5 + 0.5;
        final flow = _flowController.value;

        return SizedBox(
          width: widget.size * 1.4,
          height: widget.size * 1.4,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ambient glow
              Container(
                width: widget.size * 1.3,
                height: widget.size * 1.3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.2 + pulse * 0.15),
                      blurRadius: 80 + pulse * 30,
                      spreadRadius: 20,
                    ),
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.15 + pulse * 0.1),
                      blurRadius: 120 + pulse * 40,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
              // Ferrofluid spikes layer
              CustomPaint(
                size: Size(widget.size * 1.3, widget.size * 1.3),
                painter: _InkSpikePainter(
                  spikes: _spikes,
                  time: flow,
                  pulse: pulse,
                  primaryColor: const Color(0xFF8B5CF6),
                  secondaryColor: const Color(0xFF3730A3),
                ),
              ),
              // Core orb with 3D shading
              Container(
                width: widget.size * (0.85 + pulse * 0.05),
                height: widget.size * (0.85 + pulse * 0.05),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.25, -0.35),
                    radius: 0.9,
                    colors: [
                      const Color(0xFF4C1D95).withValues(alpha: 0.3),
                      const Color(0xFF1E1B4B).withValues(alpha: 0.8),
                      const Color(0xFF0F0A1F).withValues(alpha: 0.95),
                      Colors.black,
                    ],
                    stops: const [0.0, 0.35, 0.7, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.4 + pulse * 0.2),
                      blurRadius: 25 + pulse * 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: CustomPaint(
                    size: Size(widget.size * 0.85, widget.size * 0.85),
                    painter: _InkFlowPainter(
                      time: flow,
                      pulse: pulse,
                    ),
                  ),
                ),
              ),
              // Inner highlight reflection
              Positioned(
                top: widget.size * 0.15,
                left: widget.size * 0.25,
                child: Container(
                  width: widget.size * 0.25,
                  height: widget.size * 0.12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.size * 0.1),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.15 + pulse * 0.05),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InkSpike {
  final double angle;
  final double baseHeight;
  final double speed;
  final double phase;

  _InkSpike({
    required this.angle,
    required this.baseHeight,
    required this.speed,
    required this.phase,
  });

  double getHeight(double time, double pulse) {
    return baseHeight *
        (0.8 + 0.4 * sin(time * speed * 2 * pi + phase)) *
        (0.9 + pulse * 0.2);
  }
}

class _InkSpikePainter extends CustomPainter {
  final List<_InkSpike> spikes;
  final double time;
  final double pulse;
  final Color primaryColor;
  final Color secondaryColor;

  _InkSpikePainter({
    required this.spikes,
    required this.time,
    required this.pulse,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.32;

    for (var spike in spikes) {
      final height = spike.getHeight(time, pulse);
      final spikeLength = baseRadius * height;

      final startPoint = Offset(
        center.dx + cos(spike.angle) * baseRadius,
        center.dy + sin(spike.angle) * baseRadius,
      );

      final endPoint = Offset(
        center.dx + cos(spike.angle) * (baseRadius + spikeLength),
        center.dy + sin(spike.angle) * (baseRadius + spikeLength),
      );

      // Control points for bezier curve (creates fluid spike shape)
      final controlAngle1 = spike.angle - 0.15;
      final controlAngle2 = spike.angle + 0.15;

      final ctrl1 = Offset(
        center.dx + cos(controlAngle1) * (baseRadius + spikeLength * 0.7),
        center.dy + sin(controlAngle1) * (baseRadius + spikeLength * 0.7),
      );

      final ctrl2 = Offset(
        center.dx + cos(controlAngle2) * (baseRadius + spikeLength * 0.7),
        center.dy + sin(controlAngle2) * (baseRadius + spikeLength * 0.7),
      );

      final path = Path()
        ..moveTo(startPoint.dx - cos(spike.angle + pi / 2) * 8,
            startPoint.dy - sin(spike.angle + pi / 2) * 8)
        ..quadraticBezierTo(ctrl1.dx, ctrl1.dy, endPoint.dx, endPoint.dy)
        ..quadraticBezierTo(
            ctrl2.dx,
            ctrl2.dy,
            startPoint.dx + cos(spike.angle + pi / 2) * 8,
            startPoint.dy + sin(spike.angle + pi / 2) * 8)
        ..close();

      final paint = Paint()
        ..shader = ui.Gradient.linear(
          startPoint,
          endPoint,
          [
            secondaryColor.withValues(alpha: 0.8),
            primaryColor.withValues(alpha: 0.6),
            primaryColor.withValues(alpha: 0.2),
          ],
          [0.0, 0.5, 1.0],
        )
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _InkSpikePainter oldDelegate) =>
      time != oldDelegate.time || pulse != oldDelegate.pulse;
}

class _InkFlowPainter extends CustomPainter {
  final double time;
  final double pulse;

  _InkFlowPainter({required this.time, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw flowing ink streams
    for (int i = 0; i < 6; i++) {
      final streamPath = Path();
      final startAngle = (i / 6) * 2 * pi + time * 2 * pi;

      streamPath.moveTo(center.dx, center.dy);

      for (double t = 0; t <= 1; t += 0.05) {
        final angle = startAngle + t * pi * 0.8;
        final radius = t * size.width * 0.4;
        final wobble = sin(t * 8 + time * 4 * pi) * 10 * t;

        streamPath.lineTo(
          center.dx + cos(angle) * radius + wobble,
          center.dy + sin(angle) * radius + wobble,
        );
      }

      final paint = Paint()
        ..color = const Color(0xFF8B5CF6).withValues(alpha: 0.15 + pulse * 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 + pulse * 2
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(streamPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _InkFlowPainter oldDelegate) =>
      time != oldDelegate.time || pulse != oldDelegate.pulse;
}
