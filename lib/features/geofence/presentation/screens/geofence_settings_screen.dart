import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:cipherowl/core/constants/app_constants.dart';
import 'package:cipherowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cipherowl/features/geofence/data/models/safe_zone.dart';
import 'package:cipherowl/features/geofence/data/services/geofence_service.dart';
import 'package:cipherowl/features/geofence/presentation/bloc/geofence_bloc.dart';

/// Settings screen for managing geo-fence safe zones.
///
/// Shows a list of saved safe zones, allows adding/editing/deleting them,
/// and provides a master toggle for the auto-lock feature.
class GeofenceSettingsScreen extends StatelessWidget {
  const GeofenceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GeofenceBloc, GeofenceState>(
      listener: (context, state) {
        if (state is GeofenceLoaded) {
          // Trigger vault lock when the bloc signals exit.
          if (state.shouldLockVault) {
            context.read<AuthBloc>().add(const AuthVaultLocked());
          }
          if (state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message!),
              backgroundColor: AppConstants.primaryCyan,
              duration: const Duration(seconds: 2),
            ));
          }
          if (state.permissionDenied) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('يرجى منح إذن الموقع من إعدادات النظام'),
              backgroundColor: AppConstants.errorRed,
            ));
          }
        }
      },
      builder: (context, state) {
        final isLoaded = state is GeofenceLoaded;
        final zones = isLoaded ? state.zones : <SafeZone>[];
        final isMonitoring = isLoaded && state.isMonitoring;
        final isInsideZone = isLoaded ? state.isInsideZone : null;

        return Scaffold(
          backgroundColor: AppConstants.backgroundDark,
          appBar: AppBar(
            backgroundColor: AppConstants.surfaceDark,
            title: const Text(
              'السياج الجغرافي',
              style: TextStyle(
                color: AppConstants.primaryCyan,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: const BackButton(color: AppConstants.textSecondary),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Master toggle card ───────────────────────────────────────────
              _MasterToggleCard(
                isMonitoring: isMonitoring,
                isInsideZone: isInsideZone,
                onToggle: () => context
                    .read<GeofenceBloc>()
                    .add(const GeofenceMonitoringToggled()),
              ),
              const SizedBox(height: 16),

              // ── Info banner ─────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppConstants.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppConstants.primaryCyan.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppConstants.primaryCyan, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'تُقفَل الخزنة تلقائياً عند مغادرة جميع المناطق الآمنة المفعّلة.',
                        style: TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Section header ──────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'المناطق الآمنة (${zones.length})',
                    style: const TextStyle(
                      color: AppConstants.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddZoneDialog(context),
                    icon: const Icon(Icons.add,
                        color: AppConstants.primaryCyan, size: 18),
                    label: const Text('إضافة',
                        style: TextStyle(color: AppConstants.primaryCyan)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Zones list ──────────────────────────────────────────────────
              if (zones.isEmpty)
                _EmptyZonesPlaceholder(
                    onAdd: () => _showAddZoneDialog(context))
              else
                ...zones.map((zone) => _SafeZoneTile(
                      zone: zone,
                      onToggle: () => context
                          .read<GeofenceBloc>()
                          .add(GeofenceZoneToggled(zone.id)),
                      onEdit: () =>
                          _showEditZoneDialog(context, zone),
                      onDelete: () => _confirmDelete(context, zone),
                    )),
            ],
          ),
        );
      },
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────────

  void _showAddZoneDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<GeofenceBloc>(),
        child: const _ZoneFormDialog(),
      ),
    );
  }

  void _showEditZoneDialog(BuildContext context, SafeZone zone) {
    showDialog<void>(
      context: context,
      builder: (dlgCtx) => BlocProvider.value(
        value: context.read<GeofenceBloc>(),
        child: _ZoneFormDialog(existing: zone),
      ),
    );
  }

  void _confirmDelete(BuildContext context, SafeZone zone) {
    showDialog<void>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: AppConstants.surfaceDark,
        title: Text('حذف "${zone.name}"?',
            style: const TextStyle(color: AppConstants.textPrimary)),
        content: const Text('لا يمكن التراجع عن هذا الإجراء.',
            style: TextStyle(color: AppConstants.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('إلغاء',
                style: TextStyle(color: AppConstants.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<GeofenceBloc>()
                  .add(GeofenceZoneRemoved(zone.id));
              Navigator.pop(dlgCtx);
            },
            child: const Text('حذف',
                style: TextStyle(color: AppConstants.errorRed)),
          ),
        ],
      ),
    );
  }
}

