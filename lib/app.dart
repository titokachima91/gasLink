// lib/app.dart
// This is the main entry point of the GasLink app. It initializes the app,
// sets up the theme, and routes to the correct dashboard based on the session
// restored by [AuthService]. Login and logout navigate explicitly, so the app
// never re-derives the role from FirebaseAuth.

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_locale.dart';
import 'core/locale_controller.dart';
import 'core/notification_routing.dart';
import 'core/theme.dart';
import 'core/theme_controller.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'screens/role_router.dart';

// FIXED GLOBAL NAVIGATION KEY: Creates a permanent handle for background and foreground notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class GasLinkApp extends ConsumerStatefulWidget {
  const GasLinkApp({super.key});

  @override
  ConsumerState<GasLinkApp> createState() => _GasLinkAppState();
}

class _GasLinkAppState extends ConsumerState<GasLinkApp> {
  @override
  void initState() {
    super.initState();
    NotificationService.instance.onTapMessage = _handleNotificationTap;
    NotificationService.instance.onForegroundMessage = _showForegroundBanner;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Cold start from a terminated state.
      final message = await NotificationService.instance.initialMessage();
      if (message != null && mounted) {
        _handleNotificationTap(message);
      }
    });
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = NotificationRouteData.fromPayload(message.data);
    final navigator = navigatorKey.currentState;
    if (navigator == null || data.orderId.isEmpty) return;
    NotificationRouting.openOrder(
      navigator.context,
      AuthService.instance.currentRole,
      data.orderId,
    );
  }

  void _showForegroundBanner(RemoteMessage message) {
    final data = NotificationRouteData.fromPayload(message.data);
    if (data.orderId.isEmpty) return;
    final navigator = navigatorKey.currentState;
    final context = navigator?.context;
    if (context == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentMaterialBanner();
    messenger.showMaterialBanner(
      MaterialBanner(
        leading: const Icon(Icons.notifications_active_outlined),
        content: Text(
          message.notification?.title ?? 'GasLink',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () {
              messenger.hideCurrentMaterialBanner();
              NotificationRouting.openOrder(
                context,
                AuthService.instance.currentRole,
                data.orderId,
              );
            },
            child: Text(AppLocalizations.of(context).view),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeControllerProvider);
    final appLocale = ref.watch(localeControllerProvider);

    return MaterialApp(
      title: 'GasLink',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: themeMode,
      locale: appLocale.locale,
      supportedLocales: const [Locale('sw'), Locale('en')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // The session is restored in main() before runApp, and every login or
      // logout navigation replaces this route, so AuthService is the only
      // source of truth for the active role.
      home: RoleRouter(userRole: AuthService.instance.currentRole),
    );
  }
}
