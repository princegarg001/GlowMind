# Freesound API Integration Guide for GlowMind

This guide explains how to integrate the Freesound API to fetch and play ambient sounds based on mood in the GlowMind app.

## Table of Contents
1. [Getting API Credentials](#getting-api-credentials)
2. [Environment Setup](#environment-setup)
3. [Architecture Overview](#architecture-overview)
4. [API Endpoints](#api-endpoints)
5. [Mood-to-Sound Mapping](#mood-to-sound-mapping)
6. [Usage Examples](#usage-examples)
7. [Attribution Requirements](#attribution-requirements)

---

## Getting API Credentials

### Step 1: Create a Freesound Account
1. Go to [https://freesound.org](https://freesound.org)
2. Register for a free account

### Step 2: Apply for API Credentials
1. Navigate to [https://freesound.org/apiv2/apply/](https://freesound.org/apiv2/apply/)
2. Fill in the application form:
   - **Name**: `glowmind`
   - **URL**: Your app's website or GitHub repository
   - **Callback URL**: `http://freesound.org/home/app_permissions/permission_granted/`
   - **Description**: Describe your app (e.g., "GlowMind is a mood-based ambient sound and meditation app")
3. Accept the terms of use
4. Submit the application

### Step 3: Get Your Credentials
After approval, you'll receive:
- **Client ID**: Used for OAuth2 authentication
- **API Key**: Used for API requests (this is what we need)

---

## Environment Setup

### Supabase Edge Function Secrets

Add the following secrets to your Supabase Edge Functions via the Supabase Panel in Dreamflow:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `FREESOUND_API_KEY` | Your Freesound API key | `abc123xyz...` |
| `FREESOUND_CLIENT_ID` | Your Freesound Client ID (optional, for OAuth) | `12345` |

### How to Add Secrets in Dreamflow:
1. Open the **Supabase** panel from the left sidebar
2. Navigate to **Edge Functions**
3. Click on the `freesound-api` function
4. Go to **Secrets** tab
5. Add `FREESOUND_API_KEY` with your API key value
6. Deploy the edge function

---

## Architecture Overview

```
┌─────────────────┐      ┌──────────────────────┐      ┌─────────────────┐
│                 │      │                      │      │                 │
│  Flutter App    │─────▶│  Supabase Edge       │─────▶│  Freesound API  │
│  (GlowMind)     │      │  Function            │      │                 │
│                 │◀─────│  (freesound-api)     │◀─────│                 │
└─────────────────┘      └──────────────────────┘      └─────────────────┘
        │                                                      
        │                                                      
        ▼                                                      
┌─────────────────┐                                           
│  Audio Service  │                                           
│  (just_audio)   │                                           
└─────────────────┘                                           
```

**Why use an Edge Function?**
- Keeps your API key secure (not exposed in client code)
- Allows rate limiting and caching
- Enables custom sound filtering and curation

---

## API Endpoints

### Supabase Edge Function: `freesound-api`

#### Search Sounds by Mood
```
POST /functions/v1/freesound-api
Content-Type: application/json
Authorization: Bearer <anon-key>

{
  "action": "search",
  "mood": "sleep",
  "page": 1,
  "pageSize": 15
}
```

**Response:**
```json
{
  "count": 150,
  "results": [
    {
      "id": 123456,
      "name": "Gentle Rain",
      "url": "https://freesound.org/...",
      "previewUrl": "https://freesound.org/data/previews/...",
      "duration": 120.5,
      "username": "soundauthor",
      "license": "Creative Commons 0",
      "tags": ["rain", "ambient", "relaxing"]
    }
  ]
}
```

#### Get Sound Details
```
POST /functions/v1/freesound-api
Content-Type: application/json
Authorization: Bearer <anon-key>

{
  "action": "getSoundDetails",
  "soundId": 123456
}
```

#### Get Download URL
```
POST /functions/v1/freesound-api
Content-Type: application/json
Authorization: Bearer <anon-key>

{
  "action": "getDownloadUrl",
  "soundId": 123456
}
```

---

## Mood-to-Sound Mapping

The edge function automatically maps GlowMind moods to Freesound search queries:

| Mood | Search Keywords | Filters |
|------|-----------------|---------|
| `sleep` | `"ambient sleep relaxing soft"` | duration: 60-600s |
| `study` | `"lo-fi ambient background focus"` | duration: 120-600s |
| `party` | `"upbeat electronic dance energy"` | duration: 120-300s |
| `meditate` | `"meditation zen calm peaceful"` | duration: 60-600s |
| `deepFocus` | `"binaural focus concentration ambient"` | duration: 180-600s |
| `nature` | `"nature forest rain ocean birds"` | duration: 60-600s |

---

## Usage Examples

### In Flutter - Using FreesoundService

```dart
import 'package:glowmind/services/freesound_service.dart';

// Initialize service
final freesoundService = FreesoundService();

// Search sounds by mood
final sounds = await freesoundService.searchByMood(MoodType.sleep);

// Get sound details
final details = await freesoundService.getSoundDetails(123456);

// Convert to Track for AudioService
final track = Track(
  id: 'freesound_123456',
  name: 'Gentle Rain',
  url: previewUrl,
  source: 'freesound',
  freesoundId: 123456,
  durationSeconds: 120,
  attribution: 'Sound by username - freesound.org',
);

// Play with AudioService
final playlist = Playlist(
  id: 'freesound_sleep',
  userId: 'user123',
  mood: MoodType.sleep,
  name: 'Sleep Sounds from Freesound',
  tracks: [track],
  createdAt: DateTime.now(),
);

audioService.loadPlaylist(playlist);
audioService.play();
```

### Creating a Mood Playlist

```dart
Future<Playlist> createMoodPlaylist(MoodType mood, String userId) async {
  final sounds = await freesoundService.searchByMood(mood, pageSize: 10);
  
  final tracks = sounds.map((sound) => Track(
    id: 'freesound_${sound.id}',
    name: sound.name,
    url: sound.previewUrl,
    source: 'freesound',
    freesoundId: sound.id,
    durationSeconds: sound.duration.toInt(),
    attribution: 'Sound by ${sound.username} - freesound.org',
  )).toList();
  
  return Playlist(
    id: 'freesound_${mood.name}_${DateTime.now().millisecondsSinceEpoch}',
    userId: userId,
    mood: mood,
    name: '${mood.displayName} Sounds',
    tracks: tracks,
    createdAt: DateTime.now(),
  );
}
```

---

## Attribution Requirements

**Important:** Freesound requires attribution for most sounds. Always display:

1. **Sound name and author**
2. **Link to original sound on Freesound**
3. **License type**

### Example Attribution Widget

```dart
Widget buildAttribution(Track track) {
  if (track.attribution == null) return SizedBox.shrink();
  
  return Text(
    track.attribution!,
    style: TextStyle(fontSize: 10, color: Colors.grey),
  );
}
```

### License Types on Freesound:
- **CC0 (Public Domain)**: No attribution required
- **CC BY**: Attribution required
- **CC BY-NC**: Attribution required, non-commercial use only
- **CC Sampling+**: Special sampling license

---

## Rate Limits

Freesound API has the following limits:
- **Requests per day**: 2,000 (may vary)
- **Requests per minute**: 60

The edge function includes basic caching to minimize API calls.

---

## Troubleshooting

### Common Issues

1. **"Invalid API key" error**
   - Check that `FREESOUND_API_KEY` is correctly set in Supabase secrets
   - Verify the API key hasn't expired

2. **No sounds returned**
   - Try broader search terms
   - Check if filters are too restrictive

3. **Preview URL not working**
   - Freesound preview URLs are temporary; fetch fresh URLs before playing
   - Use `hq-mp3` or `lq-mp3` preview formats

4. **CORS errors**
   - All requests should go through the edge function, not directly to Freesound

---

## Additional Resources

- [Freesound API Documentation](https://freesound.org/docs/api/)
- [Freesound API Reference](https://freesound.org/apiv2/)
- [License Information](https://freesound.org/help/faq/#licenses)

---

## Files Created/Modified for Integration

| File | Purpose |
|------|---------|
| `supabase/functions/freesound-api/index.ts` | Edge function handling API calls |
| `lib/services/freesound_service.dart` | Flutter service for Freesound |
| `lib/models/freesound_models.dart` | Data models for API responses |
| `FREESOUND_GUIDE.md` | This guide |
