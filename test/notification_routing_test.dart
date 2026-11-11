import 'package:flutter_test/flutter_test.dart';

import 'package:gaslink_app/core/notification_routing.dart';

void main() {
  group('notification payload parsing', () {
    test('reads orderId variants and type', () {
      expect(
        NotificationRouteData.fromPayload({'orderId': 'o1'}).orderId,
        'o1',
      );
      expect(
        NotificationRouteData.fromPayload({'order_id': ' o2 '}).orderId,
        'o2',
      );
      expect(
        NotificationRouteData.fromPayload({'type': 'new_order'}).type,
        'new_order',
      );
      expect(NotificationRouteData.fromPayload({}).orderId, '');
    });
  });

  group('role-aware routing', () {
    test('maps roles to targets only when an order id exists', () {
      expect(
        NotificationRouting.targetFor('admin', 'o1'),
        NotificationTarget.adminOrder,
      );
      expect(
        NotificationRouting.targetFor('vendor', 'o1'),
        NotificationTarget.vendorOrders,
      );
      expect(
        NotificationRouting.targetFor('consumer', 'o1'),
        NotificationTarget.consumerOrder,
      );
      expect(
        NotificationRouting.targetFor('consumer', ''),
        NotificationTarget.none,
      );
      expect(
          NotificationRouting.targetFor(null, 'o1'), NotificationTarget.none);
      expect(
        NotificationRouting.targetFor('guest', 'o1'),
        NotificationTarget.none,
      );
    });
  });
}
