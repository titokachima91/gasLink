import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../screens/admin/admin_order_detail_screen.dart';
import '../screens/consumer/consumer_order_screen.dart';
import '../screens/vendor/vendor_order_screen.dart';

/// Destination a notification tap can resolve to.
enum NotificationTarget { none, consumerOrder, vendorOrders, adminOrder }

/// Parsed FCM data payload carried by order notifications.
class NotificationRouteData {
  const NotificationRouteData({this.orderId = '', this.type = ''});

  final String orderId;
  final String type;

  factory NotificationRouteData.fromPayload(Map<dynamic, dynamic> payload) {
    String read(Object? value) => (value ?? '').toString().trim();
    return NotificationRouteData(
      orderId: read(payload['orderId'] ?? payload['order_id']),
      type: read(payload['type'] ?? ''),
    );
  }
}

/// Role-aware routing for order notification taps.
class NotificationRouting {
  NotificationRouting._();

  /// Pure mapping from session role + order id to a destination.
  static NotificationTarget targetFor(String? role, String? orderId) {
    if ((orderId ?? '').trim().isEmpty) return NotificationTarget.none;
    switch (role) {
      case 'admin':
        return NotificationTarget.adminOrder;
      case 'vendor':
        return NotificationTarget.vendorOrders;
      case 'consumer':
        return NotificationTarget.consumerOrder;
      default:
        return NotificationTarget.none;
    }
  }

  /// Opens the consumer order tracker for [orderId], pulling the display
  /// values from the stored order document.
  static Future<void> openConsumerOrder(
    BuildContext context,
    String orderId,
  ) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();
      if (!context.mounted) return;
      final d = doc.data() ?? {};
      double numOr(dynamic value, double fallback) =>
          value is num ? value.toDouble() : fallback;
      final screen = ConsumerOrderScreen(
        orderId: orderId,
        vendorId: (d['vendor_id'] ?? d['vendorId'] ?? '').toString(),
        vendorName: (d['vendor_name'] ?? d['vendorName'] ?? '').toString(),
        brandName: (d['brand'] ?? d['brand_name'] ?? '').toString(),
        cylinderSize: (d['size'] ?? d['weight'] ?? '15kg').toString(),
        unitPrice: numOr(d['unit_price'] ?? d['unitPrice'], 0),
        totalPrice: numOr(d['total'] ?? d['total_price'], 0),
        deliveryAddress:
            (d['delivery_address'] ?? d['deliveryAddress'] ?? '').toString(),
        contactPhone:
            (d['contact_phone'] ?? d['consumerPhone'] ?? '').toString(),
        paymentMethod: (d['payment_method'] ?? 'cash').toString(),
        quantity: d['quantity'] is num ? (d['quantity'] as num).toInt() : 1,
        specialRequests: (d['special_requests'] ?? '').toString(),
        receiverPhone: (d['receiver_phone'] ?? '').toString(),
        orderIntent:
            (d['order_intent'] ?? d['orderIntent'] ?? 'new_asset').toString(),
      );
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    } catch (error) {
      debugPrint('Notification order lookup failed: $error');
    }
  }

  /// Opens the destination for the active role. No-op when the payload has
  /// no order id or the role is unknown.
  static void openOrder(BuildContext context, String? role, String orderId) {
    switch (targetFor(role, orderId)) {
      case NotificationTarget.consumerOrder:
        openConsumerOrder(context, orderId);
        break;
      case NotificationTarget.vendorOrders:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const VendorOrderScreen()),
        );
        break;
      case NotificationTarget.adminOrder:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AdminOrderDetailScreen(orderId: orderId),
          ),
        );
        break;
      case NotificationTarget.none:
        break;
    }
  }
}
