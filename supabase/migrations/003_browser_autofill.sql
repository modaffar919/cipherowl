-- =============================================================================
-- CipherOwl — Migration 003: Browser Extension AutoFill Cache
-- Apply via: Supabase Dashboard → SQL Editor  (or `supabase db push`)
-- =============================================================================
--
-- browser_autofill stores simplified credential objects for the CipherOwl
-- browser extension.  Entries are encrypted with the user's sync key
-- (AES-256-GCM, same key managed by ZeroKnowledgeSyncService on mobile).
-- The browser extension obtains the sync key via the "Link Browser Extension"
-- flow in the mobile app Settings screen.
--
-- Decrypted payload schema (browser extension only):
--   { id, title, username, password, url }
-- =============================================================================

-- ── browser_autofill ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.browser_autofill (
    id                TEXT        PRIMARY KEY,
    user_id           UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    -- base64(nonce(12) || AES-256-GCM(sync_key)(JSON))
    encrypted_payload TEXT        NOT NULL,
    -- Plaintext domain hint so the extension can pre-filter without decrypting
    url_hint          TEXT        NOT NULL DEFAULT '',
    updated_at        TIMESTAMPTZ NOT NULL,
    is_deleted        BOOLEAN     NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_baf_user
    ON public.browser_autofill (user_id);

CREATE INDEX IF NOT EXISTS idx_baf_user_deleted
    ON public.browser_autofill (user_id, is_deleted);

-- ── Row Level Security ────────────────────────────────────────────────────────
ALTER TABLE public.browser_autofill ENABLE ROW LEVEL SECURITY;

CREATE POLICY "browser_autofill: select own"
    ON public.browser_autofill FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "browser_autofill: insert own"
    ON public.browser_autofill FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "browser_autofill: update own"
    ON public.browser_autofill FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "browser_autofill: delete own"
    ON public.browser_autofill FOR DELETE
    USING (auth.uid() = user_id);
