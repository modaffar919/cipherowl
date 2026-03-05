-- =============================================================================
-- CipherOwl — Migration 001: Core Schema
-- Apply via: Supabase Dashboard → SQL Editor  (or `supabase db push`)
-- =============================================================================

-- ── profiles ──────────────────────────────────────────────────────────────────
-- One row per Supabase auth user. Created automatically by trigger.
CREATE TABLE IF NOT EXISTS public.profiles (
    id             UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name   TEXT,
    avatar_url     TEXT,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── encrypted_vaults ──────────────────────────────────────────────────────────
-- ZERO-KNOWLEDGE storage: only AES-256-GCM encrypted payloads are kept here.
-- The server NEVER sees plaintext titles, passwords, notes, or TOTP secrets.
-- Schema of the decrypted payload (client-side only):
--   { id, userId, title, username, encryptedPassword, url, encryptedNotes,
--     encryptedTotpSecret, category, isFavorite, strengthScore,
--     createdAt, updatedAt, lastAccessedAt }
CREATE TABLE IF NOT EXISTS public.encrypted_vaults (
    id                TEXT        PRIMARY KEY,          -- VaultEntry.id (client UUID)
    user_id           UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    encrypted_payload TEXT        NOT NULL,             -- base64(AES-256-GCM(JSON(VaultEntry)))
    category          TEXT        NOT NULL DEFAULT 'login', -- plaintext only for analytics
    updated_at        TIMESTAMPTZ NOT NULL,             -- mirrors VaultEntry.updatedAt (conflict resolution)
    synced_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_deleted        BOOLEAN     NOT NULL DEFAULT FALSE -- soft-delete tombstone for sync
);

CREATE INDEX IF NOT EXISTS idx_ev_user
    ON public.encrypted_vaults (user_id);

CREATE INDEX IF NOT EXISTS idx_ev_user_updated
    ON public.encrypted_vaults (user_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_ev_user_deleted
    ON public.encrypted_vaults (user_id, is_deleted);

-- ── sync_metadata ─────────────────────────────────────────────────────────────
-- Tracks per-user sync state.
CREATE TABLE IF NOT EXISTS public.sync_metadata (
    user_id        UUID        PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    last_sync_at   TIMESTAMPTZ,
    total_items    INT         NOT NULL DEFAULT 0,
    sync_version   INT         NOT NULL DEFAULT 1
);

-- ── Trigger: auto-create profile & sync_metadata on sign-up ──────────────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.profiles (id, display_name)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email)
    )
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.sync_metadata (user_id)
    VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();