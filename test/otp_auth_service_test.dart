import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gaslink_app/core/app_error.dart';
import 'package:gaslink_app/services/otp_auth_service.dart';
import 'package:gaslink_app/services/sms_gateway_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('OTP login is disabled by default', () async {
    final service = OtpAuthService(enabled: false);

    expect(service.isEnabled, isFalse);
    await expectLater(
      service.requestCode('0767304776'),
      throwsA(
        isA<AppError>().having(
          (e) => e.code,
          'code',
          AppError.otpDisabled,
        ),
      ),
    );
  });

  test('enabled OTP service calls send and verify endpoints', () async {
    final calls = <String>[];
    final client = MockClient((request) async {
      calls.add(request.url.path);
      if (request.url.path == '/v1/otp/send') {
        return http.Response(
          jsonEncode({'success': true, 'ref': 'ref-9'}),
          201,
        );
      }
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['code'], '654321');
      return http.Response(jsonEncode({'verified': true}), 200);
    });
    final service = OtpAuthService(
      enabled: true,
      gateway: SmsGatewayService(
        client: client,
        baseUrl: 'http://localhost:3000',
        apiKey: 'gl-test',
      ),
    );

    final challenge = await service.requestCode('0767304776');
    expect(challenge.ref, 'ref-9');

    expect(
      await service.verifyCode(
        phone: '0767304776',
        ref: challenge.ref,
        code: '654321',
      ),
      isTrue,
    );
    expect(calls, ['/v1/otp/send', '/v1/otp/verify']);
  });
}
