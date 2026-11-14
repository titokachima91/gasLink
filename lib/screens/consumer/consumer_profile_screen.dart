// lib/screens/consumer/consumer_profile_screen.dart
// Consumer profile: account summary and quick links to the main features.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../core/session_gate.dart';
import '../../core/theme_ext.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_ui.dart';
import '../legal/legal_screens.dart';
import 'consumer_cylinder_screen.dart';
import 'consumer_settings_screen.dart';
import 'consumer_profile_setup_screen.dart';
import 'safety_hub_screen.dart';

class ConsumerProfileScreen extends StatelessWidget {
  const ConsumerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!SessionGate.isConsumer) {
      return const SessionRedirect();
    }

    final l10n = AppLocalizations.of(context);
    final uid = AuthService.instance.currentUserId ?? '';
    final phone = AuthService.instance.currentPhone ?? '';
    final maskedPhone = phone.length >= 10
        ? '${phone.substring(0, phone.length - 4)}••••'
        : phone;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          l10n.profile,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? {};
          final name = (data['name'] ?? '').toString().trim();
          final displayName = name.isEmpty ? l10n.consumerRole : name;
          final created = data['createdAt'];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.colors.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        displayName.characters.first.toUpperCase(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: context.colors.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            maskedPhone,
                            style: TextStyle(
                              fontSize: 13,
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          AppStatusPill(
                            label: l10n.consumerRole,
                            icon: Icons.person_outline,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (created != null && created is Timestamp) ...[
                const SizedBox(height: 12),
                AppStatusPill(
                  label: l10n.memberSince(
                    MaterialLocalizations.of(context)
                        .formatMediumDate(created.toDate()),
                  ),
                  icon: Icons.calendar_month_outlined,
                  color: context.colors.onSurfaceVariant,
                ),
              ],
              const SizedBox(height: 22),
              AppSectionHeader(
                title: l10n.quickLinks,
                icon: Icons.link_outlined,
              ),
              const SizedBox(height: 10),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.propane_tank_outlined,
                        color: context.colors.primary,
                      ),
                      title: Text(l10n.myCylinders),
                      subtitle: Text(l10n.myCylindersSubtitle),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ConsumerCylinderScreen(),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.location_on_outlined,
                        color: context.colors.primary,
                      ),
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
                      leading: Icon(
                        Icons.health_and_safety_outlined,
                        color: context.colors.primary,
                      ),
                      title: Text(l10n.safetyHub),
                      subtitle: Text(l10n.safetyHubSubtitle),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SafetyHubScreen()),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.settings_outlined,
                        color: context.colors.primary,
                      ),
                      title: Text(l10n.settings),
                      subtitle: Text(l10n.settingsSubtitle),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ConsumerSettingsScreen(),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.description_outlined,
                        color: context.colors.primary,
                      ),
                      title: Text(l10n.terms),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TermsScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
