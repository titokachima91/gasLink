// lib/screens/vendor/vendor_settings_screen.dart
// Vendor-facing settings: read-only commission terms, profile shortcut,
// theme picker, notification toggle, about section, and sign-out.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme_controller.dart';
import '../../models/vendor.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'vendor_profile_screen.dart';
import 'widgets/vendor_commission_card.dart';

import '../../core/theme_ext.dart';

class VendorSettingsScreen extends ConsumerStatefulWidget {
  const VendorSettingsScreen({super.key});

  @override
  ConsumerState<VendorSettingsScreen> createState() =>
      _VendorSettingsScreenState();
}

class _VendorSettingsScreenState extends ConsumerState<VendorSettingsScreen> {
  static const String _supportPhone = '+255767304776';

  bool _notificationsEnabled = true;

  String get _uid =>
      FirebaseAuth.instance.currentUser?.uid ??
      AuthService.instance.currentUserId ??
      '';

  Future<void> _callSupport() async {
    final uri = Uri.parse('tel:$_supportPhone');
    try {
      await launchUrl(uri);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Huduma ya kupiga simu haipatikani.')),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ondoka kwenye akaunti?'),
        content: const Text(
          'Kikao chako kitaondolewa kwenye kifaa hiki.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Ghairi / Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.error,
              foregroundColor: context.colors.onError,
            ),
            child: const Text('Ondoka / Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Mipangilio / Settings',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── SECTION 1: BILLING ───────────────────────────────────────────
          Text(
            'Bili / Billing',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<Vendor?>(
            stream: FirebaseFirestore.instance
                .collection('vendors')
                .doc(_uid)
                .snapshots()
                .map((doc) => doc.exists ? Vendor.fromDoc(doc) : null),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                );
              }
              return VendorCommissionTermsCard(vendor: snapshot.data);
            },
          ),
          const SizedBox(height: 20),

          // ── SECTION 2: PROFILE ───────────────────────────────────────────
          Text(
            'Wasifu / Profile',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colors.outlineVariant),
            ),
            child: ListTile(
              leading: Icon(Icons.storefront, color: colors.primary),
              title: const Text('Taarifa za Duka / Store Profile'),
              subtitle: const Text('Wasifu, leseni na picha za duka'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VendorProfileScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // ── SECTION 3: APPEARANCE ────────────────────────────────────────
          Text(
            'Muonekano / Appearance',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colors.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.brightness_6_outlined,
                      color: colors.primary,
                    ),
                    title: const Text('Mandhari / Theme'),
                    subtitle: Text(_themeModeLabel(
                      ref.watch(themeControllerProvider),
                    )),
                  ),
                  SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.settings_suggest_outlined),
                        label: Text('System'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_outlined),
                        label: Text('Light'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_outlined),
                        label: Text('Dark'),
                      ),
                    ],
                    selected: {ref.watch(themeControllerProvider)},
                    onSelectionChanged: (selection) {
                      ref
                          .read(themeControllerProvider.notifier)
                          .setMode(selection.first);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── SECTION 4: PREFERENCES ───────────────────────────────────────
          Text(
            'Mapendeleo / Preferences',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colors.outlineVariant),
            ),
            child: SwitchListTile(
              secondary:
                  Icon(Icons.notifications_outlined, color: colors.primary),
              title: const Text('Taarifa / Notifications'),
              subtitle: const Text('Pokea taarifa za oda na mabadiliko'),
              value: _notificationsEnabled,
              activeColor: colors.primary,
              onChanged: (val) {
                setState(() => _notificationsEnabled = val);
              },
            ),
          ),
          const SizedBox(height: 20),

          // ── SECTION 5: ABOUT ─────────────────────────────────────────────
          Text(
            'Kuhusu / About',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colors.outlineVariant),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info_outline, color: colors.primary),
                  title: const Text('GasLink'),
                  subtitle: const Text('Toleo / Version 1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.support_agent, color: colors.primary),
                  title: const Text('Msaada / Support'),
                  subtitle: const Text(_supportPhone),
                  trailing: const Icon(Icons.call_outlined, size: 18),
                  onTap: _callSupport,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── SECTION 6: ACCOUNT ───────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.error,
                side: BorderSide(color: colors.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Ondoka / Sign out'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }
}
