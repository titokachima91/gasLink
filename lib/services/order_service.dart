import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gaslink_app/core/constants.dart';
import 'package:gaslink_app/models/order.dart' as models;

class OrderService {
  OrderService._();
  static final OrderService instance = OrderService._();
  final _db = FirebaseFirestore.instance;

  CollectionReference get _orders => _db.collection('orders');

  /// Consumer places an order. Commission stamped here, once.
  Future<void> placeOrder({
    required String consumerUid,
    required String vendorId,
    required String productId,
    required String brand,
    required String size,
    required String type,
    required int quantity,
    required double unitPrice,
    required double vendorCommissionRate,
    required String deliveryAddress,
    double? latitude,
    double? longitude,
  }) async {
    final total = unitPrice * quantity;
    await _orders.add(models.Order(
      // was: Order(
      id: '', // set by Firestore
      consumerUid: consumerUid,
      vendorId: vendorId,
      productId: productId,
      brand: brand,
      size: size,
      type: type,
      quantity: quantity,
      unitPrice: unitPrice,
      total: total,
      commissionRate: vendorCommissionRate,
      commissionDue: total * vendorCommissionRate,
      status: AppConstants.statusPlaced,
      deliveryAddress: deliveryAddress,
      latitude: latitude,
      longitude: longitude,
      createdAt: DateTime.now(),
    ).toMap());
  }

  /// Live tracking: stream of one consumer's orders, newest first.
  Stream<QuerySnapshot> consumerOrders(String uid) => _orders
      .where('consumer_uid', isEqualTo: uid)
      .orderBy('created_at', descending: true)
      .snapshots();

  /// Vendor dashboard: incoming + active orders.
  Stream<QuerySnapshot> vendorOrders(String vendorId) => _orders
      .where('vendor_id', isEqualTo: vendorId)
      .orderBy('created_at', descending: true)
      .snapshots();

  /// Vendor advances status: placed → confirmed → on_the_way → delivered.
  Future<void> updateStatus(String orderId, String status) async {
    final update = <String, dynamic>{'status': status};
    if (status == AppConstants.statusDelivered) {
      update['delivered_at'] = Timestamp.fromDate(DateTime.now());
    }
    await _orders.doc(orderId).update(update);
  }
}
