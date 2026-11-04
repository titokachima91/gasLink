/// ============================================================================
/// FILE: lib/screens/role_router.dart
///
/// SUMMARY:
/// Dynamic role router using `AuthService.instance` session data.
/// Routes vendors to `VendorDashboardScreen`, consumers/guests to `ConsumerHomeScreen`,
/// and unauthenticated users to `LoginScreen`.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';
import 'vendor/vendor_dashboard_screen.dart';
import 'consumer/consumer_home_screen.dart';

class RoleRouter extends StatelessWidget {
  final String? userRole;

  const RoleRouter({super.key, this.userRole});

  @override
  Widget build(BuildContext context) {
    // 1. Determine active role: explicit parameter first, fallback to AuthService session
    final effectiveRole = userRole ?? AuthService.instance.currentRole;

    // 2. Vendor Route
    if (effectiveRole == 'vendor') {
      return const VendorDashboardScreen();
    }

    // 3. Consumer & Guest Route
    if (effectiveRole == 'consumer' || effectiveRole == 'guest') {
      return const ConsumerHomeScreen();
    }

    // 4. Unauthenticated Default -> Show LoginScreen
    return const LoginScreen();
  }
}
