/// ============================================================================
/// FILE: lib/models/vendor.dart
/// ROLE: Single Source of Truth for Vendor Data Structures & Serialization
/// ============================================================================
library;

import 'package:cloud_firestore/cloud_firestore.dart';

class Vendor {
  final String id; // = Auth UID (doc ID), set by admin during onboarding
  final String ownerUid;
  final String businessName;
  final String phone;
  final String secondaryPhone;
  final String email;

  // --- Location & Delivery ---
  final String region;
  final String district;
  final String ward;
  final String street;
  final String areaText;
  final double? latitude;
  final double? longitude;
  final double deliveryRadiusKm;
  final String deliveryFeeModel; // 'Free', 'Flat Rate', 'Per Km'

  // --- Operations & Payments ---
  final String openingHours;
  final bool acceptsCash;
  final bool acceptsMobileMoney;
  final String? lipaNumber;
  final String? imageUrl; // Shop Front / Banner photo

  // --- General App Attributes ---
  final List<String> stockedBrandNames;
  final double commissionRate;
  final bool active;
  final double rating;
  final DateTime createdAt;

  // --- TIER 1: MANDATORY REQUIREMENTS ---
  final bool hasOperationalScale;
  final List<String> offeredServices; // Must select >= 2 services

  // --- TIER 2: VERIFICATION & COMPLIANCE (IMAGE PROOFS ONLY) ---
  final String? businessLicenseUrl; // Picha ya Leseni ya Biashara
  final String? wmaStickerUrl; // Picha ya Vibandiko/Sticker ya WMA
  final String? superDealerProofUrl; // Picha ya Risiti/Invoisi ya Super-Dealer
  final bool agreedToConsumerProtection; // Mandatory weighing upon request

  // --- TIER 3: TRACK RECORD & PERFORMANCE ---
  final int completedOrders;
  final double avgDeliveryTimeMinutes;
  final int currentTier; // 1, 2, or 3

  Vendor({
    required this.id,
    this.ownerUid = '',
    required this.businessName,
    this.phone = '',
    this.secondaryPhone = '',
    this.email = '',
    this.region = 'Dar es Salaam',
    this.district = '',
    this.ward = '',
    this.street = '',
    this.areaText = '',
    this.latitude,
    this.longitude,
    this.deliveryRadiusKm = 5.0,
    this.deliveryFeeModel = 'Flat Rate',
    this.openingHours = '07:00 AM - 09:00 PM',
    this.acceptsCash = true,
    this.acceptsMobileMoney = false,
    this.lipaNumber,
    this.imageUrl,
    this.stockedBrandNames = const [],
    this.commissionRate = 0.03,
    this.active = true,
    this.rating = 0,
    required this.createdAt,
    this.hasOperationalScale = false,
    this.offeredServices = const [],
    this.businessLicenseUrl,
    this.wmaStickerUrl,
    this.superDealerProofUrl,
    this.agreedToConsumerProtection = false,
    this.completedOrders = 0,
    this.avgDeliveryTimeMinutes = 0.0,
    this.currentTier = 1,
  });

  String get displayName => businessName.isEmpty ? 'Vendor' : businessName;

  /// Dynamic completion percentage logic
  int get completionPercentage {
    int score = 0;
    // Section A: Core Business & Email (25%)
    if (businessName.isNotEmpty && phone.isNotEmpty && email.isNotEmpty) {
      score += 25;
    }
    // Section B: Location & Delivery (25%)
    if (district.isNotEmpty &&
        (ward.isNotEmpty || areaText.isNotEmpty) &&
        latitude != null) {
      score += 25;
    }
    // Section C: Operations & Payments (25%)
    if (openingHours.isNotEmpty &&
        (acceptsCash ||
            (acceptsMobileMoney && (lipaNumber?.isNotEmpty ?? false)))) {
      score += 25;
    }
    // Section D: Compliance & Tier Requirements (25%)
    if (hasOperationalScale && offeredServices.length >= 2) score += 25;
    return score;
  }

  /// Dynamic Tier Evaluation Logic
  int get calculatedTier {
    // Tier 1 Base Qualifications
    bool tier1Pass = businessName.isNotEmpty &&
        phone.isNotEmpty &&
        hasOperationalScale &&
        offeredServices.length >= 2;
    if (!tier1Pass) return 0; // Draft / Unverified

    // Tier 2 Verification & Compliance Qualifications (Image Checks)
    bool tier2Pass = tier1Pass &&
        (wmaStickerUrl?.trim().isNotEmpty ?? false) &&
        ((businessLicenseUrl?.trim().isNotEmpty ?? false) ||
            (superDealerProofUrl?.trim().isNotEmpty ?? false));
    if (!tier2Pass) return 1;

    // Tier 3 Performance & Complete Profile Qualifications
    bool tier3Pass = tier2Pass &&
        (imageUrl?.trim().isNotEmpty ?? false) &&
        agreedToConsumerProtection &&
        completedOrders >= 10;
    return tier3Pass ? 3 : 2;
  }

