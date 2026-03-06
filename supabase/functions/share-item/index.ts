/**
 * CipherOwl — Edge Function: share-item
 *
 * Creates and retrieves encrypted share links.
 *
 * POST   /functions/v1/share-item   — create a new share (requires auth)
 * GET    /functions/v1/share-item?id=<uuid>  — retrieve a share (public)
 *
 * The encrypted payload + key stay zero-knowledge: the server only stores
 * the ciphertext. The AES-256-GCM key lives in the URL fragment (#key=...)
 * and is never transmitted to the server.
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const ALLOWED_ORIGIN = Deno.env.get('ALLOWED_ORIGIN') ?? '*';

function corsHeaders(origin: string): HeadersInit {
  return {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Authorization, Content-Type',
  };
}

function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders(ALLOWED_ORIGIN), 'Content-Type': 'application/json' },
  });
}

function jsonError(status: number, message: string): Response {
  return jsonResponse({ error: message }, status);
}

Deno.serve(async (req: Request): Promise<Response> => {
  // ── CORS preflight ────────────────────────────────────────────────────────
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders(ALLOWED_ORIGIN) });
  }

  const url = new URL(req.url);

  // ── GET: retrieve a share (public, no auth needed) ────────────────────────
  if (req.method === 'GET') {
    const shareId = url.searchParams.get('id');
    if (!shareId) return jsonError(400, 'Missing id parameter');

    // Use service-role to bypass RLS for public read.
    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const { data, error } = await admin
      .from('shared_items')
      .select('id, encrypted_data, expires_at, is_one_time, require_pin, accessed_at, is_revoked')
      .eq('id', shareId)
      .single();

    if (error || !data) return jsonError(404, 'Share not found');

    // Check expiry.
    if (new Date(data.expires_at) < new Date()) {
      return jsonError(410, 'Share has expired');
    }

    // Check revoked.
    if (data.is_revoked) {
      return jsonError(410, 'Share has been revoked');
    }

    // Check one-time use: if already accessed, deny.
    if (data.is_one_time && data.accessed_at) {
      return jsonError(410, 'Share has already been used');
    }

    // Mark as accessed.
    if (!data.accessed_at) {
      await admin
        .from('shared_items')
        .update({ accessed_at: new Date().toISOString() })
        .eq('id', shareId);
    }

    return jsonResponse({
      id: data.id,
      encrypted_data: data.encrypted_data,
      require_pin: data.require_pin,
    });
  }

  // ── POST: create a new share (requires auth) ─────────────────────────────
  if (req.method === 'POST') {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) return jsonError(401, 'Missing Authorization header');

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    );

    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) return jsonError(401, 'Unauthorized');

    let body: {
      encrypted_data: string;
      recipient_email?: string;
      expires_in_hours: number;
      is_one_time: boolean;
      require_pin: boolean;
      pin_hash?: string;
    };

    try {
      body = await req.json();
    } catch {
      return jsonError(400, 'Invalid JSON body');
    }

    if (!body.encrypted_data || typeof body.encrypted_data !== 'string') {
      return jsonError(400, 'encrypted_data is required');
    }

    if (!body.expires_in_hours || body.expires_in_hours < 1 || body.expires_in_hours > 168) {
      return jsonError(400, 'expires_in_hours must be 1–168');
    }

    const expiresAt = new Date(Date.now() + body.expires_in_hours * 3600 * 1000).toISOString();

    const { data, error } = await supabase.from('shared_items').insert({
      owner_id: user.id,
      encrypted_data: body.encrypted_data,
      recipient_email: body.recipient_email ?? null,
      expires_at: expiresAt,
      is_one_time: body.is_one_time ?? true,
      require_pin: body.require_pin ?? false,
      pin_hash: body.pin_hash ?? null,
    }).select('id, expires_at').single();

    if (error) return jsonError(500, `Failed to create share: ${error.message}`);

    return jsonResponse({ id: data.id, expires_at: data.expires_at }, 201);
  }

  return jsonError(405, 'Method not allowed');
});
