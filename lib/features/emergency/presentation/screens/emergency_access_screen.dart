import 'package:flutter/material.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import 'package:cipherowl/features/emergency/data/services/emergency_service.dart';

/// Emergency Access management screen.
///
/// Owner can: add/remove trusted contacts, view/approve/deny incoming requests.
/// Contact can: see invitations they've received.
class EmergencyAccessScreen extends StatefulWidget {
  const EmergencyAccessScreen({super.key});

  @override
  State<EmergencyAccessScreen> createState() => _EmergencyAccessScreenState();
}

class _EmergencyAccessScreenState extends State<EmergencyAccessScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _service = EmergencyService();

  List<EmergencyContact> _contacts = [];
  List<EmergencyRequest> _incoming = [];
  List<EmergencyRequest> _outgoing = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final contacts = await _service.listContacts();
      final requests = await _service.listRequests();
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
        _incoming = requests.incoming;
        _outgoing = requests.outgoing;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundDark,
        title: const Text(
          '\u0648\u0635\u0648\u0644 \u0627\u0644\u0637\u0648\u0627\u0631\u0626', // وصول الطوارئ
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppConstants.primaryCyan,
          labelColor: AppConstants.primaryCyan,
          unselectedLabelColor: Colors.white38,
          tabs: [
            Tab(
              text:
                  '\u062C\u0647\u0627\u062A \u0627\u0644\u0627\u062A\u0635\u0627\u0644', // جهات الاتصال
            ),
            Tab(
              text:
                  '\u0627\u0644\u0637\u0644\u0628\u0627\u062A', // الطلبات
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddContactDialog,
        backgroundColor: AppConstants.primaryCyan,
        child: const Icon(Icons.person_add, color: AppConstants.backgroundDark),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _ContactsTab(
                  contacts: _contacts,
                  onRemove: _removeContact,
                ),
                _RequestsTab(
                  incoming: _incoming,
                  outgoing: _outgoing,
                  onResolve: _resolveRequest,
                ),
              ],
            ),
    );
  }

  // ── Add Contact Dialog ──────────────────────────────────────────────────

  void _showAddContactDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String accessLevel = 'read';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppConstants.cardDark,
          title: const Text(
            '\u0625\u0636\u0627\u0641\u0629 \u062C\u0647\u0629 \u0627\u062A\u0635\u0627\u0644 \u0637\u0648\u0627\u0631\u0626', // إضافة جهة اتصال طوارئ
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: '\u0627\u0644\u0627\u0633\u0645', // الاسم
                  labelStyle: const TextStyle(color: Colors.white38),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppConstants.borderDark),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppConstants.primaryCyan),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: '\u0627\u0644\u0628\u0631\u064A\u062F \u0627\u0644\u0625\u0644\u0643\u062A\u0631\u0648\u0646\u064A', // البريد الإلكتروني
                  labelStyle: const TextStyle(color: Colors.white38),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppConstants.borderDark),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppConstants.primaryCyan),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: accessLevel,
                dropdownColor: AppConstants.cardDark,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: '\u0645\u0633\u062A\u0648\u0649 \u0627\u0644\u0648\u0635\u0648\u0644', // مستوى الوصول
                  labelStyle: const TextStyle(color: Colors.white38),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppConstants.borderDark),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'read',
                    child: Text('\u0642\u0631\u0627\u0621\u0629 \u0641\u0642\u0637'), // قراءة فقط
                  ),
                  DropdownMenuItem(
                    value: 'read_write',
                    child: Text('\u0642\u0631\u0627\u0621\u0629 + \u062A\u0639\u062F\u064A\u0644'), // قراءة + تعديل
                  ),
                  DropdownMenuItem(
                    value: 'full',
                    child: Text('\u0648\u0635\u0648\u0644 \u0643\u0627\u0645\u0644'), // وصول كامل
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => accessLevel = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                '\u0625\u0644\u063A\u0627\u0621', // إلغاء
                style: TextStyle(color: Colors.white38),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty) return;
                Navigator.pop(ctx);
                await _addContact(
                  nameCtrl.text.trim(),
                  emailCtrl.text.trim(),
                  accessLevel,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryCyan,
                foregroundColor: AppConstants.backgroundDark,
              ),
              child: const Text('\u0625\u0636\u0627\u0641\u0629'), // إضافة
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addContact(
      String name, String email, String accessLevel) async {
    try {
      await _service.addContact(
        contactName: name,
        contactEmail: email,
        accessLevel: accessLevel,
      );
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '\u0641\u0634\u0644 \u0625\u0636\u0627\u0641\u0629 \u062C\u0647\u0629 \u0627\u0644\u0627\u062A\u0635\u0627\u0644: $e', // فشل إضافة جهة الاتصال
          ),
          backgroundColor: AppConstants.errorRed,
        ),
      );
    }
  }

  Future<void> _removeContact(String contactId) async {
    try {
      await _service.removeContact(contactId);
      await _loadData();
    } catch (_) {}
  }

  Future<void> _resolveRequest(String requestId, bool approve) async {
    try {
      await _service.resolveRequest(requestId: requestId, approve: approve);
      await _loadData();
    } catch (_) {}
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Contacts Tab
// ═════════════════════════════════════════════════════════════════════════════

class _ContactsTab extends StatelessWidget {
  final List<EmergencyContact> contacts;
  final Future<void> Function(String) onRemove;

  const _ContactsTab({required this.contacts, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline,
                size: 64, color: Colors.white.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            const Text(
              '\u0644\u0627 \u062A\u0648\u062C\u062F \u062C\u0647\u0627\u062A \u0627\u062A\u0635\u0627\u0644 \u0637\u0648\u0627\u0631\u0626', // لا توجد جهات اتصال طوارئ
              style: TextStyle(color: Colors.white38, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              '\u0623\u0636\u0641 \u0634\u062E\u0635\u0627\u064B \u0645\u0648\u062B\u0648\u0642\u0627\u064B \u0644\u0644\u0648\u0635\u0648\u0644 \u0644\u062E\u0632\u0646\u062A\u0643 \u0641\u064A \u062D\u0627\u0644\u0627\u062A \u0627\u0644\u0637\u0648\u0627\u0631\u0626', // أضف شخصاً موثوقاً للوصول لخزنتك في حالات الطوارئ
              style: TextStyle(color: Colors.white24, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: contacts.length,
      itemBuilder: (_, i) => _ContactCard(
        contact: contacts[i],
        onRemove: () => onRemove(contacts[i].id),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback onRemove;

  const _ContactCard({required this.contact, required this.onRemove});

  String get _accessLabelAr {
    switch (contact.accessLevel) {
      case 'read':
        return '\u0642\u0631\u0627\u0621\u0629 \u0641\u0642\u0637'; // قراءة فقط
      case 'read_write':
        return '\u0642\u0631\u0627\u0621\u0629 + \u062A\u0639\u062F\u064A\u0644'; // قراءة + تعديل
      case 'full':
        return '\u0648\u0635\u0648\u0644 \u0643\u0627\u0645\u0644'; // وصول كامل
      default:
        return contact.accessLevel;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.borderDark),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppConstants.primaryCyan.withValues(alpha: 0.15),
            child: Text(
              contact.contactName.isNotEmpty
                  ? contact.contactName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: AppConstants.primaryCyan,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.contactName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  contact.contactEmail,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryCyan.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _accessLabelAr,
                        style: const TextStyle(
                          color: AppConstants.primaryCyan,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (contact.isAccepted
                                ? AppConstants.successGreen
                                : AppConstants.warningAmber)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        contact.isAccepted
                            ? '\u0645\u0642\u0628\u0648\u0644' // مقبول
                            : '\u0628\u0627\u0646\u062A\u0638\u0627\u0631 \u0627\u0644\u0642\u0628\u0648\u0644', // بانتظار القبول
                        style: TextStyle(
                          color: contact.isAccepted
                              ? AppConstants.successGreen
                              : AppConstants.warningAmber,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline,
                color: AppConstants.errorRed, size: 20),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Requests Tab
// ═════════════════════════════════════════════════════════════════════════════

class _RequestsTab extends StatelessWidget {
  final List<EmergencyRequest> incoming;
  final List<EmergencyRequest> outgoing;
  final Future<void> Function(String, bool) onResolve;

  const _RequestsTab({
    required this.incoming,
    required this.outgoing,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    if (incoming.isEmpty && outgoing.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined,
                size: 64, color: Colors.white.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            const Text(
              '\u0644\u0627 \u062A\u0648\u062C\u062F \u0637\u0644\u0628\u0627\u062A', // لا توجد طلبات
              style: TextStyle(color: Colors.white38, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (incoming.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              '\u0637\u0644\u0628\u0627\u062A \u0648\u0627\u0631\u062F\u0629', // طلبات واردة
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...incoming.map((r) => _RequestCard(
                request: r,
                isIncoming: true,
                onApprove: () => onResolve(r.id, true),
                onDeny: () => onResolve(r.id, false),
              )),
          const SizedBox(height: 20),
        ],
        if (outgoing.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              '\u0637\u0644\u0628\u0627\u062A\u064A', // طلباتي
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...outgoing.map((r) => _RequestCard(
                request: r,
                isIncoming: false,
              )),
        ],
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  final EmergencyRequest request;
  final bool isIncoming;
  final VoidCallback? onApprove;
  final VoidCallback? onDeny;

  const _RequestCard({
    required this.request,
    required this.isIncoming,
    this.onApprove,
    this.onDeny,
  });

  Color get _statusColor {
    switch (request.status) {
      case 'pending':
        return AppConstants.warningAmber;
      case 'approved':
        return AppConstants.successGreen;
      case 'denied':
        return AppConstants.errorRed;
      default:
        return Colors.white38;
    }
  }

  String get _statusLabelAr {
    switch (request.status) {
      case 'pending':
        return '\u0628\u0627\u0646\u062A\u0638\u0627\u0631'; // بانتظار
      case 'approved':
        return '\u0645\u0648\u0627\u0641\u0642 \u0639\u0644\u064A\u0647'; // موافق عليه
      case 'denied':
        return '\u0645\u0631\u0641\u0648\u0636'; // مرفوض
      default:
        return request.status;
    }
  }

  String _formatRemaining(Duration d) {
    if (d == Duration.zero) {
      return '\u0627\u0646\u062A\u0647\u0649 \u0627\u0644\u0648\u0642\u062A'; // انتهى الوقت
    }
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    return '$hours \u0633\u0627\u0639\u0629 $minutes \u062F\u0642\u064A\u0642\u0629'; // X ساعة Y دقيقة
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _statusColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emergency, color: _statusColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  request.contactName ??
                      request.contactEmail ??
                      request.contactId,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _statusLabelAr,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (request.reason != null) ...[
            const SizedBox(height: 6),
            Text(
              request.reason!,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
          if (request.status == 'pending') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.timer_outlined,
                    color: Colors.white30, size: 14),
                const SizedBox(width: 4),
                Text(
                  '\u0645\u0648\u0627\u0641\u0642\u0629 \u062A\u0644\u0642\u0627\u0626\u064A\u0629 \u0628\u0639\u062F: ${_formatRemaining(request.timeRemaining)}', // موافقة تلقائية بعد: X
                  style: const TextStyle(color: Colors.white30, fontSize: 11),
                ),
              ],
            ),
          ],
          if (isIncoming && request.status == 'pending') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDeny,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.errorRed,
                      side: const BorderSide(color: AppConstants.errorRed),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('\u0631\u0641\u0636'), // رفض
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.successGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('\u0645\u0648\u0627\u0641\u0642\u0629'), // موافقة
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
