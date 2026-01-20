<p align="center">
  <img src="assets/icons/dreamflow_icon.jpg" alt="GlowMind Logo" width="120" height="120" style="border-radius: 24px;"/>
</p>

<h1 align="center">✨ GlowMind</h1>

<p align="center">
  <strong>Your AI-Powered Mental Wellness Companion</strong>
</p>

<p align="center">
  <em>Transform your emotional journey with ambient soundscapes, personalized affirmations, and intelligent mood insights</em>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#screenshots">Screenshots</a> •
  <a href="#getting-started">Getting Started</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#tech-stack">Tech Stack</a>
</p>

---

## 🌟 Overview

GlowMind is a beautifully crafted mental wellness app that combines ambient audio experiences with AI-powered insights to help you understand and improve your emotional well-being. With its signature **Living Glow Interface**, the app responds to your emotional patterns, creating a deeply personal and intuitive experience.

## ✨ Features

### 🎭 Mood-Based Soundscapes
Navigate through immersive audio experiences designed for different mental states:
- **🌙 Sleep** - Calming sounds to guide you into restful sleep
- **📚 Study** - Focus-enhancing ambient tracks for productivity
- **🎉 Party** - Upbeat energy to lift your spirits
- **🧘 Meditate** - Peaceful soundscapes for mindfulness
- **🎯 Deep Focus** - Concentration-boosting audio for flow states
- **🌿 Nature** - Natural ambient sounds for relaxation

### 💫 The Living Glow Engine
The app's centerpiece is an intelligent ambient system that:
- Analyzes your journal entries and sleep patterns
- Adapts its visual "glow" based on your emotional state
- Provides subtle visual cues about burnout risk and anxiety levels
- Creates a breathing, living interface that responds to you

### 📊 Insights Dashboard
Track your emotional wellness journey with:
- **Mood History Charts** - Visualize patterns over days, weeks, and months
- **Streak Tracking** - Build consistency in your wellness practice
- **Duration Analytics** - Understand how you spend time in different moods
- **Personalized Recommendations** - AI-driven suggestions based on your patterns

### 💬 Daily Affirmations
Boost your mindset with:
- **Curated Affirmations** - Carefully selected positive statements
- **Category-Based** - Self-love, confidence, gratitude, and more
- **Voice Recording** - Record and replay affirmations in your own voice
- **Favorites Collection** - Save and revisit your most impactful affirmations
- **Scheduled Reminders** - Daily affirmation notifications

### 🔐 Secure Authentication
- Email/Password sign-up and sign-in
- Google OAuth integration
- Guest mode for quick access
- Secure data sync across devices

### 😴 Sleep Tracking
- Set and track your bedtime and wake time
- Sleep duration analysis
- Integration with the Glow Engine for holistic wellness insights

## 🎨 Design Philosophy

GlowMind embraces a **dark, ambient aesthetic** with:
- Deep purple and blue gradients
- Glowing orb interfaces that pulse with life
- Smooth animations and transitions
- Particle effects and breathing backgrounds
- Accessibility-focused design

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.6.0 or higher
- Dart SDK 3.6.0 or higher
- Android Studio / VS Code
- A Supabase account (for backend services)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/glowmind.git
   cd glowmind
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**
   
   Create a file `lib/supabase/supabase_config.dart`:
   ```dart
   class SupabaseConfig {
     static const String supabaseUrl = 'YOUR_SUPABASE_URL';
     static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   }
   ```

4. **Set up the database**
   
   Run the SQL files in your Supabase SQL Editor:
   - `lib/supabase/supabase_tables.sql` - Create tables
   - `lib/supabase/supabase_policies.sql` - Set up RLS policies
   - `lib/supabase/music_schema.sql` - Initialize playlists

5. **Deploy Edge Functions**
   ```bash
   supabase functions deploy freesound-api
   ```

6. **Run the app**
   ```bash
   flutter run
   ```

### Running on Different Platforms

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web
flutter run -d chrome

# Windows
flutter run -d windows
```

## 🏗️ Architecture

```
lib/
├── main.dart                 # App entry point
├── nav.dart                  # GoRouter navigation
├── theme.dart                # App theming
│
├── auth/                     # Authentication
│   ├── auth_manager.dart
│   └── supabase_auth_manager.dart
│
├── models/                   # Data models
│   ├── models.dart           # Core models (Notes, Sleep, Glow)
│   ├── music_models.dart     # Music/Playlist models
│   ├── affirmation.dart      # Affirmation models
│   └── freesound_models.dart # Freesound API models
│
├── pages/                    # UI screens
│   ├── home/                 # Home with Glow Engine
│   ├── music/                # Mood-based player
│   ├── Insights/             # Analytics dashboard
│   ├── affirmations/         # Affirmation features
│   ├── sleep/                # Sleep tracking
│   └── auth/                 # Sign in/up pages
│
├── services/                 # Business logic
│   ├── glow_engine.dart      # AI emotional analysis
│   ├── audio_service.dart    # Audio playback
│   ├── freesound_service.dart# Freesound API integration
│   ├── insights_service.dart # Mood history analytics
│   ├── notification_service.dart
│   └── supabase_service.dart
│
├── state/                    # State management
│   ├── app_state.dart        # Global app state
│   ├── music_state.dart      # Music player state
│   └── affirmation_state.dart
│
├── widgets/                  # Reusable components
│   ├── glow_background.dart  # Animated backgrounds
│   ├── breathing_orb.dart    # Pulsing orb widget
│   ├── mood_chip.dart        # Mood selection chips
│   └── orbs/                 # Mood-specific orbs
│
└── supabase/                 # Backend configuration
    ├── supabase_config.dart
    ├── supabase_tables.sql
    ├── supabase_policies.sql
    └── music_schema.sql
```

## 🛠️ Tech Stack

| Layer | Technology |
|-------|------------|
| **Framework** | Flutter 3.6+ |
| **Language** | Dart |
| **State Management** | Provider |
| **Navigation** | GoRouter |
| **Backend** | Supabase (PostgreSQL + Auth + Edge Functions) |
| **Audio** | just_audio + audio_session |
| **Charts** | fl_chart |
| **Notifications** | flutter_local_notifications |
| **Audio API** | Freesound (via Edge Function) |

## 📱 Supported Platforms

| Platform | Status |
|----------|--------|
| Android | ✅ Fully Supported |
| iOS | ✅ Fully Supported |
| Web | ✅ Fully Supported |
| Windows | ✅ Supported |
| macOS | ✅ Supported |
| Linux | ✅ Supported |

## 🎵 Audio Sources

GlowMind uses a multi-layered approach to audio:

1. **Freesound API** - Primary source for mood-based ambient sounds (400k+ sounds)
2. **Global Playlists** - Curated playlists stored in Supabase
3. **User Playlists** - Personal playlists synced across devices
4. **Fallback Tracks** - SoundHelix samples for offline resilience

## 🔒 Security & Privacy

- Row-Level Security (RLS) on all database tables
- User data is isolated and encrypted
- OAuth 2.0 for Google authentication
- No data sold or shared with third parties

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Freesound](https://freesound.org/) - Community-driven sound library
- [Supabase](https://supabase.com/) - Open source Firebase alternative
- [Flutter](https://flutter.dev/) - Beautiful native apps framework
- [SoundHelix](https://www.soundhelix.com/) - Royalty-free demo tracks

---

<p align="center">
  Made with 💜 for your mental wellness
</p>

<p align="center">
  <strong>GlowMind</strong> — <em>Illuminate Your Inner Peace</em>
</p>