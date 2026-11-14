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
import '../../services/order_lifecycle.dart';
import '../../services/order_service.dart';
import '../../widgets/ad_slot.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/referral_card.dart';
import '../../widgets/root_back_guard.dart';
import '../../widgets/theme_mode_button.dart';
import '../auth/landing_screen.dart';
import 'inventory_screen.dart';
import 'vendor_badge_screen.dart';
import 'vendor_order_screen.dart';
import 'vendor_profile_screen.dart';
import 'vendor_settings_screen.dart';
import 'widgets/vendor_drawer.dart';

import '../../core/theme_ext.dart';

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

  Future<void> _acceptOrder(String orderId) => _runTransition(
        () => OrderService.instance.confirmOrder(orderId),
        successMessage: 'Oda imethibitishwa. Inaandaliwa.',
      );

  Future<void> _rejectOrder(String orderId) => _runTransition(
        () => OrderService.instance.rejectOrder(orderId),
        successMessage: 'Oda imekataliwa.',
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

  Future<void> _markArrived(String orderId) => _runTransition(
        () => OrderService.instance.markArrived(orderId),
        successMessage:
            'Imewekwa kama imefika. Mteja athibitisha ndani ya dakika 10.',
      );

  Future<void> _undoArrived(String orderId) => _runTransition(
        () => OrderService.instance.undoArrived(orderId),
        successMessage: 'Oda imerudishwa njiani.',
      );

  Future<void> _confirmArrived(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mzigo umefika?'),
        content: const Text(
          'Mteja atapewa dakika 10 kuthibitisha kupokea. Kama hakuthibitishi, oda itakamilika kiotomatiki.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Ghairi'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ndio, umefika'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _markArrived(orderId);
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thibitisha Oda',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Mteja atajulishwa kuwa oda imepokelewa na inaandaliwa. ETA itaombwa uanzapo safari.',
              style: TextStyle(
                fontSize: 12,
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Ghairi'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.primary,
                      foregroundColor: context.colors.onPrimary,
                    ),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _acceptOrder(orderId);
                    },
                    child: const Text('Thibitisha Oda'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
      return RootBackGuard(
        child: Scaffold(
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
                      MaterialPageRoute(builder: (_) => const LandingScreen()),
                      (_) => false,
                    );
                  },
                  child: const Text('Ingia / Login'),
                ),
              ],
            ),
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
        final bool isVerified = vendorData['verified'] == true;
        final bool isOpen = vendorData['is_open'] as bool? ??
            vendorData['isOnline'] as bool? ??
            true;
        return RootBackGuard(
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            // ── Left Drawer Menu (☰) ────────────────────────────────────
            drawer: VendorDrawer(
              storeName: storeName,
              imageUrl: imageUrl,
              completionPercentage: completionPercentage,
              currentTier: currentTier,
              verified: isVerified,
              selectedIndex: _selectedDrawerIndex,
              onSelectTab: _handleDrawerSelection,
              onLogout: () async {
                await AuthService.instance.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LandingScreen()),
                    (_) => false,
                  );
                }
              },
            ),
            // ── Top App Bar ─────────────────────────────────────────────
            appBar: AppBar(
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
                IconButton(
                  tooltip: 'Settings',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VendorSettingsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: Colors.white,
                  ),
                ),
                const ThemeModeButton(),
                // Store Status Switch (OPEN 🟢 / CLOSED 🔴)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Center(
                    child: Semantics(
                      button: true,
                      label: 'Hali ya duka / Store status',
                      value: isOpen ? 'OPEN' : 'CLOSED',
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
                                ? context.gasColors.success
                                : context.colors.error,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isOpen ? Icons.circle : Icons.circle_outlined,
                                size: 8,
                                color: isOpen
                                    ? context.gasColors.onSuccess
                                    : context.colors.onError,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isOpen ? 'OPEN 🟢' : 'CLOSED 🔴',
                                style: TextStyle(
                                  color: isOpen
                                      ? context.gasColors.onSuccess
                                      : context.colors.onError,
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
                ),
              ],
            ),
            body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('vendor_id', isEqualTo: _vendorUid)
                  .snapshots(),
              builder: (context, ordersSnap) {
                if (ordersSnap.hasError) {
                  return _buildOrdersError(context, ordersSnap.error!);
                }
                if (!ordersSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allOrders = ordersSnap.data?.docs ?? [];
                final now = DateTime.now();
                final startOfToday = DateTime(now.year, now.month, now.day);
                int todayOrdersCount = 0;
                double todayRevenue = 0.0;
                final activeOrders =
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                final disputedOrders =
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                for (final doc in allOrders) {
                  final data = doc.data();
                  final status = OrderLifecycle.canonical(
                    data['status']?.toString(),
                  );
                  final totalPrice =
                      ((data['total_price'] ?? data['totalPrice']) as num?)
                              ?.toDouble() ??
                          0.0;
                  final Timestamp? createdTs =
                      data['created_at'] as Timestamp? ??
                          data['createdAt'] as Timestamp?;
                  final createdAt = createdTs?.toDate() ?? DateTime.now();
                  if (!createdAt.isBefore(startOfToday)) {
                    todayOrdersCount++;
                    if (status == OrderLifecycle.delivered) {
                      todayRevenue += totalPrice;
                    }
                  }
                  if (OrderLifecycle.isActive(status)) {
                    activeOrders.add(doc);
                  } else if (status == OrderLifecycle.disputed) {
                    disputedOrders.add(doc);
                  }
                }

                int createdMs(
                  QueryDocumentSnapshot<Map<String, dynamic>> doc,
                ) {
                  final data = doc.data();
                  final ts = (data['created_at'] ?? data['createdAt'])
                      as Timestamp?;
                  return ts?.millisecondsSinceEpoch ?? 0;
                }

                activeOrders.sort((a, b) => createdMs(b).compareTo(createdMs(a)));
                disputedOrders
                    .sort((a, b) => createdMs(b).compareTo(createdMs(a)));
                final newOrders = activeOrders
                    .where((doc) => OrderLifecycle.isNew(
                          doc.data()['status']?.toString(),
                        ))
                    .toList();

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    const OfflineBanner(),
                    // ── SECTION 1: DYNAMIC DAILY METRIC COUNTERS ──────────
                    const AppSectionHeader(
                      title: 'Leo / Today',
                      subtitle: 'Muhtasari wa shughuli za leo.',
                      icon: Icons.insights_outlined,
                    ),
                    const SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('products')
                          .where('vendor_id', isEqualTo: _vendorUid)
                          .snapshots(),
                      builder: (context, productsSnap) {
                        final products = productsSnap.data?.docs ?? [];
                        final lowStockCount = products.where((doc) {
                          final p = doc.data();
                          final inStock = p['in_stock'] as bool? ??
                              p['inStock'] as bool? ??
                              true;
                          return !inStock;
                        }).length;
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.7,
                          children: [
                            _buildMetricCard(
                              title: 'Oda Leo',
                              value: '$todayOrdersCount',
                              icon: Icons.shopping_bag_outlined,
                              color: context.gasColors.info,
                            ),
                            _buildMetricCard(
                              title: 'Mapato Leo',
                              value: todayRevenue.toStringAsFixed(0),
                              subtitle: 'TZS',
                              icon: Icons.payments_outlined,
                              color: context.gasColors.success,
                            ),
                            _buildMetricCard(
                              title: 'Zinazosubiri',
                              value: '${newOrders.length}',
                              subtitle: 'Oda Mpya',
                              icon: Icons.mark_email_unread_outlined,
                              color: newOrders.isNotEmpty
                                  ? context.gasColors.warning
                                  : context.colors.onSurfaceVariant,
                            ),
                            _buildMetricCard(
                              title: 'OutOfStock',
                              value: '$lowStockCount',
                              subtitle: 'Bidhaa',
                              icon: Icons.warning_amber_rounded,
                              color: lowStockCount > 0
                                  ? context.colors.error
                                  : context.colors.onSurfaceVariant,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildVerificationCard(context, isVerified: isVerified),
                    const SizedBox(height: 20),
                    // ── SECTION 2: QUICK ACTIONS GRID ──────────────────
                    const AppSectionHeader(
                      title: 'Haraka / Quick Actions',
                      subtitle: 'Stoki, oda, wasifu na mipangilio.',
                      icon: Icons.dashboard_customize_outlined,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionTile(
                            icon: Icons.inventory,
                            label: 'Stoki',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const InventoryScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _QuickActionTile(
                            icon: Icons.list_alt,
                            label: 'Oda Zote',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const VendorOrderScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _QuickActionTile(
                            icon: Icons.storefront,
                            label: 'Wasifu',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const VendorProfileScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _QuickActionTile(
                            icon: Icons.settings_outlined,
                            label: 'Mipangilio',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const VendorSettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // ── SECTION 3: LIVE ACTIVE ORDER QUEUE ───────────────
                    AppSectionHeader(
                      title: 'Oda Zinazoendelea / Active Orders',
                      subtitle: activeOrders.isEmpty
                          ? 'Hakuna oda inayoendelea kwa sasa.'
                          : 'Pokea, anza safari, au thibitisha kuwasili.',
                      icon: Icons.local_shipping_outlined,
                      trailing: AppStatusPill(
                        label: '${activeOrders.length} Hai',
                        color: activeOrders.isNotEmpty
                            ? context.gasColors.warning
                            : context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (activeOrders.isEmpty)
                      _buildEmptyOrdersCard(context)
                    else
                      ...activeOrders.map(
                        (doc) => _buildActiveOrderCard(context, doc),
                      ),
                    if (disputedOrders.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      AppSectionHeader(
                        title: 'Migogoro / Disputes',
                        subtitle: 'GasLink support inashughulikia oda hizi.',
                        icon: Icons.gavel_outlined,
                        trailing: AppStatusPill(
                          label: '${disputedOrders.length}',
                          color: context.colors.error,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...disputedOrders.map(
                        (doc) => _buildDisputedOrderCard(context, doc),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ReferralCard(uid: _vendorUid, role: 'vendor'),
                    const SizedBox(height: 20),
                    const AdSlot(placementId: 'vendor_dashboard'),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrdersError(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 40, color: context.colors.error),
            const SizedBox(height: 12),
            const Text(
              'Imeshindikana kupata oda / Could not load orders',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              '$error',
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Jaribu tena / Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyOrdersCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: context.colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: context.colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: context.colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 30,
                color: context.colors.primary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Hakuna oda bado / No orders yet',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Wateja watakuagiza mara tu bidhaa zako zitakapoonekana kwenye app.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InventoryScreen()),
                );
              },
              icon: const Icon(Icons.inventory, size: 18),
              label: const Text('Hakiki Bidhaa Zako / Check Inventory'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrderCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final status = OrderLifecycle.canonical(data['status']?.toString());
    final brand = (data['brand_name'] ?? data['brand'] ?? 'Gesi').toString();
    final weight = (data['cylinder_weight'] ??
            data['weight'] ??
            data['size'] ??
            '')
        .toString();
    final qty = (data['quantity'] as num?)?.toInt() ?? 1;
    final total = ((data['total_price'] ??
                data['totalPrice'] ??
                data['total']) as num?)
            ?.toDouble() ??
        0.0;
    final phone = (data['contact_phone'] ??
            data['consumerPhone'] ??
            data['receiver_phone'] ??
            '')
        .toString();
    final extraNote = (data['special_requests'] as String?) ?? '';
    final altPhone = (data['receiver_phone'] as String?) ?? '';
    final eta = (data['eta_minutes'] as num?)?.toInt();
    final driverPhone =
        (data['driver_phone'] ?? data['driverPhone'] ?? '').toString();
    final hasExtraDetails = extraNote.isNotEmpty || altPhone.isNotEmpty;
    final isNewOrder = OrderLifecycle.isNew(status);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isNewOrder
              ? context.gasColors.warning
              : context.colors.primary,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.colors.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '⚡ ODA #${OrderLifecycle.orderCode(doc.id)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.colors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AppStatusPill(
                  label: _statusLabel(status),
                  color: isNewOrder
                      ? context.gasColors.warning
                      : context.colors.primary,
                ),
              ],
            ),
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Simu: $phone',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
            if (hasExtraDetails) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.gasColors.infoContainer,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: context.gasColors.infoContainer),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: context.gasColors.info,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'ℹ️ Ina maelezo ya ziada',
                        style: TextStyle(
                          color: context.gasColors.info,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              weight.isEmpty ? '$brand (Idadi: x$qty)' : '$brand $weight (Idadi: x$qty)',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Jumla: TZS ${total.toStringAsFixed(0)} • Cash on Delivery',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: context.gasColors.success,
              ),
            ),
            if (status == OrderLifecycle.onTheWay && eta != null) ...[
              const SizedBox(height: 4),
              Text(
                'ETA: dakika $eta${driverPhone.isEmpty ? '' : ' • Dereva: $driverPhone'}',
                style: TextStyle(
                  fontSize: 12,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
            const Divider(height: 20),
            _buildOrderActions(context, doc, status),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderActions(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String status,
  ) {
    switch (status) {
      case OrderLifecycle.placed:
      case OrderLifecycle.seen:
        return Row(
          children: [
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VendorOrderScreen(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.colors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'View',
                style: TextStyle(color: context.colors.primary),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _rejectOrder(doc.id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.colors.error,
                  side: BorderSide(color: context.colors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Kataa / Reject'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _showAcceptOrderDialog(doc.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.colors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Pokea / Accept'),
              ),
            ),
          ],
        );
      case OrderLifecycle.confirmed:
        return Row(
          children: [
            Expanded(
              child: Text(
                'Imethibitishwa. Anza safari ukikamilisha maandalizi.',
                style: TextStyle(
                  fontSize: 12,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _showStartJourneyDialog(doc.id),
              icon: const Icon(Icons.local_shipping, size: 18),
              label: const Text('Anza Safari'),
            ),
          ],
        );
      case OrderLifecycle.onTheWay:
        return Row(
          children: [
            Expanded(
              child: Text(
                'Njiani 🚚',
                style: TextStyle(
                  color: context.colors.tertiary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => _confirmArrived(doc.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.gasColors.success,
                foregroundColor: context.gasColors.onSuccess,
              ),
              child: const Text('Imefika / Arrived'),
            ),
          ],
        );
      case OrderLifecycle.deliveredPending:
        return Row(
          children: [
            Expanded(
              child: Text(
                'Inasubiri mteja athibitishe (dakika 10).',
                style: TextStyle(
                  color: context.colors.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            TextButton(
              onPressed: () => _undoArrived(doc.id),
              child: Text(
                'Batilisha / Undo',
                style: TextStyle(
                  color: context.colors.error,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDisputedOrderCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final brand = (data['brand_name'] ?? data['brand'] ?? 'Gesi').toString();
    final total = ((data['total_price'] ??
                data['totalPrice'] ??
                data['total']) as num?)
            ?.toDouble() ??
        0.0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.colors.error),
      ),
      child: ListTile(
        leading: Icon(Icons.gavel, color: context.colors.error),
        title: Text(
          'Oda #${OrderLifecycle.orderCode(doc.id)} • $brand',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Mteja amesema hakupokea. GasLink support: 0767304776\nTZS ${total.toStringAsFixed(0)}',
        ),
        isThreeLine: true,
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case OrderLifecycle.placed:
        return 'Mpya';
      case OrderLifecycle.seen:
        return 'Imeonekana';
      case OrderLifecycle.confirmed:
        return 'Imethibitishwa';
      case OrderLifecycle.onTheWay:
        return 'Njiani';
      case OrderLifecycle.deliveredPending:
        return 'Inasubiri mteja';
      default:
        return status;
    }
  }

  Widget _buildVerificationCard(
    BuildContext context, {
    required bool isVerified,
  }) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isVerified
                ? context.gasColors.success.withOpacity(0.12)
                : context.colors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isVerified ? Icons.verified : Icons.workspace_premium_outlined,
            color:
                isVerified ? context.gasColors.success : context.colors.primary,
            size: 24,
          ),
        ),
        title: Text(
          isVerified ? 'Umethibitishwa / Verified' : 'Pata Badge ya Uhakiki',
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          isVerified
              ? 'Wateja wanaona nembo yako ya uhakiki kwenye app.'
              : 'Thibitisha duka lako kuongeza imani kwa wateja.',
          style: TextStyle(
            fontSize: 11.5,
            color: context.colors.onSurfaceVariant,
          ),
        ),
        trailing: isVerified
            ? AppStatusPill(
                label: 'Verified',
                icon: Icons.verified,
                color: context.gasColors.success,
              )
            : const Icon(Icons.chevron_right, size: 18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VendorBadgeScreen()),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.outlineVariant),
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
              style: TextStyle(
                  fontSize: 9, color: context.colors.onSurfaceVariant),
            ),
          Text(
            title,
            style:
                TextStyle(fontSize: 10, color: context.colors.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Compact tappable tile used in the vendor quick actions row.
class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      child: Column(
        children: [
          Icon(icon, color: context.colors.primary, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
