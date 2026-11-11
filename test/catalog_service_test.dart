import 'package:flutter_test/flutter_test.dart';

import 'package:gaslink_app/services/catalog_service.dart';

CatalogProduct product(
  String id, {
  String brand = 'Brand',
  String size = '',
  double price = 0,
  bool inStock = true,
}) =>
    CatalogProduct(
      id: id,
      // Merge tests never touch the reference; null is allowed by the model.
      ref: null,
      brand: brand,
      size: size,
      price: price,
      inStock: inStock,
    );

void main() {
  test('merge dedupes by id with top-level winning', () {
    final legacy = [
      product('a', brand: 'Legacy Brand', size: '6kg', price: 100),
    ];
    final topLevel = [
      product('a', brand: 'Top Brand', size: '6kg', price: 200, inStock: false),
      product('b', brand: 'Top Brand', size: '15kg', price: 300),
    ];

    final merged = CatalogService.merge(legacy, topLevel);

    expect(merged.length, 2);
    final a = merged.firstWhere((p) => p.id == 'a');
    expect(a.brand, 'Top Brand');
    expect(a.inStock, isFalse);
  });

  test('merge sorts by label', () {
    final legacy = [
      product('b', brand: 'Oryx', size: '15kg', price: 300),
    ];
    final topLevel = [
      product('a', brand: 'Alpha', size: '6kg', price: 100),
    ];

    final merged = CatalogService.merge(legacy, topLevel);
    expect(merged.first.id, 'a');
    expect(merged.last.id, 'b');
  });
}
