/// ============================================================================
/// FILE: lib/core/filter_sort.dart
///
/// SUMMARY:
/// Sorting and filtering utility for VendorOffer streams and lists.
/// Evaluates search queries, brand selections, cylinder net gas weights,
/// and sorting options against SessionData models.
/// ============================================================================
library;

import 'session_data.dart';

class FilterCriteria {
  final String query;
  final int sortIndex;
  final String? brand;
  final String? weight;
  final bool verifiedOnly;

  const FilterCriteria({
    this.query = '',
    this.sortIndex = 3,
    this.brand,
    this.weight,
    this.verifiedOnly = false,
  });
}

class FilterSort {
  /// Primary entry point used across discovery screens & search delegates
  static List<VendorOffer> apply(
    List<VendorOffer> offers,
    FilterCriteria criteria,
  ) {
    final filtered = offers.where((offer) {
      final vendor = offer.vendor;
      final q = criteria.query.trim().toLowerCase();

      // 1. Text Search (Shop Name or Area)
      final matchesQuery = q.isEmpty ||
          vendor.businessName.toLowerCase().contains(q) ||
          vendor.area.toLowerCase().contains(q);

      // 2. Brand Matching against offer.vendorBrands
      final matchesBrand = criteria.brand == null ||
          criteria.brand!.isEmpty ||
          offer.vendorBrands.any(
            (b) => b.toLowerCase() == criteria.brand!.toLowerCase(),
          );

      // 3. Cylinder Net Weight Matching against offer.weights
      final matchesWeight = criteria.weight == null ||
          criteria.weight!.isEmpty ||
          offer.weights.any(
            (w) => w.weight.toLowerCase() == criteria.weight!.toLowerCase(),
          );

      // 4. Verified Status
      final matchesVerified = !criteria.verifiedOnly || vendor.verified;

      return matchesQuery && matchesBrand && matchesWeight && matchesVerified;
    }).toList();

    // Sort the filtered results
    return _sort(filtered, criteria.sortIndex);
  }

  static List<VendorOffer> _sort(List<VendorOffer> offers, int sortIndex) {
    final list = List<VendorOffer>.from(offers);

    switch (sortIndex) {
      case 0: // Price: Low to High
        list.sort((a, b) => a.summary.minPrice.compareTo(b.summary.minPrice));
        break;
      case 1: // Distance: Nearest First
        list.sort((a, b) {
          final distA = a.distanceKm ?? 999999.0;
          final distB = b.distanceKm ?? 999999.0;
          return distA.compareTo(distB);
        });
        break;
      case 2: // Most Brands Available
        list.sort((a, b) =>
            b.summary.inStockBrands.compareTo(a.summary.inStockBrands));
        break;
      case 3: // Default / Alphabetical
      default:
        list.sort((a, b) => a.vendor.businessName
            .toLowerCase()
            .compareTo(b.vendor.businessName.toLowerCase()));
        break;
    }

    return list;
  }
}
