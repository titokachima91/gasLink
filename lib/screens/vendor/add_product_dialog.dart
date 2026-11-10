// lib/screens/vendor/add_product_dialog.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';

import '../../core/theme_ext.dart';

class AddProductDialog extends StatefulWidget {
  const AddProductDialog({super.key});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();

  String _selectedCategory = 'refill';
  late String _selectedBrand;
  late String _selectedWeight;
  String? _selectedAccessory;
  String? _selectedService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedBrand = AppConstants.gasBrands.first;
    final weights =
        AppConstants.brandSizes[_selectedBrand] ?? ['6kg', '15kg', '38kg'];
    _selectedWeight = weights.first;
    _selectedAccessory = AppConstants.accessoryItems.first;
    _selectedService = AppConstants.serviceItems.first;
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid ??
        AuthService.instance.currentUserId;
    if (uid == null || uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User not logged in')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String brand;
      String size;
      String docId;

      if (_selectedCategory == 'accessories') {
        brand = 'Vifaa';
        size = _selectedAccessory ?? 'Accessory';
        docId = '${uid}__accessories__$size';
      } else if (_selectedCategory == 'services') {
        brand = 'Huduma';
        size = _selectedService ?? 'Service';
        docId = '${uid}__services__$size';
      } else {
        // refill or full_set
        brand = _selectedBrand;
        size = _selectedWeight;
        docId = '${uid}__${_selectedCategory}__${brand}__$size';
      }

      // Write to TOP-LEVEL products collection (buyers read from here)
      await FirebaseFirestore.instance.collection('products').doc(docId).set({
        'id': docId,
        'vendor_id': uid,
        'brand': brand,
        'size': size,
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'in_stock': true,
        'inStock': true,
        'category':
            _selectedCategory, // refill | full_set | accessories | services
        'updated_at': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bidhaa imehifadhiwa / Product saved'),
            backgroundColor: context.gasColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add product: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableWeights = AppConstants.brandSizes[_selectedBrand] ?? [];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ongeza Bidhaa / Add Product',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // ===== CATEGORY SELECTOR (from constants) =====
              const Text(
                'Aina ya Bidhaa / Product Type',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: AppConstants.productCategories.map((cat) {
                  return ChoiceChip(
                    label: Text(
                      AppConstants.categoryLabels[cat] ?? cat,
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: _selectedCategory == cat,
                    selectedColor: context.colors.primaryContainer,
                    onSelected: (_) {
                      setState(() => _selectedCategory = cat);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // ===== FIELDS BY CATEGORY =====
              if (_selectedCategory == 'accessories') ...[
                DropdownButtonFormField<String>(
                  value: _selectedAccessory,
                  decoration: const InputDecoration(
                    labelText: 'Kifaa / Accessory',
                    border: OutlineInputBorder(),
                  ),
                  items: AppConstants.accessoryItems
                      .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedAccessory = val);
                  },
                ),
              ] else if (_selectedCategory == 'services') ...[
                DropdownButtonFormField<String>(
                  value: _selectedService,
                  decoration: const InputDecoration(
                    labelText: 'Huduma / Service',
                    border: OutlineInputBorder(),
                  ),
                  items: AppConstants.serviceItems
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedService = val);
                  },
                ),
              ] else ...[
                // Refill or Full Set → Brand + Weight
                DropdownButtonFormField<String>(
                  value: _selectedBrand,
                  decoration: const InputDecoration(
                    labelText: 'Chapa / Brand',
                    border: OutlineInputBorder(),
                  ),
                  items: AppConstants.gasBrands
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedBrand = val;
                        final weights = AppConstants.brandSizes[val] ?? [];
                        if (weights.isNotEmpty) {
                          _selectedWeight = weights.first;
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: availableWeights.contains(_selectedWeight)
                      ? _selectedWeight
                      : (availableWeights.isNotEmpty
                          ? availableWeights.first
                          : null),
                  decoration: const InputDecoration(
                    labelText: 'Ujazo / Weight',
                    border: OutlineInputBorder(),
                  ),
                  items: availableWeights
                      .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedWeight = val);
                  },
                ),
              ],

              const SizedBox(height: 12),

              // Price
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Bei / Price (TZS)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Ingiza bei' : null,
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isLoading ? null : _submitProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.colors.onPrimary,
                        ),
                      )
                    : Text(
                        'Hifadhi / Save Product',
                        style: TextStyle(
                          color: context.colors.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
