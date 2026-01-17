# Sound Therapy Feature - Implementation Guide

## Overview

The Sound Therapy feature provides curated playlists of calming sounds from FreeSound.org, tailored to the user's current emotional state (GlowMood). This feature integrates seamlessly with GlowMind's existing audio infrastructure and UI design patterns.

## Features

### 🎵 Curated Playlists
- **Balanced Mind**: 10 calming nature and ambient sounds for maintaining emotional balance
- **Anxiety Relief**: 10 soothing sounds specifically chosen to reduce anxiety and stress
- **Recovery & Restoration**: 10 restorative sounds for recovery from burnout and exhaustion

### 🎛️ Playback Controls
- Play/Pause toggle
- Previous/Next track navigation
- Shuffle mode
- Loop modes (Off, Loop One, Loop All)
- Progress bar with seek functionality
- Sleep timer integration

### 🎨 Beautiful UI
- Dark gradient backgrounds matching GlowMind theme
- Mood-specific colors (Purple for balanced, Blue for anxious, Grey for burnoutRisk)
- Smooth animations and transitions
- Consistent spacing and rounded corners
- Glowing effects on active elements

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    GlowHomePage                         │
│           [Soothing Sounds Button] ──┐                  │
└──────────────────────────────────────┼──────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────┐
│                SoundTherapyPage                         │
│  ┌───────────────────────────────────────────────┐     │
│  │  - Displays curated playlist                  │     │
│  │  - Integrates with MusicState                 │     │
│  │  - Playback controls                          │     │
│  │  - Sleep timer                                │     │
│  └───────────────────────────────────────────────┘     │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│            SoundTherapyService                          │
│  ┌───────────────────────────────────────────────┐     │
│  │  - Loads curated_sound_playlists.json         │     │
│  │  - Fetches stream URLs from FreeSound API     │     │
│  │  - Caches playlists                           │     │
│  │  - Maps GlowMood → Playlist                   │     │
│  └───────────────────────────────────────────────┘     │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│             FreesoundService                            │
│  ┌───────────────────────────────────────────────┐     │
│  │  - Calls Supabase Edge Function               │     │
│  │  - Gets download/stream URLs                  │     │
│  │  - Returns FreesoundSound objects             │     │
│  └───────────────────────────────────────────────┘     │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│      Supabase Edge Function (freesound-api)            │
│  ┌───────────────────────────────────────────────┐     │
│  │  - Proxies FreeSound API                      │     │
│  │  - Keeps API key secure                       │     │
│  │  - Handles rate limiting                      │     │
│  └───────────────────────────────────────────────┘     │
└──────────────┬──────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────┐
│              FreeSound API                              │
│         (https://freesound.org/apiv2)                   │
└─────────────────────────────────────────────────────────┘
```

## Files Created/Modified

### New Files
1. **`assets/curated_sound_playlists.json`**
   - Contains 10 tracks per GlowMood with sound IDs from FreeSound
   - Includes metadata like name, description, duration, tags

2. **`lib/services/sound_therapy_service.dart`**
   - Service for loading and managing curated sound therapy playlists
   - Handles JSON parsing, API calls, and caching
   - Maps GlowMood to MoodType for audio service compatibility

3. **`lib/pages/sound_therapy/sound_therapy_page.dart`**
   - Full-screen playlist UI with playback controls
   - Mood-specific theming and colors
   - Integrates with existing MusicState for playback

### Modified Files
1. **`pubspec.yaml`**
   - Added `assets/curated_sound_playlists.json` to assets list

2. **`lib/pages/home/glow_home_page.dart`**
   - Added "Soothing Sounds" button that opens SoundTherapyPage
   - Button appears below "Start Glow Ritual"
   - Uses mood-specific colors from current glow state

## Usage

### From User Perspective

1. **Access Sound Therapy**
   - Open GlowMind app
   - On home page, tap "Soothing Sounds" button
   - Playlist loads based on current emotional state

2. **Playback Controls**
   - Tap play/pause button to control playback
   - Use skip buttons to navigate tracks
   - Tap shuffle icon to randomize order
   - Tap repeat icon to cycle loop modes
   - Tap a track in the list to play it

3. **Sleep Timer**
   - Tap timer icon in top right
   - Select preset duration or custom time
   - Audio fades out 30 seconds before timer expires

### From Developer Perspective

```dart
// Get playlist for a mood
final soundService = SoundTherapyService();
final playlist = await soundService.getPlaylistForMood(
  GlowMood.balanced,
  userId,
);

// Play the playlist
final musicState = context.read<MusicState>();
await musicState.playPlaylist(playlist);

// Navigate to sound therapy page
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => SoundTherapyPage(
      mood: currentMood,
    ),
  ),
);
```

## Configuration

### FreeSound API Setup

The FreeSound API key is already configured in the Supabase Edge Function secrets:
- Secret Name: `FREESOUND_API_KEY`
- Value: `QDODuntRkC5I8w72iw9cQA0QUreRgXO3J4MAHIDD`

This is documented in `FREESOUND_GUIDE.md`.

### Supabase Edge Function

The edge function at `lib/supabase/functions/freesound-api/index.ts` handles:
- Authentication with FreeSound API
- Rate limiting
- Response transformation
- Error handling

## Curated Sound Selection Criteria

Sounds were curated based on:
1. **Duration**: 2-6 minutes for most tracks (longer for sleep-focused content)
2. **Quality**: High-rated sounds with clear previews
3. **License**: Preference for CC0 (public domain) or CC BY
4. **Relevance**: Tags matching mood characteristics
5. **Variety**: Mix of natural, ambient, and instrumental sounds

### Balanced Mind Playlist
- Ocean waves, forest birds, rain, singing bowls
- Focus: Gentle, neutral sounds for maintaining equilibrium

### Anxiety Relief Playlist
- Binaural beats, slow rhythms, white noise, meditation guides
- Focus: Grounding, rhythmic sounds to reduce stress

### Recovery & Restoration Playlist
- Deep ambient drones, spa sounds, delta waves, campfire
- Focus: Ultra-calm, restorative sounds for deep rest

## Testing

### Manual Testing Checklist

- [ ] Tap "Soothing Sounds" button on home page
- [ ] Verify correct playlist loads for current mood
- [ ] Test play/pause controls
- [ ] Test previous/next track navigation
- [ ] Test shuffle mode activation
- [ ] Test loop mode cycling (off → all → one → off)
- [ ] Test track selection from list
- [ ] Test progress bar seeking
- [ ] Test sleep timer functionality
- [ ] Test back navigation
- [ ] Verify UI matches GlowMind theme
- [ ] Test with different GlowMoods

### Error Cases

- Network failure: Shows error message with retry button
- Empty playlist: Shows "No sounds available" message
- API failure: Gracefully handles and continues with available tracks
- Missing sound: Skips to next track automatically

## Future Enhancements

1. **Offline Support**
   - Cache downloaded sounds locally
   - Pre-fetch playlists for offline use

2. **Personalization**
   - Allow users to create custom playlists
   - Save favorite sounds
   - Track listening history

3. **Additional Moods**
   - Expand to other MoodTypes (study, party, etc.)
   - Create hybrid playlists

4. **Social Features**
   - Share playlists with friends
   - Community-curated collections

5. **Advanced Features**
   - Crossfade between tracks
   - Volume normalization
   - EQ controls

## Troubleshooting

### Common Issues

**Problem**: "Failed to load playlist" error
- **Solution**: Check internet connection and Supabase Edge Function deployment

**Problem**: Sounds don't play
- **Solution**: Verify FreeSound API key is configured in Supabase secrets

**Problem**: UI doesn't match theme
- **Solution**: Ensure latest theme colors are used in SoundTherapyPage

**Problem**: Multiple audio instances playing
- **Solution**: Verify only one AudioService instance exists in app (managed by MusicState)

## Attribution

All sounds are sourced from FreeSound.org under Creative Commons licenses. Attribution is displayed in the UI as required by the licenses.

Format: `Sound "<name>" by <username> - freesound.org (<license>)`

## License Compliance

- **CC0**: No attribution required (preferred)
- **CC BY**: Attribution required (shown in UI)
- **CC BY-NC**: Attribution required, non-commercial use only

GlowMind is a personal wellness app (non-commercial context) and provides proper attribution for all sounds.

## Performance Considerations

- **Lazy Loading**: Playlists are loaded on-demand
- **Caching**: API responses are cached to minimize network calls
- **Stream URLs**: Fresh URLs fetched before playback to avoid expiration
- **Memory**: Only current playlist kept in memory

## Security

- API keys stored in Supabase secrets (not in client code)
- All API calls go through Edge Function proxy
- No direct client → FreeSound API communication
- Rate limiting handled server-side

---

## Support

For issues or questions:
1. Check this documentation
2. Review `FREESOUND_GUIDE.md` for API details
3. Check console logs for error messages
4. Verify Supabase Edge Function is deployed and working
