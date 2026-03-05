/**
 * CipherOwl — Edge Function: send-notification
 *
 * Sends a Firebase Cloud Messaging (FCM) push notification to a user's device
 * for security alerts (breach detected, suspicious login, idle vault timeout).
 *
 * POST /functions/v1/send-notification
 * Headers: Authorization: Bearer <supabase-service-role-key>  ← server-to-server
 * Body: {
 *   "userId": "uuid",          // Supabase auth user ID
 *   "type": "breach" | "login_alert" | "idle_warning" | "custom",
 *   "title": "...",            // optional override
 *   "body": "...",             // optional override
 * }
 *
 * The function looks up the user's FCM token from the `profiles` table
 * (field `fcm_token`), then calls the FCM v1 API.
 *
 * Required env vars:
 *   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, FIREBASE_PROJECT_ID,
 *   FIREBASE_SERVICE_ACCOUNT_JSON  (full SA JSON for OAuth2 token exchange)
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// ── Notification templates ────────────────────────────────────────────────────

const TEMPLATES: Record<string, { title: string; body: string }> = {
  breach: {
    title: '⚠️ اختراق مكتشف',
    body: 'تم اكتشاف إحدى كلمات مرورك في قواعد بيانات الاختراقات. افتح التطبيق فورًا.',
  },
  login_alert: {
    title: '🔐 تسجيل دخول جديد',
    body: 'تم تسجيل الدخول إلى حسابك على جهاز جديد.',
  },
  idle_warning: {
    title: '🔒 قفل تلقائي قريب',
    body: 'لم تنشط منذ فترة — ستُقفل الخزينة تلقائيًا قريبًا.',
  },
  custom: {
    title: 'CipherOwl',
    body: 'لديك إشعار أمني جديد.',
  },
};

// ── Handler ───────────────────────────────────────────────────────────────────

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders() });
  }

  // Service-role only — no user JWT accepted
  const authHeader = req.headers.get('Authorization');
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!authHeader || authHeader !== `Bearer ${serviceKey}`) {
    return jsonError(401, 'Service role key required');
  }

  let body: { userId: string; type: string; title?: string; body?: string };
  try {
    body = await req.json();
  } catch {
    return jsonError(400, 'Invalid JSON body');
  }

  if (!body.userId || !body.type) {
    return jsonError(400, 'userId and type are required');
  }

  // ── Fetch FCM token from profiles table ──────────────────────────────────
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    serviceKey!,
  );

  const { data: profile, error: profileError } = await supabase
    .from('profiles')
    .select('fcm_token')
    .eq('id', body.userId)
    .single();

  if (profileError || !profile?.fcm_token) {
    // User has no FCM token — silently succeed (no device registered)
    return new Response(JSON.stringify({ sent: false, reason: 'no_fcm_token' }), {
      status: 200,
      headers: { 'Content-Type': 'application/json', ...corsHeaders() },
    });
  }

  const template = TEMPLATES[body.type] ?? TEMPLATES['custom'];
  const title = body.title ?? template.title;
  const message = body.body ?? template.body;

  // ── Obtain FCM OAuth2 access token ───────────────────────────────────────
  const fcmAccessToken = await _getFcmAccessToken();
  if (!fcmAccessToken) {
    return jsonError(503, 'Could not obtain FCM access token');
  }

  const projectId = Deno.env.get('FIREBASE_PROJECT_ID');
  const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

  // ── Send notification via FCM v1 API ─────────────────────────────────────
  const fcmRes = await fetch(fcmUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${fcmAccessToken}`,
    },
    body: JSON.stringify({
      message: {
        token: profile.fcm_token,
        notification: { title, body: message },
        android: { priority: 'high' },
        apns: { payload: { aps: { 'content-available': 1 } } },
        data: { type: body.type, userId: body.userId },
      },
    }),
  });

  if (!fcmRes.ok) {
    const err = await fcmRes.text();
    console.error('FCM error:', err);
    return jsonError(502, 'FCM delivery failed');
  }

  const fcmBody = await fcmRes.json();
  return new Response(JSON.stringify({ sent: true, messageId: fcmBody.name }), {
    status: 200,
    headers: { 'Content-Type': 'application/json', ...corsHeaders() },
  });
});

// ─── Helpers ──────────────────────────────────────────────────────────────────

/** Exchange the Firebase service account for a short-lived OAuth2 bearer token. */
async function _getFcmAccessToken(): Promise<string | null> {
  const saJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON');
  if (!saJson) return null;

  try {
    const sa = JSON.parse(saJson);
    const { default: { SignJWT, importPKCS8 } } = await import(
      'https://deno.land/x/jose@v4.15.4/index.ts'
    );

    const now = Math.floor(Date.now() / 1000);
    const privateKey = await importPKCS8(sa.private_key, 'RS256');

    const jwt = await new SignJWT({
      scope: 'https://www.googleapis.com/auth/cloud-messaging',
    })
      .setProtectedHeader({ alg: 'RS256' })
      .setIssuedAt(now)
      .setExpirationTime(now + 3600)
      .setIssuer(sa.client_email)
      .setAudience('https://oauth2.googleapis.com/token')
      .sign(privateKey);

    const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: jwt,
      }),
    });

    if (!tokenRes.ok) return null;
    const { access_token } = await tokenRes.json();
    return access_token ?? null;
  } catch (err) {
    console.error('JWT signing error:', err);
    return null;
  }
}

function corsHeaders(): Record<string, string> {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  };
}

function jsonError(status: number, message: string): Response {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { 'Content-Type': 'application/json', ...corsHeaders() },
  });
}
