// ============================================================================
// FILE PATH: lib/services/order_service.dart
// ROLE OF THIS FILE:
// This is the core order management service for GasLink. It is responsible for:
// 1. Saving new customer orders into the Firebase database.
// 2. Updating order statuses (e.g., Confirmed, In Transit, Delivered).
// 3. Sending instant push notification alerts to customers and vendors whenever
//    an order is placed or updated.
// ============================================================================
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:gaslink_app/core/constants.dart';
import 'package:gaslink_app/models/order.dart' as models;
import 'notification_service.dart';

class OrderService {
  OrderService._();
  static final OrderService instance = OrderService._();

  final _db = FirebaseFirestore.instance;
  CollectionReference get _orders => _db.collection('orders');

  /// Customer places an order. Stamped with standardized keys.
  Future<DocumentReference> placeOrder({
    required String consumerUid,
    required String vendorId,
    required String vendorName,
    required String productId,
    required String brand,
    required String size,
    required String type,
    String orderIntent = 'new_asset',
    required int quantity,
    required double unitPrice,
    required double vendorCommissionRate,
    String commissionModel = 'percentage',
    required String deliveryAddress,
    String contactPhone = '',
    String receiverPhone = '',
    String specialRequests = '',
    String paymentMethod = 'cash',
    double? latitude,
    double? longitude,
  }) async {
    final total = unitPrice * quantity;

    // Subscription vendors pay a monthly fee instead of a per-order cut.
    final isSubscription = commissionModel == 'subscription';
    final effectiveRate = isSubscription ? 0.0 : vendorCommissionRate;

    // Create the standardized Order model object
    final newOrder = models.Order(
      id: '',
      consumerUid: consumerUid,
      vendorId: vendorId,
      productId: productId,
      brand: brand,
      size: size,
      type: type,
      orderIntent: orderIntent,
      quantity: quantity,
      unitPrice: unitPrice,
      total: total,
      commissionRate: effectiveRate,
      commissionDue: total * effectiveRate,
      commissionModel: isSubscription ? 'subscription' : 'percentage',
      status: AppConstants.statusPlaced,
      deliveryAddress: deliveryAddress,
      contactPhone: contactPhone,
      receiverPhone: receiverPhone,
      specialRequests: specialRequests,
      paymentMethod: paymentMethod,
      latitude: latitude,
      longitude: longitude,
      createdAt: DateTime.now(),
    );

    // CONVERT TO MAP AND INJECT DUAL-FIELD FALLBACKS TO ENSURE CONSISTENCY
    final orderMap = newOrder.toMap();
    orderMap['consumer_uid'] = consumerUid;
    orderMap['consumerUid'] = consumerUid;
    orderMap['vendor_id'] = vendorId;
    orderMap['vendorId'] = vendorId;
    orderMap['total_price'] = total;
    orderMap['totalPrice'] = total;
    orderMap['total'] = total;
    orderMap['order_intent'] = orderIntent;
    orderMap['orderIntent'] = orderIntent;
    orderMap['vendorViewed'] = false;
    orderMap['vendor_viewed'] = false;

    // Save order document flat in Firestore with complete consistency
    final docRef = await _orders.add(orderMap);

    // Send instant push notification to the vendor
    try {
      await NotificationService.instance.sendNotificationToUser(
        userId: vendorId,
        title: 'Oda Mpya! / New Order!',
        body: 'Umepokea oda mpya ya $brand ($size).',
        data: {
          'orderId': docRef.id,
          'type': 'new_order',
        },
      );
    } catch (e) {
      debugPrint(
          'FCM direct vendor notification warning during placeOrder: $e');
    }

    return docRef;
  }

  /// Live tracking stream for a customer's active and historical orders.
  Stream<QuerySnapshot> consumerOrders(String uid) {
    return _orders
        .where(Filter.or(
          Filter('consumer_uid', isEqualTo: uid),
          Filter('consumerUid', isEqualTo: uid),
        ))
        .snapshots();
  }

  /// Live tracking stream for a vendor's incoming and active orders.
  Stream<QuerySnapshot> vendorOrders(String vendorId) => _orders
      .where(Filter.or(
        Filter('vendor_id', isEqualTo: vendorId),
        Filter('vendorId', isEqualTo: vendorId),
      ))
      .orderBy('created_at', descending: true)
      .snapshots();

  /// Marks an order as viewed by the vendor so the consumer knows
  /// they are being attended to and the vendor is online.
  Future<void> markOrderAsSeen(String orderId) async {
    try {
      final doc = await _orders.doc(orderId).get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>?;
      final currentStatus = data?['status'] ?? AppConstants.statusPlaced;

      final updateData = <String, dynamic>{
        'vendorViewed': true,
        'vendor_viewed': true,
      };

      // Transition from pending/placed to 'seen' if not already progressed
      if (currentStatus == AppConstants.statusPlaced ||
          currentStatus == 'pending') {
        updateData['status'] = 'seen';
      }

      await _orders.doc(orderId).update(updateData);
    } catch (e) {
      debugPrint('Error marking order as seen: $e');
    }
  }

