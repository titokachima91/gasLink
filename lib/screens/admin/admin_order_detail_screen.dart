import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme_ext.dart';
import '../../models/order.dart';
import '../../models/vendor.dart';
import '../../services/admin_service.dart';
import '../../utils/formatters.dart';
import 'widgets/admin_ui.dart';
import 'admin_consumer_detail_screen.dart';
import 'admin_vendor_detail_screen.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  const AdminOrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  bool _busy = false;

  Future<void> _cancelOrder() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel order'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Reason shown in the audit trail',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Keep order'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) return;
              Navigator.pop(dialogContext, value);
            },
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.error,
              foregroundColor: context.colors.onError,
            ),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || reason.trim().isEmpty) return;

    setState(() => _busy = true);
    try {
      await AdminService.instance.cancelOrder(
        orderId: widget.orderId,
        reason: reason.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Order cancelled and audit recorded.'),
          backgroundColor: context.gasColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not cancel order: $error'),
          backgroundColor: context.colors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order detail')),
      body: StreamBuilder<Order?>(
        stream: AdminService.instance.streamOrder(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AdminLoading();
          }
          if (snapshot.hasError) {
            return AdminErrorState(message: '${snapshot.error}');
          }
          final order = snapshot.data;
          if (order == null) {
            return const AdminEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Order not found',
              message: 'This order may have been removed.',
            );
          }

          final normalized = _normalizeStatus(order.status);
          final canCancel =
              normalized != 'delivered' && normalized != 'cancelled';

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${order.brand} ${order.size}',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        AdminStatusBadge(status: normalized),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order #${shortId(order.id, length: 12)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: AdminStatCard(
                            label: 'Order value',
                            value: formatTzs(order.total),
                            icon: Icons.payments_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AdminStatCard(
                            label: 'Quantity',
                            value: '${order.quantity}',
                            icon: Icons.numbers,
                            accent: context.gasColors.info,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (canCancel)
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _cancelOrder,
                    icon: Icon(Icons.cancel_outlined,
                        color: context.colors.error),
                    label: Text(
                      'Cancel order',
                      style: TextStyle(color: context.colors.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.colors.error),
                    ),
                  ),
                ),
              if (normalized == 'cancelled' &&
                  order.cancellationReason.isNotEmpty) ...[
                const SizedBox(height: 12),
                AdminCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: context.colors.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cancellation reason',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 3),
                            Text(order.cancellationReason),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
              const AdminSectionHeader(
                title: 'Timeline',
                subtitle: 'Canonical seven-stage order lifecycle.',
              ),
              AdminCard(
                child: _OrderTimeline(status: normalized),
              ),
              const SizedBox(height: 22),
              const AdminSectionHeader(
                title: 'Customer',
                subtitle: 'Contact and delivery information.',
              ),
              AdminCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: [
                    AdminInfoRow(
                      icon: Icons.person_outline,
                      label: 'Consumer UID',
                      value: order.consumerUid,
                      onTap: order.consumerUid.isEmpty
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminConsumerDetailScreen(
                                    uid: order.consumerUid,
                                  ),
                                ),
                              ),
                    ),
                    AdminInfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Contact',
                      value: order.contactPhone,
                    ),
                    AdminInfoRow(
                      icon: Icons.phone_forwarded_outlined,
                      label: 'Receiver',
                      value: order.receiverPhone,
                    ),
                    AdminInfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Address',
                      value: order.deliveryAddress,
                    ),
                    AdminInfoRow(
                      icon: Icons.notes_outlined,
                      label: 'Requests',
                      value: order.specialRequests,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const AdminSectionHeader(
                title: 'Vendor',
                subtitle: 'Fulfilling store and contact.',
              ),
              _VendorLookup(vendorId: order.vendorId),
              const SizedBox(height: 22),
              const AdminSectionHeader(
                title: 'Commercials',
                subtitle: 'Line item, payment and commission snapshot.',
              ),
              AdminCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: [
                    AdminInfoRow(
                      icon: Icons.category_outlined,
                      label: 'Type',
                      value: '${order.type} · ${order.orderIntent}',
                    ),
                    AdminInfoRow(
                      icon: Icons.sell_outlined,
                      label: 'Unit price',
                      value: formatTzs(order.unitPrice),
                    ),
                    AdminInfoRow(
                      icon: Icons.shopping_bag_outlined,
                      label: 'Order total',
                      value: formatTzs(order.total),
                    ),
                    AdminInfoRow(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Payment',
                      value: order.paymentMethod == 'mobile_money'
                          ? 'Mobile money'
                          : 'Cash',
                    ),
                    AdminInfoRow(
                      icon: Icons.percent,
                      label: 'Commission',
                      value: order.commissionModel == 'subscription'
                          ? 'Subscription (no per-order cut)'
                          : '${formatPercent(order.commissionRate)} · '
                              '${formatTzs(order.commissionDue)}',
                    ),
                    AdminInfoRow(
                      icon: Icons.receipt_outlined,
                      label: 'Billed',
                      value: order.billed ? 'Yes' : 'No',
                    ),
                    AdminInfoRow(
                      icon: Icons.event_outlined,
                      label: 'Created',
                      value: formatDateTime(order.createdAt),
                    ),
                    AdminInfoRow(
                      icon: Icons.check_circle_outline,
                      label: 'Delivered',
                      value: formatDateTime(order.deliveredAt),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _normalizeStatus(String raw) {
    final value = raw.trim().toLowerCase();
    if (value == 'completed') return 'delivered';
    if (value == 'accepted') return 'confirmed';
    if (value == 'pending') return 'placed';
    if (value == 'in_transit') return 'on_the_way';
    return value;
  }
}

class _VendorLookup extends StatefulWidget {
  const _VendorLookup({required this.vendorId});

  final String vendorId;

  @override
  State<_VendorLookup> createState() => _VendorLookupState();
}

class _VendorLookupState extends State<_VendorLookup> {
  late Future<Vendor?> _future;

  @override
  void initState() {
    super.initState();
    _future = AdminService.instance.getVendor(widget.vendorId);
  }

  @override
  void didUpdateWidget(covariant _VendorLookup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vendorId != widget.vendorId) {
      _future = AdminService.instance.getVendor(widget.vendorId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Vendor?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AdminCard(child: AdminLoading());
        }
        final vendor = snapshot.data;
        if (vendor == null) {
          return AdminCard(
            child: Text('Vendor ${shortId(widget.vendorId)} not found.'),
          );
        }
        return AdminCard(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminVendorDetailScreen(vendorId: vendor.id),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AdminAvatar(name: vendor.displayName),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendor.displayName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          [
                            if (vendor.district.isNotEmpty) vendor.district,
                            if (vendor.phone.isNotEmpty) vendor.phone,
                          ].join(' · '),
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AdminStatusBadge(status: vendor.status),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  AdminKeyValueChip(
                    label: 'Tier',
                    value: '${vendor.currentTier}',
                  ),
                  const SizedBox(width: 6),
                  AdminKeyValueChip(
                    label: 'Commission',
                    value: vendor.isSubscription
                        ? 'TZS ${vendor.subscriptionFee.toStringAsFixed(0)}/mo'
                        : formatPercent(vendor.commissionRate),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OrderTimeline extends StatelessWidget {
  const _OrderTimeline({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    if (status == 'disputed') {
      return Column(
        children: [
          for (final entry in [
            ('placed', 'Order placed'),
            ('delivered_pending', 'Vendor marked arrived'),
            ('disputed', 'Customer denied receipt — GasLink mediation'),
          ])
            _TimelineStep(
              label: entry.$2,
              status: entry.$1,
              done: true,
              current: entry.$1 == 'disputed',
              last: entry.$1 == 'disputed',
            ),
        ],
      );
    }

    if (status == 'cancelled') {
      return Column(
        children: [
          for (final entry in [
            ('placed', 'Order placed'),
            ('cancelled', 'Cancelled by admin or vendor'),
          ])
            _TimelineStep(
              label: entry.$2,
              status: entry.$1,
              done: true,
              current: entry.$1 == 'cancelled',
              last: entry.$1 == 'cancelled',
            ),
        ],
      );
    }

    final happyPath = AppConstants.orderStatuses
        .where((status) => status != 'cancelled' && status != 'disputed')
        .toList();
    final currentIndex = happyPath.indexOf(status);
    return Column(
      children: [
        for (var i = 0; i < happyPath.length; i++)
          _TimelineStep(
            label: _timelineLabel(happyPath[i]),
            status: happyPath[i],
            done: i <= currentIndex,
            current: i == currentIndex,
            last: i == happyPath.length - 1,
          ),
      ],
    );
  }

  static String _timelineLabel(String status) {
    switch (status) {
      case 'placed':
        return 'Order placed';
      case 'seen':
        return 'Seen by vendor';
      case 'confirmed':
        return 'Confirmed';
      case 'on_the_way':
        return 'On the way';
      case 'delivered_pending':
        return 'Delivery confirmation pending';
      case 'delivered':
        return 'Delivered';
      case 'disputed':
        return 'Disputed — GasLink mediation';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.label,
    required this.status,
    required this.done,
    required this.current,
    required this.last,
  });

  final String label;
  final String status;
  final bool done;
  final bool current;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = done
        ? adminStatusColor(context, status)
        : context.colors.outlineVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Container(
                width: current ? 20 : 14,
                height: current ? 20 : 14,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: done ? color : context.colors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: done ? color : context.colors.outline,
                    width: 2,
                  ),
                ),
                child: current
                    ? Icon(Icons.circle, size: 7, color: context.colors.surface)
                    : null,
              ),
              if (!last)
                Container(
                  width: 2,
                  height: 28,
                  color: done ? color : context.colors.outlineVariant,
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                    color: done
                        ? context.colors.onSurface
                        : context.colors.onSurfaceVariant,
                  ),
                ),
                if (current)
                  Text(
                    'Current status',
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
