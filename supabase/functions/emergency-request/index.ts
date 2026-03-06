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
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders(ALLOWED_ORIGIN) });
  }

  const authHeader = req.headers.get('Authorization');

  // ── POST: Create emergency access request ─────────────────────────────
  if (req.method === 'POST') {
    if (!authHeader) return jsonError(401, 'Missing Authorization header');

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: { user }, error: authErr } = await supabase.auth.getUser();
    if (authErr || !user) return jsonError(401, 'Unauthorized');

    const { contact_id, reason } = await req.json();
    if (!contact_id) return jsonError(400, 'contact_id is required');

    // Verify contact exists and belongs to a different user
    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const { data: contact, error: contactErr } = await admin
      .from('emergency_contacts')
      .select('*')
      .eq('id', contact_id)
      .eq('contact_email', user.email)
      .eq('is_accepted', true)
      .single();

    if (contactErr || !contact) {
      return jsonError(404, 'Emergency contact not found or not accepted');
    }

    // Check for existing pending request
    const { data: existing } = await admin
      .from('emergency_requests')
      .select('id')
      .eq('contact_id', contact_id)
      .eq('requester_id', user.id)
      .eq('status', 'pending')
      .single();

    if (existing) {
      return jsonError(409, 'A pending request already exists');
    }

    // Create the request with configurable delay
    const delayHours = contact.delay_hours ?? 72;
    const autoApproveAt = new Date(Date.now() + delayHours * 60 * 60 * 1000);

    const { data: request, error: insertErr } = await admin
      .from('emergency_requests')
      .insert({
        contact_id,
        requester_id: user.id,
        owner_id: contact.owner_id,
        delay_hours: delayHours,
        auto_approve_at: autoApproveAt.toISOString(),
        reason: reason ?? null,
      })
      .select()
      .single();

    if (insertErr) return jsonError(500, 'Failed to create request');

    // Send notification to owner via FCM (if token exists)
    const { data: ownerProfile } = await admin
      .from('profiles')
      .select('fcm_token')
      .eq('id', contact.owner_id)
      .single();

    if (ownerProfile?.fcm_token) {
      // Fire-and-forget notification
      try {
        await admin.functions.invoke('send-notification', {
          body: {
            token: ownerProfile.fcm_token,
            title: 'طلب وصول طوارئ',
            body: `${user.email} يطلب وصول طوارئ لخزنتك. لديك ${delayHours} ساعة للرد.`,
            data: { type: 'emergency_request', request_id: request.id },
          },
        });
      } catch {
        // Non-critical — notification failure shouldn't block the request
      }
    }

    return jsonResponse({ request });
  }

  // ── GET: Check request status or list requests ────────────────────────
  if (req.method === 'GET') {
    if (!authHeader) return jsonError(401, 'Missing Authorization header');

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: { user }, error: authErr } = await supabase.auth.getUser();
    if (authErr || !user) return jsonError(401, 'Unauthorized');

    const url = new URL(req.url);
    const requestId = url.searchParams.get('id');

    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    if (requestId) {
      // Single request status
      const { data, error } = await admin
        .from('emergency_requests')
        .select('*, emergency_contacts(contact_name, access_level)')
        .eq('id', requestId)
        .single();

      if (error || !data) return jsonError(404, 'Request not found');
      if (data.owner_id !== user.id && data.requester_id !== user.id) {
        return jsonError(403, 'Forbidden');
      }

      // Auto-approve expired pending requests
      if (data.status === 'pending' && new Date(data.auto_approve_at) <= new Date()) {
        await admin
          .from('emergency_requests')
          .update({ status: 'approved', resolved_at: new Date().toISOString() })
          .eq('id', requestId);
        data.status = 'approved';
        data.resolved_at = new Date().toISOString();
      }

      return jsonResponse({ request: data });
    }

    // List all requests for user (as owner or requester)
    const { data: asOwner } = await admin
      .from('emergency_requests')
      .select('*, emergency_contacts(contact_name, contact_email, access_level)')
      .eq('owner_id', user.id)
      .order('requested_at', { ascending: false });

    const { data: asRequester } = await admin
      .from('emergency_requests')
      .select('*, emergency_contacts(contact_name, access_level)')
      .eq('requester_id', user.id)
      .order('requested_at', { ascending: false });

    return jsonResponse({
      incoming: asOwner ?? [],
      outgoing: asRequester ?? [],
    });
  }

  // ── PATCH: Approve or deny request ────────────────────────────────────
  if (req.method === 'PATCH') {
    if (!authHeader) return jsonError(401, 'Missing Authorization header');

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: { user }, error: authErr } = await supabase.auth.getUser();
    if (authErr || !user) return jsonError(401, 'Unauthorized');

    const { request_id, action } = await req.json();
    if (!request_id || !action) return jsonError(400, 'request_id and action required');
    if (action !== 'approve' && action !== 'deny') {
      return jsonError(400, 'action must be approve or deny');
    }

    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const { data: request, error: fetchErr } = await admin
      .from('emergency_requests')
      .select('*')
      .eq('id', request_id)
      .eq('owner_id', user.id)
      .eq('status', 'pending')
      .single();

    if (fetchErr || !request) {
      return jsonError(404, 'Pending request not found');
    }

    const newStatus = action === 'approve' ? 'approved' : 'denied';
    const { error: updateErr } = await admin
      .from('emergency_requests')
      .update({
        status: newStatus,
        resolved_at: new Date().toISOString(),
      })
      .eq('id', request_id);

    if (updateErr) return jsonError(500, 'Failed to update request');

    return jsonResponse({ status: newStatus });
  }

  return jsonError(405, 'Method not allowed');
});
