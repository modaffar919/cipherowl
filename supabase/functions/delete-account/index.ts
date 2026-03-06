/**
 * CipherOwl — Edge Function: delete-account
 *
 * GDPR Article 17 (Right to Erasure) — permanently deletes all user data
 * from Supabase and the auth system.
 *
 * POST /functions/v1/delete-account
 * Headers: Authorization: Bearer <user-jwt>
 * Body: { "confirmation": "DELETE" }
 * Response: { "success": true }
 *
 * Deletion order (foreign-key safe):
 *   1. vault_item_versions
 *   2. vault_attachments
 *   3. encrypted_vaults
 *   4. fido2_credentials
 *   5. emergency_contacts / emergency_requests
 *   6. sync_metadata
 *   7. browser_autofill
 *   8. shared_items
 *   9. org_members
 *  10. fcm_tokens
 *  11. profiles
 *  12. Supabase Auth user
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const ALLOWED_ORIGIN = Deno.env.get('ALLOWED_ORIGIN') ?? '*';

function corsHeaders(origin: string): Record<string, string> {
  return {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Authorization, Content-Type',
  };
}

function jsonError(status: number, message: string): Response {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { ...corsHeaders(ALLOWED_ORIGIN), 'Content-Type': 'application/json' },
  });
}

Deno.serve(async (req: Request): Promise<Response> => {
  // ── CORS preflight ────────────────────────────────────────────────────────
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: corsHeaders(ALLOWED_ORIGIN),
    });
  }

  if (req.method !== 'POST') {
    return jsonError(405, 'Method not allowed');
  }

  // ── Auth: require a valid Supabase JWT ───────────────────────────────────
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return jsonError(401, 'Missing Authorization header');
  }

  // User-level client to verify the JWT.
  const supabaseUser = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user }, error: authError } = await supabaseUser.auth.getUser();
  if (authError || !user) {
    return jsonError(401, 'Unauthorized');
  }

  // ── Validate confirmation ────────────────────────────────────────────────
  let body: { confirmation?: string };
  try {
    body = await req.json();
  } catch {
    return jsonError(400, 'Invalid JSON body');
  }

  if (body.confirmation !== 'DELETE') {
    return jsonError(400, 'Confirmation must be "DELETE"');
  }

  // ── Service-role client for cascade deletion ─────────────────────────────
  const supabaseAdmin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  const uid = user.id;

  try {
    // Delete in dependency order (children before parents).
    const tables = [
      { table: 'vault_item_versions', column: 'user_id' },
      { table: 'vault_attachments', column: 'user_id' },
      { table: 'encrypted_vaults', column: 'user_id' },
      { table: 'fido2_credentials', column: 'user_id' },
      { table: 'emergency_contacts', column: 'user_id' },
      { table: 'emergency_contacts', column: 'contact_user_id' },
      { table: 'emergency_requests', column: 'requester_id' },
      { table: 'emergency_requests', column: 'owner_id' },
      { table: 'sync_metadata', column: 'user_id' },
      { table: 'browser_autofill', column: 'user_id' },
      { table: 'shared_items', column: 'owner_id' },
      { table: 'shared_items', column: 'recipient_id' },
      { table: 'org_members', column: 'user_id' },
      { table: 'fcm_tokens', column: 'user_id' },
      { table: 'profiles', column: 'id' },
    ];

    for (const { table, column } of tables) {
      const { error } = await supabaseAdmin
        .from(table)
        .delete()
        .eq(column, uid);

      // Ignore "relation does not exist" — table may not exist in all envs.
      if (error && !error.message.includes('does not exist')) {
        console.error(`Failed to delete from ${table}: ${error.message}`);
      }
    }

    // Delete storage objects (vault attachments bucket).
    try {
      const { data: files } = await supabaseAdmin.storage
        .from('vault-attachments')
        .list(uid);
      if (files && files.length > 0) {
        const paths = files.map((f: { name: string }) => `${uid}/${f.name}`);
        await supabaseAdmin.storage.from('vault-attachments').remove(paths);
      }
    } catch {
      // Bucket may not exist — that's OK.
    }

    // Audit log entry (before user deletion).
    await supabaseAdmin.from('account_deletion_log').insert({
      user_id: uid,
      email: user.email ?? 'unknown',
      deleted_at: new Date().toISOString(),
    }).then(() => { }, () => {
      // Log table may not exist — non-critical.
    });

    // Finally, delete the auth user.
    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(uid);
    if (deleteError) {
      return jsonError(500, `Failed to delete auth user: ${deleteError.message}`);
    }

    return new Response(
      JSON.stringify({ success: true }),
      {
        status: 200,
        headers: {
          ...corsHeaders(ALLOWED_ORIGIN),
          'Content-Type': 'application/json',
        },
      },
    );
  } catch (e) {
    console.error('Account deletion error:', e);
    return jsonError(500, 'Internal server error during account deletion');
  }
});
