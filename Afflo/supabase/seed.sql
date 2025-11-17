-- Seed file for local development
-- Creates a mock user for testing without Apple Sign-In
-- Run with: psql postgresql://postgres:postgres@127.0.0.1:54322/postgres -f supabase/seed.sql

-- Insert mock user into auth.users (if not exists)
INSERT INTO auth.users (
    id,
    instance_id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    recovery_sent_at,
    last_sign_in_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
) VALUES (
    '00000000-0000-0000-0000-000000000000'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'authenticated',
    'authenticated',
    'dev@afflo.local',
    crypt('dev-password-123', gen_salt('bf')), -- Mock password (won't be used)
    now(),
    null,
    now(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"name": "Dev User", "email": "dev@afflo.local"}'::jsonb,
    now(),
    now(),
    '',
    '',
    '',
    ''
)
ON CONFLICT (id) DO NOTHING;

-- Insert mock user profile (if not exists)
INSERT INTO public.user_profiles (
    id,
    manifest_goal,
    why,
    obstacle,
    created_at,
    updated_at
) VALUES (
    '00000000-0000-0000-0000-000000000000'::uuid,
    'Build an amazing app',
    'To help people achieve their goals',
    'Finding time to code',
    now(),
    now()
)
ON CONFLICT (id) DO NOTHING;

-- Confirm seed completed
DO $$
BEGIN
    RAISE NOTICE '✅ Seed complete: Dev user created (dev@afflo.local)';
END $$;
