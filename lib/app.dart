// lib/app.dart
// This is the main entry point of the GasLink app. It initializes the app, sets up the theme, and manages user authentication state. Depending on whether the user is logged in and their role (consumer or vendor), it routes them to the appropriate screen using the RoleRouter widget. The app listens to Firebase authentication state changes and fetches user roles from Firestore to determine the correct navigation flow.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/theme.dart';
import 'services/auth_service.dart';
import 'screens/role_router.dart';

// FIXED GLOBAL NAVIGATION KEY: Creates a permanent handle for background and foreground notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class GasLinkApp extends StatelessWidget {
  const GasLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GasLink',
      navigatorKey:
          navigatorKey, // 🟢 FIXED: Linked the root handle cleanly here
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance
            .authStateChanges(), // Standard Firebase auth stream
        builder: (context, authSnap) {
          // 1. Waiting for auth state check
          if (authSnap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = authSnap.data;

          // 2. Not logged in -> pass null to RoleRouter (shows Login/Auth Screen)
          if (user == null) {
            return const RoleRouter(userRole: null);
          }

          // 3. Logged in -> fetch the user's role from Firestore ONCE,
          //    then sync to AuthService (single source of truth)
          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(),
            builder: (context, userSnap) {
              if (userSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              final userData = userSnap.data?.data();
              final role = userData?['role'] as String? ?? 'consumer';
              // Sync to AuthService — this is the single source of truth for role
              AuthService.instance.currentRole = role;
              AuthService.instance.currentUserId = user.uid;
              AuthService.instance.currentPhone =
                  userData?['phone'] as String?;
              return RoleRouter(userRole: role);
            },
          );
        },
      ),
    );
  }
}
