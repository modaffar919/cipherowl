-- Add FCM token column to profiles for push notification delivery.
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Allow users to update their own FCM token.
-- (The existing RLS policies already cover this since profiles has
--  a policy allowing users to update their own row.)
