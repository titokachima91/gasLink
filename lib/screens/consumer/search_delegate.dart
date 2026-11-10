/// ============================================================================
/// FILE: lib/screens/consumer/search_delegate.dart
///
/// SUMMARY:
/// Instant, zero-latency search overlay delegate for LPG consumer discovery.
/// Streams queries directly against `SessionData.instance.offers` as the consumer
/// types, filtering by shop business name, area location, or stocked gas brands.
/// Passes the selected `VendorOffer` back to the caller or navigates directly
/// to `VendorDetailScreen`.
///
/// KEY COMPONENTS & RESPONSIBILITIES:
/// - `appBarTheme()`: Overrides Flutter SearchDelegate theme styling with orange branding.
/// - Live Filtering: Evaluates `vendor.businessName`, `vendor.area`, and `offer.vendorBrands`.
/// - Handoff & Navigation: Launches `VendorDetailScreen` with required `vendorId` and `businessName`.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import '../../core/session_data.dart';
import 'vendor_detail_screen.dart';

import '../../core/theme_ext.dart';

class VendorSearchDelegate extends SearchDelegate<VendorOffer?> {
  final int sortIndex;

  VendorSearchDelegate({this.sortIndex = 3});

  @override
  String get searchFieldLabel => 'Tafuta jina la duka au eneo...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white70, fontSize: 15),
      ),
      textTheme: theme.textTheme.copyWith(
        titleLarge: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () => close(context, null),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.white),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  List<VendorOffer> _filteredOffers() {
    final q = query.trim().toLowerCase();
    final offers = SessionData.instance.offers;

    if (q.isEmpty) return offers;

    return offers.where((offer) {
      final vendor = offer.vendor;
      final matchesName = vendor.businessName.toLowerCase().contains(q);
      final matchesArea = vendor.area.toLowerCase().contains(q);
      final matchesBrand =
          offer.vendorBrands.any((b) => b.toLowerCase().contains(q));

      return matchesName || matchesArea || matchesBrand;
    }).toList();
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList(context);
  }

  Widget _buildList(BuildContext context) {
    final results = _filteredOffers();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: context.colors.outline),
            const SizedBox(height: 8),
            Text(
              'Hakuna maduka yaliyopatikana / No shops found',
              style: TextStyle(color: context.colors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final offer = results[index];
        final vendor = offer.vendor;
        final summary = offer.summary;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: context.colors.outlineVariant),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              close(context, offer);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VendorDetailScreen(
                    vendorId: vendor.id,
                    businessName: vendor.businessName,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: context.colors.primaryContainer,
                    child: Icon(Icons.store, color: context.colors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendor.businessName.isEmpty
                              ? 'Duka la Gesi'
                              : vendor.businessName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (vendor.area.isNotEmpty)
                          Text(
                            vendor.area,
                            style: TextStyle(
                              fontSize: 11,
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          '${summary.inStockBrands} chapa zipo • Kuanzia TZS ${summary.minPrice}',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.onSurface,
                          ),
                        ),
                        if (offer.distanceKm != null)
                          Text(
                            'Umbali: ${offer.distanceKm!.toStringAsFixed(1)} km',
                            style: TextStyle(
                              fontSize: 11,
                              color: context.colors.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Icon(Icons.chevron_right, color: context.colors.primary),
                      SizedBox(height: 4),
                      Text(
                        'Tazama',
                        style: TextStyle(
                          fontSize: 10,
                          color: context.colors.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
