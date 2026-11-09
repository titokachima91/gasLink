import 'package:flutter_test/flutter_test.dart';
import 'package:gaslink_app/services/admin_pin_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('session round-trips and can be cleared on logout', () async {
    final service = AdminPinService.instance;

    expect(await service.loadSession(), isNull);

    await service.saveSession(
      role: 'consumer',
      phone: '+255777000778',
      userId: 'user-1',
    );

    final session = await service.loadSession();
    expect(session?.role, 'consumer');
    expect(session?.phone, '+255777000778');
    expect(session?.userId, 'user-1');

    await service.clearSession();
    expect(await service.loadSession(), isNull);
  });

  test('logging in with another account overwrites the previous session',
      () async {
    final service = AdminPinService.instance;

    await service.saveSession(
      role: 'consumer',
      phone: '+255777000778',
      userId: 'user-1',
    );
    await service.saveSession(
      role: 'vendor',
      phone: '+255777000777',
      userId: 'user-2',
    );

    final session = await service.loadSession();
    expect(session?.role, 'vendor');
    expect(session?.phone, '+255777000777');
    expect(session?.userId, 'user-2');
  });

  test('guest session persists without phone or user id', () async {
    final service = AdminPinService.instance;

    await service.saveSession(role: 'guest');

    final session = await service.loadSession();
    expect(session?.role, 'guest');
    expect(session?.phone, isNull);
    expect(session?.userId, isNull);
  });
}
