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

class VendorDrawer extends StatelessWidget {
  final String storeName;
  final String? imageUrl;
  final int completionPercentage;
  final int currentTier;
  final int selectedIndex;
  final Function(int) onSelectTab;
  final VoidCallback onLogout;

  const VendorDrawer({
    super.key,
    required this.storeName,
    this.imageUrl,
    required this.completionPercentage,
    required this.currentTier,
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
            accountEmail: Row(
              children: [
                Icon(badgeIcon, size: 16, color: badgeColor),
                const SizedBox(width: 6),
                Expanded(
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
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                  ? NetworkImage(imageUrl!)
                  : null,
              child: imageUrl == null || imageUrl!.isEmpty
                  ? Icon(Icons.storefront,
                      color: context.colors.primary, size: 36)
                  : null,
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
                  leading: const Text('📊', style: TextStyle(fontSize: 20)),
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
                  leading: Icon(Icons.workspace_premium,
                      color: context.colors.primary),
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
                  leading: const Text('📦', style: TextStyle(fontSize: 20)),
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
                  leading: const Text('🚚', style: TextStyle(fontSize: 20)),
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
                  leading: const Text('🏪', style: TextStyle(fontSize: 20)),
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
            leading:
                Icon(Icons.settings_outlined, color: context.colors.primary),
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
            leading: const Text('🚪', style: TextStyle(fontSize: 20)),
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
            ListTile(
              leading: Icon(Icons.language, color: context.colors.primary),
              title: const Text('Lugha / Language'),
              subtitle: const Text('Kiswahili (Chaguo kuu)'),
              onTap: () => Navigator.pop(context),
            ),
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
