// lib/screens/vendor/inventory_screen.dart
// Vendor inventory: merged catalogue view (top-level products + legacy
// subcollection), so what the vendor manages is exactly what consumers see.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/catalog_service.dart';
import '../../widgets/app_ui.dart';
import 'add_product_dialog.dart';

import '../../core/theme_ext.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  bool _loading = true;
  String? _error;
  List<CatalogProduct> _products = [];

  String get _uid =>
      FirebaseAuth.instance.currentUser?.uid ??
      AuthService.instance.currentUserId ??
      '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await CatalogService.instance.fetchVendorCatalog(_uid);
      if (!mounted) return;
      setState(() {
        _products = products;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Hitilafu / Error: $e';
        _loading = false;
      });
    }
  }

  void _showAddProductModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const AddProductDialog(),
    ).then((_) => _load());
  }

  Future<void> _toggleStock(CatalogProduct product) async {
    try {
      await CatalogService.instance.toggleStock(product);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hitilafu ya kubadilisha stoki: $e'),
          backgroundColor: context.colors.error,
        ),
      );
    }
  }

  Future<void> _deleteProduct(CatalogProduct product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Futa Bidhaa / Delete Product'),
        content: Text('Unahakika unataka kufuta ${product.label}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ghairi / Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Futa / Delete',
              style: TextStyle(color: context.colors.error),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      await CatalogService.instance.delete(product);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hitilafu ya kufuta: $e'),
          backgroundColor: context.colors.error,
        ),
      );
    }
  }

  void _showEditProductDialog(CatalogProduct product) {
    final priceController =
        TextEditingController(text: product.price.toString());
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Badili Bei / ${product.label}'),
          content: TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Bei Mpya (TZS)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ghairi'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newPrice = double.tryParse(priceController.text.trim());
                if (newPrice != null) {
                  await CatalogService.instance.updatePrice(product, newPrice);
                  if (context.mounted) Navigator.pop(context);
                  await _load();
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary),
              child: Text(
                'Hifadhi',
                style: TextStyle(color: context.colors.onPrimary),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_uid.isEmpty) {
      return const Scaffold(
        body:
            Center(child: Text('Tafadhali ingia kwenye mfumo / Please log in')),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Stoki & Bidhaa / Inventory',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProductModal,
        backgroundColor: context.colors.primary,
        icon: Icon(Icons.add, color: context.colors.onPrimary),
        label: Text(
          'Add Product',
          style: TextStyle(
              color: context.colors.onPrimary, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: context.colors.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Jaribu Tena')),
          ],
        ),
      );
    }
    if (_products.isEmpty) {
      return AppEmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'Bado huna bidhaa zozote',
        message: 'Ongeza bidhaa zako ili wateja wazione kwenye app.',
        actionLabel: 'Ongeza Bidhaa',
        onAction: _showAddProductModal,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        itemCount: _products.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppSectionHeader(
                title: 'Bidhaa Zangu / My Products',
                subtitle: '${_products.length} bidhaa kwenye katalogi.',
                icon: Icons.inventory_2_outlined,
              ),
            );
          }

          final product = _products[index - 1];

          return AppCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.colors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.propane_tank_outlined,
                    color: context.colors.primary,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _showEditProductDialog(product),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            AppStatusPill(
                              label: 'TZS ${product.price}',
                              icon: Icons.sell_outlined,
                            ),
                            AppStatusPill(
                              label: product.inStock ? 'Ipo Stoki' : 'Hakuna',
                              icon: product.inStock
                                  ? Icons.check_circle_outline
                                  : Icons.remove_circle_outline,
                              color: product.inStock
                                  ? context.gasColors.success
                                  : context.colors.error,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: product.inStock,
                      activeColor: context.colors.primary,
                      onChanged: (_) => _toggleStock(product),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: context.colors.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () => _deleteProduct(product),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
