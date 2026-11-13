import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gaslink_app/services/sms_gateway_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('sendSms posts the normalized recipient, message and tenant key',
      () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode({'success': true, 'tenant': 'GasLink'}),
        200,
      );
    });
    final service = SmsGatewayService(
      client: client,
      baseUrl: 'http://192.168.1.12:3000',
      apiKey: 'gl-test',
    );

    await service.sendSms(recipient: '0767304776', message: 'Oda imepokelewa');

    expect(captured.url.path, '/v1/send-sms');
    expect(captured.headers['x-api-key'], 'gl-test');
    expect(captured.headers['content-type'], 'application/json');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['recipient'], '+255767304776');
    expect(body['message'], 'Oda imepokelewa');
  });

  test('sendOtp returns the gateway reference and never a code', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/v1/otp/send');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['phone'], '+255767304776');
      return http.Response(
        jsonEncode({
          'success': true,
          'ref': 'otp-ref-1',
          'expiresAt': '2026-11-13T12:00:00.000Z',
        }),
        201,
      );
    });
    final service = SmsGatewayService(
      client: client,
      baseUrl: 'http://localhost:3000',
      apiKey: 'gl-test',
    );

    final challenge = await service.sendOtp('+255767304776');

    expect(challenge.ref, 'otp-ref-1');
    expect(challenge.expiresAt, isNotNull);
  });

  test('verifyOtp posts phone, ref and code and reads verified', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/v1/otp/verify');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['phone'], '+255767304776');
      expect(body['ref'], 'otp-ref-1');
      expect(body['code'], '123456');
      return http.Response(jsonEncode({'verified': true}), 200);
    });
    final service = SmsGatewayService(
      client: client,
      baseUrl: 'http://localhost:3000',
      apiKey: 'gl-test',
    );

    expect(
      await service.verifyOtp(
        phone: '0767304776',
        ref: 'otp-ref-1',
        code: '123456',
      ),
      isTrue,
    );
  });

  test('unauthorized responses become typed exceptions', () async {
    final client = MockClient((_) async => http.Response('{}', 401));
    final service = SmsGatewayService(
      client: client,
      baseUrl: 'http://localhost:3000',
      apiKey: 'wrong',
    );

    await expectLater(
      service.sendSms(recipient: '0767304776', message: 'test'),
      throwsA(
        isA<SmsGatewayException>().having(
          (e) => e.code,
          'code',
          SmsGatewayException.unauthorized,
        ),
      ),
    );
  });

  test('missing API key disables sending safely', () async {
    final service = SmsGatewayService(
      client: MockClient((_) async => http.Response('{}', 200)),
      baseUrl: 'http://localhost:3000',
      apiKey: '',
    );

    expect(service.isConfigured, isFalse);
    await expectLater(
      service.sendSms(recipient: '0767304776', message: 'test'),
      throwsA(
        isA<SmsGatewayException>().having(
          (e) => e.code,
          'code',
          SmsGatewayException.notConfigured,
        ),
      ),
    );
  });
}
