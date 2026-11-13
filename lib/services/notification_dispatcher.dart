// lib/services/notification_dispatcher.dart
// Central fan-out for every user-facing notification.
//
// It reads the recipient's channel preference and then:
//   push_only / both  -> existing Firestore notification ledger + FCM flow
//   sms_only / both   -> POST /v1/send-sms on the self-hosted gateway
//   none              -> nothing
//
// Failures never break order placement: each channel is best-effort and logs.

import 'package:flutter/foundation.dart';

import 'notification_preferences.dart';
import 'notification_service.dart';
import 'sms_gateway_service.dart';

class NotificationDispatcher {
  NotificationDispatcher({
    PushNotificationSink? push,
    SmsGatewayService? sms,
    NotificationPreferenceSource? preferences,
  })  : _push = push ?? NotificationService.instance,
        _sms = sms ?? SmsGatewayService.instance,
        _preferences = preferences ?? NotificationPreferences();

  static final NotificationDispatcher instance = NotificationDispatcher();

  final PushNotificationSink _push;
  final SmsGatewayService _sms;
  final NotificationPreferenceSource _preferences;

  /// Dispatches one event to one recipient.
  ///
  /// [title], [body] and [smsMessage] should already be localized by the
  /// caller. When [smsMessage] is null only the push channel is attempted.
  Future<void> dispatchToUser({
    required String userId,
    required String title,
    required String body,
    String? smsMessage,
    Map<String, dynamic>? data,
  }) async {
    if (userId.trim().isEmpty) return;

    final profile = await _preferences.load(userId);

    if (profile.channel.wantsPush) {
      try {
        await _push.sendNotificationToUser(
          userId: userId,
          title: title,
          body: body,
          data: data,
        );
      } catch (e) {
        debugPrint('Notification push dispatch warning: $e');
      }
    }

    if (profile.channel.wantsSms &&
        smsMessage != null &&
        smsMessage.trim().isNotEmpty) {
      if (!_sms.isConfigured) {
        debugPrint(
          'SMS skipped for $userId: SMS_GATEWAY_API_KEY is not configured.',
        );
        return;
      }
      if (profile.phone.trim().isEmpty) {
        debugPrint('SMS skipped for $userId: no phone number on profile.');
        return;
      }
      try {
        await _sms.sendSms(recipient: profile.phone, message: smsMessage);
      } catch (e) {
        debugPrint('SMS dispatch warning for $userId: $e');
      }
    }
  }
}
