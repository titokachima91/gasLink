/// ============================================================================
/// FILE: lib/screens/vendor/vendor_dashboard_screen.dart
///
/// SUMMARY:
/// Single operational home screen for LPG vendors.
/// Displays real-time store OPEN/CLOSED switch, daily sales performance metrics,
/// urgent incoming order decision alerts, and connects directly to VendorDrawer (☰).
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../auth/login_screen.dart';
import 'inventory_screen.dart';
import 'vendor_order_screen.dart';
import 'vendor_profile_screen.dart';
import 'widgets/vendor_drawer.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  int _selectedDrawerIndex = 0;

  String get _vendorUid =>
      FirebaseAuth.instance.currentUser?.uid ??
      AuthService.instance.currentUserId ??
      '';

  DocumentReference<Map<String, dynamic>> get _vendorDocRef =>
      FirebaseFirestore.instance.collection('vendors').doc(_vendorUid);

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();

      // ADD THIS EXACT LINE HERE TO SOLVE ALL THE CONSOLE ERRORS:
      final orderData = orderDoc.data() ?? {};

      final int etaMins = (orderData['eta_minutes'] as num?)?.toInt() ?? 20;
      final String vendorUid =
          orderData['vendor_id'] ?? orderData['vendorId'] ?? '';

      final String consumerUid = orderData['consumer_uid'] ??
          orderData['user_id'] ??
          orderData['userId'] ??
          orderData['consumer_id'] ??
          orderData['consumerId'] ??
          '';

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'status': newStatus,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Send push notification to consumer on order status update
      if (consumerUid.isNotEmpty) {
        String title = 'Mabadiliko ya Oda / Order Status Update';
        String body = 'Hali ya oda yako imebadilika kuwa: $newStatus';

        if (newStatus == 'cancelled' || newStatus == 'rejected') {
          title = 'Oda Imesitishwa / Order Cancelled';
          body =
              'Muuzaji amesitisha oda yako. Tafadhali jaribu muuzaji mwingine.';
        } else if (newStatus == 'on_the_way' || newStatus == 'dispatched') {
          title = 'Oda Ipo Njiani! / Order On The Way!';
          body = 'Dereva yuko njiani kuleta oda yako.';
        } else if (newStatus == 'delivered' || newStatus == 'completed') {
          title = 'Oda Imewasili! / Order Delivered!';
          body = 'Oda yako imekamilika kikamilifu. Asante kwa kutumia GasLink!';
        }

        try {
          await NotificationService.instance.sendNotificationToUser(
            userId: consumerUid,
            title: title,
            body: body,
            data: {
              'orderId': orderId,
              'type': 'order_status',
              'status': newStatus,
            },
          );
        } catch (e) {
          debugPrint('Failed to send consumer push notification: $e');
        }
      }

      // When order is completed, update vendor's total delivery stats for rolling average
      if (newStatus == 'delivered' && vendorUid.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('vendors')
            .doc(vendorUid)
            .set({
          'completed_orders_count': FieldValue.increment(1),
          'total_delivery_minutes': FieldValue.increment(etaMins),
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hali ya oda imebadilishwa: $newStatus'),
          backgroundColor: newStatus == 'cancelled' ? Colors.red : Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hitilafu: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _toggleStoreStatus(bool currentStatus) async {
    if (_vendorUid.isEmpty) return;
    try {
      await _vendorDocRef.update({
        'is_open': !currentStatus,
        'isOnline': !currentStatus,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hitilafu ya kubadili hali ya duka: $e')),
      );
    }
  }

  void _handleDrawerSelection(int index) {
    setState(() => _selectedDrawerIndex = index);
    switch (index) {
      case 0:
        // Already on Dashboard
        break;
      case 1:
        // Badges Hub
        // Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorBadgeScreen()));
        break;
      case 2:
        // Inventory
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InventoryScreen()),
        );
        break;
      case 3:
        // Orders
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VendorOrderScreen()),
        );
        break;
      case 4:
        // Store Profile
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VendorProfileScreen()),
        );
        break;
    }
  }

  void _showAcceptOrderDialog(String orderId) {
    int selectedEta = 20;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chagua Muda wa Kuwasilisha (ETA)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Mteja ataona muda huu kwenye app yake mara tu utakapothibitisha.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    children: [15, 20, 30, 45, 60].map((mins) {
                      final isSelected = selectedEta == mins;
                      return ChoiceChip(
                        label: Text('Dakika $mins'),
                        selected: isSelected,
                        selectedColor: Colors.orange,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) {
                          setModalState(() => selectedEta = mins);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        // FIXED: Capture ScaffoldMessenger helper before popping modal tree context
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        Navigator.pop(context);

                        try {
                          final orderDoc = await FirebaseFirestore.instance
                              .collection('orders')
                              .doc(orderId)
                              .get();
                          final orderData = orderDoc.data() ?? {};
                          final String consumerUid =
                              orderData['consumer_uid'] ??
                                  orderData['user_id'] ??
                                  orderData['userId'] ??
                                  orderData['consumer_id'] ??
                                  orderData['consumerId'] ??
                                  '';

                          await FirebaseFirestore.instance
                              .collection('orders')
                              .doc(orderId)
                              .update({
                            'status': 'accepted',
                            'eta_minutes': selectedEta,
                            'updated_at': FieldValue.serverTimestamp(),
                          });
                          // Send push notification to consumer when vendor accepts order
                          if (consumerUid.isNotEmpty) {
                            try {
                              await NotificationService.instance
                                  .sendNotificationToUser(
                                userId: consumerUid,
                                title: 'Oda Imethibitishwa! / Order Confirmed!',
                                body:
                                    'Muuzaji amethibitisha oda yako. Muda wa kuwasili ni takriban dakika $selectedEta.',
                                data: {
                                  'orderId': orderId,
                                  'type': 'order_status',
                                  'status': 'accepted',
                                },
                              );
                            } catch (e) {
                              debugPrint(
                                  'Failed to send consumer accept notification: $e');
                            }
                          }

                          // FIXED: Use the parent widget's lifecycle state verification
                          if (!mounted) return;
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Oda imethibitishwa: Dakika $selectedEta'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                                content: Text('Hitilafu: $e'),
                                backgroundColor: Colors.red),
                          );
                        }
                      },
                      child: const Text('Thibitisha Oda ➔',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_vendorUid.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Tafadhali ingia kama muuzaji'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                },
                child: const Text('Ingia / Login'),
              ),
            ],
          ),
        ),
      );
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _vendorDocRef.snapshots(),
      builder: (context, vendorSnap) {
        final vendorData = vendorSnap.data?.data() ?? {};
        final String storeName = vendorData['businessName'] ?? 'Duka Langu';
        final String? imageUrl =
            vendorData['imageUrl'] ?? vendorData['photoUrl'];
        final int currentTier = (vendorData['badgeTier'] as num?)?.toInt() ??
            (vendorData['tier'] as num?)?.toInt() ??
            1;
        final int completionPercentage =
            (vendorData['completionPercentage'] as num?)?.toInt() ?? 65;
        final bool isOpen = vendorData['is_open'] as bool? ??
            vendorData['isOnline'] as bool? ??
            true;
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          // ── Left Drawer Menu (☰) ────────────────────────────────────
          drawer: VendorDrawer(
            storeName: storeName,
            imageUrl: imageUrl,
            completionPercentage: completionPercentage,
            currentTier: currentTier,
            selectedIndex: _selectedDrawerIndex,
            onSelectTab: _handleDrawerSelection,
            onLogout: () async {
              await AuthService.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
          ),
          // ── Top App Bar ─────────────────────────────────────────────
          appBar: AppBar(
            backgroundColor: Colors.orange,
            elevation: 0,
            title: Text(
              storeName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            actions: [
              // Store Status Switch (OPEN 🟢 / CLOSED 🔴)
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Center(
                  child: InkWell(
                    onTap: () => _toggleStoreStatus(isOpen),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isOpen
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOpen ? Icons.circle : Icons.circle_outlined,
                            size: 8,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOpen ? 'OPEN 🟢' : 'CLOSED 🔴',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('vendor_id', isEqualTo: _vendorUid)
                .snapshots(),
            builder: (context, ordersSnap) {
              final allOrders = ordersSnap.data?.docs ?? [];
              final now = DateTime.now();
              final startOfToday = DateTime(now.year, now.month, now.day);
              int todayOrdersCount = 0;
              double todayRevenue = 0.0;
              final pendingOrders =
                  <QueryDocumentSnapshot<Map<String, dynamic>>>[];
              for (final doc in allOrders) {
                final data = doc.data();
                final status = (data['status'] as String? ?? 'pending')
                    .toLowerCase()
                    .trim();
                final totalPrice =
                    (data['total_price'] ?? data['totalPrice'] as num?)
                            ?.toDouble() ??
                        0.0;
                final Timestamp? createdTs = data['created_at'] as Timestamp? ??
                    data['createdAt'] as Timestamp?;
                final createdAt = createdTs?.toDate() ?? DateTime.now();
                if (createdAt.isAfter(startOfToday)) {
                  todayOrdersCount++;
                  if (status == 'delivered' ||
                      status == 'accepted' ||
                      status == 'in_transit' ||
                      status == 'on_the_way') {
                    todayRevenue += totalPrice;
                  }
                }
                // Include 'seen' alongside 'pending' and 'placed' so seen orders remain visible
                if (status == 'pending' ||
                    status == 'placed' ||
                    status == 'seen') {
                  pendingOrders.add(doc);
                }
              }
              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // ── SECTION 1: DYNAMIC DAILY METRIC COUNTERS ──────────
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _vendorDocRef.collection('products').snapshots(),
                    builder: (context, productsSnap) {
                      final products = productsSnap.data?.docs ?? [];
                      final lowStockCount = products.where((doc) {
                        final p = doc.data();
                        final inStock = p['in_stock'] as bool? ??
                            p['inStock'] as bool? ??
                            true;
                        return !inStock;
                      }).length;
                      return Row(
                        children: [
                          _buildMetricCard(
                            title: 'Oda Leo',
                            value: '$todayOrdersCount',
                            icon: Icons.shopping_bag_outlined,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          _buildMetricCard(
                            title: 'Mapato Leo',
                            value: todayRevenue.toStringAsFixed(0),
                            subtitle: 'TZS',
                            icon: Icons.payments_outlined,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          _buildMetricCard(
                            title: 'OutOfStock',
                            value: '$lowStockCount',
                            subtitle: 'Bidhaa',
                            icon: Icons.warning_amber_rounded,
                            color: lowStockCount > 0 ? Colors.red : Colors.grey,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // ── SECTION 2: QUICK ACTION BUTTONS ──────────────────
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const InventoryScreen(),
                              ),
                            );
                          },
                          icon:
                              const Icon(Icons.inventory, color: Colors.white),
                          label: const Text(
                            'Stoki / Inventory',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Colors.orange),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const VendorOrderScreen(),
                              ),
                            );
                          },
                          icon:
                              const Icon(Icons.list_alt, color: Colors.orange),
                          label: const Text(
                            'Oda Zote / Orders',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // ── SECTION 3: REAL-TIME INCOMING ORDER ALERTS ───────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Oda Mpya Zinazoingia / Incoming Orders',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text('${pendingOrders.length} Mpya'),
                        backgroundColor: pendingOrders.isNotEmpty
                            ? Colors.orange.shade100
                            : Colors.grey.shade200,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          color: pendingOrders.isNotEmpty
                              ? Colors.orange.shade900
                              : Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (pendingOrders.isEmpty)
                    Card(
                      elevation: 0,
                      color: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Hakuna oda mpya kwa sasa.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ...pendingOrders.map((doc) {
                      final data = doc.data();
                      final currentStatus = (data['status'] as String? ?? '')
                          .toLowerCase()
                          .trim();

                      final brand =
                          data['brand_name'] ?? data['brand'] ?? 'Gesi';
                      final weight = data['cylinder_weight'] ??
                          data['weight'] ??
                          data['size'] ??
                          '13kg';
                      final qty = data['quantity'] ?? 1;
                      final total =
                          (data['total_price'] ?? data['totalPrice'] as num?)
                                  ?.toDouble() ??
                              0.0;
                      final phone =
                          data['contact_phone'] ?? data['consumerPhone'] ?? '';

                      // ℹ️ EXTRA INSTRUCTIONS ALERTS: Read field conditions live from Firestore
                      final extraNote =
                          data['special_requests'] as String? ?? '';
                      final altPhone = data['receiver_phone'] as String? ?? '';
                      final bool hasExtraDetails =
                          extraNote.isNotEmpty || altPhone.isNotEmpty;

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: currentStatus == 'delivered_pending'
                                ? Colors.grey
                                : Colors.orange.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '⚡ ODA #${doc.id.substring(0, doc.id.length > 6 ? 6 : doc.id.length).toUpperCase()}',
                                      style: TextStyle(
                                        color: Colors.orange.shade900,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    phone,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // HIGH-VISIBILITY WARNING BADGE: Flashes dynamically if special requests exist
                              if (hasExtraDetails) ...[
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border:
                                        Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.info_outline,
                                          size: 14,
                                          color: Colors.blue.shade800),
                                      const SizedBox(width: 6),
                                      Text(
                                        'ℹ️ Ina maelezo ya ziada',
                                        style: TextStyle(
                                            color: Colors.blue.shade900,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              Text(
                                '$brand $weight (Idadi: x$qty)',
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Jumla: TZS ${total.toStringAsFixed(0)} • Cash on Delivery',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green),
                              ),
                              const Divider(height: 20),
                              // DYNAMIC EXPLICIT UI MORPHING TIMELINE HOOKS
                              if (currentStatus == 'seen' ||
                                  currentStatus == 'placed' ||
                                  currentStatus == 'pending') ...[
                                Row(
                                  children: [
                                    OutlinedButton(
                                      onPressed: () {
                                        // View Shortcut routes straight to the detailed Order Manager Screen
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const VendorOrderScreen()));
                                      },
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                            color: Colors.orange),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                      child: const Text('View',
                                          style:
                                              TextStyle(color: Colors.orange)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _updateOrderStatus(
                                            doc.id, 'cancelled'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(
                                              color: Colors.red),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                        ),
                                        child: const Text('Kataa / Reject'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            _showAcceptOrderDialog(doc.id),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                        ),
                                        child: const Text('Pokea / Accept'),
                                      ),
                                    ),
                                  ],
                                ),
                              ] else if (currentStatus == 'accepted') ...[
                                // INLINE DRIVER PHONE TEXT TRAY: Appears automatically once order is accepted
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Ingiza namba ya dereva:',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 40,
                                            child: TextField(
                                              keyboardType: TextInputType.phone,
                                              decoration: InputDecoration(
                                                hintText: 'Mfano: 0777123456',
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 8),
                                                border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8)),
                                              ),
                                              onChanged: (val) {
                                                data['_tmp_driver_phone'] = val;
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () async {
                                            final dPhone =
                                                data['_tmp_driver_phone']
                                                        as String? ??
                                                    '';
                                            if (dPhone.isEmpty) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(const SnackBar(
                                                      content: Text(
                                                          'Tafadhali weka namba ya simu ya dereva.')));
                                              return;
                                            }
                                            // Write driver parameters cleanly and advance state to on_the_way
                                            await doc.reference.update({
                                              'driver_phone': dPhone,
                                              'status': 'on_the_way',
                                              'updated_at':
                                                  FieldValue.serverTimestamp(),
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.purple,
                                              foregroundColor: Colors.white),
                                          child: const Text('Hifadhi'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ] else if (currentStatus == 'on_the_way') ...[
                                // STATE 3 UI LINE: Displays native Njiani status tag and green Delivered button
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Njiani 🚚',
                                        style: TextStyle(
                                            color: Colors.purple,
                                            fontWeight: FontWeight.bold)),
                                    ElevatedButton(
                                      onPressed: () async {
                                        // Update state to pending approval to flag the 4s undo clock ticker
                                        await doc.reference.update({
                                          'status': 'delivered_pending',
                                          '_delivered_at_ms': DateTime.now()
                                              .millisecondsSinceEpoch,
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white),
                                      child: const Text('Imefika / Delivered'),
                                    ),
                                  ],
                                ),
                              ] else if (currentStatus ==
                                  'delivered_pending') ...[
                                // STATE 4 UI LINE: Anti-mock protection ledger display with 4-second instant Undo text trigger
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Inasubiri Mteja...',
                                        style: TextStyle(
                                            color: Colors.grey,
                                            fontStyle: FontStyle.italic)),
                                    TextButton(
                                      onPressed: () async {
                                        // Rollback state back to on_the_way instantly to resolve mis-clicks smoothly
                                        await doc.reference
                                            .update({'status': 'on_the_way'});
                                      },
                                      child: const Text(
                                        'Batilisha / Undo',
                                        style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                            decoration:
                                                TextDecoration.underline),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: const TextStyle(fontSize: 9, color: Colors.grey),
              ),
            Text(
              title,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
