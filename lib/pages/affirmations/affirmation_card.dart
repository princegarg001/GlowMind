import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/affirmation.dart';

class AffirmationCard extends StatelessWidget {
  final Affirmation affirmation;
  final bool isLarge;
  final AnimationController breatheController;
  final VoidCallback onFavorite;
  final VoidCallback onShare;

  const AffirmationCard({
    super.key,
    required this.affirmation,
    required this.breatheController,
    required this.onFavorite,
    required this.onShare,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: breatheController,
      builder: (context, child) {
        return Container(
          height: isLarge ? 380 : 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: affirmation.category.color.withValues(alpha: 0.3),
                blurRadius: 30 + (breatheController.value * 15),
                offset: const Offset(0, 15),
                spreadRadius: breatheController.value * 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              children: [
                // Gradient background
                _buildGradientBackground(),
                
                // Glassmorphism overlay
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.15),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                ),
                
                // Decorative elements
                _buildDecorations(),
                
                // Content
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const Spacer(flex: 1),
                      _buildAffirmationText(),
                      const Spacer(flex: 2),
                      _buildActions(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGradientBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getGradientStart(),
            _getGradientMiddle(),
            _getGradientEnd(),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  Color _getGradientStart() {
    return Color.lerp(
      const Color(0xFF1A0F3D),
      affirmation.category.color,
      0.4,
    )!;
  }

  Color _getGradientMiddle() {
    return Color.lerp(
      const Color(0xFF0F0720),
      affirmation.category.color,
      0.2,
    )!;
  }

  Color _getGradientEnd() {
    return const Color(0xFF0B061A);
  }

  Widget _buildDecorations() {
    return AnimatedBuilder(
      animation: breatheController,
      builder: (context, child) {
        return Stack(
          children: [
            // Large glowing orb
            Positioned(
              right: -60,
              top: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      affirmation.category.color.withValues(alpha: 0.4),
                      affirmation.category.color.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Small decorative circles
            Positioned(
              left: 30,
              bottom: 100 + (breatheController.value * 10),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFEC4899).withValues(alpha: 0.3),
                      const Color(0xFFEC4899).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 80,
              bottom: 60 - (breatheController.value * 5),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                      const Color(0xFF8B5CF6).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Sparkle decorations
            ..._buildSparkles(),
          ],
        );
      },
    );
  }

  List<Widget> _buildSparkles() {
    return [
      Positioned(
        right: 40,
        top: 40,
        child: _Sparkle(
          size: 8,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
      Positioned(
        left: 60,
        top: 80,
        child: _Sparkle(
          size: 6,
          color: affirmation.category.color.withValues(alpha: 0.8),
        ),
      ),
      Positioned(
        right: 120,
        bottom: 140,
        child: _Sparkle(
          size: 5,
          color: const Color(0xFFEC4899).withValues(alpha: 0.7),
        ),
      ),
    ];
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Category badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: affirmation.category.color.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: affirmation.category.color.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                affirmation.category.icon,
                color: affirmation.category.color,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                affirmation.category.displayName,
                style: TextStyle(
                  color: affirmation.category.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Favorite button with glow
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onFavorite();
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: affirmation.isFavorite
                  ? const Color(0xFFEC4899).withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              boxShadow: affirmation.isFavorite
                  ? [
                      BoxShadow(
                        color: const Color(0xFFEC4899).withValues(alpha: 0.4),
                        blurRadius: 15,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              affirmation.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: affirmation.isFavorite
                  ? const Color(0xFFEC4899)
                  : Colors.white70,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAffirmationText() {
    return AnimatedBuilder(
      animation: breatheController,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.white,
                Colors.white.withValues(alpha: 0.9),
                Colors.white,
              ],
              stops: [
                0.0,
                0.5 + (breatheController.value * 0.1),
                1.0,
              ],
            ).createShader(bounds);
          },
          child: Text(
            affirmation.text,
            style: TextStyle(
              color: Colors.white,
              fontSize: isLarge ? 28 : 20,
              fontWeight: FontWeight.w600,
              height: 1.5,
              letterSpacing: 0.3,
            ),
          ),
        );
      },
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        _ActionButton(
          icon: Icons.copy_rounded,
          label: "Copy",
          onTap: () {
            HapticFeedback.lightImpact();
            Clipboard.setData(ClipboardData(text: affirmation.text));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Copied to clipboard ✨"),
                behavior: SnackBarBehavior.floating,
                backgroundColor: affirmation.category.color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 12),
        _ActionButton(
          icon: Icons.share_rounded,
          label: "Share",
          onTap: onShare,
        ),
        const Spacer(),
        // Type indicator
        if (affirmation.type != AffirmationType.generated)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  affirmation.type == AffirmationType.voice
                      ? Icons.mic
                      : Icons.edit_note,
                  color: Colors.white60,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  affirmation.type == AffirmationType.voice ? "Voice" : "Custom",
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  final double size;
  final Color color;

  const _Sparkle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: size * 2,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
