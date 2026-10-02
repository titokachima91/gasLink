import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String vendorId;
  final String brand; // must match AppConstants.gasBrands
  final String size; // must match AppConstants.cylinderSizes
  final double price; // TZS
  final bool inStock; // vendor toggles; out-of-stock hidden/disabled
  final String type; // 'refill' | 'exchange' (AppConstants)

  Product({
    required this.id,
    required this.vendorId,
    required this.brand,
    required this.size,
    required this.price,
    this.inStock = true,
    this.type = 'refill',
  });

  Map<String, dynamic> toMap() => {
        'vendor_id': vendorId,
        'brand': brand,
        'size': size,
        'price': price,
        'in_stock': inStock,
        'type': type,
      };

  factory Product.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      vendorId: d['vendor_id'] ?? '',
      brand: d['brand'] ?? '',
      size: d['size'] ?? '',
      price: (d['price'] ?? 0).toDouble(),
      inStock: d['in_stock'] ?? true,
      type: d['type'] ?? 'refill',
    );
  }
}
