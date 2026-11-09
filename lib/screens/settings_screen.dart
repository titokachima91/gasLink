// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'Swahili';
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: 0,
        title: const Text(
          'Mipangilio / Settings',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // ── SECTION 1: PREFERENCES ───────────────────────────────────────
          const Text(
            'Mipangilio ya App / App Preferences',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language, color: Colors.orange),
                  title: const Text('Lugha / Language'),
                  subtitle: Text(_selectedLanguage),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showLanguageDialog,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined,
                      color: Colors.orange),
                  title: const Text('Taarifa (Notifications)'),
                  subtitle: const Text('Pokea taarifa za oda na mabadiliko'),
                  value: _notificationsEnabled,
                  activeColor: Colors.orange,
                  onChanged: (val) {
                    setState(() => _notificationsEnabled = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── SECTION 2: ABOUT & LEGAL ─────────────────────────────────────
          const Text(
            'Kuhusu App / About & Legal',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.orange),
                  title: Text('Kuhusu GasLink / About GasLink'),
                  subtitle: Text('Toleo 1.0.0 (Version 1.0.0)'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined,
                      color: Colors.orange),
                  title: const Text('Sera ya Faragha / Privacy Policy'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('GasLink Privacy Policy v1.0')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined,
                      color: Colors.orange),
                  title: const Text('Vigezo na Masharti / Terms of Service'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('GasLink Terms of Service v1.0')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── SECTION 3: LOGOUT ───────────────────────────────────────────
          ElevatedButton.icon(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text(
              'Ondoka / Logout',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Chagua Lugha / Select Language'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              setState(() => _selectedLanguage = 'Swahili');
              Navigator.pop(context);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child:
                  Text('Kiswahili (Swahili)', style: TextStyle(fontSize: 16)),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              setState(() => _selectedLanguage = 'English');
              Navigator.pop(context);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('English', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ondoka / Logout'),
        content: const Text('Unahakika unataka kuondoka kwenye akaunti?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ghairi'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ondoka', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}