  Map<String, dynamic> toMap() => {
        'ownerUid': ownerUid,
        'businessName': businessName,
        'phone': phone,
        'secondaryPhone': secondaryPhone,
        'email': email,
        'region': region,
        'district': district,
        'ward': ward,
        'street': street,
        'areaText': areaText,
        'latitude': latitude,
        'longitude': longitude,
        'deliveryRadiusKm': deliveryRadiusKm,
        'deliveryFeeModel': deliveryFeeModel,
        'openingHours': openingHours,
        'acceptsCash': acceptsCash,
        'acceptsMobileMoney': acceptsMobileMoney,
        'lipaNumber': lipaNumber,
        'imageUrl': imageUrl,
        'stockedBrandNames': stockedBrandNames,
        'commissionRate': commissionRate,
        'active': active,
        'rating': rating,
        'createdAt': Timestamp.fromDate(createdAt),
        // Tier 1
        'hasOperationalScale': hasOperationalScale,
        'offeredServices': offeredServices,
        // Tier 2
        'businessLicenseUrl': businessLicenseUrl,
        'wmaStickerUrl': wmaStickerUrl,
        'superDealerProofUrl': superDealerProofUrl,
        'agreedToConsumerProtection': agreedToConsumerProtection,
        // Tier 3
        'completedOrders': completedOrders,
        'avgDeliveryTimeMinutes': avgDeliveryTimeMinutes,
        'currentTier': currentTier,
      };

  factory Vendor.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return Vendor(
      id: doc.id,
      ownerUid: d['ownerUid'] as String? ?? '',
      businessName: d['businessName'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      secondaryPhone: d['secondaryPhone'] as String? ?? '',
      email: d['email'] as String? ?? '',
      region: d['region'] as String? ?? 'Dar es Salaam',
      district: d['district'] as String? ?? '',
      ward: d['ward'] as String? ?? '',
      street: d['street'] as String? ?? '',
      areaText: d['areaText'] as String? ?? '',
      latitude: (d['latitude'] as num?)?.toDouble(),
      longitude: (d['longitude'] as num?)?.toDouble(),
      deliveryRadiusKm: (d['deliveryRadiusKm'] as num? ?? 5.0).toDouble(),
      deliveryFeeModel: d['deliveryFeeModel'] as String? ?? 'Flat Rate',
      openingHours: d['openingHours'] as String? ?? '07:00 AM - 09:00 PM',
      acceptsCash: d['acceptsCash'] as bool? ?? true,
      acceptsMobileMoney: d['acceptsMobileMoney'] as bool? ?? false,
      lipaNumber: d['lipaNumber'] as String?,
      imageUrl: d['imageUrl'] as String?,
      stockedBrandNames: (d['stockedBrandNames'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      commissionRate: (d['commissionRate'] as num? ?? 0.03).toDouble(),
      active: d['active'] as bool? ?? true,
      rating: (d['rating'] as num? ?? 0).toDouble(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      // Tier 1
      hasOperationalScale: d['hasOperationalScale'] as bool? ?? false,
      offeredServices: (d['offeredServices'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      // Tier 2
      businessLicenseUrl: d['businessLicenseUrl'] as String?,
      wmaStickerUrl: d['wmaStickerUrl'] as String?,
      superDealerProofUrl: d['superDealerProofUrl'] as String?,
      agreedToConsumerProtection:
          d['agreedToConsumerProtection'] as bool? ?? false,
      // Tier 3
      completedOrders: (d['completedOrders'] as num? ?? 0).toInt(),
      avgDeliveryTimeMinutes:
          (d['avgDeliveryTimeMinutes'] as num? ?? 0.0).toDouble(),
      currentTier: (d['currentTier'] as num? ?? 1).toInt(),
    );
  }
}

class SizeEntry {
  SizeEntry({required this.sizeKg, this.price, this.inStock = true});
  final num sizeKg;
  final num? price;
  final bool inStock;

  factory SizeEntry.fromMap(Map<String, dynamic> data) {
    return SizeEntry(
      sizeKg: (data['sizeKg'] as num?) ?? 0,
      price: data['price'] as num?,
      inStock: (data['inStock'] as bool?) ?? true,
    );
  }
}

class InventoryDoc {
  InventoryDoc({required this.brandName, required this.sizes});
  final String brandName;
  final List<SizeEntry> sizes;

  factory InventoryDoc.fromFirestore(Map<String, dynamic> data) {
    return InventoryDoc(
      brandName: (data['brandName'] as String?) ?? '',
      sizes: (data['sizes'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(SizeEntry.fromMap)
          .toList()
        ..sort((a, b) => a.sizeKg.compareTo(b.sizeKg)),
    );
  }
  bool get hasSizes => sizes.isNotEmpty;
}
