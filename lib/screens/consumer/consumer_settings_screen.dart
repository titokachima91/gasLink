// lib/screens/consumer/consumer_settings_screen.dart
// Consumer settings: account, appearance, preferences, legal, support, and
// sign-out. Guests are bounced to sign in.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/session_gate.dart';
import '../../core/theme_controller.dart';
import '../../core/theme_ext.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/language_picker.dart';
import '../../widgets/notifications_ai_settings.dart';
import '../about_screen.dart';
import '../auth/landing_screen.dart';
import '../legal/legal_screens.dart';
import 'gas_plan_screen.dart';
import 'consumer_profile_setup_screen.dart';
import 'safety_hub_screen.dart';

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

  String get _uid => AuthService.instance.currentUserId ?? '';

  Future<void> _editName(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.changeName),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.yourName,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(l10n.save),
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
        content: Text(l10n.nameUpdated),
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

    final l10n = AppLocalizations.of(context);
    final phone = AuthService.instance.currentPhone ?? '';
    final maskedPhone = phone.length >= 10
        ? '${phone.substring(0, phone.length - 4)}••••'
        : phone;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          l10n.settings,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── ACCOUNT ────────────────────────────────────────────────
          AppSectionHeader(
            title: l10n.account,
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
                        ? l10n.customer
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
                        tooltip: l10n.changeName,
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _editName(context),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(l10n.profileDetails),
                  subtitle: Text(l10n.profileDetailsSubtitle),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ConsumerProfileSetupScreen(),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.storefront_outlined),
                  title: Text(l10n.registerAsVendor),
                  subtitle: Text(l10n.comingSoon),
                  enabled: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── APPEARANCE ─────────────────────────────────────────────
          AppSectionHeader(
            title: l10n.appearance,
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
                  title: Text(l10n.theme),
                ),
                SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: const Icon(Icons.settings_suggest_outlined),
                      label: Text(l10n.themeSystem),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: const Icon(Icons.light_mode_outlined),
                      label: Text(l10n.themeLight),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: const Icon(Icons.dark_mode_outlined),
                      label: Text(l10n.themeDark),
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
          AppSectionHeader(
            title: l10n.preferences,
            icon: Icons.tune_outlined,
          ),
          const SizedBox(height: 10),
          const AppCard(
            padding: EdgeInsets.zero,
            child: LanguagePickerTile(),
          ),
          const SizedBox(height: 20),

          // ── NOTIFICATIONS & AI ─────────────────────────────────────
          AppSectionHeader(
            title: l10n.notificationsAiSection,
            icon: Icons.notifications_active_outlined,
          ),
          const SizedBox(height: 10),
          NotificationsAiSettings(uid: _uid),
          const SizedBox(height: 20),

          // ── FEATURES ───────────────────────────────────────────────
          AppSectionHeader(
            title: l10n.features,
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
              title: Text(l10n.gasPlanTitle),
              subtitle: Text(l10n.gasPlanSettingsSubtitle),
              trailing: AppStatusPill(
                label: l10n.comingSoonShort,
                icon: Icons.schedule,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GasPlanScreen()),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── ABOUT ──────────────────────────────────────────────────
          AppSectionHeader(
            title: l10n.about,
            icon: Icons.info_outline,
          ),
          const SizedBox(height: 10),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.info_outline,
                    color: context.colors.primary,
                  ),
                  title: Text(l10n.aboutTitle),
                  subtitle: Text(
                    l10n.versionLabel(AppConstants.appVersion),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.privacy_tip_outlined,
                    color: context.colors.primary,
                  ),
                  title: Text(l10n.privacy),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── SUPPORT ────────────────────────────────────────────────
          AppSectionHeader(
            title: l10n.support,
            icon: Icons.support_agent_outlined,
          ),
          const SizedBox(height: 10),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.health_and_safety_outlined,
                    color: context.colors.primary,
                  ),
                  title: Text(l10n.safetyHub),
                  subtitle: Text(l10n.safetyHubSubtitle),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SafetyHubScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading:
                      Icon(Icons.call_outlined, color: context.colors.primary),
                  title: Text(l10n.callSupport),
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
                  title: Text(l10n.emailSupport),
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
              label: Text(l10n.signOut),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
