// lib/screens/vendor/vendor_order_screen.dart
// Live order management for LPG vendors (Usimamizi wa Oda).
//
// This screen never writes order status directly. Every action goes through
// OrderService so the state machine, audit trail and notification outbox stay
// authoritative. The 10-minute receipt finalizer runs on the gateway, not here.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/order_lifecycle.dart';
import '../../services/order_service.dart';
import '../../widgets/app_ui.dart';

import '../../core/theme_ext.dart';

class VendorOrderScreen extends StatefulWidget {
  const VendorOrderScreen({super.key});

  @override
  State<VendorOrderScreen> createState() => _VendorOrderScreenState();
}

class _VendorOrderScreenState extends State<VendorOrderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String get _vendorUid =>
      FirebaseAuth.instance.currentUser?.uid ??
      AuthService.instance.currentUserId ??
      '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri =
        Uri(scheme: 'tel', path: phoneNumber.replaceAll(RegExp(r'[^\d+]'), ''));
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imeshindwa kupiga simu kwa $phoneNumber')));
    }
  }

  Future<void> _runTransition(
    Future<OrderTransitionResult> Function() action, {
    required String successMessage,
  }) async {
    try {
      final result = await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success ? successMessage : result.message),
          backgroundColor: result.success
              ? context.gasColors.success
              : context.colors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hitilafu: $e'),
          backgroundColor: context.colors.error,
        ),
      );
    }
  }

  Future<void> _openOrder(String orderId, String status) async {
    if (status == OrderLifecycle.placed) {
      await OrderService.instance.markOrderAsSeen(orderId);
    }
  }

  Future<void> _acceptOrder(String orderId) => _runTransition(
        () => OrderService.instance.confirmOrder(orderId),
        successMessage: 'Oda imethibitishwa. Inaandaliwa.',
      );

  Future<void> _rejectOrder(String orderId) => _runTransition(
        () => OrderService.instance.rejectOrder(orderId),
        successMessage: 'Oda imekataliwa.',
      );

  Future<void> _markArrived(String orderId) => _runTransition(
        () => OrderService.instance.markArrived(orderId),
        successMessage:
            'Imewekwa kama imefika. Mteja athibitisha ndani ya dakika 10.',
      );

  Future<void> _undoArrived(String orderId) => _runTransition(
        () => OrderService.instance.undoArrived(orderId),
        successMessage: 'Oda imerudishwa njiani.',
      );

  Future<void> _startJourney(
    String orderId,
    int etaMinutes,
    String driverPhone,
  ) =>
      _runTransition(
        () => OrderService.instance.startJourney(
          orderId: orderId,
          etaMinutes: etaMinutes,
          driverPhone: driverPhone,
        ),
        successMessage: 'Safari imeanza. Mteja amejulishwa ETA na dereva.',
      );

  void _showStartJourneyDialog(String orderId) {
    int selectedEta = 20;
    final driverController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Anza Safari',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Weka ETA. Namba ya dereva ni ya hiari; mteja ataipata mara moja.',
                style: TextStyle(
                  fontSize: 12,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                children: [15, 20, 30, 45, 60].map((mins) {
                  final isSelected = selectedEta == mins;
                  return ChoiceChip(
                    label: Text('Dakika $mins'),
                    selected: isSelected,
                    selectedColor: context.colors.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? context.colors.onPrimary
                          : context.colors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (_) {
                      setModalState(() => selectedEta = mins);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: driverController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Namba ya dereva (hiari)',
                  hintText: '0712345678',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: context.colors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _startJourney(
                      orderId,
                      selectedEta,
                      driverController.text.trim(),
                    );
                  },
                  child: const Text(
                    'Anza Safari',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(driverController.dispose);
  }

  @override
  Widget build(BuildContext context) {
    if (_vendorUid.isEmpty) {
      return const Scaffold(
          body: Center(child: Text('Tafadhali ingia kama muuzaji')));
    }
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: const Text('Usimamizi wa Oda / Order Manager',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(text: 'Zote'),
            Tab(text: 'Mpya'),
            Tab(text: 'Njiani'),
            Tab(text: 'Kamilifu')
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('vendor_id', isEqualTo: _vendorUid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return AppEmptyState(
              icon: Icons.cloud_off,
              title: 'Imeshindikana kupata oda',
              message: '${snapshot.error}',
            );
          }
          if (!snapshot.hasData) {
            return Center(
                child:
                    CircularProgressIndicator(color: context.colors.primary));
          }
          final allDocs = snapshot.data?.docs ??
              <QueryDocumentSnapshot<Map<String, dynamic>>>[];

          final sortedDocs =
              List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(allDocs)
                ..sort((a, b) {
                  final Timestamp? tA = a.data()['created_at'] as Timestamp? ??
                      a.data()['createdAt'] as Timestamp?;
                  final Timestamp? tB = b.data()['created_at'] as Timestamp? ??
                      b.data()['createdAt'] as Timestamp?;
                  return (tB?.millisecondsSinceEpoch ?? 0)
                      .compareTo(tA?.millisecondsSinceEpoch ?? 0);
                });

          String statusOf(QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              OrderLifecycle.canonical(doc.data()['status']?.toString());

          final newOrders =
              sortedDocs.where((d) => OrderLifecycle.isNew(statusOf(d))).toList();

          final movingOrders = sortedDocs.where((d) {
            final st = statusOf(d);
            return st == OrderLifecycle.confirmed ||
                st == OrderLifecycle.onTheWay ||
                st == OrderLifecycle.deliveredPending;
          }).toList();

          final closedOrders = sortedDocs
              .where((d) => OrderLifecycle.isClosed(statusOf(d)))
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOrderList(sortedDocs, 'Oda Zote'),
              _buildOrderList(newOrders, 'Oda Mpya'),
              _buildOrderList(movingOrders, 'Zinazoenda'),
              _buildOrderList(closedOrders, 'Zilizokamilika'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderList(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String title,
  ) {
    if (docs.isEmpty) {
      return AppEmptyState(
        icon: Icons.inbox_outlined,
        title: 'Hakuna oda',
        message: 'Oda za "$title" hazipo kwa sasa.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: docs.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppSectionHeader(
              title: title,
              subtitle: '${docs.length} oda kwenye orodha hii.',
              icon: Icons.receipt_long_outlined,
            ),
          );
        }

        final doc = docs[index - 1];
        final data = doc.data();
        final String status =
            OrderLifecycle.canonical(data['status']?.toString());
        final String brand =
            (data['brand'] ?? data['brand_name'] ?? 'Gesi').toString();
        final String weight =
            (data['weight'] ?? data['size'] ?? '').toString();
        final int quantity = (data['quantity'] as num?)?.toInt() ?? 1;
        final double totalPrice =
            ((data['total_price'] ?? data['totalPrice'] ?? 0) as num)
                .toDouble();
        final String address = (data['delivery_address'] ??
                data['deliveryAddress'] ??
                'Dar es Salaam')
            .toString();
        final String phone =
            (data['contact_phone'] ?? data['consumerPhone'] ?? '').toString();
        final String customerName =
            (data['consumerName'] ?? data['consumer_name'] ?? 'Mteja')
                .toString();
        final String specialRequests =
            (data['special_requests'] ?? '').toString();
        final String receiverPhone = (data['receiver_phone'] ?? '').toString();
        final int? eta = (data['eta_minutes'] as num?)?.toInt();
        final String driverPhone =
            (data['driver_phone'] ?? data['driverPhone'] ?? '').toString();

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: context.colors.outlineVariant)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openOrder(doc.id, status),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'ODA #${OrderLifecycle.orderCode(doc.id)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: context.colors.onSurface)),
                            Text('Mteja: $customerName',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: context.colors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      if (phone.isNotEmpty)
                        SizedBox(
                          width: 96,
                          height: 32,
                          child: ElevatedButton.icon(
                            onPressed: () => _makePhoneCall(phone),
                            icon: const Icon(Icons.phone, size: 12),
                            label: const Text('Piga Simu',
                                style: TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                backgroundColor: context.gasColors.success,
                                foregroundColor: context.gasColors.onSuccess,
                                elevation: 0),
                          ),
                        ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                            weight.isEmpty
                                ? '$brand (x$quantity)'
                                : '$brand $weight (x$quantity)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusChip(status),
                    ],
                  ),
                  Text('Jumla: TZS ${totalPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                          color: context.colors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                  if (status == OrderLifecycle.onTheWay && eta != null)
                    Text(
                      'ETA: dakika $eta${driverPhone.isEmpty ? '' : ' • Dereva: $driverPhone'}',
                      style: TextStyle(
                          fontSize: 11,
                          color: context.colors.onSurfaceVariant),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 14, color: context.colors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text(address,
                              style: TextStyle(
                                  fontSize: 11, color: context.colors.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  if (specialRequests.isNotEmpty ||
                      receiverPhone.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: context.gasColors.infoContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: context.gasColors.infoContainer)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.info_outline,
                                size: 14, color: context.gasColors.info),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text('ℹ️ Maelezo ya Ziada:',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: context.gasColors.info)),
                            )
                          ]),
                          if (specialRequests.isNotEmpty)
                            Text('📝 Ombi: $specialRequests',
                                style: const TextStyle(fontSize: 11)),
                          if (receiverPhone.isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text('📞 Mpokeaji: $receiverPhone',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold)),
                                ),
                                TextButton(
                                    onPressed: () =>
                                        _makePhoneCall(receiverPhone),
                                    child: Text('Piga Simu',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: context.gasColors.success))),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                  const Divider(height: 20),
                  _buildOrderActions(doc, status),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderActions(
      QueryDocumentSnapshot<Map<String, dynamic>> doc, String status) {
    if (status == OrderLifecycle.placed || status == OrderLifecycle.seen) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _rejectOrder(doc.id),
              style: OutlinedButton.styleFrom(
                  foregroundColor: context.colors.error,
                  side: BorderSide(color: context.colors.error)),
              child: const Text('Kataa Oda', style: TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _acceptOrder(doc.id),
              style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.colors.onPrimary,
                  elevation: 0),
              child: const Text('Pokea Oda', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      );
    }
    if (status == OrderLifecycle.confirmed) {
      return SizedBox(
        width: double.infinity,
        height: 42,
        child: ElevatedButton.icon(
          onPressed: () => _showStartJourneyDialog(doc.id),
          style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.tertiary,
              foregroundColor: context.colors.onTertiary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          icon: const Icon(Icons.delivery_dining, size: 16),
          label: const Text('Anza Safari ➔',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ),
      );
    }
    if (status == OrderLifecycle.onTheWay) {
      return Row(
        children: [
          Expanded(
            child: Text('Njiani 🚚',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: context.colors.tertiary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _markArrived(doc.id),
            style: ElevatedButton.styleFrom(
                backgroundColor: context.gasColors.success,
                foregroundColor: context.gasColors.onSuccess,
                elevation: 0),
            icon: const Icon(Icons.check_circle_outline, size: 16),
            label: const Text('Imefika / Arrived',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }
    if (status == OrderLifecycle.deliveredPending) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: context.gasColors.infoContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.gasColors.infoContainer)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.hourglass_top,
                  size: 16, color: context.gasColors.info),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Inasubiri Ithibitishwe na Mteja',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: context.colors.onSurface)),
              )
            ]),
            const SizedBox(height: 4),
            Text(
                'Mzigo umewasilishwa. Mteja athibitishe kupokea au muda wa dakika 10 uishe kiotomatiki.',
                style: TextStyle(
                    fontSize: 11, color: context.colors.onSurfaceVariant)),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _undoArrived(doc.id),
                child: Text(
                  'Batilisha / Undo',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.colors.error,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (status == OrderLifecycle.disputed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: context.colors.errorContainer,
            borderRadius: BorderRadius.circular(8)),
        child: Text(
          'Mgogoro / Disputed. GasLink support inashughulikia. Piga 0767304776.',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: context.colors.onErrorContainer),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildStatusChip(String status) {
    Color color = context.colors.primary;
    String text = 'Mpya';
    if (status == OrderLifecycle.seen) {
      color = context.gasColors.info;
      text = 'Imeonekana';
    } else if (status == OrderLifecycle.confirmed) {
      color = context.gasColors.info;
      text = 'Imethibitishwa';
    } else if (status == OrderLifecycle.onTheWay) {
      color = context.colors.tertiary;
      text = 'Njiani';
    } else if (status == OrderLifecycle.deliveredPending) {
      color = context.gasColors.warning;
      text = 'Inasubiri mteja';
    } else if (status == OrderLifecycle.delivered) {
      color = context.gasColors.success;
      text = 'Kamilifu';
    } else if (status == OrderLifecycle.disputed) {
      color = context.colors.error;
      text = 'Mgogoro';
    } else if (status == OrderLifecycle.cancelled) {
      color = context.colors.error;
      text = 'Imeghairiwa';
    }
    return AppStatusPill(label: text, color: color);
  }
}
