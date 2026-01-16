import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:glowmind/models/music_models.dart';
import 'package:glowmind/state/music_state.dart';
import 'package:glowmind/pages/music/mood_page.dart';
import 'package:glowmind/nav.dart';

/// TikTok-style vertical mood swiper with full-screen immersive UI
class VerticalMoodNavigator extends StatefulWidget {
  const VerticalMoodNavigator({super.key});

  @override
  State<VerticalMoodNavigator> createState() => _VerticalMoodNavigatorState();
}

class _VerticalMoodNavigatorState extends State<VerticalMoodNavigator> {
  late PageController _pageController;
  int _currentPageIndex = 0;

  // All moods in order
  final List<MoodType> _moods = [
    MoodType.sleep,
    MoodType.study,
    MoodType.party,
    MoodType.meditate,
    MoodType.deepFocus,
    MoodType.nature,
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize page controller
    _pageController = PageController(
      initialPage: _currentPageIndex,
      viewportFraction: 1.0,
    );

    // Load last mood from music state after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLastMood();
    });
  }

  /// Load and restore last played mood
  void _loadLastMood() {
    final musicState = context.read<MusicState>();
    final lastMood = musicState.preferences?.lastMood;
    
    if (lastMood != null) {
      final index = _moods.indexOf(lastMood);
      if (index >= 0 && index != _currentPageIndex) {
        setState(() {
          _currentPageIndex = index;
        });
        _pageController.jumpToPage(index);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (index == _currentPageIndex) return;

    setState(() {
      _currentPageIndex = index;
    });

    // Change mood in music state
    final musicState = context.read<MusicState>();
    final newMood = _moods[index];
    musicState.changeMood(newMood);
  }

  void _onSettings() {
    context.push(AppRoutes.settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No app bar for immersive experience
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        onPageChanged: _onPageChanged,
        itemCount: _moods.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return MoodPage(
            mood: _moods[index],
            onSettings: _onSettings,
          );
        },
      ),
    );
  }
}
