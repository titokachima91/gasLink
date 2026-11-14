// ============================================================================
// FILE PATH: lib/services/order_service.dart
// ROLE: The only writer of order status in the GasLink app.
//
// Every transition goes through OrderLifecycle, is validated, is written with
// an audit trail, and queues its notifications in `notification_outbox`.
// The gateway drains that outbox with retry, so a closed app or a temporary
// network failure can no longer lose a vendor or customer notification.
// ============================================================================
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:gaslink_app/core/constants.dart';
import 'package:gaslink_app/l10n/localized_messages.dart';
import 'package:gaslink_app/models/order.dart' as models;
import 'order_lifecycle.dart';

class OrderTransitionResult {
  const OrderTransitionResult({
    required this.success,
    required this.status,
    this.message = '',
    this.orderId = '',
  });

  final bool success;
  final String status;
  final String message;
  final String orderId;

  static OrderTransitionResult ok({
    required String orderId,
    required String status,
    String message = '',
  }) {
    return OrderTransitionResult(
      success: true,
      status: status,
      message: message,
      orderId: orderId,
    );
  }

  static OrderTransitionResult fail({
    required String orderId,
    required String status,
    required String message,
  }) {
    return OrderTransitionResult(
      success: false,
      status: status,
      message: message,
      orderId: orderId,
    );
  }
}

class _OutboxEntry {
  const _OutboxEntry(this.id, this.payload);

  final String id;
  final Map<String, dynamic> payload;
}

class OrderService {
  OrderService._();
  static final OrderService instance = OrderService._();

  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');
  CollectionReference<Map<String, dynamic>> get _outbox =>
      _db.collection('notification_outbox');

