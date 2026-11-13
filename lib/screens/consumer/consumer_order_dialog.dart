// ============================================================================
// FILE PATH: lib/screens/consumer/consumer_order_dialog.dart
// ROLE OF THIS FILE:
// This is the Express Checkout dialog box for consumers. It is responsible for:
// 1. Collecting quantity, delivery address, contact phones, and payment choice[cite: 5].
// 2. Checking if the user already has an active cylinder of this brand/size in their kitchen[cite: 5].
// 3. Displaying the "Gas Yako Haijaisha!" warning dialog if significant gas remains[cite: 5].
// 4. Capturing the user's intent ('add_stock' vs 'new_asset') and routing to the tracking screen[cite: 5].
// ============================================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'consumer_order_screen.dart';
import '../../core/constants.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart';

import '../../core/theme_ext.dart';

class ConsumerOrderDialog extends StatefulWidget {
  final String vendorId;
  final String vendorName;
  final String brandName;
  final String cylinderWeight;
  final double price;

  ConsumerOrderDialog({
    super.key,
    required this.vendorId,
    required this.vendorName,
    required this.brandName,
    String? cylinderWeight,
    String? cylinderSize,
    required this.price,
  }) : cylinderWeight = cylinderWeight ?? cylinderSize ?? '15kg';

  @override
  State<ConsumerOrderDialog> createState() => _ConsumerOrderDialogState();
}

class _ConsumerOrderDialogState extends State<ConsumerOrderDialog> {
  // Order configuration state variables
  int _quantity = 1;
  String _paymentMethod = 'cash';
  final _formKey = GlobalKey<FormState>();
  // Text editing controllers for delivery and contact information form fields
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _specialController = TextEditingController();
  final TextEditingController _receiverPhoneController =
      TextEditingController();

  // Async verification flags & user intention routing tracking
  bool _isCheckingThreshold = false;
  String _orderIntent =
      'new_asset'; // Default intent: new asset / baseline reset

  @override
  void dispose() {
    // Clean up controllers when widget is disposed to prevent memory leaks
    _addressController.dispose();
    _phoneController.dispose();
    _specialController.dispose();
    _receiverPhoneController.dispose();
    super.dispose();
  }

  /// ===========================================================================
  /// KITCHEN THRESHOLD VALIDATION PIPELINE
  /// Queries the user's kitchen cylinder subcollection to check remaining gas.
  /// Uses normalized string matching to prevent mismatch bugs between UI and DB.
  /// ===========================================================================
  Future<void> _validateAndSubmitOrder() async {
    final l10n = AppLocalizations.of(context);
    // 🛠️ ROBUST USER ID CHECK WITH FALLBACK
    final currentUser = FirebaseAuth.instance.currentUser;
    final String uid =
        currentUser?.uid ?? AuthService.instance.currentUserId ?? '';

    if (uid.isEmpty) {
      // Show your sign-in prompt only if both are truly empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSignInFirst)),
      );
      return;
    }

    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();

    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addressRequired)),
      );
      return;
    }

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.phoneRequired)),
      );
      return;
    }

    try {
      // 1. Fetch kitchen cylinders for threshold validation
      // 1. Fetch kitchen cylinders for threshold validation
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('cylinders')
          .get();

      final targetBrandClean =
          widget.brandName.replaceAll(RegExp(r'\s+'), '').toLowerCase();
      final targetSizeClean =
          widget.cylinderWeight.replaceAll(RegExp(r'\s+'), '').toLowerCase();

      Map<String, dynamic>? matchingCylinder;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final brandClean = (data['brand'] ?? '')
            .toString()
            .replaceAll(RegExp(r'\s+'), '')
            .toLowerCase();
        final sizeClean = (data['weight'] ?? data['size'] ?? '')
            .toString()
            .replaceAll(RegExp(r'\s+'), '')
            .toLowerCase();

        if (brandClean == targetBrandClean && sizeClean == targetSizeClean) {
          matchingCylinder = data;
          break;
        }
      }

      // 2. Evaluate gas status if matching cylinder exists
      bool hasRemainingGas = false;
      if (matchingCylinder != null) {
        final lastRefillStr = matchingCylinder['lastRefillDate'] ??
            matchingCylinder['last_refill_date'];
        if (lastRefillStr != null) {
          final lastRefill = DateTime.tryParse(lastRefillStr.toString());
          if (lastRefill != null) {
            final daysPassed = DateTime.now().difference(lastRefill).inDays;
            final estimatedCycleDays = 30;
            final daysLeft = estimatedCycleDays - daysPassed;

            double percentLeft = (daysLeft / estimatedCycleDays) * 100;
            if (percentLeft < 0) percentLeft = 0;
            if (percentLeft > 100) percentLeft = 100;
            if (percentLeft > 15 && daysLeft > 0) {
              hasRemainingGas = true;
            }
          }
        }
      }

      // 3. Prompt user if gas is still remaining
      if (hasRemainingGas) {
        final String? chosenIntent = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(l10n.gasRemainingTitle),
            content: Text(
              l10n.gasRemainingBody(widget.brandName, widget.cylinderWeight),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'add_stock'),
                child: Text(l10n.orderAddStock),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, 'new_asset'),
                child: Text(l10n.changeCylinder),
              ),
            ],
          ),
        );

        if (chosenIntent == null) return; // User cancelled
        _orderIntent = chosenIntent;
      } else {
        _orderIntent = 'new_asset';
      }

      // 4. Proceed to Order Creation Pipeline (Step 2)
