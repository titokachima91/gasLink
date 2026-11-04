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

    // 2. Admin Route -> Admin dashboard (stub, build out later)
    if (effectiveRole == AuthService.roleAdmin) {
      return const AdminScreen();
    }

    // 3. Vendor Route
    if (effectiveRole == AuthService.roleVendor) {
      return const VendorDashboardScreen();
    }

    // 4. Consumer & Guest Route
    if (effectiveRole == AuthService.roleConsumer || effectiveRole == 'guest') {
      return const ConsumerHomeScreen();
    }

    // 5. Unauthenticated Default -> Show LoginScreen
    return const LoginScreen();
  }

  }

/// Stub admin screen — replace with real admin panel when ready.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: const Center(
        child: Text('Admin panel coming soon.\nUse Firestore Console to create vendors.'),
      ),
    );
  }
}
