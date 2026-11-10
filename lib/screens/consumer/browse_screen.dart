/// ============================================================================
/// FILE: lib/screens/consumer/browse_screen.dart
///
/// SUMMARY:
/// Primary consumer browse screen for exploring LPG gas shops. Renders cached
/// `SessionData.instance.offers` through sorting and brand filtering pipelines.
/// Enables seamless navigation to search overlays (`VendorSearchDelegate`) and
/// individual storefront profiles (`VendorDetailScreen`).
///
/// KEY COMPONENTS & RESPONSIBILITIES:
/// - Real-Time Pipeline: Filters and sorts `VendorOffer` objects by distance,
///   lowest price, and stock completeness.
/// - Dynamic Brand Chips: Extracts active gas brands across all loaded vendor offers.
/// - Storefront Handoff: Launches `VendorDetailScreen` upon selecting a shop card.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import '../../core/session_data.dart';
import 'search_delegate.dart';
import 'vendor_detail_screen.dart';

import '../../core/theme_ext.dart';

enum SortOption { distance, price, stock, none }

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  SortOption _sort = SortOption.none;
  String? _brandFilter;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await SessionData.instance.ensureLoaded();
    } catch (e) {
      _error = e.toString();
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  String _sortLabel(SortOption s) {
    switch (s) {
      case SortOption.distance:
        return 'Nearest / Karibu Zaidi';
      case SortOption.price:
        return 'Price ↑ / Bei ya Chini';
      case SortOption.stock:
        return 'In stock first / Zilizopo Stoki';
      case SortOption.none:
        return 'Default / Za Kawaida';
    }
  }

  /// Pure pipeline operating on cached SessionData VendorOffer list
  List<VendorOffer> _apply() {
    var list = SessionData.instance.offers;

    if (_brandFilter != null) {
      list = list.where((o) => o.vendorBrands.contains(_brandFilter)).toList();
    }

    final sortedList = List<VendorOffer>.from(list);

    if (_sort == SortOption.distance) {
      sortedList.sort(
        (a, b) => (a.distanceKm ?? 1e9).compareTo(b.distanceKm ?? 1e9),
      );
    } else if (_sort == SortOption.price) {
      sortedList.sort(
        (a, b) => a.summary.minPrice.compareTo(b.summary.minPrice),
      );
    } else if (_sort == SortOption.stock) {
      sortedList.sort((a, b) {
        final fa = a.summary.fullyStocked ? 1 : 0;
        final fb = b.summary.fullyStocked ? 1 : 0;
        final f = fb - fa;
        return f != 0 ? f : a.summary.minPrice.compareTo(b.summary.minPrice);
      });
    }

    return sortedList;
  }

  /// Extracts unique sorted LPG brands available in current SessionData
  List<String> get _allBrands {
    final set = <String>{};
    for (final o in SessionData.instance.offers) {
      set.addAll(o.vendorBrands);
    }
    return set.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: context.colors.primary),
        ),
      );
    }

    final results = _apply();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Maduka ya Gesi / Gas Shops',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          if (_error != null)
            Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(Icons.warning_amber_rounded,
                  color: context.colors.onPrimary),
            ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () async {
              final picked = await showSearch<VendorOffer?>(
                context: context,
                delegate: VendorSearchDelegate(),
              );
              if (picked != null && mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VendorDetailScreen.fromOffer(picked),
                  ),
                );
              }
            },
          ),
          PopupMenuButton<SortOption>(
            initialValue: _sort,
            icon: const Icon(Icons.sort, color: Colors.white),
            onSelected: (s) {
              setState(() {
                _sort = s;
              });
            },
            itemBuilder: (_) {
              return SortOption.values.map((s) {
                return PopupMenuItem<SortOption>(
                  value: s,
                  child: Text(_sortLabel(s)),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: context.gasColors.warningContainer,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              'Orodha ya maduka yote ya gesi karibu nawe',
              style: TextStyle(fontSize: 12, color: context.colors.onSurface),
            ),
          ),

          // Horizontal Brand Filter Chips
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              children: [
                ChoiceChip(
                  label: const Text('Zote / All'),
                  selected: _brandFilter == null,
                  selectedColor: context.colors.primaryContainer,
                  onSelected: (_) {
                    setState(() {
                      _brandFilter = null;
                    });
                  },
                ),
                ..._allBrands.map((b) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      label: Text(b),
                      selected: _brandFilter == b,
                      selectedColor: context.colors.primaryContainer,
                      onSelected: (_) {
                        setState(() {
                          _brandFilter = b;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          // Storefront Results List
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.storefront,
                            size: 48, color: context.colors.outline),
                        const SizedBox(height: 8),
                        Text(
                          'No shops found / Hakuna matokeo',
                          style: TextStyle(color: context.colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: context.colors.primary,
                    onRefresh: () async {
                      SessionData.instance.loaded = false;
                      await SessionData.instance.ensureLoaded();
                      setState(() {});
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final offer = results[index];
                        final summary = offer.summary;
                        final vendor = offer.vendor;

                        final brandCountText =
                            '${summary.inStockBrands} chapa zipo';
                        final priceText =
                            'Kuanzia TZS ${summary.minPrice.toStringAsFixed(0)}';
                        final distanceText = offer.distanceKm != null
                            ? ' • ${offer.distanceKm!.toStringAsFixed(1)} km'
                            : '';

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: context.colors.outlineVariant),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: CircleAvatar(
                              backgroundColor: context.colors.primaryContainer,
                              child:
                                  Icon(Icons.store, color: context.colors.primary),
                            ),
                            title: Text(
                              vendor.businessName.isEmpty
                                  ? 'Duka la Gesi'
                                  : vendor.businessName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (vendor.area.isNotEmpty)
                                    Text(
                                      vendor.area,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: context.colors.onSurfaceVariant),
                                    ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$brandCountText • $priceText$distanceText',
                                    style: TextStyle(
                                        fontSize: 12, color: context.colors.onSurface),
                                  ),
                                ],
                              ),
                            ),
                            trailing: Icon(Icons.chevron_right,
                                color: context.colors.primary),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      VendorDetailScreen.fromOffer(offer),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
