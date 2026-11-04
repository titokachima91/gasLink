/// ============================================================================
/// FILE: lib/screens/consumer/vendor_detail_screen.dart
///
/// ARCHITECTURE & OVERVIEW:
/// Displays detailed profile information, neighborhood-first location, operating
/// hours, delivery terms, vendor "About Us" summary, extra services, and brand-grouped
/// real-time inventory for a specific LPG vendor.
///
/// KEY TECHNICAL & ARCHITECTURAL HIGHLIGHTS:
///
/// 1. Safe Factory Parsing (`VendorDetailScreen.fromOffer`):
///    - Safely handles incoming navigation arguments from discovery screens or
///      search maps.
///    - Inspects whether incoming data is a typed `VendorOffer` instance or a raw
///      `Map<String, dynamic>`, extracting `id` and `businessName` without
///      throwing runtime type errors.
///
/// 2. Dual Real-Time Stream Architecture:
///    - Vendor Stream: Listens directly to `/vendors/{vendorId}` for live profile
///      details (neighborhood address, working hours, delivery terms, store
///      description, and extra service badges).
///    - Products Stream: Listens to `/products` where `vendor_id == widget.vendorId`.
///      Dynamically splits stock items into:
///        * Cylinders List: Standard LPG packages.
///        * Accessories List: Spare parts, hose pipes, regulators, and stoves
///          (filtered by category keywords: `accessory`, `vifaa`, or `kifaa`).
///
/// 3. State Management & Interactive Controls:
///    - `_selectedCategoryIndex`: Toggles between `0 = 🔥 Mitungi ya Gesi` and
///      `1 = 🔧 Vifaa & Aksesari` to keep vertical scrolling short.
///    - `_selectedWeightPerBrand` (`Map<String, String>`): Stores active weight pill
///      per brand (e.g., `{'Oryx Gas': '15kg'}`). Tapping a weight pill (`6kg`, `15kg`)
///      updates only that specific brand card's price, capacity, and stock status.
///
/// 4. Component Layout Breakdown:
///    - Header Card (`_buildVendorHeaderCard`): Renders store name, verified badge,
///      area-first address (`Eneo: Sinza Mori (Ubungo)`), operating hours, delivery
///      fee rules, mandatory vendor summary, and extra service chips.
///    - Category Toggle (`_buildCategoryToggle`): Compact segmented bar switching
///      views between cylinders and accessories.
///    - Brand-Grouped Cylinders (`_buildCylindersSection`): Groups cylinders by brand,
///      provides weight choice pills (`ChoiceChip`), and shows active price/stock with
///      an `Oda Sasa` action button.
///    - Accessories Grid (`_buildAccessoriesSection`): 2-column grid showing spare
///      parts, regulators, hose pipes, and an `Oda Kifaa` action button.
///
/// 5. Checkout & Order Sheet Bridge:
///    - Tapping `Oda Sasa` or `Oda Kifaa` triggers `ConsumerOrderDialog` as a modal
///      bottom sheet, passing `vendorId`, `brandName`, `cylinderWeight`, `vendorName`,
///      and `price` forward to initiate checkout.
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'consumer_order_dialog.dart';

class VendorDetailScreen extends StatefulWidget {
  const VendorDetailScreen({
    super.key,
    required this.vendorId,
    required this.businessName,
  });

  /// Factory constructor called by discovery screens.
  factory VendorDetailScreen.fromOffer(dynamic offer, {Key? key}) {
    String id = '';
    String name = 'Vendor';
    try {
      if (offer != null) {
        id = offer.vendor?.id ?? offer.vendorId ?? offer.id ?? '';
        name = offer.vendor?.businessName ?? offer.businessName ?? 'Vendor';
      }
    } catch (_) {
      if (offer is Map) {
        id = offer['vendorId'] ?? offer['id'] ?? '';
        name = offer['businessName'] ?? offer['name'] ?? 'Vendor';
      }
    }
    return VendorDetailScreen(
      key: key,
      vendorId: id,
      businessName: name,
    );
  }

  final String vendorId;
  final String businessName;