// 4. Proceed to Order Creation Pipeline (Step 2)
      await _executeRoutingPipeline(uid, address, phone);
    } catch (e) {
      debugPrint('Error validating kitchen cylinder prior to order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cylinderCheckFailed('$e'))),
      );
    }
  }

  /// ===========================================================================
  /// THRESHOLD WARNING DIALOG
  /// Modal shown when consumer tries to order while gas is still in the cylinder[cite: 5].
  /// ===========================================================================
  void _showThresholdWarningDialog(int daysLeft) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: context.colors.primary, size: 24),
              SizedBox(width: 8),
              Text(l10n.gasRemainingTitle,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            l10n.gasRemainingDays(daysLeft),
            style: TextStyle(fontSize: 13, color: context.colors.onSurface),
          ),
          actions: [
            Column(
              children: [
                // Option A: Add stock / extend cycle math
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.primary, elevation: 0),
                    onPressed: () {
                      setState(() => _orderIntent = 'add_stock');
                      Navigator.pop(context);
                      _executeRoutingPipeline(
                        FirebaseAuth.instance.currentUser?.uid ?? '',
                        _addressController.text.trim(),
                        _phoneController.text.trim(),
                      );
                    },
                    child: Text(l10n.orderAddStock,
                        style: TextStyle(
                            color: context.colors.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 4),
                // Option B: Change cylinder / standard swap
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(color: context.colors.outlineVariant)),
                    onPressed: () {
                      setState(() => _orderIntent = 'new_asset');
                      Navigator.pop(context);
                      _executeRoutingPipeline(
                        FirebaseAuth.instance.currentUser?.uid ?? '',
                        _addressController.text.trim(),
                        _phoneController.text.trim(),
                      );
                    },
                    child: Text(l10n.changeCylinder,
                        style: TextStyle(
                            color: context.colors.onSurface, fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: null,
                    child: Text(l10n.orderForFriendSoon,
                        style: TextStyle(
                            fontSize: 12,
                            color: context.colors.onSurfaceVariant)),
                  ),
                ),
                const Divider(),
                // Option C: Cancel order altogether
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(this.context);
                  },
                  child: Text(l10n.cancelOrderShort,
                      style: TextStyle(
                          color: context.colors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// ===========================================================================
  /// ORDER ROUTING & FIRESTORE CREATION PIPELINE
  /// Creates the order document in Firestore and routes user to live tracking[cite: 5].
  /// ===========================================================================
  Future<void> _executeRoutingPipeline(
    String uid,
    String deliveryAddress,
    String contactPhone,
  ) async {
    final l10n = AppLocalizations.of(context);
    final totalPrice = widget.price * _quantity;
    final specialRequests = _specialController.text.trim();
    final receiverPhone = _receiverPhoneController.text.trim();

    try {
      if (uid.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.pleaseSignInFirst),
            ),
          );
        }
        return;
      }

      // Fetch the vendor's commission terms so the order stamps them correctly.
      double vendorRate = AppConstants.defaultCommissionRate;
      String commissionModel = 'percentage';
      try {
        final vendorDoc = await FirebaseFirestore.instance
            .collection('vendors')
            .doc(widget.vendorId)
            .get();
        if (vendorDoc.exists) {
          final vd = vendorDoc.data() ?? {};
          commissionModel =
              (vd['commissionModel'] ?? 'percentage').toString().toLowerCase();
          vendorRate = (vd['commissionRate'] as num? ?? 0.03).toDouble();
        }
      } catch (e) {
        debugPrint('Commission fetch warning during order placement: $e');
      }

      // 1. Save order to Firestore via OrderService and retrieve real database reference ID[cite: 5]
      final docRef = await OrderService.instance.placeOrder(
        consumerUid: uid,
        vendorId: widget.vendorId,
        vendorName: widget.vendorName,
        productId: '',
        brand: widget.brandName,
        size: widget.cylinderWeight,
        type: 'refill',
        orderIntent: _orderIntent,
        quantity: _quantity,
        unitPrice: widget.price,
        vendorCommissionRate: vendorRate,
        commissionModel: commissionModel,
        deliveryAddress: deliveryAddress,
        contactPhone: contactPhone,
        receiverPhone: receiverPhone,
        specialRequests: specialRequests,
        paymentMethod: _paymentMethod,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close express checkout bottom sheet modal

      // 2. Push to live tracking screen with actual orderId and order intent[cite: 5]
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConsumerOrderScreen(
            orderId: docRef.id,
            vendorId: widget.vendorId,
            vendorName: widget.vendorName,
            brandName: widget.brandName,
            cylinderSize: widget.cylinderWeight,
            unitPrice: widget.price,
            totalPrice: totalPrice,
            deliveryAddress: deliveryAddress,
            contactPhone: contactPhone,
            paymentMethod: _paymentMethod,
            quantity: _quantity,
            specialRequests: specialRequests,
            receiverPhone: receiverPhone,
            orderIntent: _orderIntent,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error placing order from dialog: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.orderFailed('$e')),
              backgroundColor: context.colors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final double totalPrice = widget.price * _quantity;

    return Padding(
      padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with title and close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.expressCheckout,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),

              // Selected Product Summary Card with Quantity Counter
              Card(
                elevation: 0,
                color: context.colors.primaryContainer,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: context.colors.primaryContainer)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.local_fire_department,
                          color: context.colors.primary, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${widget.brandName} (${widget.cylinderWeight})',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold)),
                            Text(l10n.vendorPrefix(widget.vendorName),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: context.colors.onSurface)),
                            Text(
                                l10n.priceEach(
                                    widget.price.toStringAsFixed(0)),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: context.colors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      // Quantity increment/decrement buttons
                      Row(
                        children: [
                          IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  size: 20),
                              onPressed: _quantity > 1
                                  ? () => setState(() => _quantity--)
                                  : null),
                          Text('$_quantity',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          IconButton(
                              icon: Icon(Icons.add_circle_outline,
                                  size: 20, color: context.colors.primary),
                              onPressed: () => setState(() => _quantity++)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Delivery Information Section Title
              Text(l10n.deliveryInfo,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // Delivery Address Form Field
              TextFormField(
                controller: _addressController,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.addressRequiredShort
                    : null,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  labelText: l10n.addressLabel,
                  hintText: l10n.addressHint,
                  prefixIcon: Icon(Icons.location_on_outlined,
                      color: context.colors.primary, size: 18),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 10),

              // Customer Phone Number Form Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.phoneRequiredShort
                    : null,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  labelText: l10n.contactPhoneLabel,
                  hintText: l10n.phoneHintShort,
                  prefixIcon: Icon(Icons.phone_outlined,
                      color: context.colors.primary, size: 18),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 10),

              // Special Requests / Instructions Form Field
              TextFormField(
                controller: _specialController,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  labelText: l10n.specialRequestsLabel,
                  hintText: l10n.specialRequestsHint,
                  prefixIcon: Icon(Icons.assignment_outlined,
                      color: context.colors.primary, size: 18),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 10),

              // Home Receiver Phone Number Form Field
              TextFormField(
                controller: _receiverPhoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  labelText: l10n.receiverPhoneLabel,
                  hintText: l10n.phoneHintShort,
                  prefixIcon: Icon(Icons.phone_android_outlined,
                      color: context.colors.primary, size: 18),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 16),

              // Payment Method Section Title
              Text(l10n.paymentMethodLabel,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // Payment Choice Chips (Cash vs Mobile Money)
              Row(
                children: [
                  Expanded(
                      child: ChoiceChip(
                          label: Text(l10n.paymentCash,
                              style: const TextStyle(fontSize: 11)),
                          selected: _paymentMethod == 'cash',
                          selectedColor: context.colors.primaryContainer,
                          onSelected: (val) {
                            if (val) setState(() => _paymentMethod = 'cash');
                          })),
                  const SizedBox(width: 8),
                  Expanded(
                      child: ChoiceChip(
                          label: Text(l10n.paymentMobileMoney,
                              style: const TextStyle(fontSize: 11)),
                          selected: _paymentMethod == 'mobile_money',
                          selectedColor: context.colors.primaryContainer,
                          onSelected: (val) {
                            if (val)
                              setState(() => _paymentMethod = 'mobile_money');
                          })),
                ],
              ),
              const SizedBox(height: 20),

              // Bottom Action Row: Total Price & Submit Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.totalPrice,
                          style: TextStyle(
                              fontSize: 11,
                              color: context.colors.onSurfaceVariant)),
                      Text('TZS ${totalPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: context.colors.primary)),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: ElevatedButton(
                        onPressed: _isCheckingThreshold
                            ? null
                            : _validateAndSubmitOrder,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: context.colors.primary,
                            foregroundColor: context.colors.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: _isCheckingThreshold
                            ? SizedBox(
                                height: 18,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: context.colors.onPrimary,
                                    strokeWidth: 2))
                            : Text(l10n.confirmOrder,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
