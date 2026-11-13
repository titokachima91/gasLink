// lib/screens/about_screen.dart
// App information, readable Terms/Privacy copies, and support contacts.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import '../core/theme_ext.dart';
import '../widgets/app_ui.dart';
import 'legal/legal_screens.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _supportPhone = '+255767304776';
  static const _supportEmail = 'support@gaslink.co.tz';

  Future<void> _callSupport() async {
    await launchUrl(Uri.parse('tel:$_supportPhone'));
  }

  Future<void> _emailSupport() async {
    await launchUrl(Uri(scheme: 'mailto', path: _supportEmail));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Kuhusu GasLink / About GasLink',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.colors.primaryContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.local_fire_department,
                    size: 32,
                    color: context.colors.primary,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  AppConstants.appName,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Toleo / Version ${AppConstants.appVersion}',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gesi mkononi — uthibitisho kabla ya ununuzi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
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
                  title: const Text(
                    'Vigezo na Masharti / Terms & Conditions',
                  ),
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
                  title: const Text('Sera ya Faragha / Privacy Policy'),
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
                  leading: Icon(
                    Icons.phone_outlined,
                    color: context.colors.primary,
                  ),
                  title: const Text('Piga simu / Call'),
                  subtitle: const Text(_supportPhone),
                  onTap: () => _callSupport(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.email_outlined,
                    color: context.colors.primary,
                  ),
                  title: const Text('Barua pepe / Email'),
                  subtitle: const Text(_supportEmail),
                  onTap: () => _emailSupport(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              '© 2026 GasLink',
              style: TextStyle(
                fontSize: 11,
                color: context.colors.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
