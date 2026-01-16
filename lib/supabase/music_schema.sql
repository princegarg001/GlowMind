-- Music schema for GlowMind immersive mood swiper feature

-- User music preferences table
CREATE TABLE IF NOT EXISTS user_music_prefs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  last_mood TEXT,
  last_track_id TEXT,
  volume FLOAT DEFAULT 0.7 CHECK (volume >= 0 AND volume <= 1),
  auto_play BOOLEAN DEFAULT true,
  shuffle BOOLEAN DEFAULT false,
  loop_mode TEXT DEFAULT 'all' CHECK (loop_mode IN ('off', 'one', 'all')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id)
);

-- Custom playlists table
CREATE TABLE IF NOT EXISTS playlists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  mood TEXT NOT NULL CHECK (mood IN ('sleep', 'study', 'party', 'meditate', 'deepFocus', 'nature')),
  name TEXT NOT NULL,
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Playlist tracks table
CREATE TABLE IF NOT EXISTS playlist_tracks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  playlist_id UUID REFERENCES playlists(id) ON DELETE CASCADE,
  track_name TEXT NOT NULL,
  track_url TEXT NOT NULL,
  source TEXT NOT NULL DEFAULT 'bundled' CHECK (source IN ('bundled', 'freesound', 'url')),
  freesound_id INTEGER,
  duration_seconds INTEGER,
  attribution TEXT,
  order_index INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_music_prefs_user ON user_music_prefs(user_id);
CREATE INDEX IF NOT EXISTS idx_playlists_user_mood ON playlists(user_id, mood);
CREATE INDEX IF NOT EXISTS idx_playlist_tracks_playlist ON playlist_tracks(playlist_id);
CREATE INDEX IF NOT EXISTS idx_playlist_tracks_order ON playlist_tracks(playlist_id, order_index);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_user_music_prefs_updated_at BEFORE UPDATE ON user_music_prefs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_playlists_updated_at BEFORE UPDATE ON playlists
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
