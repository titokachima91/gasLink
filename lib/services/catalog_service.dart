import 'package:cloud_firestore/cloud_firestore.dart';

/// One catalogue entry from either the top-level products collection or the
/// legacy per-vendor subcollection.
class CatalogProduct {
  const CatalogProduct({
    required this.id,
    required this.ref,
    required this.brand,
    required this.size,
    required this.price,
    required this.inStock,
  });

  final String id;

  /// Source document. Nullable only for pure merge tests; always set on
  /// products returned from [CatalogService.fetchVendorCatalog].
  final DocumentReference<Map<String, dynamic>>? ref;
  final String brand;
  final String size;
  final double price;
  final bool inStock;

  String get label => size.isEmpty ? brand : '$brand $size';
}

/// Single source for the vendor catalogue.
///
/// New products are written to the top-level `products` collection (what
/// consumers read). Legacy documents in `vendors/{id}/products` are still
/// shown and edited in place so nothing disappears; they are not written to
/// again for new items.
class CatalogService {
  CatalogService._();
  static final CatalogService instance = CatalogService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Pure merge: dedupes by id with top-level documents winning.
  static List<CatalogProduct> merge(
    List<CatalogProduct> legacy,
    List<CatalogProduct> topLevel,
  ) {
    final byId = <String, CatalogProduct>{};
    for (final product in legacy) {
      byId[product.id] = product;
    }
    for (final product in topLevel) {
      byId[product.id] = product;
    }
    final list = byId.values.toList()
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return list;
  }

  /// Fetches both stores and returns the merged catalogue.
  Future<List<CatalogProduct>> fetchVendorCatalog(String vendorId) async {
    final topSnap = await _db
        .collection('products')
        .where('vendor_id', isEqualTo: vendorId)
        .get();
    final legacySnap = await _db
        .collection('vendors')
        .doc(vendorId)
        .collection('products')
        .get();

    List<CatalogProduct> map(QuerySnapshot<Map<String, dynamic>> snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return CatalogProduct(
          id: doc.id,
          ref: doc.reference,
          brand: (data['brand'] ?? 'Gesi').toString(),
          size: (data['size'] ?? data['weight'] ?? '').toString(),
          price: (data['price'] as num? ?? 0).toDouble(),
          inStock: (data['in_stock'] ?? data['inStock'] ?? true) as bool,
        );
      }).toList();
    }

    return merge(map(legacySnap), map(topSnap));
  }

  /// Writes are applied to the document's own collection so legacy and
  /// top-level documents stay editable without moving data around.
  Future<void> toggleStock(CatalogProduct product) async {
    await product.ref!.update({
      'in_stock': !product.inStock,
      'inStock': !product.inStock,
    });
  }

  Future<void> updatePrice(CatalogProduct product, double price) async {
    await product.ref!.update({'price': price});
  }

  Future<void> delete(CatalogProduct product) async {
    await product.ref!.delete();
  }
}