  /// Automatically finalize and register cylinder if order is marked delivered/completed
  /// 🛡️ DATABASE SAFETY GUARD: Automatically registers cylinder inventory
  /// and full purchase metadata the moment an order hits delivered/completed.
  /// Automatically finalize and register cylinder if order is marked delivered/completed
  Future<void> handleOrderCompletion(String orderId) async {
    if (orderId.trim().isEmpty) {
      debugPrint('❌ ABORTED: handleOrderCompletion received an empty orderId');
      return;
    }

    try {
      final orderDoc = await _orders.doc(orderId).get();
      if (!orderDoc.exists) return;

      final data = orderDoc.data() as Map<String, dynamic>? ?? {};
      final String status =
          (data['status'] ?? '').toString().toLowerCase().trim();
      final bool alreadyRegistered = data['cylinder_registered'] == true;

      if ((status == 'delivered' || status == 'completed') &&
          !alreadyRegistered) {
        final consumerUid =
            (data['consumer_uid'] ?? data['consumerUid'] ?? '').toString();
        final brandName =
            (data['brand'] ?? data['brand_name'] ?? '').toString();
        final cylinderWeight =
            (data['weight'] ?? data['size'] ?? '').toString();
        final orderIntent =
            (data['order_intent'] ?? data['orderIntent'] ?? 'new_asset')
                .toString();

        if (consumerUid.isNotEmpty && brandName.isNotEmpty) {
          // Single clean call
          await finalizeAndRegisterCylinder(
            consumerUid: consumerUid,
            brandName: brandName,
            cylinderWeight: cylinderWeight,
            orderIntent: orderIntent,
            orderId: orderId,
          );

          // Mark so it never runs again
          await _orders.doc(orderId).update({'cylinder_registered': true});
        }
      }
    } catch (e) {
      debugPrint(
          'Error handling automatic order completion cylinder registration: $e');
    }
  }

