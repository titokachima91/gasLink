// lib/screens/vendor/vendor_order_screen.dart
// Live order tracking and management interface for LPG vendors (Usimamizi wa Oda).
// Integrated Dual-Lock completion matrix supporting 10-minute cash fallbacks and Awaiting Payment states.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child:
                    CircularProgressIndicator(color: context.colors.primary));
          }
          final allDocs = snapshot.data?.docs ??
              <QueryDocumentSnapshot<Map<String, dynamic>>>[];

          final sortedDocs =
              List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(allDocs)
                ..sort((a, b) {
                  final Timestamp? tA = a.data()['createdAt'] as Timestamp? ??
                      a.data()['created_at'] as Timestamp?;
                  final Timestamp? tB = b.data()['createdAt'] as Timestamp? ??
                      b.data()['created_at'] as Timestamp?;
                  if (tA == null || tB == null) return 0;
                  return tB.compareTo(tA);
                });

          final pendingOrders = sortedDocs.where((d) {
            final st = (d.data()['status'] as String? ?? 'pending')
                .toLowerCase()
                .trim();
            return st == 'pending' || st == 'placed' || st == 'seen';
          }).toList();

          final inTransitOrders = sortedDocs.where((d) {
            final st =
                (d.data()['status'] as String? ?? '').toLowerCase().trim();
            return st == 'accepted' ||
                st == 'on_the_way' ||
                st == 'in_transit' ||
                st == 'delivering' ||
                st == 'delivered_pending';
          }).toList();
