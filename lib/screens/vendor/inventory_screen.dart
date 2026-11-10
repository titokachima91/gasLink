// lib/screens/vendor/inventory_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import 'add_product_dialog.dart';

import '../../core/theme_ext.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String get _uid =>
      FirebaseAuth.instance.currentUser?.uid ??
      AuthService.instance.currentUserId ??
      '';

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      FirebaseFirestore.instance
          .collection('vendors')
          .doc(_uid)
          .collection('products');

  void _showAddProductModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const AddProductDialog(),
    );
  }

  Future<void> _toggleStock(String docId, bool currentStatus) async {
    try {
      await _productsRef.doc(docId).update({
        'inStock': !currentStatus,
        'in_stock': !currentStatus,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hitilafu ya kubadilisha stoki: $e')),
        );
      }
    }
  }

  Future<void> _deleteProduct(String docId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Futa Bidhaa / Delete Product'),
        content: Text('Unahakika unataka kufuta $title?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ghairi / Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Futa / Delete',
                style: TextStyle(color: context.colors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _productsRef.doc(docId).delete();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hitilafu ya kufuta: $e')),
          );
        }
      }
    }
  }

  void _showEditProductDialog(
      String docId, String brand, String size, dynamic currentPrice) {
    final priceController =
        TextEditingController(text: currentPrice.toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Badili Bei / $brand $size'),
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
                  await _productsRef.doc(docId).update({'price': newPrice});
                  if (context.mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary),
              child: Text('Hifadhi',
                  style: TextStyle(color: context.colors.onPrimary)),
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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _productsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Hitilafu: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: context.colors.primary),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
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
                    label: Text('Ongeza Bidhaa',
                        style: TextStyle(color: context.colors.onPrimary)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.primary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final docId = doc.id;

              final brand = data['brand'] as String? ?? 'Gesi';
              final size = data['size'] as String? ?? '';
              final price = data['price'] ?? 0;
              final inStock = data['inStock'] as bool? ?? true;

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
                          onTap: () =>
                              _showEditProductDialog(docId, brand, size, price),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$brand $size',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                'TZS $price',
                                style: TextStyle(
                                    color: context.colors.onSurfaceVariant,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Inline Stock Switch & Delete Action
                      Row(
                        children: [
                          Text(
                            inStock ? 'Ipo' : 'Hakuna',
                            style: TextStyle(
                              fontSize: 12,
                              color: inStock
                                  ? context.gasColors.success
                                  : context.colors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Switch(
                            value: inStock,
                            activeColor: context.colors.primary,
                            onChanged: (_) => _toggleStock(docId, inStock),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline,
                                color: context.colors.onSurfaceVariant,
                                size: 20),
                            onPressed: () =>
                                _deleteProduct(docId, '$brand $size'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProductModal,
        backgroundColor: context.colors.primary,
        icon: Icon(Icons.add, color: context.colors.onPrimary),
        label: Text('Add Product',
            style: TextStyle(
                color: context.colors.onPrimary, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
