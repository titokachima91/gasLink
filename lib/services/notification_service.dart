// lib/services/notification_service.dart
// This service manages push notifications for the app. It handles Firebase Cloud Messaging (FCM)
// integration, including requesting permissions, receiving messages, and displaying local
// notification banners in the foreground. It safely updates and synchronizes user FCM tokens
// with Firestore across Web and Mobile environments without stalling authentication routines.

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();
  FirebaseMessaging? _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Called when a background notification is tapped while the app is open.
  void Function(RemoteMessage message)? onTapMessage;

  /// Called for notifications arriving while the app is in the foreground,
  /// in addition to the local heads-up.
  void Function(RemoteMessage message)? onForegroundMessage;

  RemoteMessage? _initialMessage;
  bool _initialFetched = false;

  /// The message that launched the app from a terminated state, if any.
  Future<RemoteMessage?> initialMessage() async {
    if (_initialFetched) return _initialMessage;
    _initialFetched = true;
    try {
      _initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    } catch (e) {
      debugPrint('Could not read initial FCM message: $e');
    }
    return _initialMessage;
  }

  /// Initializes FCM permissions, local channels, and foreground listeners
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _fcm = FirebaseMessaging.instance;
      // Request OS-level permissions
      await _fcm!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      // Initialize local notification settings for Android
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _localNotifications.initialize(initSettings);
      // Create high-priority notification channel for Android
      const androidChannel = AndroidNotificationChannel(
        'gaslink_orders_channel',
        'Order Status Updates',
        description: 'Notifications for incoming orders and status changes',
        importance: Importance.max,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
      // FIXED: Listens to incoming Firebase messages and displays them instantly
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null) {
          showLocalNotification(
            title: notification.title ?? 'GasLink Alert',
            body: notification.body ?? '',
          );
        }
        onForegroundMessage?.call(message);
      });
      // Tap-through: notification opened while the app is backgrounded.
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        onTapMessage?.call(message);
      });
      _initialized = true;
    } catch (e, stackTrace) {
      debugPrint('Error initializing NotificationService: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Saves or refreshes FCM token in Firestore under /users/{uid}
  /// FIXED: Explicitly accepts the authenticated uid to guarantee data matching
  Future<void> saveTokenToFirestore({String? uid, String? vapidKey}) async {
    // Fallback to memory state if an explicit uid was not passed
    final targetUid = uid ?? AuthService.instance.currentUserId;
    if (targetUid == null || _fcm == null) {
      debugPrint(
          '⚠️ Cannot save FCM token: targetUid or FCM instance is null.');
      return;
    }
    try {
      // FIXED: Correctly passes the vapidKey directly into the token request parameter
      final token = await _fcm!.getToken(
        vapidKey: kIsWeb ? vapidKey : null,
      );
      if (token != null) {
        debugPrint('🔥 FCM DEVICE TOKEN SYNCHRONIZED: $token');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUid)
            .set({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error saving FCM token to Firestore: $e');
    }
  }

  /// Displays immediate local heads-up notification banner
  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'gaslink_orders_channel',
      'Order Status Updates',
      channelDescription:
          'Notifications for incoming orders and status changes',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(android: androidDetails);
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  /// Sends a notification payload targeted to a specific user by ID
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'fcmToken': fcmToken,
        'title': title,
        'body': body,
        'data': data,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
      debugPrint('Notification sent to user $userId');
    } catch (e) {
      debugPrint('Error sending notification to user $userId: $e');
    }
  }
}
