import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import 'order.dart';
import 'vendor.dart';

/// Append-only record of an admin mutation.
class AdminAuditLog {
  const AdminAuditLog({
    required this.id,
    required this.actorUid,
    required this.actorRole,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.before = const {},
    this.after = const {},
    this.reason = '',
    required this.createdAt,
  });

  final String id;
  final String actorUid;
  final String actorRole;
  final String action;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> before;
  final Map<String, dynamic> after;
  final String reason;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'actorUid': actorUid,
        'actorRole': actorRole,
        'action': action,
        'entityType': entityType,
        'entityId': entityId,
        'before': before,
        'after': after,
        'reason': reason,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory AdminAuditLog.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    final created = d['createdAt'];
    return AdminAuditLog(
      id: doc.id,
      actorUid: d['actorUid'] as String? ?? '',
      actorRole: d['actorRole'] as String? ?? '',
      action: d['action'] as String? ?? '',
      entityType: d['entityType'] as String? ?? '',
      entityId: d['entityId'] as String? ?? '',
      before: Map<String, dynamic>.from(d['before'] as Map? ?? {}),
      after: Map<String, dynamic>.from(d['after'] as Map? ?? {}),
      reason: d['reason'] as String? ?? '',
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
    );
  }
}

/// Minimal consumer projection for admin lookup. No PIN material is loaded.
class AdminConsumer {
  const AdminConsumer({
    required this.uid,
    required this.phone,
    required this.name,
    required this.role,
    this.createdAt,
  });

  final String uid;
  final String phone;
  final String name;
  final String role;
  final DateTime? createdAt;

  String get displayName => name.trim().isEmpty ? phone : name.trim();

  factory AdminConsumer.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    final created = d['createdAt'];
    return AdminConsumer(
      uid: doc.id,
      phone: d['phone'] as String? ?? '',
      name: (d['name'] ?? d['fullName'] ?? d['displayName'] ?? '').toString(),
      role: d['role'] as String? ?? 'consumer',
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }
}

/// Flat product document used by the consumer catalogue and admin inventory.
class AdminProduct {
  const AdminProduct({
    required this.id,
    required this.vendorId,
    required this.brand,
    required this.size,
    required this.price,
    required this.inStock,
    this.category = 'refill',
    this.updatedAt,
  });

  final String id;
  final String vendorId;
  final String brand;
  final String size;
  final double price;
  final bool inStock;
  final String category;
  final DateTime? updatedAt;

  factory AdminProduct.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    final updated = d['updated_at'] ?? d['updatedAt'];
    final rawStock = d['in_stock'] ?? d['inStock'] ?? true;
    return AdminProduct(
      id: doc.id,
      vendorId: (d['vendor_id'] ?? d['vendorId'] ?? '').toString(),
      brand: (d['brand'] ?? d['brand_name'] ?? d['brandName'] ?? '').toString(),
      size: (d['size'] ?? d['weight'] ?? d['sizeKg'] ?? '').toString(),
      price: (d['price'] as num? ?? 0).toDouble(),
      inStock: rawStock is bool ? rawStock : true,
      category: d['category'] as String? ?? 'refill',
      updatedAt: _readDate(updated),
    );
  }
}

/// Cylinder held by a consumer, shown in admin lookup.
class AdminCylinder {
  const AdminCylinder({
    required this.id,
    required this.brand,
    required this.weight,
    required this.percentage,
    required this.remainingDays,
    this.supplierName = '',
    this.lastRefillDate,
  });

  final String id;
  final String brand;
  final String weight;
  final double percentage;
  final int remainingDays;
  final String supplierName;
  final DateTime? lastRefillDate;

  factory AdminCylinder.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    final rawDate = d['lastRefillDate'] ?? d['purchase_date'];
    return AdminCylinder(
      id: doc.id,
      brand: d['brand'] as String? ?? 'Cylinder',
      weight: (d['weight'] ?? d['size'] ?? '').toString(),
      percentage: (d['percentage'] as num? ?? 0).toDouble(),
      remainingDays: (d['remainingDays'] as num? ?? 0).toInt(),
      supplierName: d['supplier_name'] as String? ?? '',
      lastRefillDate: _readDate(rawDate),
    );
  }
}

class AdminSettings {
  const AdminSettings({
    this.commissionRate = 0.03,
    this.supportPhone = '+255767304776',
    this.supportEmail = '',
    this.updatedAt,
    this.updatedBy = '',
  });

  final double commissionRate;
  final String supportPhone;
  final String supportEmail;
  final DateTime? updatedAt;
  final String updatedBy;

  Map<String, dynamic> toMap() => {
        'commissionRate': commissionRate,
        'supportPhone': supportPhone,
        'supportEmail': supportEmail,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': updatedBy,
      };

  factory AdminSettings.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    final updated = d['updatedAt'];
    return AdminSettings(
      commissionRate: (d['commissionRate'] as num? ?? 0.03).toDouble(),
      supportPhone: d['supportPhone'] as String? ?? '+255767304776',
      supportEmail: d['supportEmail'] as String? ?? '',
      updatedAt: updated is Timestamp ? updated.toDate() : null,
      updatedBy: d['updatedBy'] as String? ?? '',
    );
  }
}

/// Snapshot used by the operations dashboard.
class AdminDashboardData {
  const AdminDashboardData({
    required this.totalVendors,
    required this.activeVendors,
    required this.pendingVendors,
    required this.suspendedVendors,
    required this.consumerCount,
    required this.ordersToday,
    required this.deliveredToday,
    required this.cancelledToday,
    required this.gmvToday,
    required this.outOfStockProducts,
    required this.totalProducts,
    required this.pendingApprovals,
    required this.recentOrders,
    required this.outOfStockList,
  });

  final int totalVendors;
  final int activeVendors;
  final int pendingVendors;
  final int suspendedVendors;
  final int consumerCount;
  final int ordersToday;
  final int deliveredToday;
  final int cancelledToday;
  final double gmvToday;
  final int outOfStockProducts;
  final int totalProducts;
  final List<Vendor> pendingApprovals;
  final List<Order> recentOrders;
  final List<AdminProduct> outOfStockList;
}

DateTime? _readDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}
