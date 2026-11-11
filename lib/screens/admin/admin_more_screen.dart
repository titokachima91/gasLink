import 'package:flutter/material.dart';

import '../../core/theme_ext.dart';
import '../../services/auth_service.dart';
import 'widgets/admin_ui.dart';
import 'admin_ad_requests_screen.dart';
import 'admin_consumer_list_screen.dart';
import 'admin_inventory_screen.dart';
import 'admin_settings_screen.dart';

/// Secondary admin destinations on compact layouts.
class AdminMoreScreen extends StatelessWidget {
  const AdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final phone = AuthService.instance.currentPhone ?? 'Admin';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AdminCard(
          child: Row(
            children: [
              const AdminAvatar(name: 'GasLink Admin', size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Operations admin',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      phone,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AdminKeyValueChip(
                label: 'Role',
                value: 'Admin',
                color: context.gasColors.success,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const AdminSectionHeader(
          title: 'Operations',
          subtitle: 'Lookup, stock visibility and console configuration.',
        ),
        AdminCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _MoreTile(
                icon: Icons.people_alt_outlined,
                title: 'Consumers',
                subtitle: 'Profiles, order history and cylinder holdings',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminConsumerListScreen(),
                  ),
                ),
              ),
              const Divider(height: 1),
              _MoreTile(
                icon: Icons.inventory_2_outlined,
                title: 'Inventory',
                subtitle: 'Catalogue coverage and out-of-stock items',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminInventoryScreen(),
                  ),
                ),
              ),
              const Divider(height: 1),
              _MoreTile(
                icon: Icons.campaign_outlined,
                title: 'Ad requests',
                subtitle: 'Review stakeholder advertising submissions',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminAdRequestsScreen(),
                  ),
                ),
              ),
              const Divider(height: 1),
              _MoreTile(
                icon: Icons.settings_outlined,
                title: 'Settings',
                subtitle: 'Commission, support contact and audit trail',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminSettingsScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: context.colors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
