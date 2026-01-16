# Visual Guide: Immersive Mood Swiper Feature

## Application Flow

```
┌──────────────────────────────────────────────────────────────┐
│                      App Launch                               │
│                   (Splash Screen)                             │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────┐
│                    Auth Page                                  │
│           (Login / Sign Up / Guest)                          │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────┐
│              VerticalMoodNavigator                            │
│                   (Home Page)                                 │
│                                                               │
│   ┌────────────────────────────────────────────────────┐    │
│   │            Mood Page: SLEEP                         │    │
│   │  [⚙️]                            [🎵] [🌙]          │    │
│   │                                                     │    │
│   │              ┌─────────────┐                       │    │
│   │              │   ╭─────╮   │                       │    │
│   │              │   │ 🟣  │   │  ← Purple Orb        │    │
│   │              │   ╰─────╯   │     (Pulsing)        │    │
│   │              └─────────────┘                       │    │
│   │                                                     │    │
│   │              Sleep Mode                            │    │
│   │           Rain on Leaves                           │    │
│   │                                                     │    │
│   │          [⏮️]  [⏸️]  [⏭️]                          │    │
│   │       ────────●──────────                          │    │
│   │       2:34 / 8:00                                  │    │
│   │                                                     │    │
│   │       [🔀]  [🔁]  [🔊]                            │    │
│   │                                                     │    │
│   │    ⬆️ Swipe up for Study                          │    │
│   │    ⬇️ Swipe down for Nature                        │    │
│   │    🎵 Tap here for playlist                        │    │
│   └────────────────────────────────────────────────────┘    │
│                        ▲│                                     │
│   ┌────────────────────┘│                                    │
│   │  Vertical Swipe     │                                    │
│   ▼                     ▼                                    │
│   Study → Party → Meditate → Deep Focus → Nature            │
└──────────────────────────────────────────────────────────────┘
```

## Mood Swiper Structure

```
╔═══════════════════════════════════════════════════════╗
║  PageView (Vertical Scroll)                          ║
║  ┌─────────────────────────────────────────────────┐ ║
║  │ Page 0: Sleep (Purple)                          │ ║
║  └─────────────────────────────────────────────────┘ ║
║  ┌─────────────────────────────────────────────────┐ ║
║  │ Page 1: Study (Blue)                            │ ║
║  └─────────────────────────────────────────────────┘ ║
║  ┌─────────────────────────────────────────────────┐ ║
║  │ Page 2: Party (Pink)                            │ ║
║  └─────────────────────────────────────────────────┘ ║
║  ┌─────────────────────────────────────────────────┐ ║
║  │ Page 3: Meditate (Green)                        │ ║
║  └─────────────────────────────────────────────────┘ ║
║  ┌─────────────────────────────────────────────────┐ ║
║  │ Page 4: Deep Focus (Cyan)                       │ ║
║  └─────────────────────────────────────────────────┘ ║
║  ┌─────────────────────────────────────────────────┐ ║
║  │ Page 5: Nature (Earth-tone)                     │ ║
║  └─────────────────────────────────────────────────┘ ║
╚═══════════════════════════════════════════════════════╝
```

## State Management Architecture

```
                    ┌─────────────────────┐
                    │      AppState       │
                    │  (ChangeNotifier)   │
                    └──────────┬──────────┘
                               │
                    ┌──────────┴──────────┐
                    │                     │
         ┌──────────▼────────┐  ┌────────▼───────────┐
         │    GlowEngine     │  │    MusicState      │
         │                   │  │ (ChangeNotifier)   │
         └───────────────────┘  └────────┬───────────┘
                                         │
                           ┌─────────────┴─────────────┐
                           │                           │
                  ┌────────▼─────────┐      ┌─────────▼────────┐
                  │   AudioService   │      │  MusicStorage    │
                  │                  │      │                  │
                  │ - Playback       │      │ - Local (SP)     │
                  │ - Playlists      │      │ - Supabase       │
                  │ - Sleep Timer    │      │ - CRUD           │
                  └──────────────────┘      └──────────────────┘
                           │
                  ┌────────┴────────┐
                  │                 │
         ┌────────▼────────┐  ┌────▼──────────┐
         │   just_audio    │  │ audio_session │
         │   (Package)     │  │   (Package)   │
         └─────────────────┘  └───────────────┘
```

## Playlist Manager Page

```
┌───────────────────────────────────────────────────────────┐
│  ← Playlists                                              │
├───────────────────────────────────────────────────────────┤
│  [Now Playing] [All Playlists] [Surprise Me]             │
├───────────────────────────────────────────────────────────┤
│                                                           │
│  Tab 1: Now Playing                                       │
│  ┌─────────────────────────────────────────────────────┐ │
│  │  Sleep Playlist                                      │ │
│  │  3 tracks                                            │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                           │
│  ┌─────────────────────────────────────────────────────┐ │
│  │  🎵  1  Rain on Leaves                              │ │
│  └─────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────┐ │
│  │  🎵  2  Soft Piano Lullaby                          │ │
│  └─────────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────────┐ │
│  │  ♬  3  Ocean Waves                ← Currently playing│ │
│  └─────────────────────────────────────────────────────┘ │
│                                                           │
│  Tab 2: All Playlists                                     │
│  Shows all playlists for current mood                     │
│                                                           │
│  Tab 3: Surprise Me                                       │
│  Auto-generate playlist based on mood                     │
│                                                           │
└───────────────────────────────────────────────────────────┘
```

