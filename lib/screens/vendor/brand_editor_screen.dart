/// lib/screens/vendor/brand_editor_screen.dart
///
/// BLOCK 2 — FILE 4: brand_editor_screen.dart
/// ==========================================
/// ROLE: Price & stock editor for ONE brand. Reached from InventoryScreen
/// (File 3) via the edit icon on a selected brand.
///
/// DATA RULES:
///  - Sizes come ONLY from AppConstants.brandSizes[brand] — fixed list,
///    vendor cannot invent sizes (same clean-data rule as brands).
///  - One Firestore doc per (vendor, brand, size) in collection 'products'.
///    Doc id is a composite key: '{vendorId}__{brand}__{size}' — a natural
///    unique key, so re-saving the same size UPDATES instead of duplicating
///    (no query-before-write needed; set() with the fixed id is idempotent).
///  - Doc id is also stored in field 'id' so consumer-side can build
///    'in stock at these vendors' queries cheaply later.
///  - Unticked size = not sold = its product doc (if any) is deleted.
///    Ticks, price writes, and deletes all go in ONE WriteBatch.
///  - price must be > 0 for a ticked size; validation blocks save otherwise.
///
/// FLOW: initState -> load existing product docs for this brand
///       -> user ticks sizes, enters prices, toggles in_stock
///       -> Save -> WriteBatch commit -> pop back to InventoryScreen
library vendor.brand_editor_screen;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

import '../../core/constants.dart';

class BrandEditorScreen extends StatefulWidget {
  /// Which brand we're editing (e.g. 'Oryx').
  final String brand;

  /// Sizes that already have product docs — ticks them on open.
  final List<String> existingSizes;

  const BrandEditorScreen({
    super.key,
    required this.brand,
    this.existingSizes = const [],
  });

  @override
  State<BrandEditorScreen> createState() => _BrandEditorScreenState();
}

class _BrandEditorScreenState extends State<BrandEditorScreen> {
  String get _uid => AuthService.instance.currentUserId!;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// size -> TextEditingController for price.
  final Map<String, TextEditingController> _priceControllers = {};

  /// size -> in-stock toggle.
  final Map<String, bool> _inStock = {};

  /// size -> currently ticked?
  final Set<String> _ticked = {};

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _priceControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    // Pre-tick sizes that already exist, load their price + stock.
    for (final size in AppConstants.brandSizes[widget.brand] ?? []) {
      _priceControllers[size] = TextEditingController();
      _inStock[size] = true;
    }
    _ticked.addAll(widget.existingSizes);

    // Fetch existing docs to fill prices (and correct in_stock values).
    if (widget.existingSizes.isNotEmpty) {
      final snap = await _db
          .collection('products')
          .where('vendor_id', isEqualTo: _uid)
          .where('brand', isEqualTo: widget.brand)
          .get();
      for (final d in snap.docs) {
        final data = d.data();
        final size = data['size'] as String? ?? '';
        final price = (data['price'] as num?)?.toString() ?? '';
        if (_priceControllers.containsKey(size)) {
          _priceControllers[size]!.text = price;
          _inStock[size] = data['in_stock'] as bool? ?? true;
        }
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    // Validation: every ticked size needs a price > 0.
    for (final size in _ticked) {
      final value = num.tryParse(_priceControllers[size]!.text.trim());
      if (value == null || value <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Weka bei sahihi / Enter a valid price'),
        ));
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final batch = _db.batch();
      final allSizes = AppConstants.brandSizes[widget.brand] ?? [];

      for (final size in allSizes) {
        // Composite doc id: same size always maps to same doc -> upsert.
        final docId = '${_uid}__${widget.brand}__$size';
        final ref = _db.collection('products').doc(docId);
        // Legacy corrupted id from older builds (uid/brand were not
        // interpolated). Always cleaned up so stale docs never resurface.
        final legacyRef =
            _db.collection('products').doc('{_uid}__{widget.brand}__$size');
        batch.delete(legacyRef);

        if (_ticked.contains(size)) {
          final price = num.parse(_priceControllers[size]!.text.trim());
          batch.set(
              ref,
              {
                'id': docId,
                'vendor_id': _uid,
                'brand': widget.brand,
                'size': size,
                'price': price,
                'in_stock': _inStock[size] ?? true,
                'inStock': _inStock[size] ?? true,
                'updated_at': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true));
        } else {
          // Unticked = not sold -> delete any existing doc.
          batch.delete(ref);
        }
      }

      await batch.commit();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imehifadhiwa / Saved ✓')),
      );
      Navigator.pop(context); // back to InventoryScreen, which refreshes
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final sizes = AppConstants.brandSizes[widget.brand] ?? [];
    return Scaffold(
      appBar: AppBar(title: Text('${widget.brand} — Prices / Bei')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Tick sizes you sell and set prices (TZS) / Chagua saizi na weka bei',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...sizes.map((size) {
            final ticked = _ticked.contains(size);
            return Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Checkbox(
                      value: ticked,
                      onChanged: (v) => setState(
                          () => v! ? _ticked.add(size) : _ticked.remove(size)),
                    ),
                    SizedBox(width: 60, child: Text(size)),
                    Expanded(
                      child: TextField(
                        controller: _priceControllers[size],
                        enabled: ticked,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          prefixText: 'TZS ',
                          border: OutlineInputBorder(),
                          hintText: 'e.g. 25000',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // In-stock toggle only meaningful when ticked.
                    Column(
                      children: [
                        const Text('Stock', style: TextStyle(fontSize: 12)),
                        Switch(
                          value: _inStock[size] ?? true,
                          onChanged: ticked
                              ? (v) => setState(() => _inStock[size] = v)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save / Hifadhi'),
          ),
        ],
      ),
    );
  }
}
