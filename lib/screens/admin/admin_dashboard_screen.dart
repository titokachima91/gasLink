import 'package:flutter/material.dart';

import '../../core/theme_ext.dart';
import '../../models/admin_models.dart';
import '../../models/order.dart';
import '../../models/vendor.dart';
import '../../services/admin_service.dart';
import '../../utils/formatters.dart';
import 'widgets/admin_ui.dart';
import 'admin_order_detail_screen.dart';
import 'admin_vendor_detail_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<AdminDashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = AdminService.instance.loadDashboard();
  }

  Future<void> _reload() async {
    final future = AdminService.instance.loadDashboard();
    setState(() => _future = future);
    await future;
  }

  void _openVendor(Vendor vendor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminVendorDetailScreen(vendorId: vendor.id),
      ),
    );
  }

  void _openOrder(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminOrderDetailScreen(orderId: order.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder<AdminDashboardData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AdminLoading();
          }
          if (snapshot.hasError) {
            return ListView(
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.6,
                  child: AdminErrorState(
                    message: '${snapshot.error}',
                    onRetry: _reload,
                  ),
                ),
              ],
            );
          }

          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _DashboardIntro(pending: data.pendingVendors),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900
                      ? 4
                      : constraints.maxWidth >= 620
                          ? 3
                          : 2;
                  const gap = 10.0;
                  final width =
                      (constraints.maxWidth - (columns - 1) * gap) / columns;
                  final cards = [
                    AdminStatCard(
                      label: 'Active vendors',
                      value: formatNumber(data.activeVendors),
                      subtitle: '${data.totalVendors} total',
                      icon: Icons.storefront_outlined,
                      accent: context.gasColors.success,
                    ),
                    AdminStatCard(
                      label: 'Pending KYC',
                      value: formatNumber(data.pendingVendors),
                      subtitle: 'Needs review',
                      icon: Icons.fact_check_outlined,
                      accent: context.gasColors.warning,
                    ),
                    AdminStatCard(
                      label: 'Orders today',
                      value: formatNumber(data.ordersToday),
                      subtitle: 'Africa/Dar_es_Salaam',
                      icon: Icons.receipt_long_outlined,
                      accent: context.gasColors.info,
                    ),
                    AdminStatCard(
                      label: 'GMV today',
                      value: formatTzs(data.gmvToday, compact: true),
                      subtitle: 'Delivered only',
                      icon: Icons.payments_outlined,
                    ),
                    AdminStatCard(
                      label: 'Delivered today',
                      value: formatNumber(data.deliveredToday),
                      icon: Icons.check_circle_outline,
                      accent: context.gasColors.success,
                    ),
                    AdminStatCard(
                      label: 'Cancelled today',
                      value: formatNumber(data.cancelledToday),
                      icon: Icons.cancel_outlined,
                      accent: context.colors.error,
                    ),
                    AdminStatCard(
                      label: 'Out of stock',
                      value: formatNumber(data.outOfStockProducts),
                      subtitle: '${data.totalProducts} catalogue items',
                      icon: Icons.inventory_2_outlined,
                      accent: context.gasColors.warning,
                    ),
                    AdminStatCard(
                      label: 'Consumers',
                      value: formatNumber(data.consumerCount),
                      icon: Icons.people_alt_outlined,
                      accent: context.gasColors.info,
                    ),
                  ];
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final card in cards)
                        SizedBox(width: width, child: card),
                    ],
                  );
                },
              ),
              const SizedBox(height: 22),
              AdminSectionHeader(
                title: 'Pending approvals',
                subtitle: 'Vendors waiting for a KYC decision.',
                action: data.pendingApprovals.isEmpty
                    ? null
                    : AdminKeyValueChip(
                        label: 'Queue',
                        value: '${data.pendingVendors}',
                        color: context.gasColors.warning,
                      ),
              ),
              if (data.pendingApprovals.isEmpty)
                AdminCard(
                  child: Row(
                    children: [
                      Icon(Icons.verified_outlined,
                          color: context.gasColors.success),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'No vendors are waiting for review.',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                )
              else
                AdminCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0;
                          i < data.pendingApprovals.length;
                          i++) ...[
                        if (i > 0) const Divider(height: 1),
                        _PendingVendorTile(
                          vendor: data.pendingApprovals[i],
                          onTap: () => _openVendor(data.pendingApprovals[i]),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 22),
              const AdminSectionHeader(
                title: 'Recent orders',
                subtitle: 'Latest activity across all vendors.',
              ),
              if (data.recentOrders.isEmpty)
                const AdminCard(
                  child: Text('No orders have been placed yet.'),
                )
              else
                AdminCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < data.recentOrders.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        _RecentOrderTile(
                          order: data.recentOrders[i],
                          onTap: () => _openOrder(data.recentOrders[i]),
                        ),
                      ],
                    ],
                  ),
                ),
              if (data.outOfStockList.isNotEmpty) ...[
                const SizedBox(height: 22),
                const AdminSectionHeader(
                  title: 'Inventory attention',
                  subtitle: 'Catalogue items currently marked out of stock.',
                ),
                AdminCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < data.outOfStockList.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        ListTile(
                          dense: true,
                          leading: Icon(Icons.warning_amber_rounded,
                              color: context.gasColors.warning),
                          title: Text(
                            '${data.outOfStockList[i].brand} '
                            '${data.outOfStockList[i].size}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Vendor ${shortId(data.outOfStockList[i].vendorId)}',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DashboardIntro extends StatelessWidget {
  const _DashboardIntro({required this.pending});

  final int pending;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colors.primaryContainer,
            Color.alphaBlend(
              context.colors.primary.withOpacity(context.isDark ? 0.20 : 0.12),
              context.colors.primaryContainer,
            ),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OPERATIONS CONSOLE',
                  style: TextStyle(
                    color: context.colors.onPrimaryContainer.withOpacity(0.72),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pending == 0
                      ? 'Everything is reviewed.'
                      : '$pending vendor${pending == 1 ? '' : 's'} need review.',
                  style: TextStyle(
                    color: context.colors.onPrimaryContainer,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatDate(DateTime.now()),
                  style: TextStyle(
                    color: context.colors.onPrimaryContainer.withOpacity(0.72),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.monitor_heart_outlined,
            size: 46,
            color: context.colors.onPrimaryContainer.withOpacity(0.85),
          ),
        ],
      ),
    );
  }
}

class _PendingVendorTile extends StatelessWidget {
  const _PendingVendorTile({required this.vendor, required this.onTap});

  final Vendor vendor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: AdminAvatar(name: vendor.displayName),
      title: Text(
        vendor.displayName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${vendor.district.isEmpty ? 'District missing' : vendor.district} · '
        '${formatDate(vendor.createdAt)}',
      ),
      trailing: const AdminStatusBadge(status: VendorStatus.pending),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  const _RecentOrderTile({required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colors.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.local_fire_department,
            color: context.colors.onPrimaryContainer, size: 22),
      ),
      title: Text(
        '${order.brand} ${order.size} · ${order.quantity}x',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${formatTzs(order.total)} · ${formatDateTime(order.createdAt)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: AdminStatusBadge(status: order.status),
    );
  }
}
