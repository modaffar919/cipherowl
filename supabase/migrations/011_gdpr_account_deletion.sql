-- GDPR Account Deletion support
-- Adds audit log table and cascade-delete improvements.

-- Audit log for account deletions (GDPR compliance trail).
CREATE TABLE IF NOT EXISTS public.account_deletion_log (
  id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id    UUID        NOT NULL,
  email      TEXT        NOT NULL,
  deleted_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- RLS: only service_role can access.
ALTER TABLE public.account_deletion_log ENABLE ROW LEVEL SECURITY;

-- No RLS policies = only service_role (bypasses RLS) can insert/read.
COMMENT ON TABLE public.account_deletion_log IS
  'GDPR Art.17 audit trail — records account deletion events. Accessed only by service_role.';
