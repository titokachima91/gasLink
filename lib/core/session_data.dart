/// ============================================================================
/// FILE: lib/core/session_data.dart
///
/// SUMMARY:
/// This file serves as the in-memory state engine and cache layer for consumer
/// browsing sessions. It executes a single bulk fetch against Firestore
/// (`products` where in_stock == true and all `vendors`) and maps the data into
/// strongly typed, immutable view models (`VendorOffer`). This architecture
/// minimizes redundant database reads while supplying immediate catalog data to
/// discovery screens.
///
/// KEY COMPONENTS & RESPONSIBILITIES:
/// - WeightOffer: Value object for LPG weight variants (e.g., 6kg, 13kg) and price.
/// - Vendor: Clean domain model holding vendor profile info and GPS coordinates.
/// - BrandsSummary: Computed state indicating available brands, lowest price point, and stock completeness.
/// - VendorOffer: Aggregate object coupling a vendor profile with their active weight inventory.
/// - SessionData (Singleton):
///   * `ensureLoaded()`: Idempotent session initializer preventing duplicate queries.
///   * `reload()`: Forces a live re-fetch from Firestore for pull-to-refresh interactions.
///   * `haversineKm()`: Standalone mathematical helper for calculating distance between coordinates.
/// ============================================================================

library core.session_data;

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class WeightOffer {
  final String brand;
  final String weight;
  final num price;
  final String category; // refill | full_set | accessories | services

  const WeightOffer({
    required this.brand,
    required this.weight,
    required this.price,
    this.category = 'refill',
  });
}

class Vendor {
  final String id;
  final String businessName;
  final String phone;
  final String area;
  final double? latitude;
  final double? longitude;
  final bool verified;

  const Vendor({
    required this.id,
    required this.businessName,
    required this.phone,
    required this.area,
    this.latitude,
    this.longitude,
    this.verified = false,
  });
}

class BrandsSummary {
  final int inStockBrands;
  final num minPrice;
  final bool fullyStocked;

  const BrandsSummary({
    required this.inStockBrands,
    required this.minPrice,
    required this.fullyStocked,
  });
}

class VendorOffer {
  final Vendor vendor;
  final double? distanceKm; // null when GPS is disabled or unavailable
  final List<WeightOffer> weights;
  final List<String> vendorBrands;

  const VendorOffer({
    required this.vendor,
    this.distanceKm,
    required this.weights,
    required this.vendorBrands,
  });

  BrandsSummary get summary {
    final brands = weights.map((w) => w.brand).toSet();
    final minPrice = weights.isEmpty
        ? 0
        : weights.map((w) => w.price).reduce((a, b) => a < b ? a : b);
    final fully = vendorBrands.isNotEmpty && brands.containsAll(vendorBrands);
    return BrandsSummary(
      inStockBrands: brands.length,
      minPrice: minPrice,
      fullyStocked: fully,
    );
  }
}

class SessionData {
  SessionData._();
  static final SessionData instance = SessionData._();

  List<VendorOffer> offers = [];
  bool loaded = false;

  /// One-time session load. Idempotent: safe to call repeatedly across screens.
  Future<void> ensureLoaded() async {
    if (loaded) return;
    await reload();
  }

  /// Forces a complete re-fetch from Firestore (used for pull-to-refresh).
  /// Forces a complete re-fetch from Firestore (used for pull-to-refresh).
  Future<void> reload() async {
    final db = FirebaseFirestore.instance;

    // Fetch vendors and check both root /products and subcollection /products
    final vendorSnap = await db.collection('vendors').get();

    QuerySnapshot productSnap;
    try {
      final topLevel = await db.collection('products').get();
      productSnap = topLevel.docs.isNotEmpty
          ? topLevel
          : await db.collectionGroup('products').get();
    } catch (_) {
      productSnap = await db.collectionGroup('products').get();
    }

    final vendors = <String, Vendor>{};
    final vendorBrandsMap = <String, List<String>>{};

    for (final d in vendorSnap.docs) {
      final m = d.data() as Map<String, dynamic>;

      // Combine district and area into single search string (e.g., "Ubungo, Sinza, Mori")
      final district = (m['district'] ?? '').toString().trim();
      final area = (m['area'] ?? m['areaText'] ?? m['area_text'] ?? '')
          .toString()
          .trim();
      final combinedArea =
          [district, area].where((s) => s.isNotEmpty).toSet().join(', ');

      vendors[d.id] = Vendor(
        id: d.id,
        businessName: (m['businessName'] ?? m['business_name'] ?? 'LPG Vendor')
            .toString(),
        phone: (m['phone'] ?? '').toString(),
        area: combinedArea.isNotEmpty ? combinedArea : district,
        latitude: (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
        verified: m['verified'] as bool? ?? false,
      );
      vendorBrandsMap[d.id] =
          List<String>.from(m['brands'] ?? m['stockedBrandNames'] ?? []);
    }

    final weightsByVendor = <String, List<WeightOffer>>{};

    for (final d in productSnap.docs) {
      final m = d.data() as Map<String, dynamic>;

      final vid = (m['vendor_id'] ??
              m['vendorId'] ??
              d.reference.parent.parent?.id ??
              '')
          .toString();

      final inStock = (m['in_stock'] ?? m['inStock'] ?? true) as bool;
      if (!inStock || vid.isEmpty) continue;

      final weightValue =
          (m['weight'] ?? m['size'] ?? m['sizeKg'] ?? '').toString();

      final rawCategory = (m['category'] ?? 'refill').toString().toLowerCase();

      (weightsByVendor[vid] ??= []).add(WeightOffer(
        brand: (m['brand'] ?? m['brandName'] ?? '').toString(),
        weight: weightValue.contains('kg') ? weightValue : '${weightValue}kg',
        price: (m['price'] as num?) ?? 0,
        category: rawCategory,
      ));
    }

    // Map over ALL registered vendors so vendor profile renders even prior to adding stock
    offers = vendors.values
        .map((v) => VendorOffer(
              vendor: v,
              distanceKm: null,
              weights: weightsByVendor[v.id] ?? [],
              vendorBrands: vendorBrandsMap[v.id] ?? [],
            ))
        .toList();

    loaded = true;
  }

  /// Haversine formula calculation for distance between two geographic points.
  static double haversineKm(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _rad(double d) => d * pi / 180;
}
