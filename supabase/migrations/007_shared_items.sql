-- ── Secure Sharing Table ────────────────────────────────────────────────────
-- Stores encrypted vault item shares with expiry, one-time-use, and PIN.
-- Zero-knowledge: the server only stores encrypted blobs. The decryption key
-- lives in the URL fragment and is never sent to the server.

CREATE TABLE IF NOT EXISTS public.shared_items (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    encrypted_data TEXT NOT NULL,          -- base64(AES-256-GCM(item JSON))
    recipient_email TEXT,                  -- optional, for audit/display only
    expires_at     TIMESTAMPTZ NOT NULL,
    is_one_time    BOOLEAN NOT NULL DEFAULT TRUE,
    require_pin    BOOLEAN NOT NULL DEFAULT FALSE,
    pin_hash       TEXT,                   -- Argon2id hash of PIN (if set)
    accessed_at    TIMESTAMPTZ,            -- set on first access
    is_revoked     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for quick lookup by id + expiry check.
CREATE INDEX IF NOT EXISTS idx_shared_items_expires
    ON public.shared_items (id, expires_at);

-- RLS ────────────────────────────────────────────────────────────────────────
ALTER TABLE public.shared_items ENABLE ROW LEVEL SECURITY;

-- Owner can do anything with their own shares.
CREATE POLICY shared_items_owner_all ON public.shared_items
    FOR ALL
    USING (auth.uid() = owner_id)
    WITH CHECK (auth.uid() = owner_id);

-- Anyone can SELECT a share by ID (needed for recipients without accounts).
-- The edge function handles access control (expiry, one-time, PIN).
CREATE POLICY shared_items_public_select ON public.shared_items
    FOR SELECT
    USING (TRUE);
