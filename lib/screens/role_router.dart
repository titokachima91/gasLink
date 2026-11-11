/// ============================================================================
/// FILE: lib/screens/role_router.dart
///
/// SUMMARY:
/// Dynamic role router using `AuthService.instance` session data.
/// Routes admins to `AdminShell`, vendors to `VendorDashboardScreen`,
/// consumers/guests to `ConsumerHomeScreen`, and unauthenticated users to
/// the blended landing + login screen.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'admin/admin_shell.dart';
import 'auth/landing_screen.dart';
import 'vendor/vendor_dashboard_screen.dart';
import 'consumer/consumer_home_screen.dart';

class RoleRouter extends StatelessWidget {
  final String? userRole;

  const RoleRouter({super.key, this.userRole});

  @override
  Widget build(BuildContext context) {
    // 1. Determine active role: explicit parameter first, fallback to AuthService session
    final effectiveRole = userRole ?? AuthService.instance.currentRole;

    // 2. Admin Route -> Operations console
    if (effectiveRole == AuthService.roleAdmin) {
      return const AdminShell();
    }

    // 3. Vendor Route
    if (effectiveRole == AuthService.roleVendor) {
      return const VendorDashboardScreen();
    }

    // 4. Consumer & Guest Route
    if (effectiveRole == AuthService.roleConsumer || effectiveRole == 'guest') {
      return const ConsumerHomeScreen();
    }

    // 5. Unauthenticated Default -> Landing page (login is one tap away).
    return const LandingScreen();
  }
}