// ── Master toggle card ────────────────────────────────────────────────────────

class _MasterToggleCard extends StatelessWidget {
  final bool isMonitoring;
  final bool? isInsideZone;
  final VoidCallback onToggle;

  const _MasterToggleCard({
    required this.isMonitoring,
    required this.isInsideZone,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isMonitoring
        ? (isInsideZone == false
            ? AppConstants.errorRed
            : AppConstants.successGreen)
        : AppConstants.textSecondary;

    final statusText = isMonitoring
        ? (isInsideZone == null
            ? 'جارٍ تحديد الموقع...'
            : isInsideZone!
                ? 'داخل منطقة آمنة ✓'
                : 'خارج المناطق الآمنة — الخزنة مقفلة')
        : 'المراقبة متوقفة';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMonitoring
              ? AppConstants.primaryCyan.withValues(alpha: 0.5)
              : AppConstants.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppConstants.primaryCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.location_on,
                    color: AppConstants.primaryCyan, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('السياج الجغرافي',
                        style: TextStyle(
                            color: AppConstants.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16)),
                    const SizedBox(height: 2),
                    const Text('قفل تلقائي خارج المناطق الآمنة',
                        style: TextStyle(
                            color: AppConstants.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Switch(
                value: isMonitoring,
                onChanged: (_) => onToggle(),
                activeThumbColor: AppConstants.primaryCyan,
              ),
            ],
          ),
          if (isMonitoring) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: statusColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(statusText,
                      style: TextStyle(color: statusColor, fontSize: 12)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Safe zone tile ────────────────────────────────────────────────────────────

class _SafeZoneTile extends StatelessWidget {
  final SafeZone zone;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SafeZoneTile({
    required this.zone,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final radiusDisplay = zone.radiusMeters >= 1000
        ? '${(zone.radiusMeters / 1000).toStringAsFixed(1)} كم'
        : '${zone.radiusMeters.toInt()} م';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: zone.isActive
              ? AppConstants.primaryCyan.withValues(alpha: 0.3)
              : AppConstants.borderColor,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: zone.isActive
                ? AppConstants.primaryCyan.withValues(alpha: 0.1)
                : AppConstants.surfaceDark,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.location_on_outlined,
            color: zone.isActive
                ? AppConstants.primaryCyan
                : AppConstants.textSecondary,
            size: 22,
          ),
        ),
        title: Text(zone.name,
            style: TextStyle(
              color: zone.isActive
                  ? AppConstants.textPrimary
                  : AppConstants.textSecondary,
              fontWeight: FontWeight.w600,
            )),
        subtitle: Text(
          '${zone.latitude.toStringAsFixed(4)}, ${zone.longitude.toStringAsFixed(4)}  •  $radiusDisplay',
          style: const TextStyle(
              color: AppConstants.textSecondary, fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: zone.isActive,
              onChanged: (_) => onToggle(),
              activeThumbColor: AppConstants.primaryCyan,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            PopupMenuButton<String>(
              color: AppConstants.surfaceDark,
              icon: const Icon(Icons.more_vert,
                  color: AppConstants.textSecondary, size: 20),
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'edit',
                    child: Text('تعديل',
                        style:
                            TextStyle(color: AppConstants.textPrimary))),
                const PopupMenuItem(
                    value: 'delete',
                    child: Text('حذف',
                        style: TextStyle(color: AppConstants.errorRed))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyZonesPlaceholder extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyZonesPlaceholder({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      decoration: BoxDecoration(
        color: AppConstants.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.location_off_outlined,
              size: 56, color: AppConstants.textSecondary),
          const SizedBox(height: 12),
          const Text('لا توجد مناطق آمنة بعد',
              style: TextStyle(
                  color: AppConstants.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16)),
          const SizedBox(height: 6),
          const Text(
            'أضف موقعك الحالي كمنطقة آمنة\nلتفعيل القفل التلقائي.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppConstants.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_location_alt_outlined, size: 18),
            label: const Text('إضافة منطقة آمنة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryCyan,
              foregroundColor: AppConstants.backgroundDark,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Zone form dialog (add / edit) ─────────────────────────────────────────────

class _ZoneFormDialog extends StatefulWidget {
  final SafeZone? existing;
  const _ZoneFormDialog({this.existing});

  @override
  State<_ZoneFormDialog> createState() => _ZoneFormDialogState();
}

class _ZoneFormDialogState extends State<_ZoneFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  late final TextEditingController _radiusCtrl;
  bool _fetchingLocation = false;

  @override
  void initState() {
    super.initState();
    final z = widget.existing;
    _nameCtrl =
        TextEditingController(text: z?.name ?? '');
    _latCtrl =
        TextEditingController(text: z?.latitude.toString() ?? '');
    _lngCtrl =
        TextEditingController(text: z?.longitude.toString() ?? '');
    _radiusCtrl =
        TextEditingController(text: z?.radiusMeters.toInt().toString() ?? '150');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _radiusCtrl.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _fetchingLocation = true);
    final pos = await GeofenceService.getCurrentPosition();
    if (pos != null && mounted) {
      _latCtrl.text = pos.latitude.toStringAsFixed(6);
      _lngCtrl.text = pos.longitude.toStringAsFixed(6);
    }
    if (mounted) setState(() => _fetchingLocation = false);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final zone = SafeZone(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      latitude: double.parse(_latCtrl.text.trim()),
      longitude: double.parse(_lngCtrl.text.trim()),
      radiusMeters: double.parse(_radiusCtrl.text.trim()),
    );

    if (widget.existing != null) {
      context.read<GeofenceBloc>().add(GeofenceZoneUpdated(zone));
    } else {
      context.read<GeofenceBloc>().add(GeofenceZoneAdded(zone));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return AlertDialog(
      backgroundColor: AppConstants.surfaceDark,
      title: Text(
        isEdit ? 'تعديل المنطقة' : 'إضافة منطقة آمنة',
        style: const TextStyle(
            color: AppConstants.textPrimary, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(
                controller: _nameCtrl,
                label: 'اسم المنطقة',
                icon: Icons.label_outline,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: _latCtrl,
                      label: 'خط العرض',
                      icon: Icons.explore,
                      keyboardType: const TextInputType.numberWithOptions(
                          signed: true, decimal: true),
                      validator: (v) {
                        final d = double.tryParse(v ?? '');
                        if (d == null || d < -90 || d > 90) {
                          return 'غير صالح';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _field(
                      controller: _lngCtrl,
                      label: 'خط الطول',
                      icon: Icons.explore,
                      keyboardType: const TextInputType.numberWithOptions(
                          signed: true, decimal: true),
                      validator: (v) {
                        final d = double.tryParse(v ?? '');
                        if (d == null || d < -180 || d > 180) {
                          return 'غير صالح';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: _fetchingLocation ? null : _useCurrentLocation,
                icon: _fetchingLocation
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location,
                        color: AppConstants.primaryCyan, size: 16),
                label: Text(
                  _fetchingLocation
                      ? 'جارٍ التحديد...'
                      : 'استخدام موقعي الحالي',
                  style: const TextStyle(
                      color: AppConstants.primaryCyan, fontSize: 13),
                ),
              ),
              const SizedBox(height: 8),
              _field(
                controller: _radiusCtrl,
                label: 'نطاق الأمان (متر)',
                icon: Icons.radio_button_checked,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 50 || n > 50000) {
                    return '50 — 50000 م';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء',
              style: TextStyle(color: AppConstants.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryCyan,
            foregroundColor: AppConstants.backgroundDark,
          ),
          child: Text(isEdit ? 'حفظ' : 'إضافة'),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        style: const TextStyle(color: AppConstants.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppConstants.textSecondary),
          prefixIcon:
              Icon(icon, color: AppConstants.primaryCyan, size: 18),
          filled: true,
          fillColor: AppConstants.backgroundDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppConstants.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppConstants.primaryCyan, width: 1.5),
          ),
        ),
      );
}
