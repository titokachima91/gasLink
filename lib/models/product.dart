// lib/models/product.dart
// ROLE: One inventory row per (vendor, brand, size) — the vendor's
// price/stock offering. Lives in top-level `products` collection with
// vendor_id (kept flat for easy admin queries). The vendor edit UI must
// UPSERT (never create duplicates for the same brand+size combo).
// Price is 100% vendor input, TZS, delivery included (pilot decision).
// Size validity is enforced by the UI reading AppConstants.brandSizes,
// NOT by this model.
import 'package:cloud_firestore/cloud_firestore.dart';

// Model class representing a product
class Product {
  final String id;
  final String vendorId;
  final String
      brand; // For accessories/services, this stores the item group (e.g., 'Vifaa')
  final String
      size; // For accessories/services, this stores the item name (e.g., 'Mrija')
  final double
      price; // 🟢 DYNAMIC PRICE: Always pulled directly from Firestore live rows
  final bool inStock; // vendor toggles; out-of-stock hidden/disabled

  // 🟢 DYNAMIC CATEGORY STRING: 'refill' | 'full_set' | 'accessories' | 'services'
  final String category;

  Product({
    required this.id,
    required this.vendorId,
    required this.brand,
    required this.size,
    required this.price,
    this.inStock = true,
    this.category =
        'refill', // Safely defaults to preserve existing database assets
  });

  Map<String, dynamic> toMap() => {
        'vendor_id': vendorId,
        'brand': brand,
        'size': size,
        'price': price,
        'in_stock': inStock,
        'category': category,
      };
  // FIXED FACTORY CONSTRUCTOR: Aligns perfectly with your true class name 'Product'
  factory Product.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      vendorId: d['vendor_id'] ?? '',
      brand: d['brand'] ?? '',
      size: d['size'] ?? '',
      price: (d['price'] ?? 0).toDouble(),
      inStock: d['in_stock'] ?? true,
      category: d['category'] ?? 'refill',
    );
  }
}
