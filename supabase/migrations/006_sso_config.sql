-- Migration 006: SSO Configuration
-- Stores enterprise SSO configs (OIDC, SAML, LDAP) per organisation.

create table if not exists public.sso_configs (
  id                  uuid primary key,
  org_id              uuid not null references public.organisations(id) on delete cascade,
  provider            text not null check (provider in ('oidc', 'saml', 'ldap')),
  is_enabled          boolean not null default false,

  -- OIDC / OAuth2
  oidc_client_id      text,
  oidc_client_secret  text,   -- encrypted at rest by Supabase Vault
  oidc_discovery_url  text,

  -- SAML 2.0
  saml_entity_id      text,
  saml_sso_url        text,
  saml_certificate    text,

  -- LDAP / AD
  ldap_host           text,
  ldap_port           integer,
  ldap_bind_dn        text,
  ldap_base_dn        text,
  ldap_use_ssl        boolean not null default true,

  updated_at          timestamptz not null default now(),
  unique (org_id, provider)
);

alter table public.sso_configs enable row level security;

-- Only org admins can read/write SSO configs
create policy "select_sso_configs" on public.sso_configs
  for select using (
    org_id in (
      select org_id from public.org_members
      where user_id = auth.uid()
        and role = 'admin'
        and is_active = true
    )
  );

create policy "upsert_sso_configs" on public.sso_configs
  for all using (
    org_id in (
      select org_id from public.org_members
      where user_id = auth.uid()
        and role = 'admin'
        and is_active = true
    )
  );
