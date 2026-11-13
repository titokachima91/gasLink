import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gaslink_app/services/notification_dispatcher.dart';
import 'package:gaslink_app/services/notification_preferences.dart';
import 'package:gaslink_app/services/notification_service.dart';
import 'package:gaslink_app/services/sms_gateway_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakePush implements PushNotificationSink {
  final List<Map<String, dynamic>> sent = [];

  @override
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    sent.add({
      'userId': userId,
      'title': title,
      'body': body,
      'data': data,
    });
  }
}

class _FakePreferences implements NotificationPreferenceSource {
  _FakePreferences(this.profile);

  final NotificationProfile profile;

  @override
  Future<NotificationProfile> load(String uid) async => profile;
}

void main() {
  ({NotificationDispatcher dispatcher, _FakePush push, List<String> sms})
      build(NotificationChannel channel, {String phone = '+255767304776'}) {
    final push = _FakePush();
    final sms = <String>[];
    final client = MockClient((request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      sms.add(body['message'] as String);
      return http.Response(jsonEncode({'success': true}), 200);
    });
    final dispatcher = NotificationDispatcher(
      push: push,
      sms: SmsGatewayService(
        client: client,
        baseUrl: 'http://localhost:3000',
        apiKey: 'gl-test',
      ),
      preferences: _FakePreferences(
        NotificationProfile(
          channel: channel,
          aiAssistantEnabled: false,
          phone: phone,
        ),
      ),
    );
    return (dispatcher: dispatcher, push: push, sms: sms);
  }

  test('both fans out to push and SMS', () async {
    final ctx = build(NotificationChannel.both);
    await ctx.dispatcher.dispatchToUser(
      userId: 'u1',
      title: 'Title',
      body: 'Body',
      smsMessage: 'SMS body',
    );

    expect(ctx.push.sent, hasLength(1));
    expect(ctx.push.sent.single['userId'], 'u1');
    expect(ctx.sms, ['SMS body']);
  });

  test('push_only never sends SMS', () async {
    final ctx = build(NotificationChannel.pushOnly);
    await ctx.dispatcher.dispatchToUser(
      userId: 'u1',
      title: 'Title',
      body: 'Body',
      smsMessage: 'SMS body',
    );

    expect(ctx.push.sent, hasLength(1));
    expect(ctx.sms, isEmpty);
  });

  test('sms_only never enqueues push', () async {
    final ctx = build(NotificationChannel.smsOnly);
    await ctx.dispatcher.dispatchToUser(
      userId: 'u1',
      title: 'Title',
      body: 'Body',
      smsMessage: 'SMS body',
    );

    expect(ctx.push.sent, isEmpty);
    expect(ctx.sms, ['SMS body']);
  });

  test('none suppresses every channel', () async {
    final ctx = build(NotificationChannel.none);
    await ctx.dispatcher.dispatchToUser(
      userId: 'u1',
      title: 'Title',
      body: 'Body',
      smsMessage: 'SMS body',
    );

    expect(ctx.push.sent, isEmpty);
    expect(ctx.sms, isEmpty);
  });

  test('missing phone skips SMS without throwing', () async {
    final ctx = build(NotificationChannel.both, phone: '');
    await ctx.dispatcher.dispatchToUser(
      userId: 'u1',
      title: 'Title',
      body: 'Body',
      smsMessage: 'SMS body',
    );

    expect(ctx.push.sent, hasLength(1));
    expect(ctx.sms, isEmpty);
  });

  test('null SMS message keeps push-only dispatch', () async {
    final ctx = build(NotificationChannel.both);
    await ctx.dispatcher.dispatchToUser(
      userId: 'u1',
      title: 'Title',
      body: 'Body',
    );

    expect(ctx.push.sent, hasLength(1));
    expect(ctx.sms, isEmpty);
  });
}
