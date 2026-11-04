// lib/screens/consumer/item_vendors_screen.dart
//This screen displays a list of vendors offering a specific item (brand or accessory/service) in a given category (refill, full set, accessories, services). Users can sort the vendors by price and select a vendor to place an order.
import 'package:flutter/material.dart';
import '../../core/session_data.dart';
import 'consumer_order_dialog.dart';

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
    await SessionData.instance.ensureLoaded();
    if (mounted) setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _matchingOffers {
    final results = <Map<String, dynamic>>[];

    for (final offer in SessionData.instance.offers) {
      for (final w in offer.weights) {
        final matchesCategory = w.category == widget.category;

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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.orange,
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
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Wauza Gesi / Vendors',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                DropdownButton<String>(
                  value: _sortBy,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.sort, size: 18, color: Colors.orange),
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                  onChanged: (val) {
                    if (val != null) setState(() => _sortBy = val);
                  },
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
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.orange))
                : offers.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: offers.length,
                        itemBuilder: (context, index) {
                          final item = offers[index];
                          final vendor = item['vendor'] as Vendor;
                          final price = item['price'] as double;

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.storefront,
                                        color: Colors.orange),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          vendor.businessName.isNotEmpty
                                              ? vendor.businessName
                                              : 'Muuzaji',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14),
                                        ),
                                        Text(
                                          '📍 ${vendor.area.isNotEmpty ? vendor.area : 'Dar es Salaam'}',
                                          style: const TextStyle(
                                              fontSize: 11, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'TZS ${price.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(16)),
                                        ),
                                        builder: (context) =>
                                            ConsumerOrderDialog(
                                          vendorId: vendor.id,
                                          brandName: widget.itemName,
                                          cylinderSize: item['weight'] ?? '',
                                          vendorName: vendor.businessName,
                                          price: price,
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                    ),
                                    child: const Text('Chagua',
                                        style: TextStyle(fontSize: 12)),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.remove_shopping_cart_outlined,
                size: 48, color: Colors.grey.shade400),
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
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
