// lib/services/notification_preferences.dart
// Firestore-backed communication preferences for every registered user.
//
// Schema (users/{uid}):
//   notification_channel: 'push_only' | 'sms_only' | 'both' | 'none'
//   ai_assistant_enabled: bool
//
// Missing values default to 'both' and false, so existing accounts keep
// receiving push notifications and are never silently opted into AI SMS.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'auth_service.dart';

enum NotificationChannel {
  pushOnly('push_only'),
  smsOnly('sms_only'),
  both('both'),
  none('none');

  const NotificationChannel(this.storageValue);

  final String storageValue;

  bool get wantsPush => this == pushOnly || this == both;
  bool get wantsSms => this == smsOnly || this == both;

  static NotificationChannel fromStorage(Object? raw) {
    final value = (raw ?? '').toString().trim().toLowerCase();
    for (final channel in NotificationChannel.values) {
      if (channel.storageValue == value) return channel;
    }
    return NotificationChannel.both;
  }
}

class NotificationProfile {
  const NotificationProfile({
    required this.channel,
    required this.aiAssistantEnabled,
    required this.phone,
    this.fcmToken,
  });

  final NotificationChannel channel;
  final bool aiAssistantEnabled;
  final String phone;
  final String? fcmToken;

  static const NotificationProfile fallback = NotificationProfile(
    channel: NotificationChannel.both,
    aiAssistantEnabled: false,
    phone: '',
  );

  factory NotificationProfile.fromMap(
    Map<String, dynamic> data, {
    String fallbackPhone = '',
  }) {
    final rawPhone = (data['phone'] ?? fallbackPhone).toString().trim();
    return NotificationProfile(
      channel: NotificationChannel.fromStorage(data['notification_channel']),
      aiAssistantEnabled: data['ai_assistant_enabled'] == true,
      phone: rawPhone,
      fcmToken: (data['fcmToken'] ?? data['fcm_token'])?.toString(),
    );
  }
}

abstract class NotificationPreferenceSource {
  Future<NotificationProfile> load(String uid);
}

class NotificationPreferences implements NotificationPreferenceSource {
  NotificationPreferences({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _db.collection('users').doc(uid);

  @override
  Future<NotificationProfile> load(String uid) async {
    if (uid.isEmpty) return NotificationProfile.fallback;
    try {
      final doc = await _userRef(uid).get();
      final data = doc.data();
      if (data == null) return NotificationProfile.fallback;
      final fallbackPhone =
          AuthService.instance.currentUserId == uid
              ? AuthService.instance.currentPhone ?? ''
              : '';
      return NotificationProfile.fromMap(data, fallbackPhone: fallbackPhone);
    } catch (e) {
      debugPrint('Notification preference read warning: $e');
      return NotificationProfile.fallback;
    }
  }

  Future<void> saveChannel(String uid, NotificationChannel channel) async {
    if (uid.isEmpty) return;
    await _userRef(uid).set({
      'notification_channel': channel.storageValue,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveAiAssistantEnabled(String uid, bool enabled) async {
    if (uid.isEmpty) return;
    await _userRef(uid).set({
      'ai_assistant_enabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
