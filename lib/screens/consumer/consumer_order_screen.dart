// ============================================================================
// FILE PATH: lib/screens/consumer/consumer_order_screen.dart
// ROLE: Live order tracking screen and post-order service review modal for LPG consumers.
// Enforces reinforced consumer master handshake validation and automatic 10-minute expirations.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/order_service.dart';

import '../../core/theme_ext.dart';

class ConsumerOrderScreen extends StatefulWidget {
  final String? orderId;
  final String vendorId;
  final String vendorName;
  final String brandName;
  final String cylinderSize;
  final double unitPrice;
  final double totalPrice;
  final String deliveryAddress;
  final String contactPhone;
  final String paymentMethod;
  final int quantity;
  final String specialRequests;
  final String receiverPhone;
  final String orderIntent;

  String get cylinderWeight => cylinderSize;

  const ConsumerOrderScreen({
    super.key,
    this.orderId,
    required this.vendorId,
    required this.vendorName,
    required this.brandName,
    required this.cylinderSize,
    required this.unitPrice,
    required this.totalPrice,
    required this.deliveryAddress,
    required this.contactPhone,
    required this.paymentMethod,
    required this.quantity,
    required this.specialRequests,
    required this.receiverPhone,
    required this.orderIntent,
  });

  @override
  State<ConsumerOrderScreen> createState() => _ConsumerOrderScreenState();
}

class _ConsumerOrderScreenState extends State<ConsumerOrderScreen> {
  String? _activeOrderId;
  bool _isCreatingOrder = true;

  final List<Map<String, String>> _orderSteps = [
    {
      'title': 'Oda Imetumwa / Placed',
      'subtitle': 'Inasubiri muuzaji kuipokea'
    },
    {
      'title': 'Oda Imepokelewa / Confirmed',
      'subtitle': 'Oda imekubaliwa na inaandaliwa 📦'
    },
    {
      'title': 'Gesi Yako Ipo Njiani / Dispatched',
      'subtitle': 'Dereva yuko njiani kuleta mzigo wako 15%'
    },
    {
      'title': 'Imewasili / Delivered',
      'subtitle': 'Oda imekamilika kikamilifu'
    },
  ];

