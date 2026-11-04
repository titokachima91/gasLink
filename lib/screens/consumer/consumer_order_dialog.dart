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
import 'consumer_order_screen.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart';

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
  bool _isLoading = false;
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
    // 🛠️ ROBUST USER ID CHECK WITH FALLBACK
    final currentUser = FirebaseAuth.instance.currentUser;
    final String uid =
        currentUser?.uid ?? AuthService.instance.currentUserId ?? '';

    if (uid.isEmpty) {
      // Show your sign-in prompt only if both are truly empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tafadhali ingia kwenye akaunti yako kwanza')),
      );
      return;
    }

    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();

    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali weka anwani ya kupelekewa.')),
      );
      return;
    }

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali weka nambari ya simu.')),
      );
      return;
    }

    setState(() => _isLoading = true);

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

      setState(() => _isLoading = false);

      // 3. Prompt user if gas is still remaining
      if (hasRemainingGas) {
        final String? chosenIntent = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Gas Yako Haijaisha!'),
            content: Text(
              'Mtungi wako wa ${widget.brandName} (${widget.cylinderWeight}) bado una gesi. Je, unataka kuongeza akiba au kubadilisha mtungi?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'add_stock'),
                child: const Text('Ongeza Akiba'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, 'new_asset'),
                child: const Text('Badili Mtungi'),
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
      setState(() => _isLoading = false);
      debugPrint('Error validating kitchen cylinder prior to order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hitilafu wakati wa kuhakiki mtungi: $e')),
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
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text('Gas Yako Haijaisha!',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Bado una gesi ya kutosha kwenye mtungi huu nyumbani (Inakadiriwa kubaki siku ~$daysLeft). Je, ungependa kufanya nini?',
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          actions: [
            Column(
              children: [
                // Option A: Add stock / extend cycle math
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange, elevation: 0),
                    onPressed: () {
                      setState(() => _orderIntent = 'add_stock');
                      Navigator.pop(context);
                      _executeRoutingPipeline(
                        FirebaseAuth.instance.currentUser?.uid ?? '',
                        _addressController.text.trim(),
                        _phoneController.text.trim(),
                      );
                    },
                    child: const Text('Ongeza Akiba / Add Stock',
                        style: TextStyle(
                            color: Colors.white,
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
                        side: BorderSide(color: Colors.grey.shade300)),
                    onPressed: () {
                      setState(() => _orderIntent = 'new_asset');
                      Navigator.pop(context);
                      _executeRoutingPipeline(
                        FirebaseAuth.instance.currentUser?.uid ?? '',
                        _addressController.text.trim(),
                        _phoneController.text.trim(),
                      );
                    },
                    child: const Text('Badili Mtungi / Change Cylinder',
                        style: TextStyle(color: Colors.black87, fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 4),
                const SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: null,
                    child: Text('Agizia Mwenzako (Soon)',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                ),
                const Divider(),
                // Option C: Cancel order altogether
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(this.context);
                  },
                  child: const Text('Ghairi Oda / Cancel',
                      style: TextStyle(
                          color: Colors.red,
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
    final totalPrice = widget.price * _quantity;
    final specialRequests = _specialController.text.trim();
    final receiverPhone = _receiverPhoneController.text.trim();

    try {
      if (uid.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tafadhali ingia kwenye akaunti yako kwanza.'),
            ),
          );
        }
        return;
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
        vendorCommissionRate: 0.03, // Standard vendor commission rate
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
              content: Text('Imeshindikana kuweka oda: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  const Text('Weka Oda / Express Checkout',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),

              // Selected Product Summary Card with Quantity Counter
              Card(
                elevation: 0,
                color: Colors.orange.shade50,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.orange.shade200)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department,
                          color: Colors.orange, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${widget.brandName} (${widget.cylinderWeight})',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold)),
                            Text('Muuzaji: ${widget.vendorName}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black87)),
                            Text(
                                'TZS ${widget.price.toStringAsFixed(0)} kwa moja',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade700)),
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
                              icon: const Icon(Icons.add_circle_outline,
                                  size: 20, color: Colors.orange),
                              onPressed: () => setState(() => _quantity++)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Delivery Information Section Title
              const Text('Taarifa za Usafirishaji / Delivery Info',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // Delivery Address Form Field
              TextFormField(
                controller: _addressController,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Tafadhali weka anwani au eneo lako'
                    : null,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Anwani au Eneo Lako *',
                  hintText: 'Mfano: Nyumba No. 12, Karibu na Msikiti',
                  prefixIcon: const Icon(Icons.location_on_outlined,
                      color: Colors.orange, size: 18),
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
                    ? 'Tafadhali weka namba ya simu'
                    : null,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Namba ya Simu ya Mawasiliano *',
                  hintText: 'Mfano: 07XXXXXXXX',
                  prefixIcon: const Icon(Icons.phone_outlined,
                      color: Colors.orange, size: 18),
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
                  labelText: 'Maelezo ya Ziada (Ombi Maalumu)',
                  hintText: 'Mfano: Dada yuko nyumbani kabisa',
                  prefixIcon: const Icon(Icons.assignment_outlined,
                      color: Colors.orange, size: 18),
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
                  labelText: 'Namba ya Mpokeaji wa Nyumbani',
                  hintText: 'Mfano: 07XXXXXXXX',
                  prefixIcon: const Icon(Icons.phone_android_outlined,
                      color: Colors.orange, size: 18),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 16),

              // Payment Method Section Title
              const Text('Njia ya Malipo / Payment Method',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // Payment Choice Chips (Cash vs Mobile Money)
              Row(
                children: [
                  Expanded(
                      child: ChoiceChip(
                          label: const Text('💵 Cash on Delivery',
                              style: TextStyle(fontSize: 11)),
                          selected: _paymentMethod == 'cash',
                          selectedColor: Colors.orange.shade100,
                          onSelected: (val) {
                            if (val) setState(() => _paymentMethod = 'cash');
                          })),
                  const SizedBox(width: 8),
                  Expanded(
                      child: ChoiceChip(
                          label: const Text('📱 Mobile Money',
                              style: TextStyle(fontSize: 11)),
                          selected: _paymentMethod == 'mobile_money',
                          selectedColor: Colors.orange.shade100,
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
                      const Text('Jumla Kuu / Total Price',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text('TZS ${totalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange)),
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
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: _isCheckingThreshold
                            ? const SizedBox(
                                height: 18,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Thibitisha Oda ➔',
                                style: TextStyle(
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
