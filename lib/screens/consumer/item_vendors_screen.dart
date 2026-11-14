// lib/screens/consumer/item_vendors_screen.dart
//This screen displays a list of vendors offering a specific item (brand or accessory/service) in a given category (refill, full set, accessories, services). Users can sort the vendors by price and select a vendor to place an order.
import 'package:flutter/material.dart';
import '../../core/session_data.dart';
import '../../core/session_gate.dart';
import '../../widgets/verified_badge.dart';
import 'consumer_order_dialog.dart';
import 'vendor_detail_screen.dart';

import '../../core/theme_ext.dart';

class ItemVendorsScreen extends StatefulWidget {
  final String category; // refill | full_set | accessories | services
  final String itemName; // brand name or accessory/service name

  const ItemVendorsScreen({
    super.key,
    required this.category,
    required this.itemName,
  });

  @override
  State<ItemVendorsScreen> createState() => _ItemVendorsScreenState();
}

class _ItemVendorsScreenState extends State<ItemVendorsScreen> {
  bool _isLoading = true;
  String _sortBy = 'price_low';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      // Force a live read so a previously empty session cache cannot leave the
      // shop blank after the vendor adds stock.
      await SessionData.instance.reload();
    } catch (e) {
      debugPrint('Shop reload warning: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _collectOffers(String? category) {
    final results = <Map<String, dynamic>>[];

    for (final offer in SessionData.instance.offers) {
      for (final w in offer.weights) {
        final matchesCategory = category == null || w.category == category;

        // For gas products we match brand, for accessories/services we match the item name
        final matchesItem = widget.category == 'refill' ||
                widget.category == 'full_set'
            ? w.brand.toLowerCase().contains(widget.itemName.toLowerCase()) ||
                widget.itemName.toLowerCase().contains(w.brand.toLowerCase())
            : w.weight.toLowerCase().contains(widget.itemName.toLowerCase()) ||
                w.brand.toLowerCase().contains(widget.itemName.toLowerCase());

        if (matchesCategory && matchesItem) {
          results.add({
            'vendor': offer.vendor,
            'price': w.price.toDouble(),
            'weight': w.weight,
          });
          break;
        }
      }
    }
    return results;
  }

  List<Map<String, dynamic>> get _matchingOffers {
    final results = _collectOffers(widget.category);

    if (_sortBy == 'price_low') {
      results.sort(
          (a, b) => (a['price'] as double).compareTo(b['price'] as double));
    } else {
      results.sort(
          (a, b) => (b['price'] as double).compareTo(a['price'] as double));
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    final offers = _matchingOffers;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.itemName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Sort bar
          Container(
            color: context.colors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Wauza Gesi / Vendors',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: context.colors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _sortBy,
                  isDense: true,
                  underline: const SizedBox(),
                  icon: Icon(Icons.sort, size: 18, color: context.colors.primary),
                  style: TextStyle(fontSize: 12, color: context.colors.onSurface),
                  onChanged: (val) {
                    if (val != null) setState(() => _sortBy = val);
                  },
                  selectedItemBuilder: (context) => const [
                    Text('Chini → Juu'),
                    Text('Juu → Chini'),
                  ],
                  items: const [
                    DropdownMenuItem(
                      value: 'price_low',
                      child: Text('Bei: Chini → Juu'),
                    ),
                    DropdownMenuItem(
                      value: 'price_high',
                      child: Text('Bei: Juu → Chini'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: context.colors.primary))
                : offers.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: offers.length,
                        itemBuilder: (context, index) {
                          final item = offers[index];
                          final vendor = item['vendor'] as Vendor;
                          final price = item['price'] as double;
                          final weight = (item['weight'] ?? '').toString();
                          final vendorName = vendor.businessName.trim().isNotEmpty
                              ? vendor.businessName.trim()
                              : 'Muuzaji';
                          final vendorArea = vendor.area.trim().isNotEmpty
                              ? vendor.area.trim()
                              : 'Dar es Salaam';

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                  color: context.colors.outlineVariant),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Shop header: opens the full storefront.
                                  InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () => _openStorefront(vendor),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 2),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: context
                                                  .colors.primaryContainer,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(Icons.storefront,
                                                color:
                                                    context.colors.primary),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        vendorName,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                    if (vendor.verified) ...[
                                                      const SizedBox(width: 4),
                                                      const VerifiedBadge(
                                                          compact: true),
                                                    ],
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '📍 $vendorArea',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: context.colors
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(Icons.chevron_right,
                                              size: 18,
                                              color: context
                                                  .colors.onSurfaceVariant),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          weight.isEmpty
                                              ? 'Bidhaa'
                                              : '$weight · Refill',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: context
                                                .colors.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'TZS ${price.toStringAsFixed(0)}',
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: context.colors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: () => _openOrderDialog(
                                        context,
                                        vendor,
                                        price,
                                        weight,
                                      ),
                                      icon: const Icon(
                                          Icons.shopping_cart_checkout,
                                          size: 18),
                                      label: const Text('Oda Sasa'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _openStorefront(Vendor vendor) {
    final name = vendor.businessName.trim().isNotEmpty
        ? vendor.businessName.trim()
        : 'Muuzaji';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VendorDetailScreen(
          vendorId: vendor.id,
          businessName: name,
        ),
      ),
    );
  }

  Future<void> _openOrderDialog(
    BuildContext context,
    Vendor vendor,
    double price,
    String weight,
  ) async {
    if (!await SessionGate.requireConsumer(context)) return;
    if (!mounted || !context.mounted) return;
    final vendorName = vendor.businessName.trim().isNotEmpty
        ? vendor.businessName.trim()
        : 'Muuzaji';
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ConsumerOrderDialog(
        vendorId: vendor.id,
        brandName: widget.itemName,
        cylinderSize: weight.isEmpty
            ? (widget.category == 'refill' ||
                    widget.category == 'full_set'
                ? '15kg'
                : '1pc')
            : weight,
        vendorName: vendorName,
        price: price,
        orderType: widget.category,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.remove_shopping_cart_outlined,
                size: 48, color: context.colors.outline),
            const SizedBox(height: 12),
            Text(
              'Hakuna Muuzaji wa ${widget.itemName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Hakuna muuzaji aliyetangaza bidhaa hii kwa sasa. Jaribu baadaye.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Sasisha'),
            ),
          ],
        ),
      ),
    );
  }
}
