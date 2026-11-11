import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gaslink_app/core/theme.dart';
import 'package:gaslink_app/models/order.dart';
import 'package:gaslink_app/models/vendor.dart';
import 'package:gaslink_app/screens/vendor/widgets/vendor_commission_card.dart';
import 'package:gaslink_app/services/vendor_image_service.dart';

void main() {
  group('vendor commission model', () {
    test('defaults to percentage and derives the effective rate', () {
      final vendor = Vendor.fromMap('v1', {
        'businessName': 'Percent Gas',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'commissionRate': 0.05,
      });

      expect(vendor.commissionModel, 'percentage');
      expect(vendor.isSubscription, isFalse);
      expect(vendor.effectiveCommissionRate, 0.05);
      expect(vendor.commissionLabel, '5.0% per order');
    });

    test('subscription vendors pay no per-order rate', () {
      final vendor = Vendor.fromMap('v2', {
        'businessName': 'Monthly Gas',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'commissionModel': 'subscription',
        'subscriptionFee': 75000,
        'commissionRate': 0.10,
      });

      expect(vendor.isSubscription, isTrue);
      expect(vendor.effectiveCommissionRate, 0);
      expect(vendor.commissionLabel, 'TZS 75000/month');

      final map = vendor.toMap();
      expect(map['commissionModel'], 'subscription');
      expect(map['subscriptionFee'], 75000);

      final copy = vendor.copyWith(status: VendorStatus.active);
      expect(copy.isSubscription, isTrue);
    });
  });

  group('order commission stamping', () {
    test('orders round-trip the commission model snapshot', () {
      final order = Order(
        id: 'o1',
        consumerUid: 'c1',
        vendorId: 'v1',
        productId: 'p1',
        brand: 'Oryx',
        size: '15kg',
        type: 'refill',
        quantity: 1,
        unitPrice: 25000,
        total: 25000,
        commissionRate: 0,
        commissionDue: 0,
        commissionModel: 'subscription',
        status: 'placed',
        deliveryAddress: 'Sinza',
        createdAt: DateTime(2026, 1, 1),
      );

      final map = order.toMap();
      expect(map['commission_model'], 'subscription');
      expect(map['commission_due'], 0);
      expect(order.commissionModel, 'subscription');
    });
  });

  group('vendor image validation', () {
    test('accepts only image content types', () {
      expect(VendorImageService.validateType('image/jpeg'), isNull);
      expect(VendorImageService.validateType('image/png'), isNull);
      expect(VendorImageService.validateType('application/pdf'), isNotNull);
      expect(VendorImageService.validateType(null), isNotNull);
    });

    test('rejects files over 5 MB', () {
      expect(
        VendorImageService.validateSize(4 * 1024 * 1024),
        isNull,
      );
      expect(
        VendorImageService.validateSize(6 * 1024 * 1024),
        isNotNull,
      );
    });

    test('derives a safe extension from the MIME type', () {
      expect(VendorImageService.extensionFor('image/jpeg'), 'jpg');
      expect(VendorImageService.extensionFor('image/png'), 'png');
      expect(VendorImageService.extensionFor('image/webp'), 'webp');
      expect(VendorImageService.extensionFor(null), 'jpg');
    });
  });

  group('vendor commission terms card', () {
    final percentageVendor = Vendor(
      id: 'v1',
      businessName: 'Percent Gas',
      createdAt: DateTime(2026, 1, 1),
      commissionRate: 0.045,
    );
    final subscriptionVendor = Vendor(
      id: 'v2',
      businessName: 'Monthly Gas',
      createdAt: DateTime(2026, 1, 1),
      commissionModel: 'subscription',
      subscriptionFee: 60000,
    );

    testWidgets('renders percentage terms in light and dark', (tester) async {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(brightness),
            home: Scaffold(
              body: VendorCommissionTermsCard(vendor: percentageVendor),
            ),
          ),
        );

        expect(find.text('Percentage'), findsOneWidget);
        expect(find.text('4.5% per order'), findsOneWidget);
        expect(
          find.text('Inasimamiwa na GasLink / Managed by GasLink'),
          findsOneWidget,
        );
      }
    });

    testWidgets('renders subscription terms', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: Scaffold(
            body: VendorCommissionTermsCard(vendor: subscriptionVendor),
          ),
        ),
      );

      expect(find.text('Monthly subscription'), findsOneWidget);
      expect(find.text('TZS 60000/month'), findsOneWidget);
    });

    testWidgets('handles a missing vendor', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: const Scaffold(
            body: VendorCommissionTermsCard(vendor: null),
          ),
        ),
      );

      expect(find.text('Haijawekwa / Not set'), findsOneWidget);
    });
  });
}