  /// Customer places an order. The order document and the vendor notification
  /// are committed in one batch, so the vendor alert cannot be lost if the
  /// buyer's app is closed immediately after checkout.
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
    final isSubscription = commissionModel == 'subscription';
    final effectiveRate = isSubscription ? 0.0 : vendorCommissionRate;

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
      status: OrderLifecycle.placed,
      deliveryAddress: deliveryAddress,
      contactPhone: contactPhone,
      receiverPhone: receiverPhone,
      specialRequests: specialRequests,
      paymentMethod: paymentMethod,
      latitude: latitude,
      longitude: longitude,
      createdAt: DateTime.now(),
    );

    final orderMap = newOrder.toMap();
    orderMap['consumer_uid'] = consumerUid;
    orderMap['consumerUid'] = consumerUid;
    orderMap['vendor_id'] = vendorId;
    orderMap['vendorId'] = vendorId;
    orderMap['vendor_name'] = vendorName;
    orderMap['vendorName'] = vendorName;
    orderMap['total_price'] = total;
    orderMap['totalPrice'] = total;
    orderMap['total'] = total;
    orderMap['order_intent'] = orderIntent;
    orderMap['orderIntent'] = orderIntent;
    orderMap['vendorViewed'] = false;
    orderMap['vendor_viewed'] = false;
    orderMap['status'] = OrderLifecycle.placed;
    orderMap['updated_at'] = FieldValue.serverTimestamp();
    orderMap['status_history'] = [
      {
        'from': '',
        'to': OrderLifecycle.placed,
        'actor': OrderLifecycle.actorConsumer,
        'at': Timestamp.now(),
        'note': 'order_created',
      }
    ];

    final l10n = await loadLocalizedMessages();
    final orderRef = _orders.doc();
    final vendorOutbox = _outboxPayload(
      userId: vendorId,
      title: l10n.newOrderNotificationTitle,
      body: l10n.newOrderNotificationBody(brand, size),
      smsMessage: l10n.smsOrderPlacedVendor(brand, size),
      data: {
        'orderId': orderRef.id,
        'type': 'new_order',
        'status': OrderLifecycle.placed,
      },
    );

    final batch = _db.batch();
    batch.set(orderRef, orderMap);
    batch.set(
      _outbox.doc(_outboxId(orderRef.id, 'placed', vendorId)),
      vendorOutbox,
    );
    await batch.commit();

    return orderRef;
  }

  /// Legacy direct-creation path (only used when the tracking screen is opened
  /// without an order id). Kept so old navigation cannot silently drop the
  /// vendor alert.
  Future<void> notifyVendorNewOrder({
    required String orderId,
    required String vendorId,
    required String brand,
    required String size,
  }) async {
    final l10n = await loadLocalizedMessages();
    await _outbox
        .doc(_outboxId(orderId, 'placed', vendorId))
        .set(
          _outboxPayload(
            userId: vendorId,
            title: l10n.newOrderNotificationTitle,
            body: l10n.newOrderNotificationBody(brand, size),
            smsMessage: l10n.smsOrderPlacedVendor(brand, size),
            data: {
              'orderId': orderId,
              'type': 'new_order',
              'status': OrderLifecycle.placed,
            },
          ),
          SetOptions(merge: false),
        );
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

  /// The vendor opened this specific order. This is the first buyer-visible
  /// step: "opened, waiting for confirmation".
  Future<bool> markOrderAsSeen(String orderId) async {
    try {
      final doc = await _orders.doc(orderId).get();
      if (!doc.exists) return false;
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final status = OrderLifecycle.canonical(data['status']?.toString());

      if (status == OrderLifecycle.placed) {
        final result = await _transition(
          orderId: orderId,
          toStatus: OrderLifecycle.seen,
          actor: OrderLifecycle.actorVendor,
          note: 'vendor_opened_order',
        );
        return result.success;
      }

      if (status == OrderLifecycle.seen ||
          status == OrderLifecycle.confirmed ||
          status == OrderLifecycle.onTheWay) {
        await _orders.doc(orderId).set({
          'vendorViewed': true,
          'vendor_viewed': true,
          'vendor_seen_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error marking order as seen: $e');
      return false;
    }
  }

  /// Vendor confirms the order. No ETA here: ETA belongs to start-journey.
  ///
  /// A vendor may tap Accept straight from the dashboard without opening the
  /// detail screen first, so the state machine is nudged through `seen` when
  /// needed. Both writes are transactional and idempotent.
  Future<OrderTransitionResult> confirmOrder(String orderId) async {
    await markOrderAsSeen(orderId);
    return _transition(
      orderId: orderId,
      toStatus: OrderLifecycle.confirmed,
      actor: OrderLifecycle.actorVendor,
      note: 'vendor_confirmed',
    );
  }

  /// Vendor starts the journey. ETA is required; rider phone is optional.
  Future<OrderTransitionResult> startJourney({
    required String orderId,
    required int etaMinutes,
    String driverPhone = '',
  }) {
    if (etaMinutes <= 0 || etaMinutes > 240) {
      return Future.value(OrderTransitionResult.fail(
        orderId: orderId,
        status: OrderLifecycle.confirmed,
        message: 'ETA must be between 1 and 240 minutes.',
      ));
    }
    return _transition(
      orderId: orderId,
      toStatus: OrderLifecycle.onTheWay,
      actor: OrderLifecycle.actorVendor,
      etaMinutes: etaMinutes,
      driverPhone: driverPhone.trim(),
      note: 'vendor_started_journey',
    );
  }

  /// Vendor says the cylinder has arrived. The buyer now has ten minutes to
  /// confirm receipt (or the server finalizer closes the order).
  Future<OrderTransitionResult> markArrived(String orderId) {
    return _transition(
      orderId: orderId,
      toStatus: OrderLifecycle.deliveredPending,
      actor: OrderLifecycle.actorVendor,
      note: 'vendor_marked_arrived',
    );
  }

  /// Vendor undo for a mis-tapped "arrived". Goes back to on_the_way.
  Future<OrderTransitionResult> undoArrived(String orderId) {
    return _transition(
      orderId: orderId,
      toStatus: OrderLifecycle.onTheWay,
      actor: OrderLifecycle.actorVendor,
      note: 'vendor_undo_arrived',
    );
  }

  /// Buyer confirms receipt. Allowed from on_the_way (buyer got the gas before
  /// the vendor tapped arrived) or delivered_pending.
  Future<OrderTransitionResult> confirmReceipt(String orderId) async {
    final result = await _transition(
      orderId: orderId,
      toStatus: OrderLifecycle.delivered,
      actor: OrderLifecycle.actorConsumer,
      note: 'consumer_confirmed_receipt',
    );
    if (result.success) {
      await _ensureCylinderRegistered(orderId);
    }
    return result;
  }

  /// Buyer denies receipt. This stops the ten-minute finalizer and opens a
  /// GasLink mediation record.
  Future<OrderTransitionResult> denyReceipt(
    String orderId, {
    String reason = 'consumer_did_not_receive',
  }) {
    return _transition(
      orderId: orderId,
      toStatus: OrderLifecycle.disputed,
      actor: OrderLifecycle.actorConsumer,
      reason: reason,
      note: 'consumer_denied_receipt',
    );
  }

  Future<OrderTransitionResult> cancelOrder({
    required String orderId,
    required String actor,
    String reason = 'cancelled',
  }) {
    return _transition(
      orderId: orderId,
      toStatus: OrderLifecycle.cancelled,
      actor: actor,
      reason: reason,
      note: 'order_cancelled',
    );
  }

  Future<OrderTransitionResult> rejectOrder(String orderId) {
    return cancelOrder(
      orderId: orderId,
      actor: OrderLifecycle.actorVendor,
      reason: 'vendor_rejected',
    );
  }

  /// Legacy API used by the admin console and older screens. It still goes
  /// through the same state machine and audit trail.
  Future<void> updateStatus(String orderId, String status) async {
    final target = OrderLifecycle.canonical(status);
    final result = await _transition(
      orderId: orderId,
      toStatus: target,
      actor: OrderLifecycle.actorSystem,
      note: 'legacy_status_update',
    );
    if (!result.success) {
      debugPrint('Order status update skipped: ${result.message}');
    }
  }

  /// Safety net used by legacy callers. The real registration happens in
  /// [registerCylinderForOrder] with a transaction and an idempotent unit id.
  Future<void> handleOrderCompletion(String orderId) async {
    await _ensureCylinderRegistered(orderId);
  }

  Future<bool> _ensureCylinderRegistered(String orderId) async {
    try {
      final orderDoc = await _orders.doc(orderId).get();
      if (!orderDoc.exists) return false;
      final data = orderDoc.data() as Map<String, dynamic>? ?? {};
      if (data['cylinder_registered'] == true) return true;

      final type = (data['type'] ?? data['category'] ?? 'refill').toString();
      if (!OrderLifecycle.isCylinderOrder(type)) return true;

      final consumerUid =
          (data['consumer_uid'] ?? data['consumerUid'] ?? '').toString().trim();
      final brandName =
          (data['brand'] ?? data['brand_name'] ?? '').toString().trim();
      final cylinderWeight =
          (data['weight'] ?? data['size'] ?? '').toString().trim();
      if (consumerUid.isEmpty || brandName.isEmpty || cylinderWeight.isEmpty) {
        return false;
      }

      final registered = await registerCylinderForOrder(
        orderId: orderId,
        consumerUid: consumerUid,
        brandName: brandName,
        cylinderWeight: cylinderWeight,
      );
      if (!registered) {
        await _orders.doc(orderId).set({
          'cylinder_registration_error': 'registration_failed',
        }, SetOptions(merge: true));
      }
      return registered;
    } catch (e) {
      debugPrint('Cylinder registration safety net failed: $e');
      return false;
    }
  }

  /// Idempotent kitchen-ledger registration.
  ///
  /// Firestore does not allow FieldValue.serverTimestamp() inside an array, so
  /// the unit uses a normal Timestamp. The unit carries the source order id, so
  /// a retry can never duplicate a cylinder.
  Future<bool> registerCylinderForOrder({
    required String orderId,
    required String consumerUid,
    required String brandName,
    required String cylinderWeight,
  }) async {
    final cleanOrderId = orderId.trim();
    final cleanUid = consumerUid.trim();
    if (cleanOrderId.isEmpty || cleanUid.isEmpty) return false;

    try {
      final cylindersRef =
          _db.collection('users').doc(cleanUid).collection('cylinders');

      // Match the existing brand+size document if one exists. New documents
      // use a deterministic id, so two concurrent registrations cannot create
      // two rows for the same cylinder.
      final snapshot = await cylindersRef.get();
      QueryDocumentSnapshot<Map<String, dynamic>>? existing;
      final targetBrand =
          brandName.replaceAll(RegExp(r'\s+'), '').toLowerCase();
      final targetSize =
          cylinderWeight.replaceAll(RegExp(r'\s+'), '').toLowerCase();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final brand = (data['brand'] ?? '')
            .toString()
            .replaceAll(RegExp(r'\s+'), '')
            .toLowerCase();
        final size = (data['weight'] ?? data['size'] ?? '')
            .toString()
            .replaceAll(RegExp(r'\s+'), '')
            .toLowerCase();
        if (brand == targetBrand && size == targetSize) {
          existing = doc;
          break;
        }
      }

      final cylinderRef =
          existing?.reference ?? cylindersRef.doc(_cylinderDocId(brandName, cylinderWeight));

      await _db.runTransaction((tx) async {
        final orderSnap = await tx.get(_orders.doc(cleanOrderId));
        if (!orderSnap.exists) throw StateError('order_missing');
        final order = orderSnap.data()!;
        if (order['cylinder_registered'] == true) return;
        final status = OrderLifecycle.canonical(order['status']?.toString());
        if (status != OrderLifecycle.delivered) {
          throw StateError('order_not_delivered');
        }

        final cylinderSnap = await tx.get(cylinderRef);
        final cylinder = cylinderSnap.data() ?? {};
        final units = <Map<String, dynamic>>[];
        final rawUnits = cylinder['units'];
        if (rawUnits is List) {
          for (final raw in rawUnits) {
            if (raw is Map) {
              units.add(Map<String, dynamic>.from(raw));
            }
          }
        }

        // Already registered by a previous attempt: repair the flag and stop.
        final alreadyThere = units.any((unit) =>
            (unit['source_order_id'] ?? unit['order_id'] ?? '').toString() ==
            cleanOrderId);
        if (alreadyThere) {
          tx.set(
            _orders.doc(cleanOrderId),
            {
              'cylinder_registered': true,
              'cylinder_registered_at': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
          return;
        }

        // Preserve a manually registered legacy cylinder as the first unit.
        if (units.isEmpty &&
            cylinderSnap.exists &&
            (cylinder['lastRefillDate'] != null ||
                cylinder['purchase_date'] != null)) {
          units.add({
            'id': 'legacy',
            'lastRefillDate':
                cylinder['lastRefillDate'] ?? cylinder['purchase_date'],
            'purchase_date':
                cylinder['purchase_date'] ?? cylinder['lastRefillDate'],
            'supplier_name': cylinder['supplier_name'] ?? 'Muuzaji Rasmi',
            'price': cylinder['price'] ?? 0.0,
            'remainingDays': cylinder['remainingDays'] ?? 30,
            'percentage': cylinder['percentage'] ?? 100.0,
          });
        }

        final deliveredAt =
            (order['delivered_at'] as Timestamp?)?.toDate() ?? DateTime.now();
        final supplier = (order['vendor_name'] ??
                order['vendorName'] ??
                order['shop_name'] ??
                'Muuzaji Rasmi')
            .toString();
        final price = (order['total_price'] ??
                order['totalPrice'] ??
                order['total'] ??
                0)
            .toDouble();

        units.add({
          'id': 'order_$cleanOrderId',
          'source_order_id': cleanOrderId,
          'order_id': cleanOrderId,
          'lastRefillDate': deliveredAt.toIso8601String(),
          'purchase_date': deliveredAt.toIso8601String(),
          'supplier_name': supplier,
          'price': price,
          'remainingDays': 30,
          'percentage': 100.0,
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });

        int totalDays = 0;
        double totalPercentage = 0.0;
        for (final unit in units) {
          totalDays += ((unit['remainingDays'] ?? 30) as num).toInt();
          totalPercentage +=
              ((unit['percentage'] ?? 100.0) as num).toDouble();
        }

        tx.set(
          cylinderRef,
          {
            'brand': brandName,
            'weight': cylinderWeight,
            'size': cylinderWeight,
            'status': 'active',
            'remainingDays': totalDays,
            'percentage': totalPercentage,
            'lastRefillDate': deliveredAt.toIso8601String(),
            'purchase_date': deliveredAt.toIso8601String(),
            'supplier_name': supplier,
            'price': price,
            'refillCycle': 'Every 30 days',
            'units': units,
            'updatedAt': FieldValue.serverTimestamp(),
            if (!cylinderSnap.exists) 'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        tx.set(
          _orders.doc(cleanOrderId),
          {
            'cylinder_registered': true,
            'cylinder_registered_at': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });

      return true;
    } catch (e) {
      debugPrint('Error registering cylinder for order $cleanOrderId: $e');
      return false;
    }
  }

  /// Backwards-compatible wrapper used by older code.
  Future<void> finalizeAndRegisterCylinder({
    required String consumerUid,
    required String brandName,
    required String cylinderWeight,
    required String orderIntent,
    required String orderId,
  }) async {
    await registerCylinderForOrder(
      orderId: orderId,
      consumerUid: consumerUid,
      brandName: brandName,
      cylinderWeight: cylinderWeight,
    );
  }

  // ---------------------------------------------------------------------------
  // State machine internals
  // ---------------------------------------------------------------------------

  Future<OrderTransitionResult> _transition({
    required String orderId,
    required String toStatus,
    required String actor,
    int? etaMinutes,
    String? driverPhone,
    String? reason,
    String? note,
  }) async {
    final cleanOrderId = orderId.trim();
    final target = OrderLifecycle.canonical(toStatus);
    if (cleanOrderId.isEmpty) {
      return OrderTransitionResult.fail(
        orderId: cleanOrderId,
        status: target,
        message: 'Order id is missing.',
      );
    }

    final l10n = await loadLocalizedMessages();
    final orderRef = _orders.doc(cleanOrderId);

    try {
      final result = await _db.runTransaction<OrderTransitionResult>((tx) async {
        final orderSnap = await tx.get(orderRef);
        if (!orderSnap.exists) {
          return OrderTransitionResult.fail(
            orderId: cleanOrderId,
            status: target,
            message: 'Order not found.',
          );
        }

        final data = orderSnap.data()!;
        final from = OrderLifecycle.canonical(data['status']?.toString());
        if (from == target) {
          return OrderTransitionResult.fail(
            orderId: cleanOrderId,
            status: target,
            message: 'Order is already $target.',
          );
        }
        if (!OrderLifecycle.canTransition(
          from: from,
          to: target,
          actor: actor,
        )) {
          return OrderTransitionResult.fail(
            orderId: cleanOrderId,
            status: target,
            message: 'Cannot move order from $from to $target.',
          );
        }

        final vendorId =
            (data['vendor_id'] ?? data['vendorId'] ?? '').toString();
        DocumentSnapshot<Map<String, dynamic>>? vendorSnap;
        if (target == OrderLifecycle.confirmed && vendorId.isNotEmpty) {
          vendorSnap = await tx.get(_db.collection('vendors').doc(vendorId));
        }

        final updates = <String, dynamic>{
          'status': target,
          'updated_at': FieldValue.serverTimestamp(),
          'status_history': FieldValue.arrayUnion([
            {
              'from': from,
              'to': target,
              'actor': actor,
              'at': Timestamp.now(),
              if (note != null && note.isNotEmpty) 'note': note,
              if (etaMinutes != null) 'eta_minutes': etaMinutes,
              if (reason != null && reason.isNotEmpty) 'reason': reason,
            }
          ]),
        };

        String confirmedVendorPhone = '';
        if (target == OrderLifecycle.seen) {
          updates['vendorViewed'] = true;
          updates['vendor_viewed'] = true;
          updates['vendor_seen_at'] = FieldValue.serverTimestamp();
        }

        if (target == OrderLifecycle.confirmed) {
          updates['vendor_confirmed_at'] = FieldValue.serverTimestamp();
          final vendorData = vendorSnap?.data() ?? {};
          confirmedVendorPhone =
              (vendorData['phone'] ?? vendorData['secondaryPhone'] ?? '')
                  .toString()
                  .trim();
          if (confirmedVendorPhone.isNotEmpty) {
            updates['vendor_phone'] = confirmedVendorPhone;
            updates['vendorPhone'] = confirmedVendorPhone;
          }
          final vendorName = (vendorData['businessName'] ??
                  vendorData['name'] ??
                  '')
              .toString()
              .trim();
          if (vendorName.isNotEmpty) {
            updates['vendor_name'] = vendorName;
            updates['vendorName'] = vendorName;
          }
        }

        if (target == OrderLifecycle.onTheWay) {
          final eta = etaMinutes ??
              (data['eta_minutes'] as num?)?.toInt() ??
              20;
          updates['eta_minutes'] = eta;
          updates['journey_started_at'] = FieldValue.serverTimestamp();
          final cleanDriver = (driverPhone ?? '').trim();
          if (cleanDriver.isNotEmpty) {
            updates['driver_phone'] = cleanDriver;
            updates['driverPhone'] = cleanDriver;
          }
        }

        if (target == OrderLifecycle.deliveredPending) {
          updates['delivered_pending_at'] = FieldValue.serverTimestamp();
          updates['_delivered_at_ms'] = DateTime.now().millisecondsSinceEpoch;
        }

        if (target == OrderLifecycle.delivered) {
          updates['delivered_at'] = FieldValue.serverTimestamp();
          updates['finalized_at'] = FieldValue.serverTimestamp();
          updates['finalized_by'] = actor;
          if (data['cylinder_registered'] != true) {
            updates['cylinder_registered'] = false;
          }
        }

        if (target == OrderLifecycle.disputed) {
          updates['disputed_at'] = FieldValue.serverTimestamp();
          updates['fraud_alert_flag'] = true;
          updates['dispute_reason'] =
              (reason == null || reason.isEmpty) ? 'consumer_did_not_receive' : reason;
        }

        if (target == OrderLifecycle.cancelled) {
          updates['cancelled_at'] = FieldValue.serverTimestamp();
          updates['cancelled_by'] = actor;
          updates['cancellation_reason'] =
              (reason == null || reason.isEmpty) ? actor : reason;
        }

        final outboxEntries = _buildOutboxEntries(
          orderId: cleanOrderId,
          to: target,
          actor: actor,
          data: data,
          l10n: l10n,
          etaMinutes: etaMinutes ??
              (data['eta_minutes'] as num?)?.toInt() ??
              20,
          driverPhone: driverPhone ?? '',
          vendorPhone: confirmedVendorPhone,
          reason: reason ?? '',
        );

        // All reads must happen before any writes in a Firestore transaction.
        final outboxSnaps = <DocumentSnapshot<Map<String, dynamic>>>[];
        for (final entry in outboxEntries) {
          outboxSnaps.add(await tx.get(_outbox.doc(entry.id)));
        }

        tx.update(orderRef, updates);

        for (var i = 0; i < outboxEntries.length; i++) {
          if (!outboxSnaps[i].exists) {
            tx.set(
              _outbox.doc(outboxEntries[i].id),
              outboxEntries[i].payload,
            );
          }
        }

        if (target == OrderLifecycle.disputed) {
          tx.set(
            _db.collection('disputes').doc(cleanOrderId),
            {
              'orderId': cleanOrderId,
              'consumerUid':
                  (data['consumer_uid'] ?? data['consumerUid'] ?? '').toString(),
              'vendorId': vendorId,
              'reason': (reason == null || reason.isEmpty)
                  ? 'consumer_did_not_receive'
                  : reason,
              'status': 'open',
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }

        return OrderTransitionResult.ok(
          orderId: cleanOrderId,
          status: target,
          message: 'Order moved to $target.',
        );
      });

      if (result.success && target == OrderLifecycle.delivered) {
        await _ensureCylinderRegistered(cleanOrderId);
      }
      return result;
    } catch (e) {
      debugPrint('Order transition failed ($target): $e');
      return OrderTransitionResult.fail(
        orderId: cleanOrderId,
        status: target,
        message: 'Order update failed. Please retry.',
      );
    }
  }

  List<_OutboxEntry> _buildOutboxEntries({
    required String orderId,
    required String to,
    required String actor,
    required Map<String, dynamic> data,
    required AppLocalizations l10n,
    required int etaMinutes,
    required String driverPhone,
    required String vendorPhone,
    required String reason,
  }) {
    final entries = <_OutboxEntry>[];
    final consumerUid =
        (data['consumer_uid'] ?? data['consumerUid'] ?? '').toString().trim();
    final vendorId =
        (data['vendor_id'] ?? data['vendorId'] ?? '').toString().trim();
    final brand =
        (data['brand'] ?? data['brand_name'] ?? 'Gesi').toString().trim();
    final code = OrderLifecycle.orderCode(orderId);

    void add({
      required String event,
      required String userId,
      String phone = '',
      required String title,
      required String body,
      String smsMessage = '',
      Map<String, dynamic> extra = const {},
    }) {
      if (userId.isEmpty && phone.isEmpty) return;
      final recipient = userId.isNotEmpty ? userId : phone;
      entries.add(_OutboxEntry(
        _outboxId(orderId, event, recipient),
        _outboxPayload(
          userId: userId,
          phone: phone,
          title: title,
          body: body,
          smsMessage: smsMessage,
          data: {
            'orderId': orderId,
            'type': 'order_status',
            'status': to,
            ...extra,
          },
        ),
      ));
    }

    if (to == OrderLifecycle.seen && consumerUid.isNotEmpty) {
      add(
        event: 'seen',
        userId: consumerUid,
        title: l10n.orderSeenNotificationTitle,
        body: l10n.orderSeenNotificationBody(brand),
        smsMessage: l10n.smsOrderSeen(brand),
      );
    }

    if (to == OrderLifecycle.confirmed && consumerUid.isNotEmpty) {
      final vendorLine = vendorPhone.isEmpty
          ? ''
          : ' ${l10n.vendorPhoneLabel}: $vendorPhone';
      final smsVendorLine = vendorPhone.isEmpty
          ? ''
          : ' ${l10n.vendorPhoneLabel}: $vendorPhone';
      add(
        event: 'confirmed',
        userId: consumerUid,
        title: l10n.orderStepConfirmed,
        body: '${l10n.orderStepConfirmedBody}$vendorLine',
        smsMessage: '${l10n.smsOrderConfirmed(brand)}$smsVendorLine',
      );
    }

    if (to == OrderLifecycle.onTheWay && consumerUid.isNotEmpty) {
      final driverLine = driverPhone.isEmpty
          ? ''
          : ' ${l10n.driverPhoneLabel}: $driverPhone';
      add(
        event: 'on_the_way',
        userId: consumerUid,
        title: l10n.orderStepDispatched,
        body:
            '${l10n.orderStepDispatchedBody} ${l10n.etaShort}: $etaMinutes min.$driverLine',
        smsMessage:
            '${l10n.smsOrderOnTheWay(brand)} ${l10n.etaShort}: $etaMinutes min.$driverLine',
        extra: {
          'etaMinutes': etaMinutes,
          if (driverPhone.isNotEmpty) 'driverPhone': driverPhone,
        },
      );
    }

    if (to == OrderLifecycle.deliveredPending && consumerUid.isNotEmpty) {
      add(
        event: 'arrived',
        userId: consumerUid,
        title: l10n.orderArrivedNotificationTitle,
        body: l10n.orderArrivedNotificationBody(brand),
        smsMessage: l10n.smsOrderArrived(brand),
        extra: {'minutesToConfirm': 10},
      );
    }

    if (to == OrderLifecycle.delivered) {
      if (consumerUid.isNotEmpty) {
        add(
          event: 'delivered_consumer',
          userId: consumerUid,
          title: l10n.orderStepDelivered,
          body: l10n.orderStepDeliveredBody,
          smsMessage: l10n.smsOrderDelivered(brand),
        );
      }
      if (vendorId.isNotEmpty) {
        add(
          event: 'delivered_vendor',
          userId: vendorId,
          title: l10n.orderDeliveredVendorTitle,
          body: l10n.orderDeliveredVendorBody(code),
          smsMessage: l10n.smsOrderDeliveredVendor(code),
        );
      }
    }

    if (to == OrderLifecycle.disputed) {
      if (vendorId.isNotEmpty) {
        add(
          event: 'disputed_vendor',
          userId: vendorId,
          title: l10n.orderDisputedVendorTitle,
          body: l10n.orderDisputedVendorBody(code),
          smsMessage: l10n.smsOrderDisputedVendor(code),
        );
      }
      add(
        event: 'disputed_support',
        userId: '',
        phone: AppConstants.supportPhone,
        title: l10n.orderDisputedVendorTitle,
        body: l10n.orderDisputedVendorBody(code),
        smsMessage: l10n.smsOrderDisputedSupport(code),
      );
      if (consumerUid.isNotEmpty) {
        add(
          event: 'disputed_consumer',
          userId: consumerUid,
          title: l10n.orderDisputedConsumerTitle,
          body: l10n.orderDisputedConsumerBody,
          smsMessage: l10n.smsOrderDisputedConsumer(code),
        );
      }
    }

    if (to == OrderLifecycle.cancelled) {
      if (actor == OrderLifecycle.actorConsumer) {
        if (vendorId.isNotEmpty) {
          add(
            event: 'cancelled_vendor',
            userId: vendorId,
            title: l10n.orderCancelledVendorTitle,
            body: l10n.orderCancelledVendorBody(code),
            smsMessage: l10n.smsOrderCancelledVendor(code),
          );
        }
      } else if (consumerUid.isNotEmpty) {
        add(
          event: 'cancelled_consumer',
          userId: consumerUid,
          title: l10n.orderCancelledTitle,
          body: l10n.orderCancelledBody,
          smsMessage: l10n.smsOrderCancelled(brand),
          extra: {'reason': reason},
        );
      }
    }

    return entries;
  }

  Map<String, dynamic> _outboxPayload({
    required String userId,
    String phone = '',
    required String title,
    required String body,
    String smsMessage = '',
    required Map<String, dynamic> data,
  }) {
    return {
      'userId': userId,
      'phone': phone,
      'title': title,
      'body': body,
      'smsMessage': smsMessage,
      'data': data,
      'status': 'pending',
      'attempts': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'nextAttemptAt': FieldValue.serverTimestamp(),
    };
  }

  String _outboxId(String orderId, String event, String recipient) {
    final raw = '${orderId}_${event}_$recipient';
    return raw.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
  }

  String _cylinderDocId(String brand, String size) {
    final raw = 'cyl_${brand}_$size'
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return raw.length <= 120 ? raw : raw.substring(0, 120);
  }
}
