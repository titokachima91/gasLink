import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'theme_ext.dart';

/// Central client-side admin access check.
///
/// Firestore rules and server-side checks remain mandatory before launch; this
/// guard prevents accidental navigation into the console and keeps admin-only
/// UI decisions in one place.
class AdminGuard {
  AdminGuard._();

  static bool get isAdmin => canAccess(AuthService.instance.currentRole);

  static bool canAccess(String? role) => role == AuthService.roleAdmin;
}

class AdminAccessDenied extends StatelessWidget {
  const AdminAccessDenied({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 56, color: context.colors.error),
              const SizedBox(height: 16),
              Text(
                'Admin access only',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'This account does not have permission to open the operations console.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
