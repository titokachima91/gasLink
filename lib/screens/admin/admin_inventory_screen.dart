import 'package:flutter/material.dart';

import '../../core/theme_ext.dart';
import '../../models/admin_models.dart';
import '../../models/vendor.dart';
import '../../services/admin_service.dart';
import '../../utils/formatters.dart';
import 'widgets/admin_ui.dart';

class AdminInventoryScreen extends StatefulWidget {
  const AdminInventoryScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends State<AdminInventoryScreen> {
  final _search = TextEditingController();
  late Future<Map<String, Vendor>> _vendorsFuture;
  bool _outOfStockOnly = false;

  @override
  void initState() {
    super.initState();
    _vendorsFuture = AdminService.instance.loadVendorMap();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = FutureBuilder<Map<String, Vendor>>(
      future: _vendorsFuture,
      builder: (context, vendorSnapshot) {
        final vendors = vendorSnapshot.data ?? const <String, Vendor>{};
        return StreamBuilder<List<AdminProduct>>(
          stream: AdminService.instance.streamProducts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AdminLoading();
            }
            if (snapshot.hasError) {
              return AdminErrorState(message: '${snapshot.error}');
            }
            final products = snapshot.data ?? const <AdminProduct>[];
            final query = _search.text.trim().toLowerCase();
            final groups = _groupProducts(products).where((group) {
              final matchesQuery = query.isEmpty ||
                  group.brand.toLowerCase().contains(query) ||
                  group.size.toLowerCase().contains(query);
              final matchesStock = !_outOfStockOnly || group.inStock == 0;
              return matchesQuery && matchesStock;
            }).toList()
              ..sort((a, b) {
                final stockCompare = a.inStock.compareTo(b.inStock);
                if (stockCompare != 0) return stockCompare;
                final brand = a.brand.compareTo(b.brand);
                return brand != 0 ? brand : a.size.compareTo(b.size);
              });

            final outOfStock =
                products.where((product) => !product.inStock).length;
            final vendorsWithStock = products
                .where((product) => product.inStock)
                .map((product) => product.vendorId)
                .toSet()
                .length;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AdminSearchField(
                              controller: _search,
                              hint: 'Search brand or size',
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 10),
                          AdminKeyValueChip(
                            label: 'Out',
                            value: '$outOfStock',
                            color: context.gasColors.warning,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          FilterChip(
                            label: const Text('Out of stock only'),
                            selected: _outOfStockOnly,
                            onSelected: (value) => setState(
                              () => _outOfStockOnly = value,
                            ),
                            selectedColor: context.colors.primaryContainer,
                            checkmarkColor: context.colors.onPrimaryContainer,
                          ),
                          const Spacer(),
                          Text(
                            '${products.length} offers · '
                            '$vendorsWithStock vendors stocked',
                            style: TextStyle(
                              fontSize: 11,
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: groups.isEmpty
                      ? AdminEmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: products.isEmpty
                              ? 'No catalogue items'
                              : 'Nothing matches this filter',
                          message: products.isEmpty
                              ? 'Products published by vendors will appear here.'
                              : 'Try another brand, size or stock filter.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: groups.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final group = groups[index];
                            return _StockGroupCard(
                              group: group,
                              onTap: () => _showOffers(group, vendors),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: body,
    );
  }

  void _showOffers(_StockGroup group, Map<String, Vendor> vendors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${group.brand} ${group.size}',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '${group.offers.length} vendor offers',
                style: TextStyle(
                  fontSize: 12,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: group.offers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final product = group.offers[index];
                    final vendor = vendors[product.vendorId];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.storefront_outlined,
                        color: context.colors.primary,
                      ),
                      title: Text(
                        vendor?.displayName ??
                            'Vendor ${shortId(product.vendorId)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        [
                          vendor?.district ?? 'District unknown',
                          product.category,
                        ].join(' · '),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatTzs(product.price),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            product.inStock ? 'In stock' : 'Out of stock',
                            style: TextStyle(
                              fontSize: 10,
                              color: product.inStock
                                  ? context.gasColors.success
                                  : context.colors.error,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static List<_StockGroup> _groupProducts(List<AdminProduct> products) {
    final map = <String, _StockGroup>{};
    for (final product in products) {
      final key = '${product.brand}__${product.size}';
      final group = map.putIfAbsent(
        key,
        () => _StockGroup(brand: product.brand, size: product.size),
      );
      group.offers.add(product);
    }
    return map.values.toList();
  }
}

class _StockGroup {
  _StockGroup({required this.brand, required this.size});

  final String brand;
  final String size;
  final List<AdminProduct> offers = [];

  int get inStock => offers.where((offer) => offer.inStock).length;
  int get outOfStock => offers.length - inStock;
  Set<String> get vendorIds => offers.map((offer) => offer.vendorId).toSet();
  double get minPrice => offers.isEmpty
      ? 0
      : offers.map((offer) => offer.price).reduce((a, b) => a < b ? a : b);
  double get maxPrice => offers.isEmpty
      ? 0
      : offers.map((offer) => offer.price).reduce((a, b) => a > b ? a : b);
}

class _StockGroupCard extends StatelessWidget {
  const _StockGroupCard({
    required this.group,
    required this.onTap,
  });

  final _StockGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final priceLabel = group.minPrice == group.maxPrice
        ? formatTzs(group.minPrice)
        : '${formatTzs(group.minPrice)} – ${formatTzs(group.maxPrice)}';
    return AdminCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.colors.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.propane_tank_outlined,
              color: context.colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${group.brand} ${group.size}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${group.vendorIds.length} vendors · $priceLabel',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  children: [
                    AdminKeyValueChip(
                      label: 'In stock',
                      value: '${group.inStock}',
                      color: context.gasColors.success,
                    ),
                    if (group.outOfStock > 0)
                      AdminKeyValueChip(
                        label: 'Out',
                        value: '${group.outOfStock}',
                        color: context.colors.error,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.colors.outline),
        ],
      ),
    );
  }
}
