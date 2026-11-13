// lib/screens/consumer/consumer_settings_screen.dart
// Consumer settings: account, appearance, preferences, legal, support, and
// sign-out. Guests are bounced to sign in.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/session_gate.dart';
import '../../core/theme_controller.dart';
import '../../core/theme_ext.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_ui.dart';
import '../auth/landing_screen.dart';
import '../legal/legal_screens.dart';
import 'gas_plan_screen.dart';

class ConsumerSettingsScreen extends ConsumerStatefulWidget {
  const ConsumerSettingsScreen({super.key});

  @override
  ConsumerState<ConsumerSettingsScreen> createState() =>
      _ConsumerSettingsScreenState();
}

class _ConsumerSettingsScreenState
    extends ConsumerState<ConsumerSettingsScreen> {
  static const _supportPhone = '+255767304776';
  static const _supportEmail = 'support@gaslink.co.tz';
  static const _notificationsPref = 'consumer_notifications_enabled';

  bool _notificationsEnabled = true;
  bool? _adsConsent;

  String get _uid => AuthService.instance.currentUserId ?? '';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    bool? adsConsent;
    if (_uid.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .get();
        final stored = doc.data()?['adsConsent'];
        if (stored is bool) adsConsent = stored;
      } catch (e) {
        debugPrint('Ads consent load warning: $e');
      }
    }
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.getBool(_notificationsPref) ?? true;
      _adsConsent = adsConsent;
    });
  }

  Future<void> _setNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsPref, value);
  }

  Future<void> _setAdsConsent(bool value) async {
    setState(() => _adsConsent = value);
    await AuthService.instance.saveAdsConsent(_uid, value);
  }

  Future<void> _editName(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Badilisha Jina / Change name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Jina lako / Your name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Ghairi / Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Hifadhi / Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty || _uid.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .update({'name': name.trim()});
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Jina limebadilishwa / Name updated.'),
        backgroundColor: context.gasColors.success,
      ),
    );
  }

  Future<void> _callSupport() async {
    await launchUrl(Uri.parse('tel:$_supportPhone'));
  }

  Future<void> _emailSupport() async {
    await launchUrl(Uri(scheme: 'mailto', path: _supportEmail));
  }

  Future<void> _logout() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!SessionGate.isConsumer) {
      return const SessionRedirect();
    }

    final phone = AuthService.instance.currentPhone ?? '';
    final maskedPhone = phone.length >= 10
        ? '${phone.substring(0, phone.length - 4)}••••'
        : phone;

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
          // ── ACCOUNT ────────────────────────────────────────────────
          const AppSectionHeader(
            title: 'Akaunti / Account',
            icon: Icons.account_circle_outlined,
          ),
          const SizedBox(height: 10),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(_uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final data = snapshot.data?.data() ?? {};
                    final name = (data['name'] ?? '').toString().trim().isEmpty
                        ? 'Mteja / Customer'
                        : data['name'].toString();
                    return ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: context.colors.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          name.characters.first.toUpperCase(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: context.colors.onPrimaryContainer,
                          ),
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(maskedPhone),
                      trailing: IconButton(
                        tooltip: 'Badilisha jina',
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _editName(context),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.storefront_outlined),
                  title: Text('Jiandikishe kama muuzaji'),
                  subtitle: Text('Inakuja hivi karibuni / Coming soon'),
                  enabled: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── APPEARANCE ─────────────────────────────────────────────
          const AppSectionHeader(
            title: 'Muonekano / Appearance',
            icon: Icons.brightness_6_outlined,
          ),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.palette_outlined,
                    color: context.colors.primary,
                  ),
                  title: const Text('Mandhari / Theme'),
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
          const SizedBox(height: 20),

          // ── PREFERENCES ────────────────────────────────────────────
          const AppSectionHeader(
            title: 'Mapendeleo / Preferences',
            icon: Icons.tune_outlined,
          ),
          const SizedBox(height: 10),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                    Icons.notifications_outlined,
                    color: context.colors.primary,
                  ),
                  title: const Text('Taarifa / Notifications'),
                  subtitle: const Text('Oda, matangazo na usalama'),
                  value: _notificationsEnabled,
                  activeColor: context.colors.primary,
                  onChanged: _setNotifications,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.translate_outlined,
                    color: context.colors.primary,
                  ),
                  title: const Text('Lugha / Language'),
                  subtitle: const Text('Kiswahili'),
                  trailing: const AppStatusPill(
                    label: 'Kiswahili',
                    icon: Icons.check,
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: Icon(
                    Icons.campaign_outlined,
                    color: context.colors.primary,
                  ),
                  title: const Text('Matangazo / Ads'),
                  subtitle: const Text('Ruhusu matangazo na ofa'),
                  value: _adsConsent ?? true,
                  activeColor: context.colors.primary,
                  onChanged: _setAdsConsent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── FEATURES ───────────────────────────────────────────────
          const AppSectionHeader(
            title: 'Vipengele / Features',
            icon: Icons.extension_outlined,
          ),
          const SizedBox(height: 10),
          AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.colors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.work_outline,
                  color: context.colors.primary,
                  size: 21,
                ),
              ),
              title: const Text('GasPlan kwa Waajiriwa'),
              subtitle: const Text(
                'Gesi kwa mwezi, malipo kupitia payslip.',
              ),
              trailing: const AppStatusPill(
                label: 'Inakuja',
                icon: Icons.schedule,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GasPlanScreen()),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── LEGAL ──────────────────────────────────────────────────
          const AppSectionHeader(
            title: 'Sera / Legal',
            icon: Icons.gavel_outlined,
          ),
          const SizedBox(height: 10),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.description_outlined,
                    color: context.colors.primary,
                  ),
                  title: const Text('Vigezo na Masharti'),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TermsScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.privacy_tip_outlined,
                    color: context.colors.primary,
                  ),
                  title: const Text('Sera ya Faragha'),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                  ),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('GasLink'),
                  subtitle: Text('Toleo / Version 1.0.0'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── SUPPORT ────────────────────────────────────────────────
          const AppSectionHeader(
            title: 'Msaada / Support',
            icon: Icons.support_agent_outlined,
          ),
          const SizedBox(height: 10),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading:
                      Icon(Icons.call_outlined, color: context.colors.primary),
                  title: const Text('Piga simu / Call us'),
                  subtitle: const Text(_supportPhone),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: _callSupport,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.mail_outline,
                    color: context.colors.primary,
                  ),
                  title: const Text('Barua pepe / Email us'),
                  subtitle: const Text(_supportEmail),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: _emailSupport,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── SIGN OUT ───────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              style: OutlinedButton.styleFrom(
                foregroundColor: context.colors.error,
                side: BorderSide(color: context.colors.error),
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
}
