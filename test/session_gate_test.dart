import 'package:flutter_test/flutter_test.dart';

import 'package:gaslink_app/core/session_gate.dart';
import 'package:gaslink_app/services/auth_service.dart';

void main() {
  tearDown(() {
    AuthService.instance.currentRole = null;
    AuthService.instance.currentPhone = null;
    AuthService.instance.currentUserId = null;
  });

  test('session state distinguishes guest from registered consumer', () {
    AuthService.instance.currentRole = 'guest';
    expect(AuthService.instance.isGuest, isTrue);
    expect(AuthService.instance.isRegisteredConsumer, isFalse);
    expect(SessionGate.isGuest, isTrue);
    expect(SessionGate.isConsumer, isFalse);

    AuthService.instance.currentRole = AuthService.roleConsumer;
    expect(AuthService.instance.isGuest, isFalse);
    expect(AuthService.instance.isRegisteredConsumer, isTrue);
    expect(SessionGate.isGuest, isFalse);
    expect(SessionGate.isConsumer, isTrue);
  });

  test('vendor and admin roles are never consumers or guests', () {
    for (final role in [AuthService.roleVendor, AuthService.roleAdmin]) {
      AuthService.instance.currentRole = role;
      expect(SessionGate.isConsumer, isFalse);
      expect(SessionGate.isGuest, isFalse);
    }
  });

  test('no session is treated as neither guest nor consumer', () {
    AuthService.instance.currentRole = null;
    expect(SessionGate.isConsumer, isFalse);
    expect(SessionGate.isGuest, isFalse);
  });
}
