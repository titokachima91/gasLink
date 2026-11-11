// lib/screens/vendor/inventory_screen.dart
// Vendor inventory: merged catalogue view (top-level products + legacy
// subcollection), so what the vendor manages is exactly what consumers see.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/catalog_service.dart';
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64, color: context.colors.outline),
            const SizedBox(height: 12),
            Text(
              'Bado huna bidhaa zozote / No products added',
              style: TextStyle(
                  color: context.colors.onSurfaceVariant, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddProductModal,
              icon: Icon(Icons.add, color: context.colors.onPrimary),
              label: Text(
                'Ongeza Bidhaa',
                style: TextStyle(color: context.colors.onPrimary),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: context.colors.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Icon(Icons.local_fire_department,
                      color: context.colors.primary, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _showEditProductDialog(product),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.label,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            'TZS ${product.price}',
                            style: TextStyle(
                                color: context.colors.onSurfaceVariant,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        product.inStock ? 'Ipo' : 'Hakuna',
                        style: TextStyle(
                          fontSize: 12,
                          color: product.inStock
                              ? context.gasColors.success
                              : context.colors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
            ),
          );
        },
      ),
    );
  }
}
