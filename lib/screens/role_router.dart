import 'package:flutter/material.dart';
import 'consumer/home_screen.dart';
import 'vendor/vendor_home_screen.dart';
import 'auth/login_screen.dart';

class RoleRouter extends StatelessWidget {
  final String? userRole;
  const RoleRouter({super.key, this.userRole});

  @override
  Widget build(BuildContext context) {
    switch (userRole) {
      case 'vendor':
        return const VendorHomeScreen();
      case 'consumer':
        return const ConsumerHomeScreen();
      default:
        return const LoginScreen();
    }
  }
}
