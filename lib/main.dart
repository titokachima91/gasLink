// lib/main.dart
// This is the main entry point of the GasLink app. It initializes Firebase with platform options,
// sets up the app theme, and manages user authentication state. The app listens to Firebase
// authentication state changes and fetches user roles from Firestore to determine the correct navigation flow.
// It also seeds default test users for development purposes.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart'; // <--- Added generated options import
import 'services/auth_service.dart';
import 'services/notification_service.dart';

/// Top-level background message handler required by Firebase Messaging
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint("Handling background message: ${message.messageId}");
}

void main() async {
  // 1. Ensure Flutter binding is initialized before native plugin calls
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase FIRST before any widget tree or services mount
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions
          .currentPlatform, // <--- Configured for Web, Android & macOS
    );
    debugPrint('Firebase initialized successfully.');

    // FCM setup (Background handler & Service init)
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
    }
    await NotificationService.instance.initialize();

    // Fetch and print active FCM Device Token for testing
    final String? fcmToken = await FirebaseMessaging.instance.getToken();
    debugPrint('\n==================================================');
    debugPrint('🔥 FCM DEVICE TOKEN FOR PUSH TESTING:');
    debugPrint('$fcmToken');
    debugPrint('==================================================\n');

    // Seed default test users (debug only)
    await AuthService.instance.seedUser('+255777000777', '1234', 'vendor');
    await AuthService.instance.seedUser('+255777000778', '1234', 'consumer');
  } catch (e, stackTrace) {
    debugPrint('Firebase init error: $e');
    debugPrint('Stack trace: $stackTrace');
  }

  // 3. Mount app
  runApp(const GasLinkApp());
}
