import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme_ext.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/theme_mode_button.dart';
import '../auth/landing_screen.dart';
import 'widgets/admin_ui.dart';
import 'admin_audit_log_screen.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _commission = TextEditingController();
  final _supportPhone = TextEditingController();
  final _supportEmail = TextEditingController();
  final _subscriptionFee = TextEditingController();
  String _defaultModel = 'percentage';
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _commission.dispose();
    _supportPhone.dispose();
    _supportEmail.dispose();
    _subscriptionFee.dispose();
    super.dispose();
  }

  void _hydrate(AdminSettings settings) {
    if (_initialized) return;
    _initialized = true;
    final commission = (settings.commissionRate * 100).toStringAsFixed(1);
    final phone = settings.supportPhone;
    final email = settings.supportEmail;
    final fee = settings.defaultSubscriptionFee.toStringAsFixed(0);
    _defaultModel = settings.defaultCommissionModel == 'subscription'
        ? 'subscription'
        : 'percentage';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _commission.text = commission;
      _supportPhone.text = phone;
      _supportEmail.text = email;
      _subscriptionFee.text = fee;
    });
  }

  Future<void> _save() async {
    final percent = double.tryParse(_commission.text.trim());
    if (percent == null || percent < 0 || percent > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Commission must be between 0 and 100%.'),
          backgroundColor: context.colors.error,
        ),
      );
      return;
    }
    final fee = double.tryParse(_subscriptionFee.text.trim()) ?? 0;
    if (fee < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Subscription fee cannot be negative.'),
          backgroundColor: context.colors.error,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await AdminService.instance.updateSettings(
        commissionRate: percent / 100,
        supportPhone: _supportPhone.text,
        supportEmail: _supportEmail.text,
        defaultCommissionModel: _defaultModel,
        defaultSubscriptionFee: fee,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Settings saved and audit recorded.'),
          backgroundColor: context.gasColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save settings: $error'),
          backgroundColor: context.colors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out of admin?'),
        content: const Text(
          'The saved admin session will be cleared on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.error,
              foregroundColor: context.colors.onError,
            ),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = StreamBuilder<AdminSettings>(
      stream: AdminService.instance.streamSettings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AdminLoading();
        }
        if (snapshot.hasError) {
          return AdminErrorState(message: '${snapshot.error}');
        }
        final settings = snapshot.data ?? const AdminSettings();
        _hydrate(settings);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const AdminSectionHeader(
              title: 'Commercial defaults',
              subtitle:
                  'Reference values for operations and reporting. Orders keep the commission stamped when they are placed.',
            ),
            AdminCard(
              child: Column(
                children: [
                  TextField(
                    controller: _commission,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Default commission',
                      suffixText: '%',
                      prefixIcon: Icon(Icons.percent),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'percentage',
                        icon: Icon(Icons.percent),
                        label: Text('Percentage'),
                      ),
                      ButtonSegment(
                        value: 'subscription',
                        icon: Icon(Icons.event_repeat),
                        label: Text('Subscription'),
                      ),
                    ],
                    selected: {_defaultModel},
                    onSelectionChanged: (selection) =>
                        setState(() => _defaultModel = selection.first),
                  ),
                  const SizedBox(height: 12),
                  if (_defaultModel == 'subscription')
                    TextField(
                      controller: _subscriptionFee,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Default monthly fee',
                        suffixText: 'TZS',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _supportPhone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Support phone',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _supportEmail,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Support email',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_saving ? 'Saving…' : 'Save settings'),
                    ),
                  ),
                  if (settings.updatedAt != null) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Last updated ${formatDateTime(settings.updatedAt)}'
                        '${settings.updatedBy.isEmpty ? '' : ' by ${settings.updatedBy}'}',
                        style: TextStyle(
                          fontSize: 10,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),
            const AdminSectionHeader(
              title: 'Reference data',
              subtitle:
                  'Read-only pilot lists. These move to Firestore configuration before multi-country expansion.',
            ),
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Districts (${AppConstants.districts.length})',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final district in AppConstants.districts)
                        AdminKeyValueChip(
                          label: 'District',
                          value: district,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Brands (${AppConstants.gasBrands.length})',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final brand in AppConstants.gasBrands)
                        AdminKeyValueChip(
                          label: 'Brand',
                          value: brand,
                          color: context.gasColors.info,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const AdminSectionHeader(
              title: 'Admin account',
              subtitle: 'Session, appearance and audit access.',
            ),
            AdminCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.phone_outlined,
                        color: context.colors.primary),
                    title: const Text('Signed in as'),
                    subtitle: Text(
                      AuthService.instance.currentPhone ?? 'Admin',
                    ),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.badge_outlined),
                    title: Text('Role'),
                    subtitle: Text('Operations admin'),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.brightness_6_outlined),
                    title: Text('Theme'),
                    subtitle: Text('System, light or dark'),
                    trailing: ThemeModeButton(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.history, color: context.colors.primary),
                    title: const Text('Audit trail'),
                    subtitle:
                        const Text('Every vendor, order and settings change'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminAuditLogScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: Icon(Icons.logout, color: context.colors.error),
                label: Text(
                  'Sign out',
                  style: TextStyle(color: context.colors.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.colors.error),
                ),
              ),
            ),
          ],
        );
      },
    );
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('Admin settings')),
      body: body,
    );
  }
}
