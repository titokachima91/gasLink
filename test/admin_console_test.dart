import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gaslink_app/core/admin_guard.dart';
import 'package:gaslink_app/core/theme.dart';
import 'package:gaslink_app/core/theme_controller.dart';
import 'package:gaslink_app/models/vendor.dart';
import 'package:gaslink_app/screens/admin/admin_shell.dart';
import 'package:gaslink_app/services/auth_service.dart';

void main() {
  tearDown(() {
    AuthService.instance.currentRole = null;
    AuthService.instance.currentPhone = null;
    AuthService.instance.currentUserId = null;
  });

  test('admin guard accepts only the admin role', () {
    expect(AdminGuard.canAccess(AuthService.roleAdmin), isTrue);
    expect(AdminGuard.canAccess(AuthService.roleVendor), isFalse);
    expect(AdminGuard.canAccess(AuthService.roleConsumer), isFalse);
    expect(AdminGuard.canAccess('guest'), isFalse);
    expect(AdminGuard.canAccess(null), isFalse);
  });

  test('legacy vendors derive a lifecycle status from active', () {
    final now = DateTime(2026, 1, 1);
    final legacyActive = Vendor.fromMap('v1', {
      'businessName': 'Legacy Gas',
      'createdAt': Timestamp.fromDate(now),
      'active': true,
    });
    final legacyInactive = Vendor.fromMap('v2', {
      'businessName': 'Closed Gas',
      'createdAt': Timestamp.fromDate(now),
      'active': false,
    });

    expect(legacyActive.status, VendorStatus.active);
    expect(legacyInactive.status, VendorStatus.suspended);
    expect(VendorStatus.normalize('approved'), VendorStatus.active);
    expect(VendorStatus.normalize('declined'), VendorStatus.rejected);
  });

  test('vendor serialization keeps lifecycle and KYC fields in sync', () {
    final vendor = Vendor(
      id: 'v1',
      businessName: 'Pending Gas',
      createdAt: DateTime(2026, 1, 1),
      status: VendorStatus.pending,
      statusReason: 'Awaiting licence',
      kycReviewedBy: 'admin_local',
    );

    final map = vendor.toMap();

    expect(map['status'], VendorStatus.pending);
    expect(map['statusReason'], 'Awaiting licence');
    expect(map['kycReviewedBy'], 'admin_local');
    expect(map['active'], isFalse);
    expect(map['kycReviewedAt'], isNull);
  });

  testWidgets('non-admin sessions cannot render the admin shell',
      (tester) async {
    AuthService.instance.currentRole = AuthService.roleConsumer;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: const AdminShell(),
      ),
    );
    await tester.pump();

    expect(find.byType(AdminAccessDenied), findsOneWidget);
    expect(find.text('Admin access only'), findsOneWidget);
  });

  testWidgets(
      'admin shell uses bottom navigation on compact and a rail on wide',
      (tester) async {
    await _pumpShell(tester, size: const Size(400, 800));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);

    await _pumpShell(tester, size: const Size(1280, 900));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Consumers'), findsOneWidget);
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('admin shell renders in dark mode without exceptions',
      (tester) async {
    await _pumpShell(
      tester,
      size: const Size(400, 800),
      brightness: Brightness.dark,
    );

    expect(tester.takeException(), isNull);
    expect(
      Theme.of(tester.element(find.byType(AdminShell))).brightness,
      Brightness.dark,
    );
  });
}

Future<void> _pumpShell(
  WidgetTester tester, {
  required Size size,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  AuthService.instance.currentRole = AuthService.roleAdmin;
  AuthService.instance.currentPhone = AuthService.adminPhone;
  AuthService.instance.currentUserId = 'admin_local';

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        initialThemeModeProvider.overrideWithValue(
          brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
        ),
      ],
      child: MaterialApp(
        theme: buildAppTheme(Brightness.light),
        darkTheme: buildAppTheme(Brightness.dark),
        themeMode:
            brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
        locale: const Locale('sw'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: const [Locale('sw'), Locale('en')],
        home: const AdminShell(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}
