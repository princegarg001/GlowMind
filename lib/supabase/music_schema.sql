-- ============================================
-- GlowMind Music Schema
-- Supports both authenticated users and guests
-- ============================================

-- Drop existing tables if recreating (comment out in production)
-- DROP TABLE IF EXISTS playlist_tracks CASCADE;
-- DROP TABLE IF EXISTS playlists CASCADE;
-- DROP TABLE IF EXISTS user_music_prefs CASCADE;

-- ============================================
-- User Music Preferences
-- Stores per-user settings (volume, autoplay, etc.)
-- ============================================
CREATE TABLE IF NOT EXISTS user_music_prefs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL UNIQUE,  -- TEXT to support 'guest' and UUID strings
  last_mood TEXT CHECK (last_mood IS NULL OR last_mood IN ('sleep', 'study', 'party', 'meditate', 'deepFocus', 'nature')),
  last_track_id TEXT,
  volume FLOAT DEFAULT 0.7 CHECK (volume >= 0 AND volume <= 1),
  auto_play BOOLEAN DEFAULT true,
  shuffle BOOLEAN DEFAULT false,
  loop_mode TEXT DEFAULT 'all' CHECK (loop_mode IN ('off', 'one', 'all')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- Playlists Table
-- Stores playlists organized by mood
-- ============================================
CREATE TABLE IF NOT EXISTS playlists (
  id TEXT PRIMARY KEY,  -- TEXT to support custom IDs like 'guest_sleep_default'
  user_id TEXT NOT NULL,
  mood TEXT NOT NULL CHECK (mood IN ('sleep', 'study', 'party', 'meditate', 'deepFocus', 'nature')),
  name TEXT NOT NULL,
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- Playlist Tracks Table
-- Stores individual tracks within playlists
-- ============================================
CREATE TABLE IF NOT EXISTS playlist_tracks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  playlist_id TEXT NOT NULL REFERENCES playlists(id) ON DELETE CASCADE,
  track_name TEXT NOT NULL,
  track_url TEXT NOT NULL,
  source TEXT DEFAULT 'freesound' CHECK (source IN ('bundled', 'freesound', 'url')),
  freesound_id INTEGER,
  duration_seconds INTEGER,
  attribution TEXT,
  order_index INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- Indexes for Performance
-- ============================================
CREATE INDEX IF NOT EXISTS idx_user_music_prefs_user ON user_music_prefs(user_id);
CREATE INDEX IF NOT EXISTS idx_playlists_user ON playlists(user_id);
CREATE INDEX IF NOT EXISTS idx_playlists_user_mood ON playlists(user_id, mood);
CREATE INDEX IF NOT EXISTS idx_playlists_mood ON playlists(mood);
CREATE INDEX IF NOT EXISTS idx_playlist_tracks_playlist ON playlist_tracks(playlist_id);
CREATE INDEX IF NOT EXISTS idx_playlist_tracks_order ON playlist_tracks(playlist_id, order_index);

-- ============================================
-- Auto-update timestamps trigger
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

-- Apply trigger to tables with updated_at
DROP TRIGGER IF EXISTS update_user_music_prefs_updated_at ON user_music_prefs;
CREATE TRIGGER update_user_music_prefs_updated_at 
  BEFORE UPDATE ON user_music_prefs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_playlists_updated_at ON playlists;
CREATE TRIGGER update_playlists_updated_at 
  BEFORE UPDATE ON playlists
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- Row Level Security (RLS) Policies
-- Enable for production security
-- ============================================
ALTER TABLE user_music_prefs ENABLE ROW LEVEL SECURITY;
ALTER TABLE playlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE playlist_tracks ENABLE ROW LEVEL SECURITY;

-- Allow all operations for now (tighten in production)
DROP POLICY IF EXISTS "Allow all user_music_prefs" ON user_music_prefs;
CREATE POLICY "Allow all user_music_prefs" ON user_music_prefs 
  FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all playlists" ON playlists;
CREATE POLICY "Allow all playlists" ON playlists 
  FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all playlist_tracks" ON playlist_tracks;
CREATE POLICY "Allow all playlist_tracks" ON playlist_tracks 
  FOR ALL USING (true) WITH CHECK (true);

-- ============================================
-- Default Data: Pre-seeded playlists per mood
-- These serve as global defaults for all users
-- ============================================

-- Sleep mood default tracks
INSERT INTO playlists (id, user_id, mood, name, is_default) 
VALUES ('global_sleep_default', 'global', 'sleep', 'Sleep Sounds', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO playlist_tracks (playlist_id, track_name, track_url, source, order_index) VALUES
  ('global_sleep_default', 'Rain on Leaves', 'https://cdn.pixabay.com/audio/2022/05/27/audio_1808fbf07a.mp3', 'url', 0),
  ('global_sleep_default', 'Soft Piano Lullaby', 'https://cdn.pixabay.com/audio/2022/02/23/audio_ea70ad08e3.mp3', 'url', 1),
  ('global_sleep_default', 'Ocean Waves', 'https://cdn.pixabay.com/audio/2022/06/07/audio_b9bd4170e4.mp3', 'url', 2)
ON CONFLICT DO NOTHING;

-- Study mood default tracks
INSERT INTO playlists (id, user_id, mood, name, is_default) 
VALUES ('global_study_default', 'global', 'study', 'Study Focus', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO playlist_tracks (playlist_id, track_name, track_url, source, order_index) VALUES
  ('global_study_default', 'Lo-fi Study Beat', 'https://cdn.pixabay.com/audio/2022/10/25/audio_946b0939c5.mp3', 'url', 0),
  ('global_study_default', 'Focus Ambient', 'https://cdn.pixabay.com/audio/2022/03/15/audio_8cb749d484.mp3', 'url', 1),
  ('global_study_default', 'Coffee Shop Vibes', 'https://cdn.pixabay.com/audio/2023/07/30/audio_e5e5d61a5e.mp3', 'url', 2)
ON CONFLICT DO NOTHING;

-- Party mood default tracks
INSERT INTO playlists (id, user_id, mood, name, is_default) 
VALUES ('global_party_default', 'global', 'party', 'Party Vibes', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO playlist_tracks (playlist_id, track_name, track_url, source, order_index) VALUES
  ('global_party_default', 'Upbeat Electronic', 'https://cdn.pixabay.com/audio/2022/03/10/audio_d89c289308.mp3', 'url', 0),
  ('global_party_default', 'Dance Energy', 'https://cdn.pixabay.com/audio/2022/11/22/audio_3676e5c8e9.mp3', 'url', 1),
  ('global_party_default', 'EDM Drop', 'https://cdn.pixabay.com/audio/2023/09/04/audio_de5f4a2c92.mp3', 'url', 2)
ON CONFLICT DO NOTHING;

-- Meditate mood default tracks
INSERT INTO playlists (id, user_id, mood, name, is_default) 
VALUES ('global_meditate_default', 'global', 'meditate', 'Meditation', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO playlist_tracks (playlist_id, track_name, track_url, source, order_index) VALUES
  ('global_meditate_default', 'Tibetan Bowls', 'https://cdn.pixabay.com/audio/2022/02/07/audio_3c1e8b9e15.mp3', 'url', 0),
  ('global_meditate_default', 'Zen Garden', 'https://cdn.pixabay.com/audio/2022/01/26/audio_d1718ab41b.mp3', 'url', 1),
  ('global_meditate_default', 'Deep Breath', 'https://cdn.pixabay.com/audio/2022/03/12/audio_b4f3c4519e.mp3', 'url', 2)
ON CONFLICT DO NOTHING;

-- Deep Focus mood default tracks
INSERT INTO playlists (id, user_id, mood, name, is_default) 
VALUES ('global_deepFocus_default', 'global', 'deepFocus', 'Deep Focus', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO playlist_tracks (playlist_id, track_name, track_url, source, order_index) VALUES
  ('global_deepFocus_default', 'Binaural Focus', 'https://cdn.pixabay.com/audio/2022/08/23/audio_3b8e68f90d.mp3', 'url', 0),
  ('global_deepFocus_default', 'Concentration Mode', 'https://cdn.pixabay.com/audio/2022/05/17/audio_407815a5b6.mp3', 'url', 1),
  ('global_deepFocus_default', 'White Noise', 'https://cdn.pixabay.com/audio/2022/03/24/audio_7a0ba7a7aa.mp3', 'url', 2)
ON CONFLICT DO NOTHING;

-- Nature mood default tracks
INSERT INTO playlists (id, user_id, mood, name, is_default) 
VALUES ('global_nature_default', 'global', 'nature', 'Nature Sounds', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO playlist_tracks (playlist_id, track_name, track_url, source, order_index) VALUES
  ('global_nature_default', 'Forest Ambience', 'https://cdn.pixabay.com/audio/2022/08/04/audio_2dde668d05.mp3', 'url', 0),
  ('global_nature_default', 'Birds Chirping', 'https://cdn.pixabay.com/audio/2021/09/06/audio_0917bff64a.mp3', 'url', 1),
  ('global_nature_default', 'Waterfall', 'https://cdn.pixabay.com/audio/2022/02/17/audio_cc63d1d5ad.mp3', 'url', 2)
ON CONFLICT DO NOTHING;

-- ============================================
-- Verification Query (run to test)
-- ============================================
-- SELECT p.mood, p.name, COUNT(pt.id) as track_count 
-- FROM playlists p 
-- LEFT JOIN playlist_tracks pt ON pt.playlist_id = p.id 
-- GROUP BY p.id, p.mood, p.name 
-- ORDER BY p.mood;
