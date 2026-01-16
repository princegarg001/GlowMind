-- Users table (linked to auth.users)
CREATE TABLE users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text,
  name text,
  is_guest boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Notes table
CREATE TABLE notes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  text text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Sleep profiles table
CREATE TABLE sleep_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  bedtime_hour int NOT NULL CHECK (bedtime_hour >= 0 AND bedtime_hour < 24),
  bedtime_minute int NOT NULL CHECK (bedtime_minute >= 0 AND bedtime_minute < 60),
  wake_hour int NOT NULL CHECK (wake_hour >= 0 AND wake_hour < 24),
  wake_minute int NOT NULL CHECK (wake_minute >= 0 AND wake_minute < 60),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Indexes for better query performance
CREATE INDEX idx_notes_user_id ON notes(user_id);
CREATE INDEX idx_notes_created_at ON notes(created_at DESC);
CREATE INDEX idx_sleep_profiles_user_id ON sleep_profiles(user_id);
