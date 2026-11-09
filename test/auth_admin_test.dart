import 'package:flutter_test/flutter_test.dart';
import 'package:gaslink_app/services/admin_pin_service.dart';
import 'package:gaslink_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthService.instance.currentRole = null;
    AuthService.instance.currentPhone = null;
    AuthService.instance.currentUserId = null;
  });

  test('hardcoded admin logs in with every phone format', () async {
    final auth = AuthService.instance;

    final result = await auth.login('0767304776', '0000');
    expect(result?['role'], AuthService.roleAdmin);
    expect(auth.currentRole, AuthService.roleAdmin);
    expect(auth.currentPhone, AuthService.adminPhone);

    // Session is persisted immediately.
    final session = await AdminPinService.instance.loadSession();
    expect(session?.role, AuthService.roleAdmin);
    expect(session?.phone, AuthService.adminPhone);
  });

  test('admin accepts 255... and +255... formats', () async {
    expect(
      (await AuthService.instance.login('255767304776', '0000'))?['role'],
      AuthService.roleAdmin,
    );

    AuthService.instance.currentRole = null;
    expect(
      (await AuthService.instance.login('+255767304776', '0000'))?['role'],
      AuthService.roleAdmin,
    );
  });

  test('wrong admin PIN is rejected', () async {
    expect(
      () => AuthService.instance.adminLogin('0767304776', '9999'),
      throwsA(isA<Exception>()),
    );
    expect(AuthService.instance.currentRole, isNull);
  });

  test('invalid phone numbers are rejected before any lookup', () async {
    expect(
      () => AuthService.instance.login('123456789', '0000'),
      throwsA(isA<Exception>()),
    );
    expect(
      () => AuthService.instance.register('123456789', '1234'),
      throwsA(isA<Exception>()),
    );
  });

  test('non-4-digit PINs are rejected', () async {
    expect(
      () => AuthService.instance.login('0767304776', '00'),
      throwsA(isA<Exception>()),
    );
  });

  test('restored admin session survives and keeps the admin role', () async {
    await AdminPinService.instance.saveSession(
      role: AuthService.roleAdmin,
      phone: AuthService.adminPhone,
      userId: 'admin_local',
    );

    await AuthService.instance.restoreSession();

    expect(AuthService.instance.currentRole, AuthService.roleAdmin);
    expect(AuthService.instance.currentPhone, AuthService.adminPhone);
    expect(AuthService.instance.currentUserId, 'admin_local');
  });

  test('unknown persisted roles are discarded instead of routed', () async {
    await AdminPinService.instance.saveSession(role: 'superadmin');

    await AuthService.instance.restoreSession();

    expect(AuthService.instance.currentRole, isNull);
    expect(await AdminPinService.instance.loadSession(), isNull);
  });
}
