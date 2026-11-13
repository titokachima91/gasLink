import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
        final l10n = AppLocalizations.of(sheetContext);
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
                Text(
                  l10n.signInToOrderTitle,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.signInToOrderMessage,
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
                    label: Text(l10n.login),
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
                    label: Text(l10n.createAccount),
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

/// Defensive redirect for consumer-only screens.
///
/// Normal navigation checks [SessionGate.requireConsumer] before pushing, so
/// this only runs when a stale guest session or a direct route reaches a
/// consumer screen. It replaces the route with the landing/login flow instead
/// of showing a dead-end page.
class SessionRedirect extends StatefulWidget {
  const SessionRedirect({super.key});

  @override
  State<SessionRedirect> createState() => _SessionRedirectState();
}

class _SessionRedirectState extends State<SessionRedirect> {
  bool _redirected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _redirected) return;
      _redirected = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LandingScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.shrink());
  }
}
