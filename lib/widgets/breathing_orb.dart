import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 30-second breathing orb with subtle scale and glow animation
class BreathingOrb extends StatefulWidget {
  final VoidCallback? onCompleted;
  const BreathingOrb({super.key, this.onCompleted});

  @override
  State<BreathingOrb> createState() => _BreathingOrbState();
}

class _BreathingOrbState extends State<BreathingOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  int _ticks = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..addListener(_onTick);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.repeat(reverse: true);
  }

  void _onTick() {
    final t = _ctrl.lastElapsedDuration?.inMilliseconds ?? 0;
    final seconds = (t / 1000).floor();
    if (seconds ~/ 6 > _ticks) {
      _ticks = seconds ~/ 6;
      HapticFeedback.selectionClick();
    }
    if (seconds >= 30) {
      widget.onCompleted?.call();
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final scale = 0.85 + 0.3 * sin(_anim.value * pi);
        return Center(
          child: Container(
            width: 180 * (1 + 0.1 * _anim.value),
            height: 180 * (1 + 0.1 * _anim.value),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.tertiary]),
              boxShadow: [
                BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4), blurRadius: 40 * scale, spreadRadius: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}