// Automatically mark incoming pending/placed orders as seen when loaded in vendor view
          for (var doc in pendingOrders) {
            final st =
                (doc.data()['status'] ?? '').toString().toLowerCase().trim();
            if (st == 'pending' || st == 'placed') {
              doc.reference.update({
                'status': 'seen',
                'vendor_viewed': true,
                'vendorViewed': true,
              });
            }
          }
          final completedOrders = sortedDocs.where((d) {
            final st =
                (d.data()['status'] as String? ?? '').toLowerCase().trim();
            return st == 'delivered' || st == 'completed';
          }).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOrderList(sortedDocs, 'Oda Zote'),
              _buildOrderList(pendingOrders, 'Oda Mpya'),
              _buildOrderList(inTransitOrders, 'Zinazoenda'),
              _buildOrderList(completedOrders, 'Zilizokamilika'),
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
            (data['status'] ?? 'pending').toString().toLowerCase().trim();
        final String brand =
            (data['brand'] ?? data['brand_name'] ?? 'Gesi').toString();
        final String weight =
            (data['weight'] ?? data['size'] ?? '15kg').toString();
        final int quantity = (data['quantity'] as num?)?.toInt() ?? 1;
        final double totalPrice =
            (data['total_price'] ?? data['totalPrice'] ?? 0.0).toDouble();
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

        // ⏳ 10-MINUTE CASH FALLBACK AUTO-APPROVAL HANDLER
        if (status == 'delivered_pending') {
          final int deliveredAtMs = data['_delivered_at_ms'] as int? ?? 0;
          if (deliveredAtMs > 0) {
            final int elapsedMins =
                (DateTime.now().millisecondsSinceEpoch - deliveredAtMs) ~/
                    60000;
            if (elapsedMins >= 10) {
              doc.reference.update({
                'status': 'delivered',
                'finalized_at': FieldValue.serverTimestamp(),
              });
            }
          }
        }

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: context.colors.outlineVariant)),
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
                              'ODA #${doc.id.substring(0, doc.id.length > 6 ? 6 : doc.id.length).toUpperCase()}',
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
                InkWell(
                  onTap: () async {
                    if (status == 'pending' || status == 'placed') {
                      await doc.reference.update({
                        'status': 'seen',
                        'vendor_viewed': true,
                        'vendorViewed': true,
                        'updated_at': FieldValue.serverTimestamp()
                      });
                    }
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('$brand $weight (x$quantity)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusChip(status),
                    ],
                  ),
                ),
                Text('Jumla: TZS ${totalPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                        color: context.colors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
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
                if (specialRequests.isNotEmpty || receiverPhone.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: context.gasColors.infoContainer,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: context.gasColors.infoContainer)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.info_outline,
                              size: 14, color: context.gasColors.info),
                          SizedBox(width: 4),
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
                _buildOrderActions(doc, status, data),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderActions(
      DocumentSnapshot doc, String status, Map<String, dynamic> data) {
    if (status == 'pending' || status == 'placed' || status == 'seen') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => doc.reference.update({
                'status': 'cancelled',
                'updated_at': FieldValue.serverTimestamp()
              }),
              style: OutlinedButton.styleFrom(
                  foregroundColor: context.colors.error,
                  side: BorderSide(color: context.colors.error)),
              child: const Text('Kataa Oda', style: TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => doc.reference.update({
                'status': 'accepted',
                'updated_at': FieldValue.serverTimestamp()
              }),
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
    if (status == 'accepted') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Maelezo ya Usafirishaji / Logistics Dispatch:',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: context.colors.primary)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: 'Dakika (ETA)',
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8))),
                    onChanged: (val) =>
                        data['_tmp_eta_minutes'] = int.tryParse(val) ?? 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                        labelText: 'Namba ya Dereva',
                        hintText: '0712345678',
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8))),
                    onChanged: (val) => data['_tmp_driver_phone'] = val.trim(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: () async {
                final dPhone =
                    (data['_tmp_driver_phone'] ?? '').toString().trim();
                final etaMins = data['_tmp_eta_minutes'] as int? ?? 20;
                if (dPhone.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Tafadhali weka namba ya dereva.')));
                  return;
                }
                await doc.reference.update({
                  'driver_phone': dPhone,
                  'eta_minutes': etaMins,
                  'status': 'on_the_way',
                  'updated_at': FieldValue.serverTimestamp(),
                });
              },
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
          ),
        ],
      );
    }
    if (status == 'on_the_way' ||
        status == 'in_transit' ||
        status == 'delivering') {
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
            onPressed: () => doc.reference.update({
              'status': 'delivered_pending',
              '_delivered_at_ms': DateTime.now().millisecondsSinceEpoch,
              'updated_at': FieldValue.serverTimestamp(),
            }),
            style: ElevatedButton.styleFrom(
                backgroundColor: context.gasColors.success,
                foregroundColor: context.gasColors.onSuccess,
                elevation: 0),
            icon: const Icon(Icons.check_circle_outline, size: 16),
            label: const Text('Imefika / Delivered',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }
// 🟢 AWAITING CONSUMER CONFIRMATION (No manual vendor payment gate)
    if (status == 'delivered_pending') {
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
            SizedBox(height: 4),
            Text(
                'Mzigo umewasilishwa. Inasubiri mteja athibitishe kupokea au muda wa dakika 10 uishe kiotomatiki.',
                style: TextStyle(
                    fontSize: 11, color: context.colors.onSurfaceVariant)),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildStatusChip(String status) {
    Color color = context.colors.primary;
    String text = 'Mpya';
    if (status == 'accepted') {
      color = context.gasColors.info;
      text = 'Imepokelewa';
    } else if (status == 'on_the_way' ||
        status == 'in_transit' ||
        status == 'delivering') {
      color = context.colors.tertiary;
      text = 'Njiani';
    } else if (status == 'delivered_pending') {
      color = context.gasColors.warning;
      text = 'Awaiting';
    } else if (status == 'delivered' || status == 'completed') {
      color = context.gasColors.success;
      text = 'Kamilifu';
    } else if (status == 'cancelled' || status == 'rejected') {
      color = context.colors.error;
      text = 'Imeghairiwa';
    }
    return AppStatusPill(label: text, color: color);
  }
}
