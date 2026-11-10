import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme_ext.dart';
import '../../models/order.dart';
import '../../models/vendor.dart';
import '../../services/admin_service.dart';
import '../../utils/formatters.dart';
import 'widgets/admin_ui.dart';
import 'admin_order_detail_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final _search = TextEditingController();
  late Future<Map<String, Vendor>> _vendorsFuture;
  String _status = 'all';
  String _district = 'all';
  int _days = 30;

  @override
  void initState() {
    super.initState();
    _vendorsFuture = AdminService.instance.loadVendorMap();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, Vendor>>(
      future: _vendorsFuture,
      builder: (context, vendorSnapshot) {
        final vendorMap = vendorSnapshot.data ?? const <String, Vendor>{};
        return StreamBuilder<List<Order>>(
          stream: AdminService.instance.streamOrders(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AdminLoading();
            }
            if (snapshot.hasError) {
              return AdminErrorState(message: '${snapshot.error}');
            }

            final all = snapshot.data ?? const <Order>[];
            final query = _search.text.trim().toLowerCase();
            final districts = vendorMap.values
                .map((vendor) => vendor.district.trim())
                .where((district) => district.isNotEmpty)
                .toSet()
                .toList()
              ..sort();
            final districtValue =
                _district == 'all' || districts.contains(_district)
                    ? _district
                    : 'all';
            final cutoff = _days == 0
                ? null
                : DateTime.now().subtract(Duration(days: _days));
            final filtered = all.where((order) {
              final matchesStatus = _status == 'all' || order.status == _status;
              final matchesDate =
                  cutoff == null || !order.createdAt.isBefore(cutoff);
              final vendor = vendorMap[order.vendorId];
              final vendorName = vendor?.displayName ?? '';
              final district = vendor?.district ?? '';
              final matchesDistrict =
                  districtValue == 'all' || district == districtValue;
              final haystack = [
                order.id,
                order.brand,
                order.size,
                order.consumerUid,
                order.vendorId,
                vendorName,
                district,
                order.deliveryAddress,
              ].join(' ').toLowerCase();
              return matchesStatus &&
                  matchesDate &&
                  matchesDistrict &&
                  (query.isEmpty || haystack.contains(query));
            }).toList();

            final totalValue = filtered
                .where((order) => _isDelivered(order.status))
                .fold<double>(0, (sum, order) => sum + order.total);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AdminSearchField(
                              controller: _search,
                              hint: 'Search order, brand, customer or vendor',
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 10),
                          AdminKeyValueChip(
                            label: 'Results',
                            value: '${filtered.length}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _statusChip('all', 'All'),
                              for (final status in AppConstants.orderStatuses)
                                _statusChip(status, _statusLabel(status)),
                              const SizedBox(width: 10),
                              AdminFilterDropdown(
                                label: 'District',
                                value: districtValue,
                                items: ['all', ...districts],
                                onChanged: (value) =>
                                    setState(() => _district = value),
                              ),
                              const SizedBox(width: 10),
                              _daysChip(7, '7 days'),
                              _daysChip(30, '30 days'),
                              _daysChip(90, '90 days'),
                              _daysChip(0, 'All time'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Delivered value in view: ${formatTzs(totalValue)} · '
                          'latest 300 orders loaded',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? AdminEmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: all.isEmpty
                              ? 'No orders yet'
                              : 'No orders match this filter',
                          message: all.isEmpty
                              ? 'Orders placed by consumers will appear here.'
                              : 'Adjust the status, date range or search term.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final order = filtered[index];
                            return _OrderTile(
                              order: order,
                              vendor: vendorMap[order.vendorId],
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminOrderDetailScreen(
                                    orderId: order.id,
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

  Widget _daysChip(int days, String label) {
    final selected = _days == days;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _days = days),
        selectedColor: context.gasColors.infoContainer,
        labelStyle: TextStyle(
          fontSize: 11,
          color: selected
              ? context.gasColors.onInfoContainer
              : context.colors.onSurfaceVariant,
        ),
      ),
    );
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'placed':
        return 'Placed';
      case 'seen':
        return 'Seen';
      case 'confirmed':
        return 'Confirmed';
      case 'on_the_way':
        return 'On the way';
      case 'delivered_pending':
        return 'Pending';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

/// Local status helper so the list does not import the analytics service.
bool _isDelivered(String status) {
  final value = status.toLowerCase();
  return value == 'delivered' || value == 'completed';
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({
    required this.order,
    required this.vendor,
    required this.onTap,
  });

  final Order order;
  final Vendor? vendor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.local_fire_department,
                  color: context.colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order.brand} ${order.size} · ${order.quantity}x',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '#${shortId(order.id)} · ${formatDateTime(order.createdAt)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AdminStatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  vendor?.displayName ?? 'Vendor ${shortId(order.vendorId)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatTzs(order.total),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              AdminKeyValueChip(
                label: 'Payment',
                value: order.paymentMethod == 'mobile_money'
                    ? 'Mobile money'
                    : 'Cash',
              ),
              if (order.deliveryAddress.isNotEmpty)
                AdminKeyValueChip(
                  label: 'Area',
                  value: order.deliveryAddress,
                  color: context.gasColors.info,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
