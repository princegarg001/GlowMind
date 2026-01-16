import 'package:flutter/material.dart';

/// Music player controls widget with play/pause, skip, progress bar, and volume
class MusicControls extends StatelessWidget {
  final bool isPlaying;
  final Duration position;
  final Duration? duration;
  final double volume;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<double> onVolumeChange;

  const MusicControls({
    super.key,
    required this.isPlaying,
    required this.position,
    this.duration,
    required this.volume,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.onSeek,
    required this.onVolumeChange,
  });

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final totalDuration = duration ?? Duration.zero;
    final progress = totalDuration.inMilliseconds > 0
        ? position.inMilliseconds / totalDuration.inMilliseconds
        : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous, size: 32),
              color: Colors.white.withOpacity(0.9),
              onPressed: onPrevious,
            ),
            const SizedBox(width: 20),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 32,
                ),
                color: Colors.white,
                onPressed: onPlayPause,
              ),
            ),
            const SizedBox(width: 20),
            IconButton(
              icon: const Icon(Icons.skip_next, size: 32),
              color: Colors.white.withOpacity(0.9),
              onPressed: onNext,
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  activeTrackColor: Theme.of(context).colorScheme.primary,
                  inactiveTrackColor: Colors.white.withOpacity(0.3),
                  thumbColor: Theme.of(context).colorScheme.primary,
                  overlayColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
                child: Slider(
                  value: progress.clamp(0.0, 1.0),
                  onChanged: (value) {
                    if (totalDuration.inMilliseconds > 0) {
                      final newPosition = Duration(
                        milliseconds: (value * totalDuration.inMilliseconds).round(),
                      );
                      onSeek(newPosition);
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(position),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _formatDuration(totalDuration),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Volume control
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            children: [
              Icon(
                Icons.volume_down,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                    activeTrackColor: Colors.white.withOpacity(0.8),
                    inactiveTrackColor: Colors.white.withOpacity(0.3),
                    thumbColor: Colors.white,
                    overlayColor: Colors.white.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: volume.clamp(0.0, 1.0),
                    onChanged: onVolumeChange,
                  ),
                ),
              ),
              Icon(
                Icons.volume_up,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
