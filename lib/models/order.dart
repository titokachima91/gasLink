// ============================================================================
// FILE PATH: lib/models/order.dart
// ROLE OF THIS FILE:
// This file defines the Order blueprint (data model) for GasLink. It is responsible for:
// 1. Holding all order details in memory (e.g., customer ID, vendor ID, brand, size, quantity, total price, and status).
// 2. Converting order details into a clean format to save in the Firebase database.
// 3. Converting raw database documents into clean Dart objects so screens across the app can easily read them without crashing.
// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String id;
  final String consumerUid;
  final String vendorId;
  final String productId;
  final String brand;
  final String size;
  final String type; // 'refill' | 'full_set' | 'accessories' | 'services'
  final String orderIntent; // 'new_asset' | 'add_stock' | 'swap'
  final int quantity;
  final double unitPrice; // TZS at time of order
  final double total; // quantity * unitPrice
  final double commissionRate;
  final double commissionDue;
  final bool billed;
  final String commissionModel; // 'percentage' | 'subscription' at order time
  final String status; // See AppConstants.orderStatuses for the canonical list
  final String deliveryAddress;
  final String contactPhone;
  final String receiverPhone;
  final String specialRequests;
  final String paymentMethod; // 'cash' | 'mobile_money'
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final String cancellationReason;

  Order({
    required this.id,
    required this.consumerUid,
    required this.vendorId,
    required this.productId,
    required this.brand,
    required this.size,
    required this.type,
    this.orderIntent = 'new_asset',
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.commissionRate,
    required this.commissionDue,
    this.billed = false,
    this.commissionModel = 'percentage',
    required this.status,
    required this.deliveryAddress,
    this.contactPhone = '',
    this.receiverPhone = '',
    this.specialRequests = '',
    this.paymentMethod = 'cash',
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.deliveredAt,
    this.cancelledAt,
    this.cancellationReason = '',
  });

  Map<String, dynamic> toMap() => {
        'consumer_uid': consumerUid,
        'vendor_id': vendorId,
        'product_id': productId,
        'brand': brand,
        'size': size,
        'type': type,
        'order_intent': orderIntent,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total': total,
        'commission_rate': commissionRate,
        'commission_due': commissionDue,
        'billed': billed,
        'commission_model': commissionModel,
        'status': status,
        'delivery_address': deliveryAddress,
        'contact_phone': contactPhone,
        'receiver_phone': receiverPhone,
        'special_requests': specialRequests,
        'payment_method': paymentMethod,
        'latitude': latitude,
        'longitude': longitude,
        'created_at': Timestamp.fromDate(createdAt),
        'delivered_at':
            deliveredAt == null ? null : Timestamp.fromDate(deliveredAt!),
        'cancelled_at':
            cancelledAt == null ? null : Timestamp.fromDate(cancelledAt!),
        'cancellation_reason': cancellationReason,
      };

  factory Order.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return Order(
      id: doc.id,
      consumerUid: d['consumer_uid'] ?? d['consumerUid'] ?? '',
      vendorId: d['vendor_id'] ?? d['vendorId'] ?? '',
      productId: d['product_id'] ?? d['productId'] ?? '',
      brand: d['brand'] ?? d['brand_name'] ?? d['brandName'] ?? '',
      size: d['size'] ?? d['weight'] ?? d['cylinder_weight'] ?? '15kg',
      type: d['type'] ?? d['category'] ?? 'refill',
      orderIntent: d['order_intent'] ?? d['orderIntent'] ?? 'new_asset',
      quantity: (d['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (d['unit_price'] ?? d['unitPrice'] ?? 0).toDouble(),
      total:
          (d['total'] ?? d['total_price'] ?? d['totalPrice'] ?? 0).toDouble(),
      commissionRate:
          (d['commission_rate'] ?? d['commissionRate'] ?? 0.03).toDouble(),
      commissionDue:
          (d['commission_due'] ?? d['commissionDue'] ?? 0).toDouble(),
      billed: d['billed'] ?? false,
      commissionModel:
          (d['commission_model'] ?? d['commissionModel'] ?? 'percentage')
              .toString()
              .toLowerCase(),
      status: d['status'] ?? 'placed',
      deliveryAddress: d['delivery_address'] ?? d['deliveryAddress'] ?? '',
      contactPhone: d['contact_phone'] ?? d['consumerPhone'] ?? '',
      receiverPhone: d['receiver_phone'] ?? '',
      specialRequests: d['special_requests'] ?? '',
      paymentMethod: d['payment_method'] ?? 'cash',
      latitude: (d['latitude'])?.toDouble(),
      longitude: (d['longitude'])?.toDouble(),
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ??
          (d['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      deliveredAt: (d['delivered_at'] as Timestamp?)?.toDate(),
      cancelledAt: (d['cancelled_at'] as Timestamp?)?.toDate(),
      cancellationReason:
          (d['cancellation_reason'] ?? d['cancellationReason'] ?? '')
              .toString(),
    );
  }
}
