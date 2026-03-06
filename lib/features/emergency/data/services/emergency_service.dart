import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cipherowl/core/supabase/supabase_client_provider.dart';

/// Emergency contact with access level and invitation status.
class EmergencyContact {
  final String id;
  final String contactEmail;
  final String contactName;
  final String accessLevel; // 'read' | 'read_write' | 'full'
  final bool isAccepted;
  final DateTime createdAt;

  const EmergencyContact({
    required this.id,
    required this.contactEmail,
    required this.contactName,
    required this.accessLevel,
    required this.isAccepted,
    required this.createdAt,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String,
      contactEmail: json['contact_email'] as String,
      contactName: json['contact_name'] as String,
      accessLevel: json['access_level'] as String? ?? 'read',
      isAccepted: json['is_accepted'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Emergency access request with countdown and status.
class EmergencyRequest {
  final String id;
  final String contactId;
  final String requesterId;
  final String ownerId;
  final String status; // 'pending' | 'approved' | 'denied' | 'expired'
  final int delayHours;
  final DateTime requestedAt;
  final DateTime autoApproveAt;
  final DateTime? resolvedAt;
  final String? reason;
  final String? contactName;
  final String? contactEmail;
  final String? accessLevel;

  const EmergencyRequest({
    required this.id,
    required this.contactId,
    required this.requesterId,
    required this.ownerId,
    required this.status,
    required this.delayHours,
    required this.requestedAt,
    required this.autoApproveAt,
    this.resolvedAt,
    this.reason,
    this.contactName,
    this.contactEmail,
    this.accessLevel,
  });

  factory EmergencyRequest.fromJson(Map<String, dynamic> json) {
    final contact = json['emergency_contacts'] as Map<String, dynamic>?;
    return EmergencyRequest(
      id: json['id'] as String,
      contactId: json['contact_id'] as String,
      requesterId: json['requester_id'] as String,
      ownerId: json['owner_id'] as String,
      status: json['status'] as String,
      delayHours: json['delay_hours'] as int? ?? 72,
      requestedAt: DateTime.parse(json['requested_at'] as String),
      autoApproveAt: DateTime.parse(json['auto_approve_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      reason: json['reason'] as String?,
      contactName: contact?['contact_name'] as String?,
      contactEmail: contact?['contact_email'] as String?,
      accessLevel: contact?['access_level'] as String?,
    );
  }

  /// Time remaining before auto-approval.
  Duration get timeRemaining {
    final remaining = autoApproveAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isAutoApproved => status == 'pending' && timeRemaining == Duration.zero;
}

/// Service for managing emergency access contacts and requests.
class EmergencyService {
  final SupabaseClient _client;

  EmergencyService({SupabaseClient? client})
      : _client = client ?? SupabaseClientProvider.client;

  // ── Contacts ─────────────────────────────────────────────────────────

  /// Add a trusted emergency contact.
  Future<EmergencyContact> addContact({
    required String contactEmail,
    required String contactName,
    String accessLevel = 'read',
  }) async {
    final userId = _client.auth.currentUser!.id;
    final result = await _client
        .from('emergency_contacts')
        .insert({
          'owner_id': userId,
          'contact_email': contactEmail,
          'contact_name': contactName,
          'access_level': accessLevel,
        })
        .select()
        .single();
    return EmergencyContact.fromJson(result);
  }

  /// List all emergency contacts for current user.
  Future<List<EmergencyContact>> listContacts() async {
    final userId = _client.auth.currentUser!.id;
    final result = await _client
        .from('emergency_contacts')
        .select()
        .eq('owner_id', userId)
        .order('created_at', ascending: false);
    return (result as List).map((e) => EmergencyContact.fromJson(e)).toList();
  }

  /// Remove an emergency contact.
  Future<void> removeContact(String contactId) async {
    await _client
        .from('emergency_contacts')
        .delete()
        .eq('id', contactId)
        .eq('owner_id', _client.auth.currentUser!.id);
  }

  /// Accept an emergency contact invitation (as the contact person).
  Future<void> acceptInvitation(String contactId) async {
    await _client
        .from('emergency_contacts')
        .update({'is_accepted': true})
        .eq('id', contactId);
  }

  // ── Requests ─────────────────────────────────────────────────────────

  /// List incoming requests (as vault owner) and outgoing (as requester).
  Future<({List<EmergencyRequest> incoming, List<EmergencyRequest> outgoing})>
      listRequests() async {
    final response = await _client.functions.invoke(
      'emergency-request',
      method: HttpMethod.get,
    );
    final data = response.data as Map<String, dynamic>;
    final incoming = (data['incoming'] as List)
        .map((e) => EmergencyRequest.fromJson(e))
        .toList();
    final outgoing = (data['outgoing'] as List)
        .map((e) => EmergencyRequest.fromJson(e))
        .toList();
    return (incoming: incoming, outgoing: outgoing);
  }

  /// Approve or deny an incoming emergency request (as vault owner).
  Future<void> resolveRequest({
    required String requestId,
    required bool approve,
  }) async {
    await _client.functions.invoke(
      'emergency-request',
      method: HttpMethod.patch,
      body: {
        'request_id': requestId,
        'action': approve ? 'approve' : 'deny',
      },
    );
  }
}
