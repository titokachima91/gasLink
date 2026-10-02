import 'package:cloud_firestore/cloud_firestore.dart';

class Vendor {
  final String id;
  final String ownerUid; // matches users/<uid> with role 'vendor'
  final String shopName;
  final String phone;
  final String district; // Ilala, Kinondoni, Temeke, Ubungo, Kigamboni
  final double latitude;
  final double longitude;
  final double commissionRate; // 0.03 default; admin can set 0.02–0.05
  final bool isActive; // enforcement ladder can pause a vendor
  final String? imageUrl;
  final double rating; // future use, default 0
  final DateTime createdAt;

  Vendor({
    required this.id,
    required this.ownerUid,
    required this.shopName,
    required this.phone,
    required this.district,
    required this.latitude,
    required this.longitude,
    this.commissionRate = 0.03,
    this.isActive = true,
    this.imageUrl,
    this.rating = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'owner_uid': ownerUid,
        'shop_name': shopName,
        'phone': phone,
        'district': district,
        'latitude': latitude,
        'longitude': longitude,
        'commission_rate': commissionRate,
        'is_active': isActive,
        'image_url': imageUrl,
        'rating': rating,
        'created_at': Timestamp.fromDate(createdAt),
      };

  factory Vendor.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Vendor(
      id: doc.id,
      ownerUid: d['owner_uid'] ?? '',
      shopName: d['shop_name'] ?? '',
      phone: d['phone'] ?? '',
      district: d['district'] ?? '',
      latitude: (d['latitude'] ?? 0).toDouble(),
      longitude: (d['longitude'] ?? 0).toDouble(),
      commissionRate: (d['commission_rate'] ?? 0.03).toDouble(),
      isActive: d['is_active'] ?? true,
      imageUrl: d['image_url'],
      rating: (d['rating'] ?? 0).toDouble(),
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