  /// 🌟 PERSISTENT REVIEW CARD
  Widget _buildPersistentReviewCard(Map<String, dynamic> data) {
    final String currentStatus =
        (data['status'] as String? ?? '').toLowerCase().trim();
    final bool isDelivered =
        currentStatus == 'delivered' || currentStatus == 'completed';
    final bool isReviewed =
        data['is_reviewed'] == true || data['rated'] == true;

    if (!isDelivered || isReviewed) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      color: context.gasColors.warningContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.gasColors.warning, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star_rate_rounded,
                    color: context.gasColors.warning, size: 26),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Toa Tathmini / Rate & Review',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Oda yako imewasili! Hujaweka tathmini ya huduma hii. Bonyeza hapa chini kukamilisha.',
              style: TextStyle(fontSize: 12, color: context.colors.onSurface),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.gasColors.warning,
                  foregroundColor: context.gasColors.onWarning,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.rate_review, size: 16),
                label: const Text('Toa Tathmini Sasa',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: () => _showReviewSheet(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeOrder();
  }

  Future<void> _initializeOrder() async {
    if (widget.orderId != null && widget.orderId!.isNotEmpty) {
      setState(() {
        _activeOrderId = widget.orderId;
        _isCreatingOrder = false;
      });
      return;
    }

    try {
      final docRef = await FirebaseFirestore.instance.collection('orders').add({
        'consumer_uid': FirebaseAuth.instance.currentUser?.uid ?? '',
        'consumerUid': FirebaseAuth.instance.currentUser?.uid ?? '',
        'special_requests': widget.specialRequests,
        'receiver_phone': widget.receiverPhone,
        'vendor_id': widget.vendorId,
        'vendorId': widget.vendorId,
        'vendor_name': widget.vendorName,
        'vendorName': widget.vendorName,
        'brand_name': widget.brandName,
        'brand': widget.brandName,
        'cylinder_weight': widget.cylinderWeight,
        'weight': widget.cylinderWeight,
        'size': widget.cylinderWeight,
        'unit_price': widget.unitPrice,
        'total_price': widget.totalPrice,
        'total': widget.totalPrice,
        'totalPrice': widget.totalPrice,
        'quantity': widget.quantity,
        'delivery_address': widget.deliveryAddress,
        'deliveryAddress': widget.deliveryAddress,
        'contact_phone': widget.contactPhone,
        'consumerPhone': widget.contactPhone,
        'payment_method': widget.paymentMethod,
        'status': 'placed',
        'created_at': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      try {
        await NotificationService.instance.sendNotificationToUser(
          userId: widget.vendorId,
          title: 'Oda Mpya! / New Order!',
          body:
              'Umepokea oda mpya ya ${widget.brandName} (${widget.cylinderWeight}).',
          data: {
            'orderId': docRef.id,
            'type': 'new_order',
          },
        );
      } catch (e) {
        debugPrint('Failed to send vendor push notification: $e');
      }

      if (mounted) {
        setState(() {
          _activeOrderId = docRef.id;
          _isCreatingOrder = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isCreatingOrder = false);
    }
  }

  int _mapStatusToStep(String status) {
    switch (status.toLowerCase().trim()) {
      case 'accepted':
      case 'confirmed':
      case 'preparing':
        return 1;
      case 'on_the_way':
      case 'dispatched':
      case 'in_transit':
      case 'delivered_pending':
        return 2;
      case 'delivered':
      case 'completed':
        return 3;
      case 'seen':
      case 'placed':
      case 'pending':
      default:
        return 0;
    }
  }

  String _getStepSubtitle(int index, String status) {
    final String cleanStatus = status.toLowerCase().trim();
    if (index == 0) {
      if (cleanStatus == 'seen')
        return 'Muuzaji ameona oda yako na yuko mtandaoni'; // 🟢 Updated text
      return 'Oda Imetumwa • Inasubiri Muuzaji';
    }
    if (index == 1) {
      if (cleanStatus == 'accepted') return 'Oda Imepokelewa • Inaandaliwa 📦';
    }
    if (index == 2) {
      if (cleanStatus == 'on_the_way' ||
          cleanStatus == 'in_transit' ||
          cleanStatus == 'delivered_pending') {
        return 'Gesi Yako Ipo Njiani! 🛵';
      }
    }
    return _orderSteps[index]['subtitle']!;
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Simu ya $phoneNumber haikuweza kupigwa.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayId = _activeOrderId != null
        ? '#GL-${_activeOrderId!.substring(0, _activeOrderId!.length > 6 ? 6 : _activeOrderId!.length).toUpperCase()}'
        : '...';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text('Fuatilia Oda $displayId',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isCreatingOrder
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: context.colors.primary),
                  SizedBox(height: 12),
                  Text('Inatengeneza Oda Yako...',
                      style: TextStyle(color: context.colors.onSurfaceVariant)),
                ],
              ),
            )
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _activeOrderId != null
                  ? FirebaseFirestore.instance
                      .collection('orders')
                      .doc(_activeOrderId)
                      .snapshots()
                  : null,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data?.data() == null) {
                  return Center(
                      child: CircularProgressIndicator(color: context.colors.primary));
                }

                final data = snapshot.data!.data()!;
                final currentStatus = (data['status'] as String? ?? 'placed')
                    .toLowerCase()
                    .trim();
                final currentStep = _mapStatusToStep(currentStatus);
                final isCancelled =
                    currentStatus == 'cancelled' || currentStatus == 'rejected';
                final etaMinutes = (data['eta_minutes'] as num?)?.toInt() ?? 20;

                // ⏳ REINFORCED 10-MINUTE EXPIRY AUTO-APPROVAL SYSTEM LOGIC
                if (currentStatus == 'delivered_pending') {
                  final int deliveredAtMs =
                      data['_delivered_at_ms'] as int? ?? 0;
                  if (deliveredAtMs > 0) {
                    final int elapsedMins =
                        (DateTime.now().millisecondsSinceEpoch -
                                deliveredAtMs) ~/
                            60000;
                    if (elapsedMins >= 10) {
                      // Use OrderService so cylinder registration also runs
                      OrderService.instance.updateStatus(
                        _activeOrderId!,
                        'delivered',
                      );
                    }
                  }
                }

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    if (isCancelled) ...[
                      Card(
                        elevation: 0,
                        color: context.colors.errorContainer,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: context.colors.errorContainer)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Icon(Icons.cancel_outlined,
                                  color: context.colors.error, size: 40),
                              const SizedBox(height: 8),
                              Text('Oda Imesitishwa / Order Cancelled',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: context.colors.error)),
                              const SizedBox(height: 4),
                              Text(
                                  'Oda hii imeghairiwa. Tafadhali chagua muuzaji mwingine.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 12, color: context.colors.onSurface)),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: context.colors.error,
                                      foregroundColor: context.colors.onError,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8))),
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Rudi Kwenye Duka'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
// Persistent review card – stays until the user submits a review
                      _buildPersistentReviewCard(data),
                      const SizedBox(height: 16),
                    ],

                    Card(
                      elevation: 0,
                      color: context.colors.primaryContainer,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: context.colors.primaryContainer)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.delivery_dining,
                                size: 40, color: context.colors.primary),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Muda wa Kuwasili (ETA)',
                                      style: TextStyle(
                                          fontSize: 11, color: context.colors.onSurfaceVariant)),
                                  const SizedBox(height: 2),
                                  Text(
                                    isCancelled
                                        ? 'Imesitishwa'
                                        : (currentStep >= 3
                                            ? 'Imewasili!'
                                            : (currentStep == 0
                                                ? 'Inasubiri Muuzaji...'
                                                : 'Dakika $etaMinutes')),
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: context.colors.primary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 🏁 REINFORCED INTERACTIVE CONFIRMATION PANEL MATRIX
                    if (currentStatus == 'delivered_pending') ...[
                      Card(
                        elevation: 0,
                        color: context.gasColors.infoContainer,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                                color: context.gasColors.info, width: 1.5)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Icon(Icons.verified_user_outlined,
                                  color: context.gasColors.info, size: 36),
                              const SizedBox(height: 8),
                              Text(
                                  'Je, umepokea gesi yako? / Confirm Delivery',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: context.colors.onSurface)),
                              const SizedBox(height: 4),
                              Text(
                                  'Muuzaji ameweka alama kuwa oda imefika. Tafadhali thibitisha ikiwa umepokea mtungi na umelipa.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 11, color: context.colors.onSurfaceVariant)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        await FirebaseFirestore.instance
                                            .collection('orders')
                                            .doc(_activeOrderId)
                                            .update({
                                          'status': 'on_the_way',
                                          'fraud_alert_flag': true,
                                        });
                                      },
                                      style: OutlinedButton.styleFrom(
                                          foregroundColor: context.colors.error,
                                          side: BorderSide(
                                              color: context.colors.error)),
                                      child: const Text('Sijapokea',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        if (_activeOrderId == null ||
                                            _activeOrderId!.isEmpty) return;

                                        try {
                                          // 1. Update status to 'delivered' in Firestore
                                          // (This automatically fires handleOrderCompletion & metadata wiring safely in background)
                                          await OrderService.instance
                                              .updateStatus(
                                            _activeOrderId!,
                                            'delivered',
                                          );
                                          // 2. Pop the current tracking screen safely to prevent timer trapping
                                          if (context.mounted) {
                                            Navigator.of(context).pop();

                                            // 3. Open review & rating sheet cleanly on top of home screen
                                            _showReviewSheet();
                                          }
                                        } catch (e) {
                                          debugPrint(
                                              'Error completing order on Nimepokea tap: $e');
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: context.gasColors.success,
                                        foregroundColor: context.gasColors.onSuccess,
                                      ),
                                      child: const Text(
                                        'Nimepokea',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 🏁 CONSUMER FIRST ACCESS CLOSURE FOR ACTIVE STEPS
                    if ((currentStatus == 'on_the_way' ||
                            currentStatus == 'in_transit') &&
                        !isCancelled) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: context.gasColors.success,
                              foregroundColor: context.gasColors.onSuccess,
                              elevation: 0),
                          onPressed: () async {
                            if (_activeOrderId == null ||
                                _activeOrderId!.isEmpty) return;
                            try {
                              await OrderService.instance.updateStatus(
                                _activeOrderId!,
                                'delivered',
                              );
                              if (mounted) {
                                _showReviewSheet();
                              }
                            } catch (e) {
                              debugPrint('Error confirming delivery: $e');
                            }
                          },
                          icon:
                              const Icon(Icons.check_circle_outline, size: 16),
                          label: const Text(
                              'Nimepokea Gesi Tayari / Confirm Received',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: context.colors.outlineVariant)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Hatua ya Oda / Order Status',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            ...List.generate(_orderSteps.length, (index) {
                              final isDone =
                                  !isCancelled && index <= currentStep;
                              final isCurrent =
                                  !isCancelled && index == currentStep;
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: isDone
                                            ? context.colors.primary
                                            : context.colors.outlineVariant,
                                        child: Icon(
                                            isDone ? Icons.check : Icons.circle,
                                            size: 14,
                                            color: isDone
                                                ? context.colors.onPrimary
                                                : context.colors.onSurface),
                                      ),
                                      if (index < _orderSteps.length - 1)
                                        Container(
                                            width: 2,
                                            height: 36,
                                            color: isDone && index < currentStep
                                                ? context.colors.primary
                                                : context.colors.outlineVariant),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(_orderSteps[index]['title']!,
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: isCurrent
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: isDone
                                                    ? context.colors.onSurface
                                                    : context.colors.onSurfaceVariant)),
                                        Text(
                                            _getStepSubtitle(
                                                index, currentStatus),
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: context.colors.onSurfaceVariant)),
                                        const SizedBox(height: 16),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: context.colors.outlineVariant)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                    backgroundColor: context.colors.primary,
                                    child: Icon(Icons.person,
                                        color: context.colors.onPrimary)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(widget.vendorName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13)),
                                      Text('Muuzaji / Office Depot',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: context.colors.onSurfaceVariant)),
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _makePhoneCall(widget.contactPhone),
                                  icon: const Icon(Icons.phone, size: 12),
                                  label: const Text('Ofisini',
                                      style: TextStyle(fontSize: 10)),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: context.colors.primary,
                                      foregroundColor: context.colors.onPrimary,
                                      elevation: 0),
                                ),
                              ],
                            ),
                            if (currentStatus == 'on_the_way' ||
                                currentStatus == 'in_transit' ||
                                currentStatus == 'delivered_pending') ...[
                              Builder(
                                builder: (context) {
                                  final String driverPhone =
                                      data['driver_phone'] as String? ?? '';
                                  if (driverPhone.isEmpty)
                                    return const SizedBox.shrink();
                                  return Column(
                                    children: [
                                      const Divider(height: 16),
                                      Row(
                                        children: [
                                          CircleAvatar(
                                              backgroundColor:
                                                  context.colors.tertiaryContainer,
                                              child: Icon(
                                                  Icons.delivery_dining,
                                                  color: context.colors.tertiary,
                                                  size: 18)),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text('Dereva wa Mtungi',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13)),
                                                Text('Anakuja na mzigo wako',
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color: context.colors.onSurfaceVariant)),
                                              ],
                                            ),
                                          ),
                                          ElevatedButton.icon(
                                            onPressed: () =>
                                                _makePhoneCall(driverPhone),
                                            icon: const Icon(Icons.phone,
                                                size: 12),
                                            label: const Text('Piga Simu',
                                                style: TextStyle(fontSize: 10)),
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: context.gasColors.success,
                                                foregroundColor: context.gasColors.onSuccess,
                                                elevation: 0),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                            if (currentStep == 0 && !isCancelled) ...[
                              const Divider(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: TextButton.icon(
                                  onPressed: () async {
                                    if (_activeOrderId != null) {
                                      await FirebaseFirestore.instance
                                          .collection('orders')
                                          .doc(_activeOrderId)
                                          .update({'status': 'cancelled'});
                                    }
                                  },
                                  icon: Icon(Icons.cancel_outlined,
                                      color: context.colors.error, size: 16),
                                  label: Text(
                                      'Ghairi Oda Hii / Cancel Order',
                                      style: TextStyle(
                                          color: context.colors.error,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: context.colors.outlineVariant)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Muhtasari wa Oda',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            const Divider(),
                            _buildSummaryRow('Bidhaa',
                                '${widget.brandName} (${widget.cylinderWeight}) x${widget.quantity}'),
                            _buildSummaryRow('Anwani', widget.deliveryAddress),
                            if (widget.contactPhone.isNotEmpty)
                              _buildSummaryRow(
                                  'Simu ya Mteja', widget.contactPhone),
                            _buildSummaryRow('Gharama Kuu',
                                'TZS ${widget.totalPrice.toStringAsFixed(0)}'),
                            _buildSummaryRow(
                                'Njia ya Malipo',
                                widget.paymentMethod == 'mobile_money'
                                    ? '📱 Mobile Money'
                                    : '💵 Cash on Delivery'),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  void _showReviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true, // allow tap outside to close
      enableDrag: true, // allow slide down
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => RatingAndRefillSheet(
        vendorName: widget.vendorName,
        brandName: widget.brandName,
        orderId: _activeOrderId ?? '',
        vendorId: widget.vendorId,
        cylinderWeight: widget.cylinderWeight,
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant)),
          Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

class RatingAndRefillSheet extends StatefulWidget {
  final String vendorName;
  final String brandName;
  final String orderId;
  final String vendorId;
  final String cylinderWeight;

  const RatingAndRefillSheet({
    super.key,
    required this.vendorName,
    required this.brandName,
    required this.orderId,
    required this.vendorId,
    required this.cylinderWeight,
  });

  @override
  State<RatingAndRefillSheet> createState() => _RatingAndRefillSheetState();
}

class _RatingAndRefillSheetState extends State<RatingAndRefillSheet> {
  int _rating = 5;
  final List<String> _selectedTags = [];
  bool _enableReminder = true;
  // Aligned with ConsumerCylinderScreen day cycles instead of months
  String _reminderInterval = 'Every 30 days';
  final TextEditingController _commentController = TextEditingController();

  final List<Map<String, String>> _availableTags = [
    {'id': 'fast', 'label': '⚡ Mbio / Fast Delivery'},
    {'id': 'safe', 'label': '👍 Usalama / Safe Handle'},
    {'id': 'friendly', 'label': '😊 Lugha Nzuri / Polite'},
    {'id': 'ontime', 'label': '⏱️ Kwa Wakati / On Time'},
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (widget.orderId.isNotEmpty && uid.isNotEmpty) {
      try {
        final String commentText = _commentController.text.trim();

        // 1. Save review to reviews collection
        await FirebaseFirestore.instance.collection('reviews').add({
          'order_id': widget.orderId,
          'vendor_id': widget.vendorId,
          'vendor_name': widget.vendorName,
          'brand_name': widget.brandName,
          'rating': _rating,
          'tags': _selectedTags,
          'custom_comment': commentText,
          'enable_reminder': _enableReminder,
          'reminder_interval': _reminderInterval,
          'created_at': FieldValue.serverTimestamp(),
        });

        // 2. Mark order as reviewed so the persistent card disappears
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .update({
          'is_reviewed': true,
          'rated': true,
          'reviewed_at': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Review save error: $e');
      }
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Asante! Tathmini imerekodiwa.'),
          backgroundColor: context.gasColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header – no close (X) button
            const Text(
              'Tathmini Huduma / Post-Order Review',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Rating stars
            Center(
              child: Column(
                children: [
                  Text(
                    'Unaipeaje huduma ya ${widget.vendorName}?',
                    style: TextStyle(fontSize: 13, color: context.colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      return IconButton(
                        icon: Icon(
                          starIndex <= _rating ? Icons.star : Icons.star_border,
                          color: context.gasColors.warning,
                          size: 36,
                        ),
                        onPressed: () => setState(() => _rating = starIndex),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tags
            const Text(
              'Sifa Kuu / Quick Feedback Tags',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _availableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag['id']);
                return FilterChip(
                  label:
                      Text(tag['label']!, style: const TextStyle(fontSize: 11)),
                  selected: isSelected,
                  selectedColor: context.colors.primaryContainer,
                  checkmarkColor: context.colors.primary,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag['id']!);
                      } else {
                        _selectedTags.remove(tag['id']!);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Comment
            Text(
              'Maelezo ya Ziada / Custom Comments (Sio Lazima)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 3,
              keyboardType: TextInputType.multiline,
              style: TextStyle(fontSize: 13, color: context.colors.onSurface),
              decoration: InputDecoration(
                hintText: 'Andika maelezo au pongezi hapa...',
                hintStyle: TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant),
                contentPadding: const EdgeInsets.all(12),
                filled: true,
                fillColor: context.colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: context.colors.outlineVariant, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: context.colors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Reminder preference (kept – it is part of the review)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.colors.outlineVariant),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Kumbukumbu ya Kuagiza Tena',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Pata taarifa gesi inapokaribia kuisha',
                      style: TextStyle(fontSize: 11, color: context.colors.onSurfaceVariant),
                    ),
                    value: _enableReminder,
                    activeColor: context.colors.primary,
                    onChanged: (val) => setState(() => _enableReminder = val),
                  ),
                  if (_enableReminder) ...[
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mzunguko / Refill Cycle:',
                          style: TextStyle(fontSize: 12),
                        ),
                        DropdownButton<String>(
                          value: _reminderInterval,
                          underline: const SizedBox(),
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'Every 14 days',
                                child: Text('Every 14 days')),
                            DropdownMenuItem(
                                value: 'Every 30 days',
                                child: Text('Every 30 days')),
                            DropdownMenuItem(
                                value: 'Every 45 days',
                                child: Text('Every 45 days')),
                            DropdownMenuItem(
                                value: 'Every 60 days',
                                child: Text('Every 60 days')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _reminderInterval = val);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.colors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Hifadhi & Maliza / Submit & Complete',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Explicit Skip button (so user can come back later)
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Funga / Close (unaweza kufungua tena baadaye)',
                  style: TextStyle(
                    color: context.colors.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
