/// lib/screens/vendor_list_screen.dart
/// Consumer vendor list — read-path only, straight off Firestore.
/// Detail navigation goes to VendorDetailScreen.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/vendor.dart';
import 'consumer/vendor_detail_screen.dart';

class VendorListScreen extends StatefulWidget {
  const VendorListScreen({super.key});

  @override
  State<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends State<VendorListScreen> {
  bool _loading = true;
  String? _error;
  List<Vendor> _vendors = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snap = await FirebaseFirestore.instance.collection('vendors').get();
      _vendors = snap.docs
          .map(Vendor.fromDoc)
          .where((v) => v.active) // skip deactivated
          .toList()
        ..sort((a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
      _loading = false;
    } catch (e) {
      _error = 'Couldn\'t load vendors';
      _loading = false;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gas Vendors')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_vendors.isEmpty) {
      return const Center(child: Text('No vendors registered yet.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _vendors.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final v = _vendors[i];
          return Card(
            child: ListTile(
              title: Text(v.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (v.areaText.isNotEmpty)
                    Text(v.areaText, style: TextStyle(color: Colors.grey[600])),
                  if (v.stockedBrandNames.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 6,
                        children: [
                          for (final b in v.stockedBrandNames)
                            Chip(
                              label: Text(b),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VendorDetailScreen(
                      vendorId: v.id,
                      businessName: v.displayName,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
