// lib/app.dart
// This is the main entry point of the GasLink app. It initializes the app,
// sets up the theme, and routes to the correct dashboard based on the session
// restored by [AuthService]. Login and logout navigate explicitly, so the app
// never re-derives the role from FirebaseAuth.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'core/theme_controller.dart';
import 'services/auth_service.dart';
import 'screens/role_router.dart';

// FIXED GLOBAL NAVIGATION KEY: Creates a permanent handle for background and foreground notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class GasLinkApp extends ConsumerWidget {
  const GasLinkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);

    return MaterialApp(
      title: 'GasLink',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: themeMode,
      // The session is restored in main() before runApp, and every login or
      // logout navigation replaces this route, so AuthService is the only
      // source of truth for the active role.
      home: RoleRouter(userRole: AuthService.instance.currentRole),
    );
  }
}
