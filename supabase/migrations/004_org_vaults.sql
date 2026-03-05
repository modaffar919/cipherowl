-- Migration 004: Organisation Team Vaults
-- Creates organisations, org_members, and org_vaults tables.

-- ── organisations ──────────────────────────────────────────────────────────
create table if not exists organisations (
  id          uuid primary key,
  name        text not null,
  description text,
  owner_id    uuid not null references auth.users(id) on delete cascade,
  logo_url    text,
  created_at  timestamptz not null default now()
);

alter table organisations enable row level security;

-- Members can see the orgs they belong to
create policy "select_own_orgs" on organisations
  for select using (
    id in (
      select org_id from org_members
      where user_id = auth.uid() and is_active = true
    )
  );

-- Only org owner can update
create policy "update_own_org" on organisations
  for update using (owner_id = auth.uid());

-- ── org_members ────────────────────────────────────────────────────────────
create table if not exists org_members (
  id           uuid primary key,
  org_id       uuid not null references organisations(id) on delete cascade,
  user_id      uuid not null references auth.users(id) on delete cascade,
  display_name text not null default '',
  email        text not null default '',
  role         text not null default 'member'
                 check (role in ('admin', 'manager', 'member')),
  joined_at    timestamptz not null default now(),
  is_active    boolean not null default true,
  unique (org_id, user_id)
);

alter table org_members enable row level security;

-- Members can view others in the same org
create policy "select_org_members" on org_members
  for select using (
    org_id in (
      select org_id from org_members
      where user_id = auth.uid() and is_active = true
    )
  );

-- Admins can insert new members (enforced by service role in Edge Functions)
create policy "insert_org_members" on org_members
  for insert with check (
    org_id in (
      select org_id from org_members
      where user_id = auth.uid()
        and role = 'admin'
        and is_active = true
    )
  );

-- Admins can update member roles / deactivate
create policy "update_org_members" on org_members
  for update using (
    org_id in (
      select org_id from org_members
      where user_id = auth.uid()
        and role = 'admin'
        and is_active = true
    )
  );

-- ── org_vaults ─────────────────────────────────────────────────────────────
create table if not exists org_vaults (
  id                   uuid primary key,
  org_id               uuid not null references organisations(id) on delete cascade,
  name                 text not null,
  description          text,
  created_by_user_id   uuid not null references auth.users(id),
  created_at           timestamptz not null default now()
);

alter table org_vaults enable row level security;

-- All active org members can see vaults
create policy "select_org_vaults" on org_vaults
  for select using (
    org_id in (
      select org_id from org_members
      where user_id = auth.uid() and is_active = true
    )
  );

-- Admins and managers can create vaults
create policy "insert_org_vaults" on org_vaults
  for insert with check (
    org_id in (
      select org_id from org_members
      where user_id = auth.uid()
        and role in ('admin', 'manager')
        and is_active = true
    )
  );

-- Admins and managers can delete vaults
create policy "delete_org_vaults" on org_vaults
  for delete using (
    org_id in (
      select org_id from org_members
      where user_id = auth.uid()
        and role in ('admin', 'manager')
        and is_active = true
    )
  );
