import 'package:flutter/material.dart';

/// Welcome overlay that shows on first app load with fade transition
class WelcomeOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  final Duration displayDuration;
  final Duration fadeDuration;

  const WelcomeOverlay({
    super.key,
    required this.onComplete,
    this.displayDuration = const Duration(milliseconds: 2500),
    this.fadeDuration = const Duration(milliseconds: 800),
  });

  @override
  State<WelcomeOverlay> createState() => _WelcomeOverlayState();
}

class _WelcomeOverlayState extends State<WelcomeOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: widget.fadeDuration,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    // Start fade out after display duration
    Future.delayed(widget.displayDuration, () {
      if (mounted) {
        _fadeController.forward().then((_) {
          if (mounted) {
            widget.onComplete();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimation, _pulseController]),
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Color(0xFF1A0F3D),
                    Color(0xFF0D0620),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glowing orb
                    Container(
                      width: 120 + (_pulseController.value * 20),
                      height: 120 + (_pulseController.value * 20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF8B5CF6).withValues(alpha: 0.8),
                            const Color(0xFF6366F1).withValues(alpha: 0.4),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withValues(
                              alpha: 0.5 + (_pulseController.value * 0.3),
                            ),
                            blurRadius: 60 + (_pulseController.value * 30),
                            spreadRadius: 10 + (_pulseController.value * 10),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    // Welcome text
                    const Text(
                      'Welcome to',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFF8B5CF6),
                          Color(0xFFEC4899),
                          Color(0xFF8B5CF6),
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ).createShader(bounds),
                      child: const Text(
                        'GlowMind',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your personal mood sanctuary',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
