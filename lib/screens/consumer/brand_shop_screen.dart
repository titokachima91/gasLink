/// ============================================================================
/// FILE: lib/screens/consumer/brand_shop_screen.dart
///
/// SUMMARY:
/// Filtered brand catalog and vendor comparison view for LPG consumers.
/// Allows consumers to select specific cylinder net gas weight capacities (e.g., 6kg,
/// 13kg, 15kg, 38kg) for a chosen LPG brand, sort available vendors by price,
/// and trigger order placement.
///
/// KEY COMPONENTS & RESPONSIBILITIES:
/// - Net Weight Selection Bar: Displays choice chips for valid LPG weight variants.
/// - Sorting Controller: Sorts live vendor offers by price (lowest to highest) or rating.
/// - Live Vendor Querying: Reads directly from `SessionData.instance.offers`, filtering
///   for vendors offering the target brand and weight in the selected district area.
/// - Purged Mock Data: Completely eliminates hardcoded shop names (Sao Gas Supply, Mlimani Gas),
///   prices, and artificial ratings in favor of active Firestore vendor documents.
/// - Order Dialog Integration: Launches `ConsumerOrderDialog` populated with real,
///   snapshot-priced vendor offer data.
/// ============================================================================

import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/session_data.dart';
import '../../core/session_gate.dart';
import '../../widgets/verified_badge.dart';
import 'consumer_order_dialog.dart';

import '../../core/theme_ext.dart';

class BrandShopScreen extends StatefulWidget {
  final String brandName;
  final String selectedDistrict;

  const BrandShopScreen({
    super.key,
    required this.brandName,
    required this.selectedDistrict,
  });

  @override
  State<BrandShopScreen> createState() => _BrandShopScreenState();
}

