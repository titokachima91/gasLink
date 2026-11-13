import 'package:flutter_test/flutter_test.dart';
import 'package:gaslink_app/services/notification_preferences.dart';

void main() {
  test('channels parse from storage with both as the safe default', () {
    expect(
      NotificationChannel.fromStorage('push_only'),
      NotificationChannel.pushOnly,
    );
    expect(
      NotificationChannel.fromStorage('sms_only'),
      NotificationChannel.smsOnly,
    );
    expect(NotificationChannel.fromStorage('both'), NotificationChannel.both);
    expect(NotificationChannel.fromStorage('none'), NotificationChannel.none);
    expect(
      NotificationChannel.fromStorage(null),
      NotificationChannel.both,
    );
    expect(
      NotificationChannel.fromStorage('unexpected'),
      NotificationChannel.both,
    );
  });

  test('channel capabilities match the four modes', () {
    expect(NotificationChannel.pushOnly.wantsPush, isTrue);
    expect(NotificationChannel.pushOnly.wantsSms, isFalse);
    expect(NotificationChannel.smsOnly.wantsPush, isFalse);
    expect(NotificationChannel.smsOnly.wantsSms, isTrue);
    expect(NotificationChannel.both.wantsPush, isTrue);
    expect(NotificationChannel.both.wantsSms, isTrue);
    expect(NotificationChannel.none.wantsPush, isFalse);
    expect(NotificationChannel.none.wantsSms, isFalse);
  });

  test('existing users default to both channels and AI off', () {
    final profile = NotificationProfile.fromMap(const {});

    expect(profile.channel, NotificationChannel.both);
    expect(profile.aiAssistantEnabled, isFalse);
    expect(profile.phone, isEmpty);
  });

  test('profile reads phone, token and AI opt-in', () {
    final profile = NotificationProfile.fromMap(const {
      'phone': '+255767304776',
      'fcmToken': 'token-1',
      'notification_channel': 'sms_only',
      'ai_assistant_enabled': true,
    });

    expect(profile.channel, NotificationChannel.smsOnly);
    expect(profile.aiAssistantEnabled, isTrue);
    expect(profile.phone, '+255767304776');
    expect(profile.fcmToken, 'token-1');
  });
}
