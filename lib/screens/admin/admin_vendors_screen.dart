import 'package:flutter/material.dart';

import '../../core/theme_ext.dart';
import '../../models/vendor.dart';
import '../../services/admin_service.dart';
import '../../utils/formatters.dart';
import 'widgets/admin_ui.dart';
import 'admin_vendor_detail_screen.dart';

class AdminVendorsScreen extends StatefulWidget {
  const AdminVendorsScreen({super.key});

  @override
  State<AdminVendorsScreen> createState() => _AdminVendorsScreenState();
}

class _AdminVendorsScreenState extends State<AdminVendorsScreen> {
  final _search = TextEditingController();
  String _status = 'all';
  String _district = 'all';
  String _tier = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Vendor>>(
      stream: AdminService.instance.streamVendors(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AdminLoading();
        }
        if (snapshot.hasError) {
          return AdminErrorState(message: '${snapshot.error}');
        }

        final all = snapshot.data ?? const <Vendor>[];
        final query = _search.text.trim().toLowerCase();
        final districts = all
            .map((vendor) => vendor.district.trim())
            .where((district) => district.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
        final tiers = all
            .map((vendor) => '${vendor.currentTier}')
            .toSet()
            .toList()
          ..sort();
        final districtValue =
            _district == 'all' || districts.contains(_district)
                ? _district
                : 'all';
        final tierValue =
            _tier == 'all' || tiers.contains(_tier) ? _tier : 'all';
        final filtered = all.where((vendor) {
          final matchesStatus = _status == 'all' || vendor.status == _status;
          final matchesDistrict =
              districtValue == 'all' || vendor.district == districtValue;
          final matchesTier =
              tierValue == 'all' || '${vendor.currentTier}' == tierValue;
          final haystack = [
            vendor.displayName,
            vendor.district,
            vendor.phone,
            vendor.ownerUid,
          ].join(' ').toLowerCase();
          return matchesStatus &&
              matchesDistrict &&
              matchesTier &&
              (query.isEmpty || haystack.contains(query));
        }).toList();

        final hasFilters =
            _status != 'all' || districtValue != 'all' || tierValue != 'all';

        final pending = all.where((vendor) => vendor.isPending).length;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AdminSearchField(
                          controller: _search,
                          hint: 'Search shop, phone, district or ID',
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      AdminKeyValueChip(
                        label: 'Total',
                        value: '${all.length}',
                      ),
                      const SizedBox(width: 6),
                      AdminKeyValueChip(
                        label: 'Pending',
                        value: '$pending',
                        color: context.gasColors.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _statusChip('all', 'All'),
                        for (final status in VendorStatus.values)
                          _statusChip(status, VendorStatus.label(status)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        AdminFilterDropdown(
                          label: 'District',
                          value: districtValue,
                          items: ['all', ...districts],
                          onChanged: (value) =>
                              setState(() => _district = value),
                        ),
                        const SizedBox(width: 8),
                        AdminFilterDropdown(
                          label: 'Tier',
                          value: tierValue,
                          items: ['all', ...tiers],
                          onChanged: (value) => setState(() => _tier = value),
                        ),
                        if (hasFilters) ...[
                          const SizedBox(width: 4),
                          TextButton(
                            onPressed: () => setState(() {
                              _status = 'all';
                              _district = 'all';
                              _tier = 'all';
                            }),
                            child: const Text('Clear filters'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? AdminEmptyState(
                      icon: Icons.storefront_outlined,
                      title: all.isEmpty
                          ? 'No vendors yet'
                          : 'No vendors match this filter',
                      message: all.isEmpty
                          ? 'Vendor profiles created in the app will appear here.'
                          : 'Try a different status or search term.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final vendor = filtered[index];
                        return _VendorTile(
                          vendor: vendor,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminVendorDetailScreen(
                                vendorId: vendor.id,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _statusChip(String value, String label) {
    final selected = _status == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _status = value),
        selectedColor: context.colors.primaryContainer,
        checkmarkColor: context.colors.onPrimaryContainer,
        labelStyle: TextStyle(
          fontSize: 12,
          color: selected
              ? context.colors.onPrimaryContainer
              : context.colors.onSurfaceVariant,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _VendorTile extends StatelessWidget {
  const _VendorTile({required this.vendor, required this.onTap});

  final Vendor vendor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminAvatar(name: vendor.displayName, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        vendor.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (vendor.verified) ...[
                      Icon(
                        Icons.verified,
                        size: 16,
                        color: context.gasColors.info,
                      ),
                      const SizedBox(width: 8),
                    ],
                    AdminStatusBadge(
                      status: vendor.status,
                      label: vendor.statusLabel,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    vendor.district.isEmpty ? 'No district' : vendor.district,
                    vendor.phone.isEmpty ? 'No phone' : vendor.phone,
                  ].join(' · '),
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    AdminKeyValueChip(
                      label: 'Tier',
                      value: '${vendor.currentTier}',
                    ),
                    AdminKeyValueChip(
                      label: 'Profile',
                      value: '${vendor.completionPercentage}%',
                      color: context.gasColors.info,
                    ),
                    AdminKeyValueChip(
                      label: 'Commission',
                      value: vendor.isSubscription
                          ? 'TZS ${vendor.subscriptionFee.toStringAsFixed(0)}/mo'
                          : formatPercent(vendor.commissionRate),
                    ),
                    if (vendor.isPending)
                      AdminKeyValueChip(
                        label: 'Waiting',
                        value:
                            '${DateTime.now().difference(vendor.createdAt).inDays}d',
                        color: context.gasColors.warning,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: context.colors.outline),
        ],
      ),
    );
  }
}
