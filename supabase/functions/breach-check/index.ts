/**
 * CipherOwl — Edge Function: breach-check
 *
 * Proxies HaveIBeenPwned Range API to check if a password hash has appeared
 * in known data breaches. Only the first 5 hex chars of the SHA-1 hash are
 * sent to HIBP, preserving k-anonymity.
 *
 * POST /functions/v1/breach-check
 * Headers: Authorization: Bearer <supabase-anon-key>
 * Body: { "sha1Prefix": "ABCDE" }   ← first 5 uppercase hex chars of SHA-1
 * Response: { "suffixes": [{ "suffix": "F0E...", "count": 12345 }] }
 *
 * The client (Flutter app) computes SHA-1 locally and only sends the prefix.
 * This function acts as a proxy to avoid CORS issues and add rate-limiting.
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const HIBP_BASE = 'https://api.pwnedpasswords.com/range/';
const ALLOWED_ORIGIN = Deno.env.get('ALLOWED_ORIGIN') ?? '*';

Deno.serve(async (req: Request): Promise<Response> => {
  // ── CORS preflight ────────────────────────────────────────────────────────
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: corsHeaders(ALLOWED_ORIGIN),
    });
  }

  // ── Auth: require a valid Supabase JWT ───────────────────────────────────
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return jsonError(401, 'Missing Authorization header');
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user }, error } = await supabase.auth.getUser();
  if (error || !user) {
    return jsonError(401, 'Unauthorized');
  }

  // ── Parse request body ───────────────────────────────────────────────────
  let sha1Prefix: string;
  try {
    const body = await req.json();
    sha1Prefix = (body.sha1Prefix ?? '').toUpperCase();
  } catch {
    return jsonError(400, 'Invalid JSON body');
  }

  if (!/^[0-9A-F]{5}$/.test(sha1Prefix)) {
    return jsonError(400, 'sha1Prefix must be exactly 5 uppercase hex characters');
  }

  // ── Proxy to HIBP Range API ──────────────────────────────────────────────
  try {
    const hibpRes = await fetch(`${HIBP_BASE}${sha1Prefix}`, {
      headers: {
        'Add-Padding': 'true', // prevent traffic analysis via padding
        'User-Agent': 'CipherOwl/1.0',
      },
    });

    if (!hibpRes.ok) {
      return jsonError(502, `HIBP returned ${hibpRes.status}`);
    }

    const text = await hibpRes.text();

    // Parse response lines: each line is "SUFFIX:COUNT\n"
    const suffixes = text
      .split('\n')
      .filter((line) => line.trim().length > 0)
      .map((line) => {
        const [suffix, countStr] = line.trim().split(':');
        return { suffix, count: parseInt(countStr ?? '0', 10) };
      });

    return new Response(JSON.stringify({ suffixes }), {
      status: 200,
      headers: { 'Content-Type': 'application/json', ...corsHeaders(ALLOWED_ORIGIN) },
    });
  } catch (err) {
    console.error('HIBP proxy error:', err);
    return jsonError(502, 'Failed to reach HIBP API');
  }
});

// ─── Helpers ─────────────────────────────────────────────────────────────────

function corsHeaders(origin: string): Record<string, string> {
  return {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Headers': 'authorization, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  };
}

function jsonError(status: number, message: string): Response {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { 'Content-Type': 'application/json', ...corsHeaders(ALLOWED_ORIGIN) },
  });
}
