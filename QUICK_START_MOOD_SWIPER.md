# Quick Start Guide: Immersive Mood Swiper

This guide helps you quickly understand and use the new immersive mood swiper feature in GlowMind.

## What's New?

The home page (`/home`) is now a TikTok-style vertical swiper with 6 immersive mood environments, each with:
- Animated mood orb with unique colors
- Background music playback
- Sleep timer functionality
- Full-screen immersive experience

## For Users

### Navigation
- **Swipe Up**: Move to next mood
- **Swipe Down**: Move to previous mood
- **Top-left Icon**: Settings
- **Top-right Icons**: Playlists & Sleep Timer

### Music Controls
- **Play/Pause Button**: Toggle playback
- **Skip Buttons**: Previous/Next track
- **Progress Bar**: Seek through track
- **Volume Slider**: Adjust volume
- **Shuffle Icon**: Toggle shuffle mode
- **Repeat Icon**: Cycle through loop modes (off → all → one)

### Sleep Timer
1. Tap the moon icon (top-right)
2. Select a preset time or custom duration
3. Music will fade out 30 seconds before timer ends
4. Playback stops when timer expires

### Playlists
1. Tap the playlist icon (top-right) or the hint at bottom
2. **Now Playing**: See current queue
3. **All Playlists**: Browse playlists for current mood
4. **Surprise Me**: Generate random playlist (coming soon)

## For Developers

### Architecture

```
┌─────────────────────────────────────┐
│      VerticalMoodNavigator          │
│  (PageView with 6 MoodPages)        │
└──────────────┬──────────────────────┘
               │
       ┌───────┴────────┐
       │   MusicState   │ (ChangeNotifier)
       └───────┬────────┘
               │
    ┌──────────┴──────────┐
    │                     │
┌───▼──────┐      ┌──────▼────┐
│  Audio   │      │  Music    │
│ Service  │      │  Storage  │
└──────────┘      └───────────┘
```

### Key Classes

**MusicState** (`lib/state/music_state.dart`)
- Main state manager for music feature
- Manages current mood, playlist, playback state
- Provides methods: `changeMood()`, `togglePlayPause()`, `next()`, `previous()`

**AudioService** (`lib/services/audio_service.dart`)
- Handles audio playback using just_audio
- Manages playlists, shuffle, loop modes
- Implements sleep timer with fade-out

**MusicStorage** (`lib/services/music_storage.dart`)
- Persists preferences locally (SharedPreferences)
- Syncs with Supabase database
- Manages playlist CRUD operations

### Adding Custom Moods

To add a new mood:

1. Add to `MoodType` enum in `lib/models/music_models.dart`:
```dart
enum MoodType {
  // ... existing moods
  yourMood,
}
```

2. Add color configuration in `lib/widgets/mood_orb.dart`:
```dart
Color _getMoodColor() {
  switch (widget.mood) {
    // ... existing cases
    case MoodType.yourMood:
      return const Color(0xFFYOURCOLOR);
  }
}
```

3. Add background gradient in `lib/pages/music/mood_page.dart`:
```dart
List<Color> _getBackgroundColors() {
  switch (mood) {
    // ... existing cases
    case MoodType.yourMood:
      return [Color(0xFF...), Color(0xFF...)];
  }
}
```

4. Add default tracks in `lib/services/music_storage.dart`:
```dart
List<Track> _getDefaultTracks(MoodType mood) {
  switch (mood) {
    // ... existing cases
    case MoodType.yourMood:
      return [...];
  }
}
```

5. Update `_moods` list in `lib/pages/music/vertical_mood_navigator.dart`:
```dart
final List<MoodType> _moods = [
  // ... existing moods
  MoodType.yourMood,
];
```

### Integrating with Existing Features

The music feature is designed to integrate seamlessly:

**Access MusicState from any widget:**
```dart
final musicState = context.read<MusicState>();
// or
final musicState = context.watch<MusicState>();
```

**Change mood programmatically:**
```dart
await musicState.changeMood(MoodType.study);
```

**Check current playback state:**
```dart
if (musicState.isPlaying) {
  // Music is playing
}
```

**Get current track info:**
```dart
final track = musicState.currentTrack;
if (track != null) {
  print('Now playing: ${track.name}');
}
```

### Database Setup

Run this SQL in your Supabase project:
```sql
-- See lib/supabase/music_schema.sql for full schema
```

Or import the file directly in Supabase SQL Editor.

### Testing Locally

1. **Run the app:**
```bash
flutter run
```

2. **Login/Sign up** to create a user

3. **You'll land on the mood swiper** automatically

4. **Test features:**
   - Swipe vertically to change moods
   - Play/pause music
   - Set a sleep timer (short duration for testing)
   - Browse playlists
   - Check if last mood persists after app restart

### Troubleshooting

**Audio not playing:**
- Check internet connection (default tracks are URLs)
- Check device volume
- Verify audio URLs in `MusicStorage._getDefaultTracks()`

**Last mood not restoring:**
- Check SharedPreferences implementation
- Verify user is logged in
- Check Supabase sync

**Swipe not working:**
- Ensure PageView physics is enabled
- Check for gesture conflicts
- Verify PageController is initialized

**Build errors:**
- Run `flutter pub get`
- Check all imports
- Ensure just_audio and dependencies are installed

### Performance Tips

1. **Preload next track** in playlist for seamless transitions
2. **Lazy load playlists** - only load when needed
3. **Optimize orb animations** - use `RepaintBoundary` if needed
4. **Cache audio files** for offline playback
5. **Debounce mood changes** during rapid swipes

### Security Considerations

1. **Audio URLs** should be HTTPS
2. **User preferences** are user-specific via Supabase RLS
3. **API keys** (Freesound) should be in environment variables
4. **Audio session** properly configured for background playback

## Next Steps

1. **Test the feature** thoroughly on different devices
2. **Customize default playlists** with your own audio files
3. **Implement Freesound API** for dynamic track discovery
4. **Add track caching** for offline playback
5. **Integrate with glow engine** for mood-based recommendations
6. **Add analytics** to track popular moods and tracks

## Support

For issues or questions:
1. Check `MOOD_SWIPER_IMPLEMENTATION.md` for detailed documentation
2. Review code comments in source files
3. Check existing issues in the repository
4. Create a new issue with detailed information

## Contributing

When contributing to this feature:
1. Follow existing code style
2. Add comments for complex logic
3. Update documentation if adding new features
4. Test thoroughly before submitting PR
5. Keep changes minimal and focused

---

**Happy Coding! 🎵✨**
