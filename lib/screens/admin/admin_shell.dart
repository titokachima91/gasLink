import 'package:flutter/material.dart';

import '../../core/admin_guard.dart';
import '../../core/theme_ext.dart';
import '../../services/auth_service.dart';
import '../../widgets/theme_mode_button.dart';
import '../auth/login_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_audit_log_screen.dart';
import 'admin_consumer_list_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_inventory_screen.dart';
import 'admin_more_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_vendors_screen.dart';

/// Responsive shell for the GasLink operations console.
///
/// Compact layouts use five bottom destinations with a More hub; tablet and
/// desktop layouts expose every destination in a navigation rail.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selected = 0;

  static const _destinations = <_AdminDestination>[
    _AdminDestination(
      label: 'Dashboard',
      icon: Icons.space_dashboard_outlined,
      selectedIcon: Icons.space_dashboard,
    ),
    _AdminDestination(
      label: 'Vendors',
      icon: Icons.storefront_outlined,
      selectedIcon: Icons.storefront,
    ),
    _AdminDestination(
      label: 'Orders',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
    ),
    _AdminDestination(
      label: 'Analytics',
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights,
    ),
    _AdminDestination(
      label: 'Consumers',
      icon: Icons.people_alt_outlined,
      selectedIcon: Icons.people_alt,
    ),
    _AdminDestination(
      label: 'Inventory',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
    ),
    _AdminDestination(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  String get _title => _selected == 7 ? 'More' : _destinations[_selected].label;

  Widget _page() {
    switch (_selected) {
      case 0:
        return const AdminDashboardScreen();
      case 1:
        return const AdminVendorsScreen();
      case 2:
        return const AdminOrdersScreen();
      case 3:
        return const AdminAnalyticsScreen();
      case 4:
        return const AdminConsumerListScreen(embedded: true);
      case 5:
        return const AdminInventoryScreen(embedded: true);
      case 6:
        return const AdminSettingsScreen(embedded: true);
      case 7:
        return const AdminMoreScreen();
      default:
        return const AdminDashboardScreen();
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out of admin?'),
        content: const Text('The saved admin session will be cleared.'),
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
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!AdminGuard.isAdmin) return const AdminAccessDenied();

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            tooltip: 'Audit trail',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminAuditLogScreen(),
              ),
            ),
          ),
          const ThemeModeButton(),
          PopupMenuButton<String>(
            tooltip: 'Admin menu',
            onSelected: (value) {
              if (value == 'settings') {
                setState(() => _selected = 6);
              } else if (value == 'audit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminAuditLogScreen(),
                  ),
                );
              } else if (value == 'signout') {
                _signOut();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.settings_outlined),
                  title: Text('Settings'),
                ),
              ),
              PopupMenuItem(
                value: 'audit',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.history),
                  title: Text('Audit trail'),
                ),
              ),
              PopupMenuItem(
                value: 'signout',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.logout),
                  title: Text('Sign out'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            if (!wide) {
              return _CompactBody(
                selected: _selected,
                page: _page(),
                onDestinationSelected: (index) {
                  setState(() => _selected = index == 4 ? 7 : index);
                },
              );
            }
            return Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    border: Border(
                      right: BorderSide(color: context.colors.outlineVariant),
                    ),
                  ),
                  child: NavigationRail(
                    extended: constraints.maxWidth >= 1180,
                    minWidth: 78,
                    labelType: constraints.maxWidth >= 1180
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.all,
                    groupAlignment: -0.92,
                    selectedIndex: _selected <= 6 ? _selected : 0,
                    onDestinationSelected: (index) =>
                        setState(() => _selected = index),
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Column(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: context.colors.primary,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.local_fire_department,
                              color: context.colors.onPrimary,
                            ),
                          ),
                          if (constraints.maxWidth < 1180)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                'OPS',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    destinations: [
                      for (final destination in _destinations)
                        NavigationRailDestination(
                          icon: Icon(destination.icon),
                          selectedIcon: Icon(destination.selectedIcon),
                          label: Text(destination.label),
                        ),
                    ],
                  ),
                ),
                Expanded(child: _page()),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CompactBody extends StatelessWidget {
  const _CompactBody({
    required this.selected,
    required this.page,
    required this.onDestinationSelected,
  });

  final int selected;
  final Widget page;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: page),
        NavigationBar(
          selectedIndex: selected <= 3 ? selected : 4,
          onDestinationSelected: onDestinationSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: 'Vendors',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'Analytics',
            ),
            NavigationDestination(
              icon: Icon(Icons.more_horiz),
              selectedIcon: Icon(Icons.more_horiz),
              label: 'More',
            ),
          ],
        ),
      ],
    );
  }
}

class _AdminDestination {
  const _AdminDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
