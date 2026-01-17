import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:glowmind/models/music_models.dart';
import 'package:glowmind/nav.dart';
import 'package:glowmind/state/music_state.dart';
import 'package:glowmind/widgets/interactive_glow_background.dart';
import 'package:glowmind/widgets/minimalist_music_controls.dart';
import 'package:glowmind/widgets/orbs/mood_orb_selector.dart';
import 'package:glowmind/widgets/sleep_timer_dialog.dart';
import 'package:glowmind/widgets/welcome_overlay.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// TikTok-style vertical mood swiper with full-screen immersive UI
/// All controls are sticky overlays that don't scroll with the mood pages
class VerticalMoodNavigator extends StatefulWidget {
  const VerticalMoodNavigator({super.key});

  @override
  State<VerticalMoodNavigator> createState() => _VerticalMoodNavigatorState();
}

class _VerticalMoodNavigatorState extends State<VerticalMoodNavigator> {
  late PageController _pageController;
  // Tracks the current mood index (0.._moods.length-1), independent of page index
  int _currentMoodIndex = 0;
  int _scrollingToMoodIndex = 0; // Next mood during scroll
  double _lastVolume = 0.7;
  bool _showWelcome = true;
  double _scrollProgress = 0.0; // 0.0 to 1.0 for gradient blending
  
  // All moods in order
  final List<MoodType> _moods = [
    MoodType.sleep,
    MoodType.study,
    MoodType.party,
    MoodType.meditate,
    MoodType.deepFocus,
    MoodType.nature,
  ];

  // Large offset to simulate infinite scroll in both directions
  static const int _loopSpan = 10000; // pages per mood cycle anchor
  late final int _basePage; // anchor center page

  @override
  void initState() {
    super.initState();
    _basePage = _loopSpan * _moods.length; // big center position
    _pageController = PageController(initialPage: _basePage, viewportFraction: 1.0);
    _pageController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLastMood();
    });
  }

  void _onScroll() {
    if (!_pageController.hasClients) return;
    final page = _pageController.page ?? _basePage.toDouble();
    final pageFloor = page.floor();
    final progress = page - pageFloor;
    
    // Determine which mood we're scrolling towards
    final currentIndex = pageFloor % _moods.length;
    final nextIndex = (pageFloor + 1) % _moods.length;
    
    // Only update state if values actually changed (optimization)
    if (_scrollProgress != progress || 
        _currentMoodIndex != currentIndex ||
        _scrollingToMoodIndex != nextIndex) {
      // Use addPostFrameCallback for smoother updates
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _scrollProgress = progress;
            _currentMoodIndex = currentIndex;
            _scrollingToMoodIndex = nextIndex;
          });
        }
      });
    }
  }

  void _loadLastMood() {
    final musicState = context.read<MusicState>();
    final lastMood = musicState.preferences?.lastMood;

    if (lastMood != null) {
      final index = _moods.indexOf(lastMood);
      if (index >= 0 && index != _currentMoodIndex) {
        setState(() {
          _currentMoodIndex = index;
        });
        // Jump to anchored page that maps to this mood
        _pageController.jumpToPage(_basePage + index);
      }
    }
    _lastVolume = musicState.volume > 0 ? musicState.volume : 0.7;
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    super.dispose();
  }

  void _dismissWelcome() {
    setState(() => _showWelcome = false);
  }

  void _onPageChanged(int pageIndex) {
    // Map the large page space back to a mood index
    final nextMoodIndex = pageIndex % _moods.length;
    if (nextMoodIndex == _currentMoodIndex) return;

    setState(() => _currentMoodIndex = nextMoodIndex);

    final musicState = context.read<MusicState>();
    final newMood = _moods[nextMoodIndex];
    musicState.changeMood(newMood);
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

  void _toggleMute(MusicState musicState) {
    if (musicState.volume > 0) {
      _lastVolume = musicState.volume;
      musicState.setVolume(0);
    } else {
      musicState.setVolume(_lastVolume);
    }
  }

  @override
  Widget build(BuildContext context) {
    final musicState = context.watch<MusicState>();
    final track = musicState.currentTrack;
    final currentMood = _moods[_currentMoodIndex];
    final nextMood = _moods[_scrollingToMoodIndex];

    return Scaffold(
      body: Stack(
        children: [
          // Sticky animated background - responds to scroll interactively
          Positioned.fill(
            child: InteractiveGlowBackground(
              currentMood: currentMood,
              nextMood: nextMood,
              scrollProgress: _scrollProgress,
            ),
          ),

          // Scrolling mood pages (orb only - background handled above)
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              // Ensure final state update when scroll ends
              if (notification is ScrollEndNotification) {
                if (mounted) setState(() {});
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              onPageChanged: _onPageChanged,
              itemCount: null,
              physics: const ClampingScrollPhysics(),
              itemBuilder: (context, index) {
                final moodIndex = index % _moods.length;
                return RepaintBoundary(
                  child: MoodPageOrb(mood: _moods[moodIndex]),
                );
              },
            ),
          ),

          // Sticky overlay elements
          SafeArea(
            child: Stack(
              children: [
                // Top bar - Settings, Mood name, Playlist, Sleep timer
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Settings button
                          _GlassIconButton(
                            icon: Icons.settings,
                            onTap: () => context.push(AppRoutes.settings),
                          ),

                          // Right side buttons
                          Row(
                            children: [
                              // Playlist button
                              _GlassIconButton(
                                icon: Icons.queue_music,
                                onTap: () => context.push(AppRoutes.playlists),
                              ),
                              const SizedBox(width: 12),
                              // Sleep timer button
                              _GlassIconButton(
                                icon: Icons.bedtime,
                                isActive: musicState.sleepTimer != null,
                                onTap: () => _showSleepTimer(context, musicState),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Mood name at top
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          currentMood.displayName,
                          key: ValueKey(currentMood),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(color: Colors.black38, blurRadius: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom section - Track info, controls, swipe hint
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 24,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Track name
                      if (track != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 48),
                          child: Text(
                            track.name,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Minimalist music controls
                      MinimalistMusicControls(
                        isPlaying: musicState.isPlaying,
                        isMuted: musicState.volume == 0,
                        shuffleEnabled: musicState.shuffle,
                        onPlayPause: () => musicState.togglePlayPause(),
                        onNext: () => musicState.next(),
                        onPrevious: () => musicState.previous(),
                        onMuteToggle: () => _toggleMute(musicState),
                        onShuffleToggle: () => musicState.toggleShuffle(),
                      ),

                      const SizedBox(height: 24),

                      // Single swipe hint at bottom
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.keyboard_arrow_up,
                            color: Colors.white.withValues(alpha: 0.4),
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Swipe for more moods',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Welcome overlay on first paint
          if (_showWelcome)
            WelcomeOverlay(onComplete: _dismissWelcome),
        ],
      ),
    );
  }
}

/// Glass-morphism style icon button for top bar
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Colors.black.withValues(alpha: 0.3),
          border: Border.all(
            color: isActive
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

/// Orb-only mood page (no background - handled by navigator gradient)
class MoodPageOrb extends StatelessWidget {
  final MoodType mood;

  const MoodPageOrb({super.key, required this.mood});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final orbSize = screenSize.width < 400 ? 240.0 : 300.0;
    
    return Center(
      child: MoodOrbSelector(
        mood: mood,
        size: orbSize,
        intensity: 1.0,
      ),
    );
  }
}
