/// ============================================================================
/// FILE: lib/screens/vendor/widgets/vendor_drawer.dart
///
/// SUMMARY:
/// Primary left navigation drawer (☰) for authenticated LPG vendors.
/// Displays shop header metadata, active 3-tier badge status, profile completion
/// meter, and main menu routes (Dashboard, Badges Hub, Inventory, Orders, Store Profile).
/// ============================================================================
library;

import 'package:flutter/material.dart';
import '../vendor_badge_screen.dart';
import '../vendor_settings_screen.dart';

import '../../../core/theme_ext.dart';
import '../../../widgets/language_picker.dart';

class VendorDrawer extends StatelessWidget {
  final String storeName;
  final String? imageUrl;
  final int completionPercentage;
  final int currentTier;
  final bool verified;
  final int selectedIndex;
  final Function(int) onSelectTab;
  final VoidCallback onLogout;

  const VendorDrawer({
    super.key,
    required this.storeName,
    this.imageUrl,
    required this.completionPercentage,
    required this.currentTier,
    this.verified = false,
    required this.selectedIndex,
    required this.onSelectTab,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    // Dynamic 3-Tier Verification Badge Text & Icon
    String badgeLabel;
    IconData badgeIcon;
    Color badgeColor;

    switch (currentTier) {
      case 3:
        badgeLabel = 'Muuzaji Anayeaminika (Tier 3)';
        badgeIcon = Icons.workspace_premium;
        // Lighten status colors so they stay visible on the dark header.
        badgeColor = Color.lerp(context.gasColors.warning, Colors.white, 0.55)!;
        break;
      case 2:
        badgeLabel = 'Muuzaji Aliyethibitishwa (Tier 2)';
        badgeIcon = Icons.verified;
        badgeColor = Color.lerp(context.gasColors.success, Colors.white, 0.55)!;
        break;
      case 1:
      default:
        badgeLabel = 'Muuza Gesi (Tier 1)';
        badgeIcon = Icons.storefront;
        badgeColor = Colors.white;
        break;
    }

    return Drawer(
      child: Column(
        children: [
          // ── Header Card ──────────────────────────────────────────────
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).appBarTheme.backgroundColor,
            ),
            accountName: Text(
              storeName.isEmpty ? 'Duka Langu' : storeName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            accountEmail: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(badgeIcon, size: 16, color: badgeColor),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        badgeLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (verified) ...[
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Imethibitishwa / Verified',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty)
                  ? NetworkImage(imageUrl!)
                  : const AssetImage('assets/gaslinklogo.png') as ImageProvider,
            ),
          ),

          // ── Profile Completion Meter ──────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ukamilifu wa Akaunti',
                      style: TextStyle(
                          fontSize: 12, color: context.colors.onSurfaceVariant),
                    ),
                    Text(
                      '$completionPercentage%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: context.colors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: completionPercentage / 100,
                    minHeight: 6,
                    color: context.colors.primary,
                    backgroundColor: context.colors.outlineVariant,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // ── Drawer Menu Items ────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // 0: Dashboard
                ListTile(
                  leading: _navIcon(context, Icons.dashboard_outlined),
                  title: const Text('Dashboard'),
                  subtitle: const Text(
                    'Muhtasari wa mauzo na oda',
                    style: TextStyle(fontSize: 11),
                  ),
                  selected: selectedIndex == 0,
                  selectedTileColor: context.colors.primaryContainer,
                  selectedColor: context.colors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    onSelectTab(0);
                  },
                ),

                // 1: Badges & Gamified Progress Hub
                // NEW CODE:
                ListTile(
                  leading: _navIcon(context, Icons.workspace_premium_outlined),
                  title: const Text('Tuzo na Uthibitisho'),
                  subtitle: const Text('Hatua za Badge & Badges Hub'),
                  onTap: () {
                    Navigator.pop(context); // 1. Close the drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const VendorBadgeScreen(), // 2. Open the Badge Hub screen
                      ),
                    );
                  },
                ),
                // 2: Inventory & Products
                ListTile(
                  leading: _navIcon(context, Icons.inventory_2_outlined),
                  title: const Text('Stoki & Bidhaa'),
                  subtitle: const Text(
                    'Usimamizi wa bei na stoki',
                    style: TextStyle(fontSize: 11),
                  ),
                  selected: selectedIndex == 2,
                  selectedTileColor: context.colors.primaryContainer,
                  selectedColor: context.colors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    onSelectTab(2);
                  },
                ),

                // 3: Order Management
                ListTile(
                  leading: _navIcon(context, Icons.local_shipping_outlined),
                  title: const Text('Usimamizi wa Oda'),
                  subtitle: const Text(
                    'Oda zinazoingia na kufikishwa',
                    style: TextStyle(fontSize: 11),
                  ),
                  selected: selectedIndex == 3,
                  selectedTileColor: context.colors.primaryContainer,
                  selectedColor: context.colors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    onSelectTab(3);
                  },
                ),

                // 4: Store Profile
                ListTile(
                  leading: _navIcon(context, Icons.storefront_outlined),
                  title: const Text('Taarifa za Duka'),
                  subtitle: const Text(
                    'Leseni, Eneo & Mipangilio ya Duka',
                    style: TextStyle(fontSize: 11),
                  ),
                  selected: selectedIndex == 4,
                  selectedTileColor: context.colors.primaryContainer,
                  selectedColor: context.colors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    onSelectTab(4);
                  },
                ),
              ],
            ),
          ),

          const Divider(),

          // ── Footer Actions ───────────────────────────────────────────
          ListTile(
            leading: _navIcon(context, Icons.settings_outlined),
            title: const Text('Mipangilio / Settings'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VendorSettingsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading:
                _navIcon(context, Icons.logout, color: context.colors.error),
            title:
                Text('Logout', style: TextStyle(color: context.colors.error)),
            onTap: () {
              Navigator.pop(context);
              onLogout();
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _navIcon(BuildContext context, IconData icon, {Color? color}) {
    final accent = color ?? context.colors.primary;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, size: 18, color: accent),
    );
  }

  void _showSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mipangilio / Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            const LanguagePickerTile(),
            ListTile(
              leading: Icon(Icons.notifications_active_outlined,
                  color: context.colors.primary),
              title: const Text('Sauti ya Oda Mpya / Audio Alerts'),
              trailing: Switch(
                value: true,
                activeColor: context.colors.primary,
                onChanged: (_) {},
              ),
            ),
            ListTile(
              leading: Icon(Icons.support_agent_rounded,
                  color: context.colors.primary),
              title: const Text('Msaada / Support'),
              subtitle: const Text('Piga au Tuma ujumbe WhatsApp'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
