// ============================================================================
// FILE PATH: lib/screens/consumer/consumer_order_screen.dart
// ROLE: Live order tracking and receipt confirmation for LPG consumers.
//
// The buyer sees two first-step substeps (sent / vendor opened), the vendor
// number only after confirmation, the ETA only after the journey starts, and
// a 10-minute receipt window once the vendor marks the order arrived.
// ============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/order_lifecycle.dart';
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
  bool _busy = false;
  Timer? _clock;

  List<Map<String, String>> _orderSteps(AppLocalizations l10n) => [
        {
          'title': l10n.orderStepPlaced,
          'subtitle': l10n.orderStepPlacedBody,
        },
        {
          'title': l10n.orderStepConfirmed,
          'subtitle': l10n.orderStepConfirmedBody,
        },
        {
          'title': l10n.orderStepDispatched,
          'subtitle': l10n.orderStepDispatchedBody,
        },
        {
          'title': l10n.orderStepDelivered,
          'subtitle': l10n.orderStepDeliveredBody,
        },
      ];

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted && _activeOrderId != null) setState(() {});
    });
    _initializeOrder();
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  Future<void> _initializeOrder() async {
    if (widget.orderId != null && widget.orderId!.isNotEmpty) {
      setState(() {
        _activeOrderId = widget.orderId;
        _isCreatingOrder = false;
      });
      return;
    }

    // Legacy navigation fallback. Checkout uses OrderService.placeOrder, but
    // this keeps old deep links from silently dropping the vendor alert.
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
        'status': OrderLifecycle.placed,
        'created_at': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _activeOrderId = docRef.id;
          _isCreatingOrder = false;
        });
      }

      unawaited(OrderService.instance.notifyVendorNewOrder(
        orderId: docRef.id,
        vendorId: widget.vendorId,
        brand: widget.brandName,
        size: widget.cylinderWeight,
      ));
    } catch (e) {
      debugPrint('Could not create fallback order: $e');
      if (mounted) setState(() => _isCreatingOrder = false);
    }
  }

  int _mapStatusToStep(String status) {
    switch (OrderLifecycle.canonical(status)) {
      case OrderLifecycle.confirmed:
        return 1;
      case OrderLifecycle.onTheWay:
      case OrderLifecycle.deliveredPending:
        return 2;
      case OrderLifecycle.delivered:
        return 3;
      case OrderLifecycle.placed:
      case OrderLifecycle.seen:
      default:
        return 0;
    }
  }

  String _getStepSubtitle(
      int index, String status, AppLocalizations l10n) {
    final cleanStatus = OrderLifecycle.canonical(status);
    if (index == 0) {
      if (cleanStatus == OrderLifecycle.seen) return l10n.orderSeenSubtitle;
      return l10n.orderPlacedSubtitle;
    }
    if (index == 2 &&
        (cleanStatus == OrderLifecycle.onTheWay ||
            cleanStatus == OrderLifecycle.deliveredPending)) {
      return l10n.orderOnTheWaySubtitle;
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
            content:
                Text(AppLocalizations.of(context).callFailed(phoneNumber))),
      );
    }
  }

  Future<void> _runAction(
    Future<OrderTransitionResult> Function() action, {
    required String successMessage,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
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
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmReceipt() async {
    if (_activeOrderId == null) return;
    final result = await OrderService.instance.confirmReceipt(_activeOrderId!);
    if (!mounted) return;
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).orderStepDeliveredBody),
          backgroundColor: context.gasColors.success,
        ),
      );
      _showReviewSheet();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: context.colors.error,
        ),
      );
    }
  }

  Future<void> _denyReceipt() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hukupokea mtungi?'),
        content: const Text(
          'GasLink support atashughulikia oda hii. Muuzaji atajulishwa na tutakupigia.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Ghairi'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ndio, sikupokea'),
          ),
        ],
      ),
    );
    if (confirmed != true || _activeOrderId == null) return;
    await _runAction(
      () => OrderService.instance.denyReceipt(_activeOrderId!),
      successMessage: 'Taarifa imepokelewa. GasLink support atakupigia.',
    );
  }

  Future<void> _cancelOrder() async {
    if (_activeOrderId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sitisha oda?'),
        content: const Text('Muuzaji atajulishwa kuwa oda imesitishwa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Ghairi'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sitisha oda'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _runAction(
      () => OrderService.instance.cancelOrder(
        orderId: _activeOrderId!,
        actor: OrderLifecycle.actorConsumer,
        reason: 'consumer_cancelled',
      ),
      successMessage: 'Oda imesitishwa.',
    );
  }

  int? _remainingConfirmSeconds(Map<String, dynamic> data) {
    final int deliveredAtMs = (data['_delivered_at_ms'] as num?)?.toInt() ?? 0;
    DateTime? start;
    if (deliveredAtMs > 0) {
      start = DateTime.fromMillisecondsSinceEpoch(deliveredAtMs);
    } else if (data['delivered_pending_at'] is Timestamp) {
      start = (data['delivered_pending_at'] as Timestamp).toDate();
    }
    if (start == null) return null;
    final remaining = 600 - DateTime.now().difference(start).inSeconds;
    return remaining.clamp(0, 600);
  }

  String _etaText(
    AppLocalizations l10n,
    String status,
    int? etaMinutes,
    int? remainingSeconds,
  ) {
    if (status == OrderLifecycle.cancelled) return l10n.etaCancelled;
    if (status == OrderLifecycle.disputed) return l10n.orderDisputeTitle;
    if (status == OrderLifecycle.delivered) return l10n.etaDelivered;
    if (status == OrderLifecycle.deliveredPending) {
      final minutes = ((remainingSeconds ?? 600) / 60).ceil();
      return l10n.confirmWithinMinutes(minutes);
    }
    if (status == OrderLifecycle.onTheWay && etaMinutes != null) {
      return l10n.minutesShort(etaMinutes);
    }
    if (status == OrderLifecycle.confirmed) return l10n.etaPreparing;
    return l10n.etaWaiting;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = _orderSteps(l10n);
    final displayId = _activeOrderId != null
        ? '#GL-${OrderLifecycle.orderCode(_activeOrderId!)}'
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
                  const SizedBox(height: 12),
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
                      child: CircularProgressIndicator(
                          color: context.colors.primary));
                }

                final data = snapshot.data!.data()!;
                final currentStatus =
                    OrderLifecycle.canonical(data['status']?.toString());
                final currentStep = _mapStatusToStep(currentStatus);
                final isCancelled = currentStatus == OrderLifecycle.cancelled;
                final isDisputed = currentStatus == OrderLifecycle.disputed;
                final etaMinutes = (data['eta_minutes'] as num?)?.toInt();
                final remainingSeconds = _remainingConfirmSeconds(data);
                final vendorPhone =
                    (data['vendor_phone'] ?? data['vendorPhone'] ?? '')
                        .toString();
                final driverPhone =
                    (data['driver_phone'] ?? data['driverPhone'] ?? '')
                        .toString();
                final canSeeVendorPhone = currentStatus ==
                        OrderLifecycle.confirmed ||
                    currentStatus == OrderLifecycle.onTheWay ||
                    currentStatus == OrderLifecycle.deliveredPending ||
                    currentStatus == OrderLifecycle.delivered;

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    if (isCancelled) ...[
                      Card(
                        elevation: 0,
                        color: context.colors.errorContainer,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                                color: context.colors.errorContainer)),
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
                              Text(l10n.orderCancelledBody,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: context.colors.onSurface)),
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
                      _buildPersistentReviewCard(data),
                      const SizedBox(height: 16),
                    ],

                    if (isDisputed) ...[
                      Card(
                        elevation: 0,
                        color: context.colors.errorContainer,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: context.colors.error)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Icon(Icons.gavel,
                                  color: context.colors.error, size: 36),
                              const SizedBox(height: 8),
                              Text(l10n.orderDisputeTitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: context.colors.error)),
                              const SizedBox(height: 4),
                              Text(l10n.orderDisputeBody,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: context.colors.onSurface)),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _makePhoneCall('0767304776'),
                                  icon: const Icon(Icons.support_agent,
                                      size: 16),
                                  label: const Text('Piga GasLink: 0767304776'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Card(
                      elevation: 0,
                      color: context.colors.primaryContainer,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                              color: context.colors.primaryContainer)),
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
                                          fontSize: 11,
                                          color: context
                                              .colors.onSurfaceVariant)),
                                  const SizedBox(height: 2),
                                  Text(
                                    _etaText(l10n, currentStatus, etaMinutes,
                                        remainingSeconds),
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

                    // Receipt confirmation panel: 10-minute window.
                    if (currentStatus == OrderLifecycle.deliveredPending) ...[
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
                              Text(l10n.confirmDeliveryTitle,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: context.colors.onSurface)),
                              const SizedBox(height: 4),
                              Text(l10n.confirmDeliveryBody,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: context
                                          .colors.onSurfaceVariant)),
                              if (remainingSeconds != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  l10n.confirmWithinMinutes(
                                      (remainingSeconds / 60).ceil()),
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: context.gasColors.info),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _busy ? null : _denyReceipt,
                                      style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              context.colors.error,
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
                                      onPressed:
                                          _busy ? null : _confirmReceipt,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            context.gasColors.success,
                                        foregroundColor:
                                            context.gasColors.onSuccess,
                                      ),
                                      child: Text(
                                        l10n.received,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
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

                    // Buyer may confirm before the vendor taps "arrived".
                    if (currentStatus == OrderLifecycle.onTheWay) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: context.gasColors.success,
                              foregroundColor: context.gasColors.onSuccess,
                              elevation: 0),
                          onPressed: _busy ? null : _confirmReceipt,
                          icon: const Icon(Icons.check_circle_outline,
                              size: 16),
                          label: Text(l10n.confirmReceived,
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
                          side:
                              BorderSide(color: context.colors.outlineVariant)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.orderStatusSection,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            ...List.generate(steps.length, (index) {
                              final isDone =
                                  !isCancelled && !isDisputed && index <= currentStep;
                              final isCurrent =
                                  !isCancelled && !isDisputed && index == currentStep;
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
                                                    : context
                                                        .colors.onSurfaceVariant)),
                                        Text(
                                            _getStepSubtitle(
                                                index, currentStatus, l10n),
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: context
                                                    .colors.onSurfaceVariant)),
                                        if (index == 0) ...[
                                          const SizedBox(height: 6),
                                          _buildSubstep(
                                            l10n.orderSubstepSent,
                                            true,
                                          ),
                                          _buildSubstep(
                                            l10n.orderSubstepSeen,
                                            currentStatus ==
                                                    OrderLifecycle.seen ||
                                                currentStep >= 1,
                                          ),
                                        ],
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
                          side:
                              BorderSide(color: context.colors.outlineVariant)),
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
                                              color: context
                                                  .colors.onSurfaceVariant)),
                                    ],
                                  ),
                                ),
                                if (canSeeVendorPhone && vendorPhone.isNotEmpty)
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _makePhoneCall(vendorPhone),
                                    icon: const Icon(Icons.phone, size: 12),
                                    label: Text(l10n.callOffice,
                                        style:
                                            const TextStyle(fontSize: 10)),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            context.colors.primary,
                                        foregroundColor:
                                            context.colors.onPrimary,
                                        elevation: 0),
                                  ),
                              ],
                            ),
                            if (!canSeeVendorPhone) ...[
                              const SizedBox(height: 8),
                              Text(
                                l10n.vendorNumberAfterConfirmation,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: context.colors.onSurfaceVariant),
                              ),
                            ],
                            if (driverPhone.isNotEmpty &&
                                (currentStatus ==
                                        OrderLifecycle.onTheWay ||
                                    currentStatus ==
                                        OrderLifecycle.deliveredPending)) ...[
                              const Divider(height: 16),
                              Row(
                                children: [
                                  CircleAvatar(
                                      backgroundColor:
                                          context.colors.tertiaryContainer,
                                      child: Icon(Icons.delivery_dining,
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
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13)),
                                        Text(l10n.driverSubtitle,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: context.colors
                                                    .onSurfaceVariant)),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _makePhoneCall(driverPhone),
                                    icon: const Icon(Icons.phone, size: 12),
                                    label: Text(l10n.callDriver,
                                        style:
                                            const TextStyle(fontSize: 10)),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            context.gasColors.success,
                                        foregroundColor:
                                            context.gasColors.onSuccess,
                                        elevation: 0),
                                  ),
                                ],
                              ),
                            ],
                            if ((currentStatus == OrderLifecycle.placed ||
                                    currentStatus == OrderLifecycle.seen) &&
                                !isCancelled) ...[
                              const Divider(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: TextButton.icon(
                                  onPressed: _busy ? null : _cancelOrder,
                                  icon: Icon(Icons.cancel_outlined,
                                      color: context.colors.error, size: 16),
                                  label: Text(l10n.cancelOrder,
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
                          side:
                              BorderSide(color: context.colors.outlineVariant)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.orderSummary,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            const Divider(),
                            _buildSummaryRow(
                                l10n.summaryProduct,
                                '${widget.brandName} (${widget.cylinderWeight}) x${widget.quantity}'),
                            _buildSummaryRow(
                                l10n.summaryAddress, widget.deliveryAddress),
                            if (widget.contactPhone.isNotEmpty)
                              _buildSummaryRow(l10n.summaryConsumerPhone,
                                  widget.contactPhone),
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

  Widget _buildSubstep(String label, bool done) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 13,
            color:
                done ? context.gasColors.success : context.colors.outline,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: done
                  ? context.colors.onSurface
                  : context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 🌟 PERSISTENT REVIEW CARD
  Widget _buildPersistentReviewCard(Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context);
    final String currentStatus =
        OrderLifecycle.canonical(data['status']?.toString());
    final bool isDelivered = currentStatus == OrderLifecycle.delivered;
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
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
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
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: () => _showReviewSheet(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
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
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: context.colors.onSurfaceVariant)),
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