class _BrandShopScreenState extends State<BrandShopScreen> {
  late String _selectedWeight;
  String _sortBy = 'price_low'; // 'price_low' | 'price_high'
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final availableWeights =
        AppConstants.brandSizes[widget.brandName] ?? ['6kg', '13kg', '15kg'];
    _selectedWeight = availableWeights.first;
    _loadSessionData();
  }

  Future<void> _loadSessionData() async {
    setState(() => _isLoading = true);
    await SessionData.instance.ensureLoaded();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// Extracts vendor offers from SessionData matching the chosen Brand, Weight, and District Area
  List<Map<String, dynamic>> get _matchingVendorOffers {
    final results = <Map<String, dynamic>>[];

    final targetDistrict = widget.selectedDistrict.trim().toLowerCase();
    final targetBrand = widget.brandName.trim().toLowerCase();
    final targetWeight =
        _selectedWeight.trim().toLowerCase().replaceAll(' ', '');

    for (final offer in SessionData.instance.offers) {
      final vendorArea = offer.vendor.area.trim().toLowerCase();

      // 1. District / Area check (flexible bidirectional match)
      if (targetDistrict.isNotEmpty && vendorArea.isNotEmpty) {
        final matchesLocation = vendorArea.contains(targetDistrict) ||
            targetDistrict.contains(vendorArea);
        if (!matchesLocation) continue;
      }

      // 2. Find matching weight item for this brand
      for (final w in offer.weights) {
        final itemBrand = w.brand.trim().toLowerCase();
        final itemWeight = w.weight.trim().toLowerCase().replaceAll(' ', '');

        // Flexible brand match (handles "Oryx" vs "Oryx Gas")
        final isBrandMatch = itemBrand == targetBrand ||
            itemBrand.contains(targetBrand) ||
            targetBrand.contains(itemBrand);

        // Normalized weight match (handles "6kg" vs "6 kg")
        final isWeightMatch = itemWeight == targetWeight;

        if (isBrandMatch && isWeightMatch) {
          results.add({
            'vendor': offer.vendor,
            'price': w.price.toDouble(),
            'weightOffer': w,
          });
          break;
        }
      }
    }

    // Sort results according to consumer preference
    if (_sortBy == 'price_low') {
      results.sort(
          (a, b) => (a['price'] as double).compareTo(b['price'] as double));
    } else if (_sortBy == 'price_high') {
      results.sort(
          (a, b) => (b['price'] as double).compareTo(a['price'] as double));
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    final availableWeights = AppConstants.brandSizes[widget.brandName] ??
        ['6kg', '13kg', '15kg', '38kg'];
    final matchedOffers = _matchingVendorOffers;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.brandName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            Text(
              '📍 ${widget.selectedDistrict}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Net Gas Weight Chips & Sorting Options
          Container(
            color: context.colors.surface,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kiwango cha Uzito / Net Weight Capacity:',
                  style: TextStyle(
                      fontSize: 11,
                      color: context.colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: availableWeights.map((weight) {
                      final isSelected = _selectedWeight == weight;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(weight),
                          selected: isSelected,
                          selectedColor: context.colors.primaryContainer,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? context.colors.primary
                                : context.colors.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected)
                              setState(() => _selectedWeight = weight);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Wauza Gesi (${widget.brandName} $_selectedWeight)',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _sortBy,
                      underline: const SizedBox(),
                      icon: Icon(Icons.sort,
                          size: 18, color: context.colors.primary),
                      style:
                          TextStyle(fontSize: 12, color: context.colors.onSurface),
                      onChanged: (val) {
                        if (val != null) setState(() => _sortBy = val);
                      },
                      items: const [
                        DropdownMenuItem(
                          value: 'price_low',
                          child: Text('Bei: Chini kwenda Juu'),
                        ),
                        DropdownMenuItem(
                          value: 'price_high',
                          child: Text('Bei: Juu kwenda Chini'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 2. Dynamic Live Vendor List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: context.colors.primary),
                  )
                : matchedOffers.isEmpty
                    ? _buildEmptyOffersState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(12.0),
                        itemCount: matchedOffers.length,
                        itemBuilder: (context, index) {
                          final offer = matchedOffers[index];
                          final vendor = offer['vendor'] as Vendor;
                          final price = offer['price'] as double;

                          return _buildVendorComparisonCard(
                            vendor: vendor,
                            price: price,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  /// Card displaying real vendor details, live price points, and order button
  Widget _buildVendorComparisonCard({
    required Vendor vendor,
    required double price,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.colors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.storefront, color: context.colors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendor.businessName.isNotEmpty
                            ? vendor.businessName
                            : 'Muuzaji wa Gesi',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '📍 ${vendor.area.isNotEmpty ? vendor.area : widget.selectedDistrict}',
                        style:
                            TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (vendor.verified)
                            const VerifiedBadge(
                              label: 'Verified Vendor',
                              compact: true,
                            ),
                          if (vendor.phone.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              '• ${vendor.phone}',
                              style: TextStyle(
                                  fontSize: 11, color: context.colors.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TZS ${price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.colors.primary,
                      ),
                    ),
                    Text(
                      '🟢 Ipo Akiba / In Stock',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: context.gasColors.success,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!await SessionGate.requireConsumer(context)) return;
                    if (!mounted) return;
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (context) => ConsumerOrderDialog(
                        vendorId:
                            vendor.id, // ← Pass the required vendorId here
                        brandName: widget.brandName,
                        cylinderSize: _selectedWeight,
                        vendorName: vendor.businessName,
                        price: price,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: context.colors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text(
                    'Chagua & Weka Oda',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Empty state when no registered vendor carries the selected brand & weight combination
  Widget _buildEmptyOffersState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.remove_shopping_cart_outlined,
                size: 48, color: context.colors.outline),
            const SizedBox(height: 12),
            Text(
              'Hakuna Muuzaji wa ${widget.brandName} ($_selectedWeight)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Hakuna muuzaji aliyetangaza bidhaa ya ${widget.brandName} $_selectedWeight katika eneo la${widget.selectedDistrict}. Jaribu kuchagua uzito mwingine.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
