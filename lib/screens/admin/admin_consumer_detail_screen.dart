import 'package:flutter/material.dart';

import '../../core/theme_ext.dart';
import '../../models/admin_models.dart';
import '../../models/order.dart';
import '../../services/admin_service.dart';
import '../../utils/formatters.dart';
import 'widgets/admin_ui.dart';
import 'admin_order_detail_screen.dart';

class AdminConsumerDetailScreen extends StatelessWidget {
  const AdminConsumerDetailScreen({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consumer profile')),
      body: StreamBuilder<AdminConsumer?>(
        stream: AdminService.instance.streamConsumer(uid),
        builder: (context, consumerSnapshot) {
          if (consumerSnapshot.connectionState == ConnectionState.waiting) {
            return const AdminLoading();
          }
          if (consumerSnapshot.hasError) {
            return AdminErrorState(message: '${consumerSnapshot.error}');
          }
          final consumer = consumerSnapshot.data;
          if (consumer == null) {
            return const AdminEmptyState(
              icon: Icons.person_off_outlined,
              title: 'Consumer not found',
              message: 'This account may have been removed.',
            );
          }

          return StreamBuilder<List<Order>>(
            stream: AdminService.instance.streamConsumerOrders(uid),
            builder: (context, orderSnapshot) {
              final orders = orderSnapshot.data ?? const <Order>[];
              final delivered = orders.where((order) {
                final value = order.status.toLowerCase();
                return value == 'delivered' || value == 'completed';
              }).toList();
              final spend = delivered.fold<double>(
                0,
                (sum, order) => sum + order.total,
              );

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  AdminCard(
                    child: Row(
                      children: [
                        AdminAvatar(name: consumer.displayName, size: 58),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                consumer.displayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                consumer.phone.isEmpty
                                    ? 'No phone on file'
                                    : consumer.phone,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'UID ${consumer.uid}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AdminStatCard(
                          label: 'Orders',
                          value: '${orders.length}',
                          icon: Icons.receipt_long_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AdminStatCard(
                          label: 'Delivered',
                          value: '${delivered.length}',
                          icon: Icons.check_circle_outline,
                          accent: context.gasColors.success,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AdminStatCard(
                          label: 'Lifetime value',
                          value: formatTzs(spend, compact: true),
                          icon: Icons.payments_outlined,
                          accent: context.gasColors.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const AdminSectionHeader(
                    title: 'Account',
                    subtitle: 'Contact and registration metadata.',
                  ),
                  AdminCard(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Column(
                      children: [
                        AdminInfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: consumer.phone,
                        ),
                        AdminInfoRow(
                          icon: Icons.person_outline,
                          label: 'Role',
                          value: consumer.role,
                        ),
                        AdminInfoRow(
                          icon: Icons.event_outlined,
                          label: 'Joined',
                          value: formatDateTime(consumer.createdAt),
                        ),
                        AdminInfoRow(
                          icon: Icons.badge_outlined,
                          label: 'UID',
                          value: consumer.uid,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const AdminSectionHeader(
                    title: 'Cylinder holdings',
                    subtitle: 'Kitchen ledger maintained after delivery.',
                  ),
                  StreamBuilder<List<AdminCylinder>>(
                    stream: AdminService.instance.streamConsumerCylinders(uid),
                    builder: (context, cylinderSnapshot) {
                      if (cylinderSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const AdminCard(child: AdminLoading());
                      }
                      if (cylinderSnapshot.hasError) {
                        return AdminCard(
                          child: Text('${cylinderSnapshot.error}'),
                        );
                      }
                      final cylinders =
                          cylinderSnapshot.data ?? const <AdminCylinder>[];
                      if (cylinders.isEmpty) {
                        return const AdminCard(
                          child: Text(
                              'No cylinders registered for this consumer.'),
                        );
                      }
                      return AdminCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (var i = 0; i < cylinders.length; i++) ...[
                              if (i > 0) const Divider(height: 1),
                              ListTile(
                                leading: Icon(
                                  Icons.propane_tank_outlined,
                                  color: context.colors.primary,
                                ),
                                title: Text(
                                  '${cylinders[i].brand} '
                                  '${cylinders[i].weight}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${cylinders[i].remainingDays} days remaining'
                                  '${cylinders[i].supplierName.isEmpty ? '' : ' · ${cylinders[i].supplierName}'}',
                                ),
                                trailing: AdminStatusBadge(
                                  status: cylinders[i].percentage > 25
                                      ? 'active'
                                      : 'pending',
                                  label:
                                      '${cylinders[i].percentage.toStringAsFixed(0)}%',
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  const AdminSectionHeader(
                    title: 'Order history',
                    subtitle: 'All orders linked to this account.',
                  ),
                  if (orderSnapshot.connectionState == ConnectionState.waiting)
                    const AdminCard(child: AdminLoading())
                  else if (orderSnapshot.hasError)
                    AdminCard(child: Text('${orderSnapshot.error}'))
                  else if (orders.isEmpty)
                    const AdminCard(
                      child: Text('No orders for this consumer yet.'),
                    )
                  else
                    AdminCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var i = 0; i < orders.length; i++) ...[
                            if (i > 0) const Divider(height: 1),
                            ListTile(
                              dense: true,
                              title: Text(
                                '${orders[i].brand} ${orders[i].size} · '
                                '${formatTzs(orders[i].total)}',
                              ),
                              subtitle:
                                  Text(formatDateTime(orders[i].createdAt)),
                              trailing:
                                  AdminStatusBadge(status: orders[i].status),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminOrderDetailScreen(
                                    orderId: orders[i].id,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
