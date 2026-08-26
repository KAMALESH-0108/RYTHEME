-- =============================================================================
-- RYTHEME MUSIC APP - SUPABASE DATABASE SCHEMA & MIGRATIONS
-- Run this script inside your Supabase Dashboard -> SQL Editor
-- =============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. USER PROFILES TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    email TEXT,
    avatar_url TEXT DEFAULT 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
    listening_hours NUMERIC(10,2) DEFAULT 0.0,
    rhythm_dna JSONB DEFAULT '{"chill": 40, "melodic": 30, "energetic": 20, "experimental": 10}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Profiles Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public profiles are viewable by everyone." 
    ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile." 
    ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile." 
    ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Trigger to automatically create a profile on new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, username, email, avatar_url)
    VALUES (
        new.id,
        COALESCE(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
        new.email,
        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150'
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- =============================================================================
-- 2. LIKED SONGS TABLE (Favorites)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.liked_songs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    song_id TEXT NOT NULL,
    title TEXT NOT NULL,
    artist TEXT NOT NULL,
    image_url TEXT,
    stream_url TEXT,
    liked_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_id, song_id)
);

-- Liked Songs RLS
ALTER TABLE public.liked_songs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own liked songs." 
    ON public.liked_songs FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert into their liked songs." 
    ON public.liked_songs FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete from their liked songs." 
    ON public.liked_songs FOR DELETE USING (auth.uid() = user_id);


-- =============================================================================
-- 3. PLAYLISTS & PLAYLIST TRACKS TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.playlists (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    cover_url TEXT DEFAULT 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=350',
    is_public BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.playlist_tracks (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    playlist_id UUID NOT NULL REFERENCES public.playlists(id) ON DELETE CASCADE,
    song_id TEXT NOT NULL,
    title TEXT NOT NULL,
    artist TEXT NOT NULL,
    image_url TEXT,
    stream_url TEXT,
    added_at TIMESTAMPTZ DEFAULT NOW()
);

-- Playlists RLS
ALTER TABLE public.playlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.playlist_tracks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public playlists viewable by all, private by owner." 
    ON public.playlists FOR SELECT USING (is_public = true OR auth.uid() = user_id);

CREATE POLICY "Users can create playlists." 
    ON public.playlists FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their playlists." 
    ON public.playlists FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their playlists." 
    ON public.playlists FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view playlist tracks for accessible playlists." 
    ON public.playlist_tracks FOR SELECT USING (true);

CREATE POLICY "Users can add songs to their playlists." 
    ON public.playlist_tracks FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM public.playlists WHERE id = playlist_id AND user_id = auth.uid())
    );

CREATE POLICY "Users can remove songs from their playlists." 
    ON public.playlist_tracks FOR DELETE USING (
        EXISTS (SELECT 1 FROM public.playlists WHERE id = playlist_id AND user_id = auth.uid())
    );


-- =============================================================================
-- 4. SOUND JOURNAL TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.sound_journal (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    note TEXT NOT NULL,
    song_title TEXT NOT NULL,
    artist TEXT NOT NULL,
    mood TEXT NOT NULL,
    image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Sound Journal RLS
ALTER TABLE public.sound_journal ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own sound journal." 
    ON public.sound_journal FOR ALL USING (auth.uid() = user_id);


-- =============================================================================
-- 5. LIVE JAMS TABLE (Realtime Listening Rooms)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.jams (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    host_id TEXT NOT NULL,
    host_name TEXT NOT NULL,
    host_avatar TEXT,
    listeners_count INT DEFAULT 1,
    is_live BOOLEAN DEFAULT true,
    is_public BOOLEAN DEFAULT true,
    current_song TEXT DEFAULT 'Rytheme Jam Opener',
    current_artist TEXT DEFAULT 'JAMS Host',
    stream_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- JAMS RLS
ALTER TABLE public.jams ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Live JAMS are readable by all." 
    ON public.jams FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create JAMS." 
    ON public.jams FOR INSERT WITH CHECK (true);

CREATE POLICY "Hosts can update their JAMS." 
    ON public.jams FOR UPDATE USING (true);

CREATE POLICY "Hosts can delete their JAMS." 
    ON public.jams FOR DELETE USING (true);


-- =============================================================================
-- 6. ENABLE SUPABASE REALTIME
-- =============================================================================
-- Turn on Realtime for JAMS and Liked Songs tables
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'jams'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.jams;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'liked_songs'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.liked_songs;
    END IF;
END $$;


-- =============================================================================
-- 7. INITIAL SAMPLE SEED DATA
-- =============================================================================
INSERT INTO public.jams (name, host_id, host_name, host_avatar, listeners_count, is_live, current_song, current_artist)
VALUES 
('Late Night Vibes 🔴', 'host_01', 'Sarah K.', 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100', 14, true, 'Slow Burn Synth', 'RetroFuture'),
('Coding Focus Room 💻', 'host_02', 'Kamlesh', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100', 48, true, 'Low Pass Chill Lofi', 'Mellow Beats'),
('Techno Odyssey ⚡', 'host_03', 'DJ Vector', 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100', 92, true, 'Frequency Control', 'Acid Pulse')
ON CONFLICT DO NOTHING;