## Sleep Timer Dialog

```
┌─────────────────────────────────────────┐
│  Sleep Timer                       [×]  │
├─────────────────────────────────────────┤
│                                         │
│   [5m]  [10m]  [15m]  [30m]            │
│                                         │
│   [45m]  [1h]  [2h]  [Custom]          │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  [-]    30 min    [+]           │   │
│  └─────────────────────────────────┘   │
│                                         │
│         [Start Timer]                   │
│                                         │
│  OR (if timer active):                  │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │         ⏱️                        │   │
│  │       23:45                      │   │
│  │    Timer Active                 │   │
│  └─────────────────────────────────┘   │
│                                         │
│         [Cancel Timer]                  │
│                                         │
└─────────────────────────────────────────┘
```

## Mood Color Palette

```
┌──────────────┬──────────────┬──────────────────────┐
│ Mood         │ Primary      │ Secondary            │
├──────────────┼──────────────┼──────────────────────┤
│ Sleep        │ 🟣 #8B5CF6   │ 🟣 #6366F1 (Indigo) │
│ Study        │ 🔵 #3B82F6   │ 🔵 #60A5FA          │
│ Party        │ 🌸 #EC4899   │ 🔴 #F43F5E          │
│ Meditate     │ 🟢 #10B981   │ 🟢 #34D399          │
│ Deep Focus   │ 🔵 #06B6D4   │ 🔵 #22D3EE (Cyan)   │
│ Nature       │ 🟢 #84CC16   │ 🟢 #A3E635 (Lime)   │
└──────────────┴──────────────┴──────────────────────┘
```

## Data Flow: Changing Moods

```
User swipes vertically
        │
        ▼
PageView.onPageChanged
        │
        ▼
VerticalMoodNavigator._onPageChanged()
        │
        ▼
MusicState.changeMood(newMood)
        │
        ├─► Save to preferences (local)
        │
        ├─► Save to Supabase (async)
        │
        ├─► Load playlists for mood
        │
        ▼
AudioService.loadPlaylist()
        │
        ├─► Load first track
        │
        ├─► Apply shuffle if enabled
        │
        ▼
AudioService.play() (if auto-play)
        │
        ▼
Music starts playing 🎵
```

## Database Schema

```
┌────────────────────────┐
│  user_music_prefs      │
├────────────────────────┤
│ id (PK)                │
│ user_id (FK → users)   │
│ last_mood              │
│ last_track_id          │
│ volume                 │
│ auto_play              │
│ shuffle                │
│ loop_mode              │
│ created_at             │
│ updated_at             │
└────────────────────────┘
           │
           │ 1:N
           ▼
┌────────────────────────┐
│  playlists             │
├────────────────────────┤
│ id (PK)                │
│ user_id (FK → users)   │
│ mood                   │
│ name                   │
│ is_default             │
│ created_at             │
│ updated_at             │
└────────────────────────┘
           │
           │ 1:N
           ▼
┌────────────────────────┐
│  playlist_tracks       │
├────────────────────────┤
│ id (PK)                │
│ playlist_id (FK)       │
│ track_name             │
│ track_url              │
│ source                 │
│ freesound_id           │
│ duration_seconds       │
│ attribution            │
│ order_index            │
│ created_at             │
└────────────────────────┘
```

## User Interaction Examples

### Example 1: First Time User
```
1. User logs in
2. Lands on Sleep mood (default)
3. Default playlist loads
4. Music auto-plays (if enabled)
5. User sees purple orb pulsing slowly
6. User swipes up → Study mood
7. Music switches to lo-fi beats
8. Orb changes to blue with steady pulse
```

### Example 2: Returning User
```
1. User opens app
2. App loads last used mood (e.g., Meditate)
3. Restores playlist and position
4. User sets 30-minute sleep timer
5. Music plays for 29.5 minutes
6. Last 30 seconds: music fades out
7. At 30 minutes: music stops
```

### Example 3: Exploring Playlists
```
1. User on Party mood
2. Taps playlist button 🎵
3. Opens playlist manager
4. Switches to "All Playlists" tab
5. Sees multiple party playlists
6. Selects "Energetic Mix"
7. Returns to mood page
8. New playlist starts playing
```

## Performance Considerations

```
Animation Frame Rate
┌──────────────────────────────────────────┐
│ Target: 60 FPS (16.67ms per frame)      │
├──────────────────────────────────────────┤
│ MoodOrb Animation:                       │
│   ✓ Uses AnimationController             │
│   ✓ Hardware accelerated                 │
│   ✓ Const constructors where possible    │
│                                          │
│ PageView Scrolling:                      │
│   ✓ BouncingScrollPhysics               │
│   ✓ No heavy computations in build()    │
│   ✓ Efficient widget rebuilds           │
│                                          │
│ Audio Playback:                          │
│   ✓ Runs on separate isolate            │
│   ✓ Doesn't block UI thread             │
│   ✓ Efficient state updates via streams │
└──────────────────────────────────────────┘
```

---

This visual guide provides a comprehensive overview of the immersive mood swiper feature's structure, flow, and interactions.
