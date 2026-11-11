import 'package:flutter/material.dart';

import '../screens/auth/landing_screen.dart';
import '../screens/auth/register_screen.dart';
import '../services/auth_service.dart';

import '../core/theme_ext.dart';

/// Central gate for consumer-only features.
///
/// Guests can browse but must sign in before ordering, tracking, or seeing
/// account data. Every order CTA routes through [requireConsumer] so the
/// behaviour is consistent everywhere.
class SessionGate {
  SessionGate._();

  /// True when the active session belongs to a registered consumer.
  static bool get isConsumer => AuthService.instance.isRegisteredConsumer;

  /// True when the active session is a guest (read-only visitor).
  static bool get isGuest => AuthService.instance.isGuest;

  /// Returns true when a registered consumer session exists. Otherwise shows
  /// the sign-in sheet and returns false; callers should then stop.
  static Future<bool> requireConsumer(BuildContext context) async {
    if (isConsumer) return true;
    _showSignInSheet(context);
    return false;
  }

  static void _showSignInSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final bottomPadding = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.account_circle_outlined,
                    size: 32, color: context.colors.primary),
                const SizedBox(height: 10),
                const Text(
                  'Ingia kuagiza / Sign in to order',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Unda akaunti ya bure au ingia kuendelea na oda yako.',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LandingScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Ingia / Log in'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_add_alt),
                    label: const Text('Unda Akaunti / Create account'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
