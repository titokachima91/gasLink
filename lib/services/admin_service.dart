import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/foundation.dart';

import '../models/admin_models.dart';
import '../models/order.dart';
import '../models/vendor.dart';
import 'analytics_service.dart';
import 'auth_service.dart';
import 'order_service.dart';

/// Single data-access boundary for the admin console.
///
/// Widgets never write admin mutations directly. Every lifecycle, order or
/// settings change is written together with an append-only audit record.
class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _vendors =>
      _db.collection('vendors');
  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection('products');
  CollectionReference<Map<String, dynamic>> get _audit =>
      _db.collection('admin_audit_logs');

  String get _actorUid => AuthService.instance.currentUserId ?? 'admin_local';

  // ---------------------------------------------------------------------------
  // Vendors
  // ---------------------------------------------------------------------------

  Stream<List<Vendor>> streamVendors() {
    return _vendors.snapshots().map((snapshot) {
      final list = snapshot.docs.map(Vendor.fromDoc).toList();
      list.sort((a, b) {
        final rank = _vendorRank(a).compareTo(_vendorRank(b));
        if (rank != 0) return rank;
        return a.displayName.compareTo(b.displayName);
      });
      return list;
    });
  }

  static int _vendorRank(Vendor vendor) {
    if (vendor.isPending) return 0;
    if (vendor.isActive) return 1;
    if (vendor.isSuspended) return 2;
    return 3;
  }

  Stream<Vendor?> streamVendor(String vendorId) {
    return _vendors.doc(vendorId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Vendor.fromDoc(doc);
    });
  }

  Future<Vendor?> getVendor(String vendorId) async {
    final doc = await _vendors.doc(vendorId).get();
    if (!doc.exists) return null;
    return Vendor.fromDoc(doc);
  }

  Future<Map<String, Vendor>> loadVendorMap() async {
    final snapshot = await _vendors.get();
    return {for (final doc in snapshot.docs) doc.id: Vendor.fromDoc(doc)};
  }

  Future<void> updateVendorStatus({
    required String vendorId,
    required String status,
    String reason = '',
  }) async {
    if (!VendorStatus.values.contains(status)) {
      throw ArgumentError.value(status, 'status', 'Unknown vendor status');
    }

    final ref = _vendors.doc(vendorId);
    final doc = await ref.get();
    if (!doc.exists) throw StateError('Vendor not found');

    final data = doc.data() ?? {};
    final previousStatus = VendorStatus.normalize(
      data['status'] as String?,
      legacyActive: data['active'] as bool?,
    );
    final action = switch (status) {
      VendorStatus.active when previousStatus == VendorStatus.pending =>
        'approve_vendor',
      VendorStatus.active => 'reactivate_vendor',
      VendorStatus.suspended => 'suspend_vendor',
      VendorStatus.rejected => 'reject_vendor',
      _ => 'update_vendor',
    };

    final batch = _db.batch();
    batch.update(ref, {
      'status': status,
      'statusReason': reason.trim(),
      'active': status == VendorStatus.active,
      'kycReviewedAt': FieldValue.serverTimestamp(),
      'kycReviewedBy': _actorUid,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final audit = AdminAuditLog(
      id: '',
      actorUid: _actorUid,
      actorRole: AuthService.roleAdmin,
      action: action,
      entityType: 'vendor',
      entityId: vendorId,
      before: {
        'status': previousStatus,
        'active': data['active'] as bool? ?? true,
        'statusReason': data['statusReason'] as String? ?? '',
      },
      after: {'status': status, 'active': status == VendorStatus.active},
      reason: reason.trim(),
      createdAt: DateTime.now(),
    );
    batch.set(_audit.doc(), audit.toMap());
    await batch.commit();
  }

  // ---------------------------------------------------------------------------
  // Orders
  // ---------------------------------------------------------------------------

  Stream<List<Order>> streamOrders({int limit = 300}) {
    return _orders
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map(Order.fromDoc).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<Order>> streamVendorOrders(String vendorId, {int limit = 50}) {
    return _orders
        .where(Filter.or(
          Filter('vendor_id', isEqualTo: vendorId),
          Filter('vendorId', isEqualTo: vendorId),
        ))
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map(Order.fromDoc).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<Order>> streamConsumerOrders(String uid, {int limit = 100}) {
    return _orders
        .where(Filter.or(
          Filter('consumer_uid', isEqualTo: uid),
          Filter('consumerUid', isEqualTo: uid),
        ))
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map(Order.fromDoc).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<Order?> streamOrder(String orderId) {
    return _orders.doc(orderId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Order.fromDoc(doc);
    });
  }

  Future<void> cancelOrder({
    required String orderId,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      throw ArgumentError('A cancellation reason is required');
    }

    final ref = _orders.doc(orderId);
    final doc = await ref.get();
    if (!doc.exists) throw StateError('Order not found');

    final data = doc.data() ?? {};
    final currentStatus = (data['status'] ?? 'placed').toString();
    if (currentStatus == 'delivered' || currentStatus == 'completed') {
      throw StateError('Delivered orders cannot be cancelled');
    }

    final batch = _db.batch();
    batch.update(ref, {
      'status': 'cancelled',
      'cancellation_reason': reason.trim(),
      'cancelled_at': FieldValue.serverTimestamp(),
      'cancelled_by': _actorUid,
      'updated_at': FieldValue.serverTimestamp(),
    });

    final audit = AdminAuditLog(
      id: '',
      actorUid: _actorUid,
      actorRole: AuthService.roleAdmin,
      action: 'cancel_order',
      entityType: 'order',
      entityId: orderId,
      before: {'status': currentStatus},
      after: {'status': 'cancelled'},
      reason: reason.trim(),
      createdAt: DateTime.now(),
    );
    batch.set(_audit.doc(), audit.toMap());
    await batch.commit();

    try {
      await OrderService.instance.updateStatus(orderId, 'cancelled');
    } catch (error) {
      debugPrint('Order cancellation notification warning: $error');
    }
  }

  // ---------------------------------------------------------------------------
  // Consumers
  // ---------------------------------------------------------------------------

  Stream<List<AdminConsumer>> streamConsumers() {
    return _users.where('role', isEqualTo: 'consumer').snapshots().map(
      (snapshot) {
        final list = snapshot.docs.map(AdminConsumer.fromDoc).toList()
          ..sort((a, b) => a.displayName.compareTo(b.displayName));
        return list;
      },
    );
  }

  Stream<AdminConsumer?> streamConsumer(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AdminConsumer.fromDoc(doc);
    });
  }

  Stream<List<AdminCylinder>> streamConsumerCylinders(String uid) {
    return _users.doc(uid).collection('cylinders').snapshots().map((snapshot) {
      final list = snapshot.docs.map(AdminCylinder.fromDoc).toList()
        ..sort((a, b) => a.brand.compareTo(b.brand));
      return list;
    });
  }

  // ---------------------------------------------------------------------------
  // Inventory
  // ---------------------------------------------------------------------------

  Stream<List<AdminProduct>> streamProducts() {
    return _products.snapshots().map((snapshot) {
      final list = snapshot.docs.map(AdminProduct.fromDoc).toList()
        ..sort((a, b) {
          final brand = a.brand.compareTo(b.brand);
          return brand != 0 ? brand : a.size.compareTo(b.size);
        });
      return list;
    });
  }

  Stream<List<AdminProduct>> streamVendorProducts(String vendorId) {
    return _products
        .where(Filter.or(
          Filter('vendor_id', isEqualTo: vendorId),
          Filter('vendorId', isEqualTo: vendorId),
        ))
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map(AdminProduct.fromDoc).toList()
        ..sort((a, b) => a.brand.compareTo(b.brand));
      return list;
    });
  }

  // ---------------------------------------------------------------------------
  // Settings & audit
  // ---------------------------------------------------------------------------

  Stream<AdminSettings> streamSettings() {
    return _db
        .collection('app_settings')
        .doc('admin')
        .snapshots()
        .map((doc) => AdminSettings.fromDoc(doc));
  }

  Future<void> updateSettings({
    required double commissionRate,
    required String supportPhone,
    required String supportEmail,
  }) async {
    if (commissionRate < 0 || commissionRate > 1) {
      throw ArgumentError('Commission must be between 0% and 100%');
    }

    final ref = _db.collection('app_settings').doc('admin');
    final doc = await ref.get();
    final before = doc.data() ?? {};
    final batch = _db.batch();
    batch.set(
        ref,
        {
          'commissionRate': commissionRate,
          'supportPhone': supportPhone.trim(),
          'supportEmail': supportEmail.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': _actorUid,
        },
        SetOptions(merge: true));

    final audit = AdminAuditLog(
      id: '',
      actorUid: _actorUid,
      actorRole: AuthService.roleAdmin,
      action: 'update_settings',
      entityType: 'settings',
      entityId: 'admin',
      before: {
        'commissionRate': before['commissionRate'],
        'supportPhone': before['supportPhone'],
        'supportEmail': before['supportEmail'],
      },
      after: {
        'commissionRate': commissionRate,
        'supportPhone': supportPhone.trim(),
        'supportEmail': supportEmail.trim(),
      },
      reason: 'Admin settings update',
      createdAt: DateTime.now(),
    );
    batch.set(_audit.doc(), audit.toMap());
    await batch.commit();
  }

  Stream<List<AdminAuditLog>> streamAuditLogs({int limit = 100}) {
    return _audit
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(AdminAuditLog.fromDoc).toList());
  }

  // ---------------------------------------------------------------------------
  // Dashboard
  // ---------------------------------------------------------------------------

  Future<AdminDashboardData> loadDashboard() async {
    final vendorSnap = await _vendors.get();
    final orderSnap =
        await _orders.orderBy('created_at', descending: true).limit(300).get();
    final productSnap = await _products.limit(1000).get();
    final consumerCount =
        (await _users.where('role', isEqualTo: 'consumer').count().get())
                .count ??
            0;

    final vendors = vendorSnap.docs.map(Vendor.fromDoc).toList();
    final orders = orderSnap.docs.map(Order.fromDoc).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final products = productSnap.docs.map(AdminProduct.fromDoc).toList();

    final now = DateTime.now();
    final eat = AnalyticsService.eatDate(now);
    final todayStart =
        AnalyticsService.utcStart(DateTime.utc(eat.year, eat.month, eat.day));
    final todayOrders = orders
        .where((order) => !order.createdAt.toUtc().isBefore(todayStart))
        .toList();

    final pending = vendors.where((vendor) => vendor.isPending).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final outOfStock = products.where((product) => !product.inStock).toList();

    return AdminDashboardData(
      totalVendors: vendors.length,
      activeVendors: vendors.where((vendor) => vendor.isActive).length,
      pendingVendors: pending.length,
      suspendedVendors: vendors.where((vendor) => vendor.isSuspended).length,
      consumerCount: consumerCount,
      ordersToday: todayOrders.length,
      deliveredToday: todayOrders
          .where((order) =>
              AnalyticsService.normalizeStatus(order.status) == 'delivered')
          .length,
      cancelledToday: todayOrders
          .where((order) =>
              AnalyticsService.normalizeStatus(order.status) == 'cancelled')
          .length,
      gmvToday: todayOrders
          .where((order) =>
              AnalyticsService.normalizeStatus(order.status) == 'delivered')
          .fold<double>(0, (running, order) => running + order.total),
      outOfStockProducts: outOfStock.length,
      totalProducts: products.length,
      pendingApprovals: pending.take(5).toList(),
      recentOrders: orders.take(8).toList(),
      outOfStockList: outOfStock.take(5).toList(),
    );
  }
}
