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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'consumer_order_dialog.dart';

import '../../core/session_gate.dart';
import '../../core/theme_ext.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/verified_badge.dart';

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

  // Selected weight per brand, e.g. {'Oryx Gas': '15kg'}
  final Map<String, String> _selectedWeightPerBrand = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
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
                return Center(
                  child:
                      CircularProgressIndicator(color: context.colors.primary),
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

              return Column(
                children: [
                  Expanded(
                    child: ListView(
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
                    ),
                  ),
                  _buildOrderNowBar(cylinders, accessories),
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
    final verified = data['verified'] as bool? ?? false;
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
        side: BorderSide(color: context.colors.outlineVariant),
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
                    color: context.colors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.storefront,
                      color: context.colors.primary, size: 28),
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
                      if (verified)
                        const VerifiedBadge(
                          label: 'Duka Lililothibitishwa',
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
                Icon(Icons.location_on_outlined,
                    size: 16, color: context.colors.onSurfaceVariant),
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
                Icon(Icons.access_time,
                    size: 16, color: context.colors.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  'Masaa ya Kazi: $openingHours',
                  style:
                      TextStyle(fontSize: 13, color: context.colors.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Dynamic Average ETA Badge Row
            Row(
              children: [
                Icon(Icons.timer_outlined,
                    size: 16, color: context.colors.primary),
                const SizedBox(width: 6),
                Text(
                  'Muda wa Kuwasilisha: $displayEta',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.local_shipping_outlined,
                    size: 16, color: context.gasColors.success),
                const SizedBox(width: 6),
                Text(
                  deliveryText,
                  style: TextStyle(
                      fontSize: 13,
                      color: context.gasColors.success,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            // Vendor About Summary
            if (aboutSummary.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                'Kuhusu Duka / About Us:',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: context.colors.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text(
                aboutSummary,
                style: TextStyle(
                    fontSize: 13, color: context.colors.onSurface, height: 1.3),
              ),
            ],
            // Extra Services Chips
            if (offeredServices.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Huduma za Ziada / Offered Services:',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: context.colors.onSurfaceVariant),
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
                      color: context.colors.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: context.colors.primaryContainer),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 13, color: context.colors.primary),
                        const SizedBox(width: 4),
                        Text(
                          chipText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: context.colors.primary,
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
        color: context.colors.outlineVariant,
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
                      ? context.colors.primary
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
                          ? context.colors.onPrimary
                          : context.colors.onSurfaceVariant,
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
                      ? context.colors.primary
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
                          ? context.colors.onPrimary
                          : context.colors.onSurfaceVariant,
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

  /// Always-visible checkout CTA so a consumer can order without hunting for
  /// the per-row button below the vendor header.
  Widget _buildOrderNowBar(
    List<Map<String, dynamic>> cylinders,
    List<Map<String, dynamic>> accessories,
  ) {
    final l10n = AppLocalizations.of(context);

    Map<String, dynamic>? selected;
    String? brandName;
    String? cylinderWeight;
    double price = 0;

    for (final item in cylinders) {
      final inStock = (item['in_stock'] ?? item['inStock'] ?? true) as bool;
      if (!inStock) continue;
      selected = item;
      brandName = (item['brand'] ?? 'Gesi').toString();
      cylinderWeight =
          (item['size'] ?? item['weight'] ?? '15kg').toString();
      price = (item['price'] as num?)?.toDouble() ?? 0;
      break;
    }

    if (selected == null && accessories.isNotEmpty) {
      final item = accessories.first;
      final inStock = (item['in_stock'] ?? item['inStock'] ?? true) as bool;
      if (inStock) {
        selected = item;
        brandName = (item['name'] ?? item['title'] ?? 'Kifaa').toString();
        cylinderWeight = '1pc';
        price = (item['price'] as num?)?.toDouble() ?? 0;
      }
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(
            top: BorderSide(color: context.colors.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: selected == null
                  ? Text(
                      l10n.noProductsToOrder,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.onSurfaceVariant,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$brandName ${cylinderWeight ?? ''}'.trim(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'TZS ${_formatPrice(price)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: context.gasColors.success,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: selected == null
                  ? null
                  : () async {
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
                          vendorId: widget.vendorId,
                          brandName: brandName!,
                          cylinderWeight: cylinderWeight!,
                          vendorName: widget.businessName,
                          price: price,
                        ),
                      );
                    },
              icon: const Icon(Icons.shopping_cart_checkout, size: 18),
              label: Text(l10n.orderNow),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Last known-good storefront product card: brand, weight chips, one active
  /// offer, and a full-width order button. Keeping the summary vertical means
  /// the text can never be squeezed by an action widget.
  Widget _buildCylindersSection(List<Map<String, dynamic>> cylinders) {
    if (cylinders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(Icons.inventory_2_outlined,
                  size: 40, color: context.colors.outline),
              const SizedBox(height: 8),
              Text(
                'Muuzaji ${widget.businessName} hajaweka mitungi bado.',
                style: TextStyle(
                    color: context.colors.onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final Map<String, List<Map<String, dynamic>>> brandGrouped = {};
    for (final item in cylinders) {
      final brand = (item['brand'] ?? 'Gas').toString();
      brandGrouped.putIfAbsent(brand, () => []).add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: brandGrouped.entries.map((entry) {
        final brandName = entry.key;
        final brandItems = entry.value;
        final defaultWeight =
            (brandItems.first['weight'] ?? brandItems.first['size'] ?? '')
                .toString();
        final activeWeight =
            _selectedWeightPerBrand[brandName] ?? defaultWeight;
        final activeItem = brandItems.firstWhere(
          (i) =>
              (i['weight'] ?? i['size'] ?? '').toString() == activeWeight,
          orElse: () => brandItems.first,
        );
        final price = (activeItem['price'] as num?)?.toDouble() ?? 0.0;
        final inStock =
            (activeItem['in_stock'] ?? activeItem['inStock'] ?? true) as bool;
        final weightLabel = activeWeight.isEmpty ? 'Cylinder' : activeWeight;

        return SizedBox(
          width: double.infinity,
          child: AppCard(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        brandName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppStatusPill(
                      label: inStock ? 'Ipo' : 'Imeisha',
                      icon: inStock
                          ? Icons.check_circle_outline
                          : Icons.remove_circle_outline,
                      color: inStock
                          ? context.gasColors.success
                          : context.colors.error,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: brandItems.map((item) {
                    final weight =
                        (item['weight'] ?? item['size'] ?? '').toString();
                    final isSelected = weight == activeWeight;
                    return ChoiceChip(
                      label: Text(weight),
                      selected: isSelected,
                      selectedColor: context.colors.primary,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? context.colors.onPrimary
                            : context.colors.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      onSelected: (selected) {
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
                Text(
                  '$brandName · $weightLabel Refill',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'TZS ${_formatPrice(price)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.gasColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: inStock
                          ? context.colors.primary
                          : context.colors.outlineVariant,
                      foregroundColor: inStock
                          ? context.colors.onPrimary
                          : context.colors.onSurface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: inStock
                        ? () async {
                            if (!await SessionGate.requireConsumer(context)) {
                              return;
                            }
                            if (!mounted) return;
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
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
              Icon(Icons.build_outlined,
                  size: 40, color: context.colors.outline),
              const SizedBox(height: 8),
              Text(
                'Muuzaji ${widget.businessName} hajaweka vifaa au aksesari bado.',
                style: TextStyle(
                    color: context.colors.onSurfaceVariant, fontSize: 13),
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
            side: BorderSide(color: context.colors.outlineVariant),
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
                      color: context.colors.surfaceContainerLow,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.build_outlined,
                        color: context.colors.primary, size: 28),
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
                      style: TextStyle(
                          color: context.gasColors.success,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.colors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: inStock
                        ? () async {
                            if (!await SessionGate.requireConsumer(context)) {
                              return;
                            }
                            if (!context.mounted) return;
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
                      style: TextStyle(
                          color: context.colors.primary, fontSize: 12),
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