  @override
  State<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends State<VendorDetailScreen> {
  // Category switch: 0 = Mitungi ya Gesi (Cylinders), 1 = Vifaa & Aksesari (Accessories)
  int _selectedCategoryIndex = 0;

  // Selected weight pill per brand (e.g., {'Oryx Gas': '15kg', 'Taifa Gas': '6kg'})
  final Map<String, String> _selectedWeightPerBrand = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.businessName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('vendors')
            .doc(widget.vendorId)
            .snapshots(),
        builder: (context, vendorSnap) {
          final vendorData = vendorSnap.data?.data() ?? {};

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .where('vendor_id', isEqualTo: widget.vendorId)
                .snapshots(),
            builder: (context, productSnap) {
              if (vendorSnap.connectionState == ConnectionState.waiting &&
                  productSnap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                );
              }

              final productDocs = productSnap.data?.docs ?? [];

              // Separate inventory into Cylinders and Accessories
              final cylinders = <Map<String, dynamic>>[];
              final accessories = <Map<String, dynamic>>[];

              for (final doc in productDocs) {
                final data = doc.data();
                final type = (data['type'] ?? data['category'] ?? '')
                    .toString()
                    .toLowerCase();

                if (type == 'accessory' || type == 'vifaa' || type == 'kifaa') {
                  accessories.add(data);
                } else {
                  cylinders.add(data);
                }
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. Vendor Profile Summary Card
                  _buildVendorHeaderCard(vendorData),
                  const SizedBox(height: 16),

                  // 2. Category Switcher Bar
                  _buildCategoryToggle(),
                  const SizedBox(height: 16),

                  // 3. Active Tab Content
                  _selectedCategoryIndex == 0
                      ? _buildCylindersSection(cylinders)
                      : _buildAccessoriesSection(accessories),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// Builds Vendor Profile Card (Location, Working Hours, About Summary & Extra Services)
  /// Builds Vendor Profile Card (Location, Working Hours, Dynamic ETA, About Summary & Extra Services)
  Widget _buildVendorHeaderCard(Map<String, dynamic> data) {
    final street = (data['street'] ?? data['area'] ?? '') as String;
    final district = (data['district'] ?? '') as String;
    final openingHours = (data['openingHours'] ??
        data['opening_hours'] ??
        '07:00 AM - 09:00 PM') as String;
    final deliveryFee =
        (data['deliveryFee'] ?? data['delivery_fee'] as num?)?.toDouble() ??
            0.0;
    final deliveryType =
        (data['deliveryType'] ?? data['delivery_type'] ?? 'free') as String;
    final aboutSummary = (data['aboutSummary'] ??
        data['about'] ??
        data['description'] ??
        '') as String;
    final rawServices =
        data['offeredServices'] ?? data['offered_services'] ?? [];
    final List<String> offeredServices = (rawServices is List)
        ? rawServices.map((e) => e.toString()).toList()
        : [];

    // --- Dynamic Average ETA Calculation (Stage 1: Pre-Purchase Expectation) ---
    final int completedCount =
        (data['completed_orders_count'] as num?)?.toInt() ?? 0;
    final int totalMins =
        (data['total_delivery_minutes'] as num?)?.toInt() ?? 0;

    String displayEta = 'Dakika 15 - 25';
    if (completedCount > 0) {
      final int avg = (totalMins / completedCount).round();
      final int lowerBound = (avg - 5) < 10 ? 10 : (avg - 5);
      final int upperBound = avg + 5;
      displayEta = 'Dakika $lowerBound - $upperBound';
    }

    String deliveryText = 'Usafiri: Bure (Free Delivery)';
    if (deliveryType == 'fee' && deliveryFee > 0) {
      deliveryText = 'Usafiri: TZS ${_formatPrice(deliveryFee)}';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Title & Verified Badge
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.storefront,
                      color: Colors.orange, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.businessName,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.verified,
                              size: 14, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            'Duka Lililothibitishwa',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Neighborhood Address & Hours
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    street.isNotEmpty
                        ? 'Eneo: $street ($district)'
                        : 'Eneo: $district',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Masaa ya Kazi: $openingHours',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Dynamic Average ETA Badge Row
            Row(
              children: [
                const Icon(Icons.timer_outlined,
                    size: 16, color: Colors.orange),
                const SizedBox(width: 6),
                Text(
                  'Muda wa Kuwasilisha: $displayEta',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.local_shipping_outlined,
                    size: 16, color: Colors.green),
                const SizedBox(width: 6),
                Text(
                  deliveryText,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Colors.green,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            // Vendor About Summary
            if (aboutSummary.isNotEmpty) ...[
              const Divider(height: 24),
              const Text(
                'Kuhusu Duka / About Us:',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                aboutSummary,
                style: const TextStyle(
                    fontSize: 13, color: Colors.black87, height: 1.3),
              ),
            ],
            // Extra Services Chips
            if (offeredServices.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Huduma za Ziada / Offered Services:',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: offeredServices.map((service) {
                  final chipText = service.split('/').first.trim();
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 13, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          chipText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Segmented Category Switcher Bar
  Widget _buildCategoryToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategoryIndex = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedCategoryIndex == 0
                      ? Colors.orange
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '🔥 Mitungi ya Gesi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _selectedCategoryIndex == 0
                          ? Colors.white
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategoryIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedCategoryIndex == 1
                      ? Colors.orange
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '🔧 Vifaa & Aksesari',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _selectedCategoryIndex == 1
                          ? Colors.white
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Brand-Grouped Cylinders with Interactive Weight Selection
  Widget _buildCylindersSection(List<Map<String, dynamic>> cylinders) {
    if (cylinders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(Icons.inventory_2_outlined,
                  size: 40, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                'Muuzaji ${widget.businessName} hajaweka mitungi bado.',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    // Group cylinder documents by brand
    final Map<String, List<Map<String, dynamic>>> brandGrouped = {};
    for (final item in cylinders) {
      final brand = (item['brand'] ?? 'Gas') as String;
      brandGrouped.putIfAbsent(brand, () => []).add(item);
    }

    return Column(
      children: brandGrouped.entries.map((entry) {
        final brandName = entry.key;
        final brandItems = entry.value;

        // Default selected weight to first item weight if unset
        final defaultWeight = (brandItems.first['weight'] ??
            brandItems.first['size'] ??
            '') as String;
        final activeWeight =
            _selectedWeightPerBrand[brandName] ?? defaultWeight;

        // Active item corresponding to chosen weight
        final activeItem = brandItems.firstWhere(
          (i) => (i['weight'] ?? i['size'] ?? '') == activeWeight,
          orElse: () => brandItems.first,
        );

        final price = (activeItem['price'] as num?)?.toDouble() ?? 0.0;
        final inStock =
            (activeItem['in_stock'] ?? activeItem['inStock'] ?? true) as bool;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brandName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Weight Choice Pills
                Wrap(
                  spacing: 8,
                  children: brandItems.map((item) {
                    final weight =
                        (item['weight'] ?? item['size'] ?? '') as String;
                    final isSelected = weight == activeWeight;

                    return ChoiceChip(
                      label: Text(weight),
                      selected: isSelected,
                      selectedColor: Colors.orange,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (bool selected) {
                        if (selected) {
                          setState(() {
                            _selectedWeightPerBrand[brandName] = weight;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const Divider(height: 20),

                // Active Item Summary Card
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.propane_tank,
                          color: Colors.orange, size: 30),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$brandName ($activeWeight) Refill',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'TZS ${_formatPrice(price)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            inStock ? Colors.orange : Colors.grey.shade300,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: inStock
                          ? () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (context) => ConsumerOrderDialog(
                                  vendorId: widget.vendorId,
                                  brandName: brandName,
                                  cylinderWeight: activeWeight,
                                  vendorName: widget.businessName,
                                  price: price,
                                ),
                              );
                            }
                          : null,
                      child: Text(
                        inStock ? 'Oda Sasa' : 'Imeisha',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Accessories Catalog View
  Widget _buildAccessoriesSection(List<Map<String, dynamic>> accessories) {
    if (accessories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(Icons.build_outlined, size: 40, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                'Muuzaji ${widget.businessName} hajaweka vifaa au aksesari bado.',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: accessories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final item = accessories[index];
        final name = (item['name'] ?? item['title'] ?? 'Kifaa') as String;
        final price = (item['price'] as num?)?.toDouble() ?? 0.0;
        final inStock = (item['in_stock'] ?? item['inStock'] ?? true) as bool;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.build_outlined,
                        color: Colors.orange, size: 28),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'TZS ${_formatPrice(price)}',
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.orange),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: inStock
                        ? () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) => ConsumerOrderDialog(
                                vendorId: widget.vendorId,
                                brandName: name,
                                cylinderWeight: '1pc',
                                vendorName: widget.businessName,
                                price: price,
                              ),
                            );
                          }
                        : null,
                    child: Text(
                      inStock ? 'Oda Kifaa' : 'Imeisha',
                      style:
                          const TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Formats price into comma-separated thousands string
  String _formatPrice(num p) {
    final s = p.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final rem = s.length - i;
      buf.write(s[i]);
      if (rem > 1 && rem % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }
}
