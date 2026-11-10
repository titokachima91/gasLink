/// ============================================================================
/// FILE: lib/screens/consumer/vendor_search_screen.dart
///
/// SUMMARY:
/// Consumer discovery & multi-criteria filtering screen for finding LPG vendors.
/// Queries live `SessionData.instance.offers` in real time.
/// Supports multi-faceted search filtering by business name, area, LPG brand name,
/// and LPG net cylinder gas weight capacity (e.g. 6kg, 13kg, 15kg, 38kg).
///
/// KEY COMPONENTS & RESPONSIBILITIES:
/// - Real-time Filtering Pipeline: Evaluates search text against `vendor.businessName`
///   and `vendor.area`, selected LPG brand, and net gas weight capacity.
/// - Net Weight Standard: Uses standardized net gas weight options (6kg, 13kg, 15kg, 38kg).
/// - Dynamic Brand Badges: Renders stocked gas brands directly from `offer.vendorBrands`.
/// - Handoff & Navigation: Directly opens `VendorDetailScreen` using `vendorId` and `businessName`.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/session_data.dart';
import 'vendor_detail_screen.dart';

import '../../core/theme_ext.dart';

class VendorSearchScreen extends StatefulWidget {
  const VendorSearchScreen({super.key});

  @override
  State<VendorSearchScreen> createState() => _VendorSearchScreenState();
}

class _VendorSearchScreenState extends State<VendorSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Active Filter States
  String? _selectedBrand;
  String? _selectedWeight;
  bool _verifiedOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allOffers = SessionData.instance.offers;

    final filteredOffers = allOffers.where((offer) {
      final vendor = offer.vendor;
      final query = _searchController.text.trim().toLowerCase();

      // 1. Check search query against Shop Name or Area
      final matchesQuery = query.isEmpty ||
          vendor.businessName.toLowerCase().contains(query) ||
          vendor.area.toLowerCase().contains(query);

      // 2. Check if selected brand exists in vendor's stocked brands
      final matchesBrand =
          _selectedBrand == null || offer.vendorBrands.contains(_selectedBrand);

      // 3. Check if selected cylinder weight exists in vendor's offer items
      final matchesWeight = _selectedWeight == null ||
          offer.weights.any(
              (w) => w.weight.toLowerCase() == _selectedWeight!.toLowerCase());

      return matchesQuery && matchesBrand && matchesWeight;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Tafuta Muuzaji / Find Vendor',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // Header Search Box & Filter Chips
          Container(
            color: context.colors.surface,
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // Search Field
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() {}),
                  decoration: InputDecoration(
                    hintText:
                        'Tafuta kwa jina la duka au eneo (Mwenge, Kinondoni)...',
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: context.colors.primary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: context.colors.surfaceContainerLow,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Filter Chips Horizontal Bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Verified Vendor Filter Chip
                      FilterChip(
                        selected: _verifiedOnly,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, size: 14, color: context.gasColors.success),
                            SizedBox(width: 4),
                            Text('Duka Lililothibitishwa'),
                          ],
                        ),
                        selectedColor: context.colors.primaryContainer,
                        checkmarkColor: context.colors.primary,
                        onSelected: (val) {
                          setState(() => _verifiedOnly = val);
                        },
                      ),
                      const SizedBox(width: 8),

                      // Brand Selection Dropdown
                      PopupMenuButton<String?>(
                        onSelected: (brand) {
                          setState(() => _selectedBrand = brand);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: null,
                            child: Text('Chapa Zote / All Brands'),
                          ),
                          ...AppConstants.gasBrands.map(
                            (b) => PopupMenuItem(value: b, child: Text(b)),
                          ),
                        ],
                        child: Chip(
                          backgroundColor: _selectedBrand != null
                              ? context.colors.primaryContainer
                              : context.colors.outlineVariant,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_selectedBrand ?? 'Chapa / Brand'),
                              const Icon(Icons.arrow_drop_down, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Net Weight Dropdown (KG)
                      PopupMenuButton<String?>(
                        onSelected: (weight) {
                          setState(() => _selectedWeight = weight);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: null,
                            child: Text('Uzito Wote / All Weights'),
                          ),
                          const PopupMenuItem(value: '6kg', child: Text('6kg')),
                          const PopupMenuItem(
                              value: '13kg', child: Text('13kg')),
                          const PopupMenuItem(
                              value: '15kg', child: Text('15kg')),
                          const PopupMenuItem(
                              value: '38kg', child: Text('38kg')),
                        ],
                        child: Chip(
                          backgroundColor: _selectedWeight != null
                              ? context.colors.primaryContainer
                              : context.colors.outlineVariant,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_selectedWeight ?? 'Uzito / Weight'),
                              const Icon(Icons.arrow_drop_down, size: 18),
                            ],
                          ),
                        ),
                      ),

                      // Reset Filters
                      if (_selectedBrand != null ||
                          _selectedWeight != null ||
                          _verifiedOnly)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedBrand = null;
                              _selectedWeight = null;
                              _verifiedOnly = false;
                            });
                          },
                          child: Text(
                            'Futa Filters',
                            style: TextStyle(color: context.colors.error, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Live Vendor Offers List
          Expanded(
            child: filteredOffers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.storefront,
                            size: 48, color: context.colors.outline),
                        const SizedBox(height: 8),
                        Text(
                          'Hakuna muuzaji aliyepatikana.',
                          style: TextStyle(color: context.colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredOffers.length,
                    itemBuilder: (context, index) {
                      final offer = filteredOffers[index];
                      final vendor = offer.vendor;

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: context.colors.outlineVariant),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: context.colors.primaryContainer,
                                    child: Icon(Icons.store,
                                        color: context.colors.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                vendor.businessName.isEmpty
                                                    ? 'Duka la Gesi'
                                                    : vendor.businessName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.verified,
                                              size: 16,
                                              color: context.gasColors.info,
                                            ),
                                          ],
                                        ),
                                        Text(
                                          vendor.area.isNotEmpty
                                              ? vendor.area
                                              : 'Eneo halijatajwa',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: context.colors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),

                              // Stocked LPG Brand Badges
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: offer.vendorBrands.isEmpty
                                    ? [
                                        Chip(
                                          label: const Text(
                                            'Bidhaa zipo',
                                            style: TextStyle(fontSize: 10),
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          backgroundColor: context.colors.surfaceContainerLow,
                                        )
                                      ]
                                    : offer.vendorBrands
                                        .map(
                                          (brand) => Chip(
                                            label: Text(
                                              brand,
                                              style:
                                                  const TextStyle(fontSize: 10),
                                            ),
                                            visualDensity:
                                                VisualDensity.compact,
                                            backgroundColor:
                                                context.colors.surfaceContainerLow,
                                            padding: EdgeInsets.zero,
                                          ),
                                        )
                                        .toList(),
                              ),
                              const SizedBox(height: 10),

                              // Open Vendor Storefront Action
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: context.colors.primary,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            VendorDetailScreen(
                                          vendorId: vendor.id,
                                          businessName: vendor.businessName,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Angalia Stoki & Oda / View Shop',
                                    style: TextStyle(
                                      color: context.colors.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
}
