import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String id;
  final String consumerUid;
  final String vendorId;
  final String productId;
  final String brand;
  final String size;
  final String type; // 'refill' | 'exchange'
  final int quantity;
  final double unitPrice; // TZS at time of order
  final double total; // quantity * unitPrice
  final double commissionRate; // copied from vendor at order time
  final double commissionDue; // total * commissionRate
  final bool billed; // true once included in a monthly invoice
  final String status; // 'placed'|'confirmed'|'on_the_way'|'delivered'
  final String deliveryAddress;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime? deliveredAt; // set when status → delivered

  Order({
    required this.id,
    required this.consumerUid,
    required this.vendorId,
    required this.productId,
    required this.brand,
    required this.size,
    required this.type,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.commissionRate,
    required this.commissionDue,
    this.billed = false,
    required this.status,
    required this.deliveryAddress,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.deliveredAt,
  });

  Map<String, dynamic> toMap() => {
        'consumer_uid': consumerUid,
        'vendor_id': vendorId,
        'product_id': productId,
        'brand': brand,
        'size': size,
        'type': type,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total': total,
        'commission_rate': commissionRate,
        'commission_due': commissionDue,
        'billed': billed,
        'status': status,
        'delivery_address': deliveryAddress,
        'latitude': latitude,
        'longitude': longitude,
        'created_at': Timestamp.fromDate(createdAt),
        'delivered_at':
            deliveredAt == null ? null : Timestamp.fromDate(deliveredAt!),
      };

  factory Order.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Order(
      id: doc.id,
      consumerUid: d['consumer_uid'] ?? '',
      vendorId: d['vendor_id'] ?? '',
      productId: d['product_id'] ?? '',
      brand: d['brand'] ?? '',
      size: d['size'] ?? '',
      type: d['type'] ?? 'refill',
      quantity: d['quantity'] ?? 1,
      unitPrice: (d['unit_price'] ?? 0).toDouble(),
      total: (d['total'] ?? 0).toDouble(),
      commissionRate: (d['commission_rate'] ?? 0).toDouble(),
      commissionDue: (d['commission_due'] ?? 0).toDouble(),
      billed: d['billed'] ?? false,
      status: d['status'] ?? 'placed',
      deliveryAddress: d['delivery_address'] ?? '',
      latitude: (d['latitude'])?.toDouble(),
      longitude: (d['longitude'])?.toDouble(),
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deliveredAt: (d['delivered_at'] as Timestamp?)?.toDate(),
    );
  }
}
