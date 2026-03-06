-- Emergency Access: trusted contacts & time-delayed access requests
-- A user registers trusted contacts who can request vault access after a delay.

-- ── emergency_contacts ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS emergency_contacts (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  contact_email TEXT NOT NULL,
  contact_name TEXT NOT NULL,
  access_level TEXT NOT NULL DEFAULT 'read' CHECK (access_level IN ('read', 'read_write', 'full')),
  -- X25519 public key of the contact (base64), used to encrypt vault key
  contact_public_key TEXT,
  -- AES-256-GCM encrypted vault key blob (base64), encrypted with shared ECDH secret
  encrypted_vault_key TEXT,
  is_accepted  BOOLEAN NOT NULL DEFAULT false,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── emergency_requests ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS emergency_requests (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contact_id      UUID NOT NULL REFERENCES emergency_contacts(id) ON DELETE CASCADE,
  requester_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  owner_id        UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status          TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'denied', 'expired')),
  -- Delay in hours before auto-approval (set by owner)
  delay_hours     INT NOT NULL DEFAULT 72,
  requested_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  -- When the request will auto-approve if not denied
  auto_approve_at TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '72 hours'),
  resolved_at     TIMESTAMPTZ,
  reason          TEXT
);

-- ── Indexes ────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_emergency_contacts_owner ON emergency_contacts(owner_id);
CREATE INDEX IF NOT EXISTS idx_emergency_contacts_email ON emergency_contacts(contact_email);
CREATE INDEX IF NOT EXISTS idx_emergency_requests_owner ON emergency_requests(owner_id);
CREATE INDEX IF NOT EXISTS idx_emergency_requests_contact ON emergency_requests(contact_id);
CREATE INDEX IF NOT EXISTS idx_emergency_requests_status ON emergency_requests(status);

-- ── RLS ────────────────────────────────────────────────────────────────
ALTER TABLE emergency_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_requests ENABLE ROW LEVEL SECURITY;

-- Contacts: owner can CRUD, contact can read their own invitations
CREATE POLICY contacts_owner_all ON emergency_contacts
  FOR ALL USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY contacts_recipient_read ON emergency_contacts
  FOR SELECT USING (
    contact_email = (SELECT email FROM auth.users WHERE id = auth.uid())
  );

-- Requests: owner sees all their requests, requester sees their own
CREATE POLICY requests_owner_all ON emergency_requests
  FOR ALL USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY requests_requester_read ON emergency_requests
  FOR SELECT USING (auth.uid() = requester_id);

CREATE POLICY requests_requester_insert ON emergency_requests
  FOR INSERT WITH CHECK (auth.uid() = requester_id);
