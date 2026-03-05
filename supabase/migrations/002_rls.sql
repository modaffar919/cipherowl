-- =============================================================================
-- CipherOwl — Migration 002: Row Level Security (RLS)
-- Apply AFTER 001_schema.sql
-- Each user can only access their own rows — server enforces this at the DB level.
-- =============================================================================

-- ── Enable RLS on all tables ──────────────────────────────────────────────────
ALTER TABLE public.profiles        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.encrypted_vaults ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sync_metadata   ENABLE ROW LEVEL SECURITY;

-- ── profiles ──────────────────────────────────────────────────────────────────
-- Insert is handled by trigger (SECURITY DEFINER), so no INSERT policy needed.
CREATE POLICY "profiles: select own"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "profiles: update own"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- ── encrypted_vaults ──────────────────────────────────────────────────────────
CREATE POLICY "vaults: select own"
    ON public.encrypted_vaults FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "vaults: insert own"
    ON public.encrypted_vaults FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "vaults: update own"
    ON public.encrypted_vaults FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "vaults: delete own"
    ON public.encrypted_vaults FOR DELETE
    USING (auth.uid() = user_id);

-- ── sync_metadata ─────────────────────────────────────────────────────────────
CREATE POLICY "sync_meta: select own"
    ON public.sync_metadata FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "sync_meta: update own"
    ON public.sync_metadata FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);