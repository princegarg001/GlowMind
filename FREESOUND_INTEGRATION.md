# FreeSound Integration Guide

## Overview

GlowMind integrates with the FreeSound API to provide mood-based sound therapy playlists. This integration uses Supabase edge functions to securely proxy API requests, keeping API keys secure and server-side.

## Architecture

### Components

1. **Mood Playlist Asset** (`assets/mood_playlists.json`)
   - Contains curated lists of FreeSound track IDs for each mood
   - Organized by mood: `balanced`, `anxious`, `burnoutRisk`
   - Each track includes metadata: name, description, duration, tags

2. **FreeSound Service** (`lib/services/freesound_service.dart`)
   - Communicates with Supabase edge function `freesound-proxy`
   - Fetches sound preview URLs from FreeSound API
   - Implements caching to minimize API calls
   - Handles errors gracefully

3. **Audio Player Service** (`lib/services/audio_player_service.dart`)
   - Manages audio playback using `audioplayers` package
   - Supports multiple playback modes: single, loop one, loop all, shuffle
   - Provides streams for state changes and progress updates
   - Singleton service for app-wide audio management

4. **Playlist Page UI** (`lib/pages/playlist/playlist_page.dart`)
   - Displays mood-specific playlists
   - Integrates with FreeSound and Audio Player services
   - Follows GlowMind's dark gradient design patterns
   - Shows loading states, errors, and playback controls

## How It Works

### 1. User Flow

1. User opens GlowMind home page
2. User taps "Soothing Sounds" button
3. App navigates to playlist page for current mood
4. Playlist loads from JSON asset
5. User taps a track to play
6. App fetches preview URL from FreeSound via Supabase
7. Audio plays with playback controls

### 2. Supabase Edge Function Integration

The integration uses an existing Supabase edge function that proxies FreeSound API requests:

**Endpoint:** `SupabaseConfig.client.functions.invoke('freesound-proxy', body: {...})`

**Request Format:**
```dart
// Get single sound
{
  "action": "get_sound",
  "sound_id": "12345"
}

// Search sounds (optional feature)
{
  "action": "search_sounds",
  "query": "ocean waves"
}
```

**Response Format (get_sound):**
```json
{
  "id": "12345",
  "name": "Ocean Waves",
  "previews": {
    "preview-hq-mp3": "https://freesound.org/data/previews/123/12345_123-hq.mp3",
    "preview-lq-mp3": "https://freesound.org/data/previews/123/12345_123-lq.mp3"
  },
  "duration": 120.5,
  "description": "Peaceful ocean waves",
  "tags": ["ocean", "waves", "nature"]
}
```

### 3. Caching Strategy

- FreeSound responses are cached in memory
- Cache persists for app session
- Reduces API calls and improves performance
- Can be cleared with `FreeSoundService.instance.clearCache()`

## Updating Playlists

### Adding New Tracks

1. Find tracks on [freesound.org](https://freesound.org)
2. Note the FreeSound ID (from URL, e.g., `https://freesound.org/people/username/sounds/12345/`)
3. Edit `assets/mood_playlists.json`
4. Add new track entry:

```json
{
  "name": "Track Name",
  "freesound_id": "12345",
  "description": "Brief description",
  "duration": 120,
  "tags": ["tag1", "tag2", "tag3"]
}
```

### Adding New Moods

To add a new mood category:

1. Update `GlowMood` enum in `lib/models/models.dart`:
   ```dart
   enum GlowMood { balanced, burnoutRisk, anxious, newMood }
   ```

2. Add playlist to `assets/mood_playlists.json`:
   ```json
   {
     "balanced": [...],
     "anxious": [...],
     "burnoutRisk": [...],
     "newMood": [...]
   }
   ```

3. Update `_moodToKey()` in `lib/models/mood_playlist.dart`:
   ```dart
   String _moodToKey(GlowMood mood) {
     switch (mood) {
       case GlowMood.balanced:
         return 'balanced';
       case GlowMood.anxious:
         return 'anxious';
       case GlowMood.burnoutRisk:
         return 'burnoutRisk';
       case GlowMood.newMood:
         return 'newMood';
     }
   }
   ```

4. Update `getMoodDisplayName()` with display name for UI

## Troubleshooting

### Sound Won't Play

**Symptom:** Track loads but doesn't play audio

**Possible Causes:**
1. FreeSound API returned invalid preview URL
2. Network connectivity issues
3. Audio format not supported

**Solutions:**
- Check debug console for FreeSound API errors
- Verify FreeSound ID is valid on freesound.org
- Test different track IDs
- Check device audio permissions

### Tracks Not Loading

**Symptom:** Loading spinner shows indefinitely

**Possible Causes:**
1. Supabase edge function not responding
2. FreeSound API rate limiting
3. Invalid sound ID

**Solutions:**
- Check Supabase edge function logs
- Verify internet connection
- Try different sound IDs
- Check FreeSound API status

### Cache Issues

**Symptom:** Old or incorrect preview URLs

**Solution:**
```dart
FreeSoundService.instance.clearCache();
```

### JSON Parse Errors

**Symptom:** Playlist doesn't load

**Possible Causes:**
1. Malformed JSON in `mood_playlists.json`
2. Missing required fields

**Solutions:**
- Validate JSON with online validator
- Check all required fields are present
- Verify asset is declared in `pubspec.yaml`

## Development Tips

### Testing Playlists

1. Use debug mode to see console logs
2. Test with different moods
3. Verify all tracks have valid FreeSound IDs
4. Check playback modes (loop, shuffle)

### Adding Features

The architecture supports:
- Custom playlists per user
- Favorites/bookmarking
- Playlist sharing
- Offline caching
- Background playback

### Performance

- First load fetches from API (cached afterward)
- Subsequent plays use cached URLs
- Memory usage scales with cache size
- Consider implementing cache size limits for production

## API References

### FreeSound Service

```dart
// Get sound by ID
final track = await FreeSoundService.instance.getSound('12345');

// Search sounds
final results = await FreeSoundService.instance.searchSounds('rain');

// Clear cache
FreeSoundService.instance.clearCache();
```

### Audio Player Service

```dart
final player = AudioPlayerService.instance;

// Play track
await player.playTrack(url, name);

// Control playback
await player.pause();
await player.resume();
await player.stop();

// Set playback mode
player.setPlaybackMode(PlaybackMode.loopAll);

// Listen to state
player.stateStream.listen((state) {
  // Handle state change
});
```

### Mood Playlist Service

```dart
final service = MoodPlaylistService.instance;

// Load playlists
await service.loadPlaylists();

// Get playlist for mood
final tracks = service.getPlaylistForMood(GlowMood.balanced);

// Get display name
final name = MoodPlaylistService.getMoodDisplayName(GlowMood.anxious);
```

## Security Notes

- FreeSound API keys are stored in Supabase edge functions (server-side)
- Client app never has direct access to API keys
- All API requests are proxied through Supabase
- Rate limiting is handled by edge function

## Future Enhancements

Potential improvements:
- User-created playlists
- Integration with Spotify/Apple Music
- Offline mode with downloaded tracks
- Background audio during other app features
- Sleep timer
- Playlist recommendations based on mood history
- Social features (share playlists)
