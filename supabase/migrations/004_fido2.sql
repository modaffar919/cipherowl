-- supabase/migrations/004_fido2.sql
-- FIDO2/WebAuthn credential storage
-- Applied after 003_browser_autofill.sql

-- ─── Table ────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.fido2_credentials (
  id              TEXT PRIMARY KEY,            -- credential ID (base64url)
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  public_key      TEXT NOT NULL,               -- Ed25519 verifying key (base64)
  friendly_name   TEXT NOT NULL DEFAULT 'Passkey',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_used_at    TIMESTAMPTZ,
  sign_count      BIGINT NOT NULL DEFAULT 0,   -- replay-attack counter
  device_os       TEXT,                        -- 'android' | 'ios'
  is_backup_eligible BOOLEAN NOT NULL DEFAULT FALSE,
  is_backed_up    BOOLEAN NOT NULL DEFAULT FALSE
);

-- ─── Indexes ──────────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_fido2_user
  ON public.fido2_credentials (user_id);

-- ─── RLS ──────────────────────────────────────────────────────────────────────

ALTER TABLE public.fido2_credentials ENABLE ROW LEVEL SECURITY;

CREATE POLICY "fido2_select_own"
  ON public.fido2_credentials FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "fido2_insert_own"
  ON public.fido2_credentials FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "fido2_update_own"
  ON public.fido2_credentials FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "fido2_delete_own"
  ON public.fido2_credentials FOR DELETE
  USING (auth.uid() = user_id);
