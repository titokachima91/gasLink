// ============================================================================
// FILE PATH: lib/screens/consumer/consumer_order_screen.dart
// ROLE: Live order tracking screen and post-order service review modal for LPG consumers.
// Enforces reinforced consumer master handshake validation and automatic 10-minute expirations.
// ============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/localized_messages.dart';
import '../../services/notification_dispatcher.dart';
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

  List<Map<String, String>> _orderSteps(AppLocalizations l10n) => [
    {
      'title': l10n.orderStepPlaced,
      'subtitle': l10n.orderStepPlacedBody
    },
    {
      'title': l10n.orderStepConfirmed,
      'subtitle': l10n.orderStepConfirmedBody
    },
    {
      'title': l10n.orderStepDispatched,
      'subtitle': l10n.orderStepDispatchedBody
    },
    {
      'title': l10n.orderStepDelivered,
      'subtitle': l10n.orderStepDeliveredBody
    },
  ];

  /// 🌟 PERSISTENT REVIEW CARD
  Widget _buildPersistentReviewCard(Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context);
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
                Expanded(
                  child: Text(
                    l10n.reviewPromptTitle,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.reviewPromptBody,
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
                label: Text(l10n.reviewNow,
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

      if (mounted) {
        setState(() {
          _activeOrderId = docRef.id;
          _isCreatingOrder = false;
        });
      }

      // Do not block tracking on push/SMS delivery.
      unawaited(_notifyOrderCreated(docRef.id));
    } catch (e) {
      if (mounted) setState(() => _isCreatingOrder = false);
    }
  }

  Future<void> _notifyOrderCreated(String orderId) async {
    final l10n = await loadLocalizedMessages();
    final consumerUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    try {
      await NotificationDispatcher.instance.dispatchToUser(
        userId: widget.vendorId,
        title: l10n.newOrderNotificationTitle,
        body: l10n.newOrderNotificationBody(
            widget.brandName, widget.cylinderWeight),
        smsMessage: l10n.smsOrderPlacedVendor(
            widget.brandName, widget.cylinderWeight),
        data: {
          'orderId': orderId,
          'type': 'new_order',
        },
      );
    } catch (e) {
      debugPrint('Failed to send vendor notification: $e');
    }

    if (consumerUid.isEmpty) return;
    try {
      await NotificationDispatcher.instance.dispatchToUser(
        userId: consumerUid,
        title: l10n.orderPlacedNotificationTitle,
        body: l10n.orderPlacedNotificationBody(
            widget.brandName, widget.cylinderWeight),
        smsMessage: l10n.smsOrderPlacedCustomer(
            widget.brandName, widget.cylinderWeight),
        data: {
          'orderId': orderId,
          'type': 'order_created',
          'status': 'placed',
        },
      );
    } catch (e) {
      debugPrint('Failed to send customer notification: $e');
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

  String _getStepSubtitle(
      int index, String status, AppLocalizations l10n) {
    final String cleanStatus = status.toLowerCase().trim();
    if (index == 0) {
      if (cleanStatus == 'seen') return l10n.orderSeenSubtitle;
      return l10n.orderPlacedSubtitle;
    }
    if (index == 1) {
      if (cleanStatus == 'accepted') return l10n.orderAcceptedSubtitle;
    }
    if (index == 2) {
      if (cleanStatus == 'on_the_way' ||
          cleanStatus == 'in_transit' ||
          cleanStatus == 'delivered_pending') {
        return l10n.orderOnTheWaySubtitle;
      }
    }
    return _orderSteps(l10n)[index]['subtitle']!;
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context).callFailed(phoneNumber))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = _orderSteps(l10n);
    final displayId = _activeOrderId != null
        ? '#GL-${_activeOrderId!.substring(0, _activeOrderId!.length > 6 ? 6 : _activeOrderId!.length).toUpperCase()}'
        : '...';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(l10n.trackOrderTitle(displayId),
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
                  Text(l10n.creatingOrder,
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
                              Text(l10n.orderCancelledTitle,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: context.colors.error)),
                              const SizedBox(height: 4),
                              Text(
                                  l10n.orderCancelledBody,
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
                                  child: Text(l10n.backToShop),
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
                                  Text(l10n.etaLabel,
                                      style: TextStyle(
                                          fontSize: 11, color: context.colors.onSurfaceVariant)),
                                  const SizedBox(height: 2),
                                  Text(
                                    isCancelled
                                        ? l10n.etaCancelled
                                        : (currentStep >= 3
                                            ? l10n.etaDelivered
                                            : (currentStep == 0
                                                ? l10n.etaWaiting
                                                : l10n.minutesShort(etaMinutes))),
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
                                  l10n.confirmDeliveryTitle,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: context.colors.onSurface)),
                              const SizedBox(height: 4),
                              Text(
                                  l10n.confirmDeliveryBody,
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
                                      child: Text(l10n.notReceived,
                                          style: const TextStyle(
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
                                      child: Text(
                                        l10n.received,
                                        style: const TextStyle(
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
                          label: Text(
                              l10n.confirmReceived,
                              style: const TextStyle(
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
                            Text(l10n.orderStatusSection,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            ...List.generate(steps.length, (index) {
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
                                      if (index < steps.length - 1)
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
                                        Text(steps[index]['title']!,
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
                                                index, currentStatus, l10n),
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
                                      Text(l10n.orderVendorRole,
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
                                  label: Text(l10n.callOffice,
                                      style: const TextStyle(fontSize: 10)),
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
                                                Text(l10n.driverTitle,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13)),
                                                Text(l10n.driverSubtitle,
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
                                            label: Text(l10n.callDriver,
                                                style: const TextStyle(fontSize: 10)),
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
                                      l10n.cancelOrder,
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
                            Text(l10n.orderSummary,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            const Divider(),
                            _buildSummaryRow(l10n.summaryProduct,
                                '${widget.brandName} (${widget.cylinderWeight}) x${widget.quantity}'),
                            _buildSummaryRow(l10n.summaryAddress, widget.deliveryAddress),
                            if (widget.contactPhone.isNotEmpty)
                              _buildSummaryRow(
                                  l10n.summaryConsumerPhone, widget.contactPhone),
                            _buildSummaryRow(l10n.summaryTotal,
                                'TZS ${widget.totalPrice.toStringAsFixed(0)}'),
                            _buildSummaryRow(
                                l10n.summaryPayment,
                                widget.paymentMethod == 'mobile_money'
                                    ? l10n.paymentMobileMoney
                                    : l10n.paymentCash),
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

  final List<Map<String, String>> Function(AppLocalizations) _availableTags =
      (l10n) => [
            {'id': 'fast', 'label': l10n.tagFast},
            {'id': 'safe', 'label': l10n.tagSafe},
            {'id': 'friendly', 'label': l10n.tagFriendly},
            {'id': 'ontime', 'label': l10n.tagOnTime},
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
          content: Text(AppLocalizations.of(context).reviewThanks),
          backgroundColor: context.gasColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tags = _availableTags(l10n);
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
            Text(
              l10n.postOrderReview,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Rating stars
            Center(
              child: Column(
                children: [
                  Text(
                    l10n.rateVendor(widget.vendorName),
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
            Text(
              l10n.feedbackTags,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: tags.map((tag) {
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
              l10n.customComments,
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
                hintText: l10n.commentHint,
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
                    title: Text(
                      l10n.reminderTitle,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      l10n.reminderSubtitle,
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
                        Text(
                          l10n.refillCycleLabel,
                          style: const TextStyle(fontSize: 12),
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
                child: Text(
                  l10n.submitComplete,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
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
                  l10n.closeReview,
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
