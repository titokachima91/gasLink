/// ============================================================================
/// FILE: lib/services/vendor_repository.dart
/// ROLE: Data Access Layer for Firestore Vendor Operations
/// ----------------------------------------------------------------------------
/// PURPOSE:
/// - Encapsulates all CRUD operations for the 'vendors' Firestore collection.
/// - Provides real-time streams for Vendor profiles and Inventory sub-collections.
/// - Manages online status toggles, profile updates, and stock adjustments.
/// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vendor.dart';

class VendorRepository {
  final FirebaseFirestore _firestore;

  VendorRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference helper
  CollectionReference<Map<String, dynamic>> get _vendorsRef =>
      _firestore.collection('vendors');

  /// Stream a single vendor's live document updates
  Stream<Vendor?> streamVendor(String vendorId) {
    return _vendorsRef.doc(vendorId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Vendor.fromDoc(doc);
    });
  }

  /// Get a single vendor snapshot once
  Future<Vendor?> getVendor(String vendorId) async {
    final doc = await _vendorsRef.doc(vendorId).get();
    if (!doc.exists) return null;
    return Vendor.fromDoc(doc);
  }

  /// Create or update vendor profile data
  Future<void> saveVendorProfile(Vendor vendor) async {
    await _vendorsRef.doc(vendor.id).set(
          vendor.toMap(),
          SetOptions(merge: true),
        );
  }

  /// Toggle online/offline store availability status
  Future<void> toggleStoreStatus(String vendorId, bool isOpen) async {
    await _vendorsRef.doc(vendorId).update({
      'active': isOpen,
    });
  }

  /// Stream brand inventory items from vendor's 'products' sub-collection
  /// (matches InventoryScreen which reads /vendors/{uid}/products)
  Stream<List<InventoryDoc>> streamVendorInventory(String vendorId) {
    return _vendorsRef
        .doc(vendorId)
        .collection('products')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => InventoryDoc.fromFirestore(doc.data()))
          .toList();
    });
  }
}
