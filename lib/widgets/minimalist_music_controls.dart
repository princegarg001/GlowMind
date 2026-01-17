import 'package:flutter/material.dart';

/// Minimalist music control bar with only essential buttons
class MinimalistMusicControls extends StatelessWidget {
  final bool isPlaying;
  final bool isMuted;
  final bool shuffleEnabled;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onMuteToggle;
  final VoidCallback onShuffleToggle;

  const MinimalistMusicControls({
    super.key,
    required this.isPlaying,
    required this.isMuted,
    required this.shuffleEnabled,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.onMuteToggle,
    required this.onShuffleToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Shuffle toggle
          _ControlButton(
            icon: Icons.shuffle,
            isActive: shuffleEnabled,
            onTap: onShuffleToggle,
            size: 22,
          ),
          const SizedBox(width: 20),
          
          // Previous track
          _ControlButton(
            icon: Icons.skip_previous_rounded,
            onTap: onPrevious,
            size: 28,
          ),
          const SizedBox(width: 16),
          
          // Play/Pause (main button)
          GestureDetector(
            onTap: onPlayPause,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.25),
                    Colors.white.withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Next track
          _ControlButton(
            icon: Icons.skip_next_rounded,
            onTap: onNext,
            size: 28,
          ),
          const SizedBox(width: 20),
          
          // Mute/Unmute toggle
          _ControlButton(
            icon: isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            isActive: !isMuted,
            onTap: onMuteToggle,
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final double size;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.isActive = true,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          color: isActive 
              ? Colors.white.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.4),
          size: size,
        ),
      ),
    );
  }
}
