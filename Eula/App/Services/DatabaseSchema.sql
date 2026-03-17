-- User relationship table SQL script
-- Run this in the Supabase SQL Editor

BEGIN;

CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA extensions;

CREATE TABLE IF NOT EXISTS public.following (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id TEXT NOT NULL,
    target_user_id TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS following_user_target_unique ON public.following(user_id, target_user_id);
CREATE INDEX IF NOT EXISTS idx_following_user_id ON public.following(user_id);
CREATE INDEX IF NOT EXISTS idx_following_target_user_id ON public.following(target_user_id);

ALTER TABLE public.following ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own following" ON public.following;
DROP POLICY IF EXISTS "Users can insert own following" ON public.following;
DROP POLICY IF EXISTS "Users can delete own following" ON public.following;
DROP POLICY IF EXISTS "Users can update own following" ON public.following;

CREATE POLICY "Users can view own following" ON public.following
    FOR SELECT TO authenticated
    USING (user_id = auth.uid()::text);

CREATE POLICY "Users can insert own following" ON public.following
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid()::text);

CREATE POLICY "Users can delete own following" ON public.following
    FOR DELETE TO authenticated
    USING (user_id = auth.uid()::text);

CREATE POLICY "Users can update own following" ON public.following
    FOR UPDATE TO authenticated
    USING (user_id = auth.uid()::text)
    WITH CHECK (user_id = auth.uid()::text);

CREATE TABLE IF NOT EXISTS public.blocked_users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id TEXT NOT NULL,
    target_user_id TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS blocked_users_user_target_unique ON public.blocked_users(user_id, target_user_id);
CREATE INDEX IF NOT EXISTS idx_blocked_users_user_id ON public.blocked_users(user_id);
CREATE INDEX IF NOT EXISTS idx_blocked_users_target_user_id ON public.blocked_users(target_user_id);

ALTER TABLE public.blocked_users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own blocked" ON public.blocked_users;
DROP POLICY IF EXISTS "Users can insert own blocked" ON public.blocked_users;
DROP POLICY IF EXISTS "Users can delete own blocked" ON public.blocked_users;
DROP POLICY IF EXISTS "Users can update own blocked" ON public.blocked_users;

CREATE POLICY "Users can view own blocked" ON public.blocked_users
    FOR SELECT TO authenticated
    USING (user_id = auth.uid()::text);

CREATE POLICY "Users can insert own blocked" ON public.blocked_users
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid()::text);

CREATE POLICY "Users can delete own blocked" ON public.blocked_users
    FOR DELETE TO authenticated
    USING (user_id = auth.uid()::text);

CREATE POLICY "Users can update own blocked" ON public.blocked_users
    FOR UPDATE TO authenticated
    USING (user_id = auth.uid()::text)
    WITH CHECK (user_id = auth.uid()::text);

COMMIT;
