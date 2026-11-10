import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme_ext.dart';
import '../../models/admin_models.dart';
import '../../models/order.dart';
import '../../models/vendor.dart';
import '../../services/admin_service.dart';
import '../../utils/formatters.dart';
import 'widgets/admin_ui.dart';
import 'admin_order_detail_screen.dart';

class AdminVendorDetailScreen extends StatefulWidget {
  const AdminVendorDetailScreen({super.key, required this.vendorId});

  final String vendorId;

  @override
  State<AdminVendorDetailScreen> createState() =>
      _AdminVendorDetailScreenState();
}

class _AdminVendorDetailScreenState extends State<AdminVendorDetailScreen> {
  bool _busy = false;

  Future<void> _setStatus(
    Vendor vendor,
    String status, {
    bool requireReason = false,
  }) async {
    String reason = '';
    if (requireReason) {
      final result = await _askReason(
        title: status == VendorStatus.rejected
            ? 'Reject vendor'
            : 'Suspend vendor',
        hint: status == VendorStatus.rejected
            ? 'Why was this application rejected?'
            : 'Why is this vendor being suspended?',
      );
      if (result == null) return;
      reason = result;
    }

    setState(() => _busy = true);
    try {
      await AdminService.instance.updateVendorStatus(
        vendorId: vendor.id,
        status: status,
        reason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Vendor status updated to ${VendorStatus.label(status)}'),
          backgroundColor: context.gasColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update vendor: $error'),
          backgroundColor: context.colors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askReason({
    required String title,
    required String hint,
    bool required = true,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final reason = controller.text.trim();
              if (required && reason.isEmpty) return;
              Navigator.pop(dialogContext, reason);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return null;
    return result.trim();
  }

  Future<void> _setVerified(Vendor vendor, bool verified) async {
    final reason = await _askReason(
      title: verified ? 'Verify vendor' : 'Remove verification',
      hint: verified
          ? 'Optional note for the audit trail'
          : 'Why is verification being removed?',
      required: !verified,
    );
    if (reason == null) return;

    setState(() => _busy = true);
    try {
      await AdminService.instance.setVendorVerified(
        vendorId: vendor.id,
        verified: verified,
        reason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            verified ? 'Vendor is now verified' : 'Vendor verification removed',
          ),
          backgroundColor: context.gasColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update verification: $error'),
          backgroundColor: context.colors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openDocument(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this document link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor profile')),
      body: StreamBuilder<Vendor?>(
        stream: AdminService.instance.streamVendor(widget.vendorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AdminLoading();
          }
          if (snapshot.hasError) {
            return AdminErrorState(message: '${snapshot.error}');
          }
          final vendor = snapshot.data;
          if (vendor == null) {
            return const AdminEmptyState(
              icon: Icons.storefront_outlined,
              title: 'Vendor not found',
              message: 'This profile may have been deleted.',
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _VendorHeader(vendor: vendor),
              const SizedBox(height: 12),
              _LifecycleActions(
                vendor: vendor,
                busy: _busy,
                onApprove: () => _setStatus(vendor, VendorStatus.active),
                onReject: () => _setStatus(
                  vendor,
                  VendorStatus.rejected,
                  requireReason: true,
                ),
                onSuspend: () => _setStatus(
                  vendor,
                  VendorStatus.suspended,
                  requireReason: true,
                ),
                onReactivate: () => _setStatus(vendor, VendorStatus.active),
              ),
              const SizedBox(height: 22),
              const AdminSectionHeader(
                title: 'Trust & verification',
                subtitle: 'Explicit admin decision shown as a public badge.',
              ),
              _VerificationCard(
                vendor: vendor,
                busy: _busy,
                onVerify: () => _setVerified(vendor, true),
                onUnverify: () => _setVerified(vendor, false),
              ),
              const SizedBox(height: 22),
              const AdminSectionHeader(
                title: 'Business & contact',
                subtitle: 'Identity, location and operating profile.',
              ),
              AdminCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: [
                    AdminInfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: vendor.phone,
                    ),
                    AdminInfoRow(
                      icon: Icons.alternate_email,
                      label: 'Email',
                      value: vendor.email,
                    ),
                    AdminInfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Location',
                      value: [
                        vendor.street,
                        vendor.ward,
                        vendor.areaText,
                        vendor.district,
                        vendor.region,
                      ].where((part) => part.trim().isNotEmpty).join(', '),
                    ),
                    AdminInfoRow(
                      icon: Icons.schedule,
                      label: 'Opening hours',
                      value: vendor.openingHours,
                    ),
                    AdminInfoRow(
                      icon: Icons.payments_outlined,
                      label: 'Payments',
                      value: [
                        if (vendor.acceptsCash) 'Cash',
                        if (vendor.acceptsMobileMoney) 'Mobile money',
                      ].join(' · '),
                    ),
                    AdminInfoRow(
                      icon: Icons.percent,
                      label: 'Commission',
                      value: formatPercent(vendor.commissionRate),
                    ),
                    AdminInfoRow(
                      icon: Icons.workspace_premium_outlined,
                      label: 'Tier',
                      value: 'Tier ${vendor.currentTier}',
                    ),
                    AdminInfoRow(
                      icon: Icons.fact_check_outlined,
                      label: 'Profile',
                      value: '${vendor.completionPercentage}% complete',
                    ),
                    AdminInfoRow(
                      icon: Icons.local_shipping_outlined,
                      label: 'Deliveries',
                      value: '${vendor.completedOrders} completed',
                    ),
                    AdminInfoRow(
                      icon: Icons.star_border,
                      label: 'Rating',
                      value: vendor.rating.toStringAsFixed(1),
                    ),
                    AdminInfoRow(
                      icon: Icons.badge_outlined,
                      label: 'Owner UID',
                      value:
                          vendor.ownerUid.isEmpty ? vendor.id : vendor.ownerUid,
                    ),
                    AdminInfoRow(
                      icon: Icons.event_outlined,
                      label: 'Created',
                      value: formatDateTime(vendor.createdAt),
                    ),
                    if (vendor.statusReason.isNotEmpty)
                      AdminInfoRow(
                        icon: Icons.notes_outlined,
                        label: 'Status note',
                        value: vendor.statusReason,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const AdminSectionHeader(
                title: 'KYC documents',
                subtitle: 'Open the evidence supplied during onboarding.',
              ),
              AdminCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _DocumentTile(
                      label: 'Shop front photo',
                      url: vendor.imageUrl,
                      icon: Icons.storefront_outlined,
                      onOpen: _openDocument,
                    ),
                    const Divider(height: 1),
                    _DocumentTile(
                      label: 'Business licence',
                      url: vendor.businessLicenseUrl,
                      icon: Icons.description_outlined,
                      onOpen: _openDocument,
                    ),
                    const Divider(height: 1),
                    _DocumentTile(
                      label: 'WMA sticker',
                      url: vendor.wmaStickerUrl,
                      icon: Icons.verified_outlined,
                      onOpen: _openDocument,
                    ),
                    const Divider(height: 1),
                    _DocumentTile(
                      label: 'Super-dealer proof',
                      url: vendor.superDealerProofUrl,
                      icon: Icons.receipt_long_outlined,
                      onOpen: _openDocument,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const AdminSectionHeader(
                title: 'Catalogue',
                subtitle: 'Products published by this vendor.',
              ),
              StreamBuilder<List<AdminProduct>>(
                stream: AdminService.instance.streamVendorProducts(vendor.id),
                builder: (context, productSnapshot) {
                  if (productSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const AdminCard(child: AdminLoading());
                  }
                  if (productSnapshot.hasError) {
                    return AdminCard(
                      child: Text('${productSnapshot.error}'),
                    );
                  }
                  final products =
                      productSnapshot.data ?? const <AdminProduct>[];
                  if (products.isEmpty) {
                    return const AdminCard(
                      child: Text('No products are published yet.'),
                    );
                  }
                  return AdminCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < products.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.local_fire_department,
                              color: context.colors.primary,
                            ),
                            title: Text(
                              '${products[i].brand} ${products[i].size}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${products[i].category} · '
                              '${formatTzs(products[i].price)}',
                            ),
                            trailing: AdminStatusBadge(
                              status:
                                  products[i].inStock ? 'active' : 'suspended',
                              label: products[i].inStock ? 'In stock' : 'Out',
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
                title: 'Recent orders',
                subtitle: 'Most recent orders handled by this vendor.',
              ),
              StreamBuilder<List<Order>>(
                stream: AdminService.instance
                    .streamVendorOrders(vendor.id, limit: 10),
                builder: (context, orderSnapshot) {
                  if (orderSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const AdminCard(child: AdminLoading());
                  }
                  if (orderSnapshot.hasError) {
                    return AdminCard(child: Text('${orderSnapshot.error}'));
                  }
                  final orders = orderSnapshot.data ?? const <Order>[];
                  if (orders.isEmpty) {
                    return const AdminCard(
                      child: Text('No orders for this vendor yet.'),
                    );
                  }
                  return AdminCard(
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
                            subtitle: Text(formatDateTime(orders[i].createdAt)),
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
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VendorHeader extends StatelessWidget {
  const _VendorHeader({required this.vendor});

  final Vendor vendor;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminAvatar(name: vendor.displayName, size: 56),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vendor.displayName,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  vendor.district.isEmpty
                      ? 'District not provided'
                      : vendor.district,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    AdminStatusBadge(
                      status: vendor.status,
                      label: vendor.statusLabel,
                    ),
                    if (vendor.verified)
                      AdminKeyValueChip(
                        label: 'Trust',
                        value: 'Verified',
                        color: context.gasColors.success,
                      ),
                    AdminKeyValueChip(
                      label: 'Tier',
                      value: '${vendor.currentTier}',
                    ),
                    AdminKeyValueChip(
                      label: 'Profile',
                      value: '${vendor.completionPercentage}%',
                      color: context.gasColors.info,
                    ),
                  ],
                ),
                if (vendor.statusReason.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    vendor.statusReason,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LifecycleActions extends StatelessWidget {
  const _LifecycleActions({
    required this.vendor,
    required this.busy,
    required this.onApprove,
    required this.onReject,
    required this.onSuspend,
    required this.onReactivate,
  });

  final Vendor vendor;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onSuspend;
  final VoidCallback onReactivate;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (vendor.isPending) {
      children.add(FilledButton.icon(
        onPressed: busy ? null : onApprove,
        icon: const Icon(Icons.check),
        label: const Text('Approve'),
      ));
      children.add(OutlinedButton.icon(
        onPressed: busy ? null : onReject,
        icon: const Icon(Icons.close),
        label: const Text('Reject'),
      ));
    } else if (vendor.isActive) {
      children.add(OutlinedButton.icon(
        onPressed: busy ? null : onSuspend,
        icon: const Icon(Icons.pause_circle_outline),
        label: const Text('Suspend'),
      ));
    } else {
      children.add(FilledButton.icon(
        onPressed: busy ? null : onReactivate,
        icon: const Icon(Icons.play_circle_outline),
        label: const Text('Reactivate'),
      ));
      children.add(OutlinedButton.icon(
        onPressed: busy ? null : onReject,
        icon: const Icon(Icons.block),
        label: const Text('Reject'),
      ));
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final child in children) SizedBox(width: 160, child: child),
      ],
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({
    required this.vendor,
    required this.busy,
    required this.onVerify,
    required this.onUnverify,
  });

  final Vendor vendor;
  final bool busy;
  final VoidCallback onVerify;
  final VoidCallback onUnverify;

  @override
  Widget build(BuildContext context) {
    final verified = vendor.verified;
    final detail = [
      if (vendor.verifiedAt != null)
        'Verified ${formatDateTime(vendor.verifiedAt)}',
      if (vendor.verifiedBy.isNotEmpty) 'by ${vendor.verifiedBy}',
    ].join(' ');

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                verified ? Icons.verified : Icons.gpp_maybe_outlined,
                color: verified
                    ? context.gasColors.success
                    : context.colors.outline,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verified ? 'Verified vendor' : 'Not verified',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      verified
                          ? 'The public badge is visible to consumers.'
                          : 'The public badge is hidden from consumers.',
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
          if (verified && detail.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              detail,
              style: TextStyle(
                fontSize: 11,
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (verified)
            OutlinedButton.icon(
              onPressed: busy ? null : onUnverify,
              icon: const Icon(Icons.remove_moderator_outlined),
              label: const Text('Remove verification'),
            )
          else if (vendor.isActive)
            FilledButton.icon(
              onPressed: busy ? null : onVerify,
              icon: const Icon(Icons.verified),
              label: const Text('Verify vendor'),
            )
          else
            Text(
              'Activate the vendor before granting verification.',
              style: TextStyle(
                fontSize: 12,
                color: context.colors.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.label,
    required this.url,
    required this.icon,
    required this.onOpen,
  });

  final String label;
  final String? url;
  final IconData icon;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final value = url?.trim() ?? '';
    final available = value.isNotEmpty;
    return ListTile(
      leading: Icon(
        icon,
        color: available ? context.colors.primary : context.colors.outline,
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(available ? 'Tap to open' : 'Not provided'),
      trailing: available
          ? const Icon(Icons.open_in_new, size: 18)
          : Icon(Icons.warning_amber_rounded,
              size: 18, color: context.gasColors.warning),
      onTap: available ? () => onOpen(value) : null,
    );
  }
}