  /// Vendor or system advances order status:
  /// placed -> confirmed -> on_the_way -> delivered
  Future<void> updateStatus(String orderId, String status) async {
    final String cleanOrderId = orderId.trim();
    if (cleanOrderId.isEmpty) {
      debugPrint('❌ ABORTED: updateStatus received an empty orderId');
      return;
    }

    final update = <String, dynamic>{'status': status};
    if (status == AppConstants.statusDelivered ||
        status == 'delivered' ||
        status == 'completed') {
      update['delivered_at'] = Timestamp.fromDate(DateTime.now());
      update['finalized_at'] = FieldValue.serverTimestamp();
    }

    // Perform database write
    await _orders.doc(cleanOrderId).update(update);

    // 🛡️ DATABASE SAFETY GUARD: Automatically register cylinder if delivered/completed
    if (status == AppConstants.statusDelivered ||
        status == 'delivered' ||
        status == 'completed') {
      await handleOrderCompletion(cleanOrderId);
    }

    // Send push notification update to customer
    try {
      final doc = await _orders.doc(cleanOrderId).get();
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        final consumerUid =
            (data['consumer_uid'] ?? data['consumerUid']) as String?;
        final brandName = data['brand'] ?? data['brand_name'] ?? 'Gesi';

        if (consumerUid != null && consumerUid.trim().isNotEmpty) {
          String notificationTitle = 'Mabadiliko ya Oda / Order Update';
          String notificationBody = 'Oda yako imebadilishwa hali.';

          if (status == 'confirmed' || status == 'accepted') {
            notificationTitle = 'Oda Imethibitishwa! / Order Confirmed!';
            notificationBody = 'Muuzaji amethibitisha oda yako ya $brandName.';
          } else if (status == 'on_the_way' ||
              status == 'dispatched' ||
              status == 'in_transit') {
            notificationTitle = 'Ipo Njiani! / On The Way!';
            notificationBody = 'Gesi yako ya $brandName ipo njiani kuja kwako.';
          } else if (status == 'delivered' || status == 'completed') {
            notificationTitle = 'Imewasili! / Delivered!';
            notificationBody =
                'Oda yako ya $brandName imekamilika kikamilifu. Asante!';
          } else if (status == 'cancelled' || status == 'rejected') {
            notificationTitle = 'Oda Imesitishwa / Order Cancelled';
            notificationBody =
                'Oda yako ya $brandName imesitishwa. Wasiliana na msaada kama una swali.';
          }

          await NotificationService.instance.sendNotificationToUser(
            userId: consumerUid.trim(),
            title: notificationTitle,
            body: notificationBody,
            data: {
              'orderId': cleanOrderId,
              'status': status,
              'type': 'order_status_update',
            },
          );
        }
      }
    } catch (e) {
      debugPrint('FCM consumer status update notification warning: $e');
    }
  }

  /// Automatically provisions or updates the consumer's kitchen cylinder ledger upon successful delivery
  Future<void> finalizeAndRegisterCylinder({
    required String consumerUid,
    required String brandName,
    required String cylinderWeight,
    required String orderIntent,
    required String orderId,
  }) async {
    final String cleanConsumerUid = consumerUid.trim();
    final String cleanOrderId = orderId.trim();

    if (cleanConsumerUid.isEmpty) {
      debugPrint(
          '❌ ABORTED: Cannot register cylinder because consumerUid is empty');
      return;
    }

    try {
      final cylindersRef =
          _db.collection('users').doc(cleanConsumerUid).collection('cylinders');

      // Get supplier, price and date from the order
      String supplierName = 'Muuzaji Rasmi';
      double cylinderPrice = 0.0;
      String purchaseDateStr = DateTime.now().toIso8601String();

      if (cleanOrderId.isNotEmpty) {
        final orderDoc = await _db.collection('orders').doc(cleanOrderId).get();
        if (orderDoc.exists) {
          final orderData = orderDoc.data() ?? {};
          supplierName = orderData['vendor_name'] ??
              orderData['shop_name'] ??
              orderData['vendorName'] ??
              'Muuzaji Rasmi';
          cylinderPrice = (orderData['total_price'] ??
                  orderData['totalPrice'] ??
                  orderData['price'] ??
                  0.0)
              .toDouble();
          final Timestamp? t = orderData['delivered_at'] as Timestamp? ??
              orderData['createdAt'] as Timestamp? ??
              orderData['created_at'] as Timestamp?;
          if (t != null) {
            purchaseDateStr = t.toDate().toIso8601String();
          }
        }
      }

      // Clean brand and weight for matching
      final targetBrandClean =
          brandName.replaceAll(RegExp(r'\s+'), '').toLowerCase();
      final targetSizeClean =
          cylinderWeight.replaceAll(RegExp(r'\s+'), '').toLowerCase();

      final snapshot = await cylindersRef.get();
      QueryDocumentSnapshot<Map<String, dynamic>>? matchingDoc;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final brandClean = (data['brand'] ?? '')
            .toString()
            .replaceAll(RegExp(r'\s+'), '')
            .toLowerCase();
        final sizeClean = (data['weight'] ?? data['size'] ?? '')
            .toString()
            .replaceAll(RegExp(r'\s+'), '')
            .toLowerCase();

        if (brandClean == targetBrandClean && sizeClean == targetSizeClean) {
          matchingDoc = doc;
          break;
        }
      }

      // Create the new unit
      final newUnit = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'lastRefillDate': purchaseDateStr,
        'purchase_date': purchaseDateStr,
        'supplier_name': supplierName,
        'price': cylinderPrice,
        'remainingDays': 30,
        'percentage': 100.0,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (matchingDoc != null) {
        // Same brand + weight already exists → add new unit to the stack
        final data = matchingDoc.data();
        final List<dynamic> existingUnits =
            List<dynamic>.from(data['units'] ?? []);

        // If the document is old style (no units array yet), create the first unit from current data
        if (existingUnits.isEmpty) {
          existingUnits.add({
            'id': 'legacy',
            'lastRefillDate': data['lastRefillDate'] ?? purchaseDateStr,
            'purchase_date': data['purchase_date'] ?? purchaseDateStr,
            'supplier_name': data['supplier_name'] ?? 'Muuzaji Rasmi',
            'price': data['price'] ?? 0.0,
            'remainingDays': data['remainingDays'] ?? 30,
            'percentage': data['percentage'] ?? 100.0,
          });
        }

        existingUnits.add(newUnit);

        // Collective totals
        int totalDays = 0;
        double totalPercentage = 0.0;
        for (var u in existingUnits) {
          totalDays += ((u['remainingDays'] ?? 30) as num).toInt();
          totalPercentage += ((u['percentage'] ?? 100.0) as num).toDouble();
        }

        await matchingDoc.reference.update({
          'units': existingUnits,
          'remainingDays': totalDays,
          'percentage': totalPercentage,
          'lastRefillDate': purchaseDateStr,
          'supplier_name': supplierName,
          'price': cylinderPrice,
          'status': 'active',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Brand new size → create document with first unit
        await cylindersRef.add({
          'brand': brandName,
          'weight': cylinderWeight,
          'size': cylinderWeight,
          'status': 'active',
          'remainingDays': 30,
          'percentage': 100.0,
          'lastRefillDate': purchaseDateStr,
          'purchase_date': purchaseDateStr,
          'supplier_name': supplierName,
          'price': cylinderPrice,
          'refillCycle': 'Every 30 days',
          'units': [newUnit],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error finalizing and registering cylinder: $e');
    }
  }
}
