import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Full-screen overlay shown when the sleep timer completes with alarm
class AlarmOverlay extends StatefulWidget {
  final VoidCallback onDismiss;

  const AlarmOverlay({
    super.key,
    required this.onDismiss,
  });

  @override
  State<AlarmOverlay> createState() => _AlarmOverlayState();
}

class _AlarmOverlayState extends State<AlarmOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _bellController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bellAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _bellController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _bellAnimation = Tween<double>(begin: -0.15, end: 0.15).animate(
      CurvedAnimation(parent: _bellController, curve: Curves.easeInOut),
    );

    // Haptic feedback
    _startHapticFeedback();
  }

  Timer? _hapticTimer;

  void _startHapticFeedback() {
    _hapticTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      HapticFeedback.mediumImpact();
    });
  }

  @override
  void dispose() {
    _hapticTimer?.cancel();
    _pulseController.dispose();
    _bellController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              const Color(0xFF1A0F3D),
              const Color(0xFF0B061A),
            ],
            radius: 1.5,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              
              // Animated bell icon
              AnimatedBuilder(
                animation: Listenable.merge([_pulseAnimation, _bellAnimation]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Transform.rotate(
                      angle: _bellAnimation.value,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B)
                                  .withOpacity(0.4 + _pulseAnimation.value * 0.2),
                              blurRadius: 40 + (_pulseAnimation.value * 20),
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.alarm,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 48),

              // Title
              const Text(
                "Good Morning! ☀️",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                "Your sleep timer has ended",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),

              const Spacer(flex: 2),

              // Dismiss button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    widget.onDismiss();
                  },
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.close, color: Colors.white, size: 24),
                            SizedBox(width: 12),
                            Text(
                              "Stop Alarm",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Swipe hint
              Text(
                "Tap to dismiss",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 14,
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
