import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glowmind/models/music_models.dart';
import 'package:glowmind/state/music_state.dart';
import 'package:glowmind/widgets/mood_orb.dart';
import 'package:glowmind/widgets/music_controls.dart';
import 'package:glowmind/widgets/sleep_timer_dialog.dart';

/// Single mood page with animated orb and music controls
class MoodPage extends StatelessWidget {
  final MoodType mood;
  final VoidCallback? onSettings;

  const MoodPage({
    super.key,
    required this.mood,
    this.onSettings,
  });

  /// Get background gradient colors for the mood
  List<Color> _getBackgroundColors() {
    switch (mood) {
      case MoodType.sleep:
        return [const Color(0xFF2D1B4E), const Color(0xFF1A0F3D)];
      case MoodType.study:
        return [const Color(0xFF1E3A8A), const Color(0xFF0F172A)];
      case MoodType.party:
        return [const Color(0xFF831843), const Color(0xFF3F0F1F)];
      case MoodType.meditate:
        return [const Color(0xFF064E3B), const Color(0xFF022C22)];
      case MoodType.deepFocus:
        return [const Color(0xFF164E63), const Color(0xFF0C2D3A)];
      case MoodType.nature:
        return [const Color(0xFF3F6212), const Color(0xFF1F3108)];
    }
  }

  /// Get pulse speed for the mood
  double _getPulseSpeed() {
    switch (mood) {
      case MoodType.sleep:
        return 0.5; // Very slow
      case MoodType.study:
        return 0.8; // Steady
      case MoodType.party:
        return 1.5; // Fast
      case MoodType.meditate:
        return 0.4; // Very slow
      case MoodType.deepFocus:
        return 0.6; // Minimal
      case MoodType.nature:
        return 0.7; // Gentle
    }
  }

  void _showSleepTimer(BuildContext context, MusicState musicState) {
    showDialog(
      context: context,
      builder: (context) => SleepTimerDialog(
        currentTimer: musicState.sleepTimer,
        onStart: (duration) => musicState.startSleepTimer(duration),
        onCancel: () => musicState.cancelSleepTimer(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final musicState = context.watch<MusicState>();
    final bgColors = _getBackgroundColors();
    final track = musicState.currentTrack;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: bgColors,
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                const SizedBox(height: 60), // Space for top buttons

                // Mood orb
                Expanded(
                  flex: 3,
                  child: Center(
                    child: MoodOrb(
                      mood: mood,
                      size: 220,
                      pulseSpeed: _getPulseSpeed(),
                    ),
                  ),
                ),

                // Mood name and track info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        mood.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (track != null)
                        Text(
                          track.name,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Music controls
                Expanded(
                  flex: 2,
                  child: MusicControls(
                    isPlaying: musicState.isPlaying,
                    position: musicState.position,
                    duration: musicState.duration,
                    volume: musicState.volume,
                    onPlayPause: () => musicState.togglePlayPause(),
                    onNext: () => musicState.next(),
                    onPrevious: () => musicState.previous(),
                    onSeek: (position) => musicState.seek(position),
                    onVolumeChange: (volume) => musicState.setVolume(volume),
                  ),
                ),

                const SizedBox(height: 16),

                // Mode toggles (shuffle, loop, volume indicator)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.shuffle,
                          color: musicState.shuffle
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white.withOpacity(0.5),
                        ),
                        onPressed: () => musicState.toggleShuffle(),
                        tooltip: 'Shuffle',
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: Icon(
                          _getLoopIcon(musicState.loopMode),
                          color: musicState.loopMode != LoopMode.off
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white.withOpacity(0.5),
                        ),
                        onPressed: () => musicState.cycleLoopMode(),
                        tooltip: musicState.loopMode.displayName,
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        _getVolumeIcon(musicState.volume),
                        color: Colors.white.withOpacity(0.5),
                        size: 20,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Navigation hints
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      _buildHint(Icons.arrow_upward, 'Swipe up for next mood'),
                      const SizedBox(height: 8),
                      _buildHint(Icons.arrow_downward, 'Swipe down for previous mood'),
                      const SizedBox(height: 8),
                      _buildHint(Icons.arrow_forward, 'Swipe right for playlist'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),

            // Top buttons
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Settings button
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: onSettings,
                  ),

                  // Sleep timer button
                  GestureDetector(
                    onTap: () => _showSleepTimer(context, musicState),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: musicState.sleepTimer != null
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white.withOpacity(0.2),
                        boxShadow: musicState.sleepTimer != null
                            ? [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                  blurRadius: 12,
                                ),
                              ]
                            : null,
                      ),
                      child: const Icon(
                        Icons.bedtime,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHint(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.4), size: 16),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  IconData _getLoopIcon(LoopMode mode) {
    switch (mode) {
      case LoopMode.off:
        return Icons.repeat;
      case LoopMode.one:
        return Icons.repeat_one;
      case LoopMode.all:
        return Icons.repeat;
    }
  }

  IconData _getVolumeIcon(double volume) {
    if (volume == 0) {
      return Icons.volume_off;
    } else if (volume < 0.5) {
      return Icons.volume_down;
    } else {
      return Icons.volume_up;
    }
  }
}
