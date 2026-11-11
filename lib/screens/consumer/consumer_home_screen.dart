// lib/screens/consumer/consumer_home_screen.dart
// Consumer Discovery & Tracking Dashboard for LPG consumers in Dar es Salaam.
// Integrates persistent "Oda Zangu" mini-order tracking banners, live gauges, and real-time synchronizations.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/session_data.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../utils/cylinder_fifo.dart';
import '../auth/login_screen.dart';
import 'consumer_cylinder_screen.dart';
import 'consumer_order_screen.dart';
import 'vendor_detail_screen.dart';
import '../../models/order.dart' as models;
import '../../widgets/offline_banner.dart';
import '../../widgets/theme_mode_button.dart';
import '../../widgets/verified_badge.dart';
import 'item_vendors_screen.dart';

import '../../core/theme_ext.dart';

class ConsumerHomeScreen extends StatefulWidget {
  const ConsumerHomeScreen({super.key});

  @override
  State<ConsumerHomeScreen> createState() => _ConsumerHomeScreenState();
}

class _ConsumerHomeScreenState extends State<ConsumerHomeScreen> {
  String _selectedIntent = 'Refill';
  bool _isLoading = true;
  List<Map<String, dynamic>> _myCylinders = [];
  List<Map<String, dynamic>> _deliveredOrders = [];
  Map<String, dynamic>? _lastCompletedOrder;
  Widget _buildCategoryCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? context.colors.primaryContainer : context.colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? context.colors.primary : context.colors.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isSelected ? context.colors.primary : context.colors.onSurfaceVariant,
                size: 26),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected ? context.colors.primary : context.colors.onSurface,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? context.colors.primary : context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getListTitle() {
    switch (_selectedIntent) {
      case 'Full Set':
        return 'Chagua Chapa / Select Brand (Full Set)';
      case 'Accessories':
        return 'Chagua Kifaa / Select Accessory';
      case 'Services':
        return 'Chagua Huduma / Select Service';
      default:
        return 'Chagua Chapa / Select Brand (Refill)';
    }
  }

  List<String> _getListItems() {
    switch (_selectedIntent) {
      case 'Accessories':
        return AppConstants.accessoryItems;
      case 'Services':
        return AppConstants.serviceItems;
      default:
        return AppConstants.gasBrands;
    }
  }

  Widget _buildVerticalItemCard(String itemName) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: context.colors.outlineVariant),
      ),
      child: ListTile(
        leading: Icon(
          _selectedIntent == 'Accessories' || _selectedIntent == 'Services'
              ? Icons.handyman_outlined
              : Icons.propane_tank,
          color: context.colors.primary,
        ),
        title: Text(
          itemName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        trailing: Icon(Icons.chevron_right, color: context.colors.onSurfaceVariant),
        onTap: () {
          String category;
          switch (_selectedIntent) {
            case 'Full Set':
              category = 'full_set';
              break;
            case 'Accessories':
              category = 'accessories';
              break;
            case 'Services':
              category = 'services';
              break;
            default:
              category = 'refill';
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemVendorsScreen(
                category: category,
                itemName: itemName,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchLiveSessionData();
    _fetchUserCylinders();
    _fetchLastCompletedOrder();
  }

  Future<void> _fetchLiveSessionData() async {
    setState(() => _isLoading = true);
    await SessionData.instance.ensureLoaded();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUserCylinders() async {
    final uid = AuthService.instance.currentUserId;
    if (uid == null || uid.isEmpty) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('cylinders')
          .orderBy('createdAt', descending: true)
          .get();

      // The Cylinder Smart Hub derives FIFO from delivered orders, so the
      // home gauge reads the same source. Manual cylinders (no order history)
      // fall back to the stored lastRefillDate.
      var deliveredOrders = <Map<String, dynamic>>[];
      try {
        final ordersSnap = await FirebaseFirestore.instance
            .collection('orders')
            .where('consumer_uid', isEqualTo: uid)
            .where('status', isEqualTo: 'delivered')
            .get();
        deliveredOrders = ordersSnap.docs.map((doc) => doc.data()).toList();
      } catch (e) {
        debugPrint('Error fetching delivered orders for gauge: $e');
      }

      if (mounted) {
        setState(() {
          _myCylinders = snap.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
          _deliveredOrders = deliveredOrders;
        });
      }
    } catch (e) {
      debugPrint('Error fetching user cylinders: $e');
    }
  }

  Future<void> _fetchLastCompletedOrder() async {
    final uid = AuthService.instance.currentUserId;
    if (uid == null || uid.isEmpty) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('orders')
          .where('consumer_uid', isEqualTo: uid)
          .where('status', isEqualTo: 'delivered')
          .orderBy('created_at', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty && mounted) {
        setState(() {
          _lastCompletedOrder = snap.docs.first.data();
        });
      }
    } catch (e) {
      debugPrint('Error fetching last completed order: $e');
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      SessionData.instance.reload(),
      _fetchUserCylinders(),
      _fetchLastCompletedOrder(),
    ]);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ondoka / Logout'),
        content: const Text('Unahakika unataka kuondoka?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Ghairi')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Ondoka', style: TextStyle(color: context.colors.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  /// 🟢 PERSISTENT "ODA ZANGU" WORKSPACE TRACKER BANNER
  Widget _buildPersistentOdaZanguBanner() {
    final currentUid = AuthService.instance.currentUserId;
    if (currentUid == null || currentUid.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: OrderService.instance.consumerOrders(currentUid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyHistoryBannerLink(null);
        }

        // Convert raw Firestore docs safely through our Order model
        final List<models.Order> allOrders = snapshot.data!.docs
            .map((doc) => models.Order.fromDoc(doc))
            .toList();

        // Filter active orders that are still running
        final activeOrders = allOrders.where((order) {
          final st = order.status.toLowerCase().trim();
          return st != 'delivered' &&
              st != 'completed' &&
              st != 'cancelled' &&
              st != 'rejected' &&
              st != 'refused';
        }).toList();

        if (activeOrders.isEmpty) {
          // If no active order is running, show history link with latest record
          final latestDoc =
              snapshot.data!.docs.first.data() as Map<String, dynamic>? ?? {};
          latestDoc['id'] = snapshot.data!.docs.first.id;
          return _buildEmptyHistoryBannerLink(latestDoc);
        }

        // Primary active running order
        final primaryOrder = activeOrders.first;
        final String orderId = primaryOrder.id;
        final rawStatus = primaryOrder.status.toLowerCase().trim();
        final brand =
            primaryOrder.brand.isNotEmpty ? primaryOrder.brand : 'Gesi';
        final weight = primaryOrder.size;
        final intent = primaryOrder.orderIntent;

        String displayStatus = 'Oda Imetumwa • Inasubiri Muuzaji';
        Color statusTextColor = context.colors.primary;
        IconData statusIcon = Icons.access_time_rounded;
        int currentStepIndex = 0;

        if (rawStatus == 'seen') {
          displayStatus = 'Muuzaji Anakagua Oda Yako...';
          statusTextColor = context.gasColors.info;
          statusIcon = Icons.visibility_outlined;
          currentStepIndex = 0;
        } else if (rawStatus == 'accepted' ||
            rawStatus == 'confirmed' ||
            rawStatus == 'preparing') {
          displayStatus = 'Oda Imepokelewa • Inaandaliwa 📦';
          statusTextColor = context.colors.secondary;
          statusIcon = Icons.inventory_2_outlined;
          currentStepIndex = 1;
        } else if (rawStatus == 'on_the_way' ||
            rawStatus == 'dispatched' ||
            rawStatus == 'in_transit') {
          displayStatus = 'Gesi Yako Ipo Njiani! 🛵';
          statusTextColor = context.colors.tertiary;
          statusIcon = Icons.two_wheeler;
          currentStepIndex = 2;
        } else if (rawStatus == 'delivered_pending') {
          displayStatus = 'Imefika • Tafadhali Thibitisha';
          statusTextColor = context.gasColors.success;
          statusIcon = Icons.handshake_outlined;
          currentStepIndex = 2;
        }

        // Convert primaryOrder model back to Map for screen navigation compatibility
        final orderDataMap = primaryOrder.toMap();
        orderDataMap['id'] = orderId;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: context.colors.primary, width: 1.5),
          ),
          color: context.colors.primaryContainer,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _navigateToExtendedTrackingScreen(
              orderId,
              orderDataMap,
              intent,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(statusIcon, color: context.colors.primary, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'ODA ZANGU / ACTIVE TRACKER',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: context.colors.onSurfaceVariant,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '#${orderId.substring(0, orderId.length > 6 ? 6 : orderId.length).toUpperCase()}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    displayStatus,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: statusTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$brand $weight',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // INLINE STEPPER COMPACT GRAPHICS
                  Row(
                    children: List.generate(4, (i) {
                      final bool isDone = i <= currentStepIndex;
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color:
                                isDone ? context.colors.primary : context.colors.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        intent == 'add_stock'
                            ? '🔄 Ongeza Akiba'
                            : '📦 Mtungi Mpya',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Gusa Kufungua Maelezo Zaidi ➔',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 📜 FALLBACK WORKSPACE INTERFACE TRAY: Renders if the user queue has no live dispatches running
  Widget _buildEmptyHistoryBannerLink(Map<String, dynamic>? lastOrder) {
    final uid = AuthService.instance.currentUserId ?? '';
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.colors.outlineVariant, width: 1),
      ),
      color: context.colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: context.colors.primaryContainer,
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.history_toggle_off_rounded,
                      color: context.colors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Oda Zangu / Order History Center',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: context.colors.onSurface),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Huna oda inayotembea kwa sasa.',
                        style: TextStyle(fontSize: 11, color: context.colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.colors.primary,
                  side: BorderSide(color: context.colors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  if (uid.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ConsumerOrdersHistoryScreen(consumerUid: uid),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.receipt_long, size: 16),
                label: const Text(
                  'Fungua Historia Yote ya Oda (All Orders History)',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToExtendedTrackingScreen(
      String orderId, Map<String, dynamic> data, String intent) {
    navigateToExtendedTrackingScreen(orderId, data, intent);
  }

  void navigateToExtendedTrackingScreen(
      String orderId, Map<String, dynamic> data, String intent) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConsumerOrderScreen(
          orderId: orderId,
          vendorId: data['vendor_id'] ?? '',
          vendorName:
              (data['vendor_name'] ?? data['vendorName'] ?? 'Gas Vendor')
                  .toString(),
          brandName: (data['brand'] ?? data['brand_name'] ?? 'LPG').toString(),
          cylinderSize: (data['size'] ?? data['weight'] ?? '15kg').toString(),
          unitPrice: (data['unit_price'] as num?)?.toDouble() ?? 0.0,
          totalPrice: (data['total_price'] as num?)?.toDouble() ?? 0.0,
          deliveryAddress:
              (data['delivery_address'] ?? data['deliveryAddress'] ?? '')
                  .toString(),
          contactPhone:
              (data['contact_phone'] ?? data['consumerPhone'] ?? '').toString(),
          paymentMethod: (data['payment_method'] ?? 'cash').toString(),
          quantity: (data['quantity'] as num?)?.toInt() ?? 1,
          specialRequests: (data['special_requests'] ?? '').toString(),
          receiverPhone: (data['receiver_phone'] ?? '').toString(),
          orderIntent: intent,
        ),
      ),
    ).then((_) => _fetchUserCylinders());
  }

  Widget _buildGasEstimatorCard() {
    final hasCylinders = _myCylinders.isNotEmpty;

    // Group cylinders by brand + weight so each row represents the
    // consumer's collective stock for that cylinder (FIFO display).
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final cylinder in _myCylinders) {
      final key = '${_normalizeCylinderKey(cylinder['brand'] ?? 'Gesi')}-'
          '${_normalizeCylinderKey(cylinder['weight'] ?? cylinder['size'] ?? '15kg')}';
      (groups[key] ??= []).add(cylinder);
    }
    final groupList = groups.values.toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Gas Cylinder',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: context.colors.onSurface,
                letterSpacing: 0.3),
          ),
          const SizedBox(height: 16),
          if (!hasCylinders) ...[
            Text(
              'Hujasajili Mtungi Bado / No Cylinder Registered',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.colors.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              'Weka taarifa kuanza kukadiria matumizi yako.',
              style: TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: groupList.length,
              separatorBuilder: (context, index) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(height: 1),
              ),
              itemBuilder: (context, index) {
                final groupCylinders = groupList[index];
                final brandName =
                    (groupCylinders.first['brand'] ?? 'Gesi').toString();
                final weight = (groupCylinders.first['weight'] ??
                        groupCylinders.first['size'] ??
                        '15kg')
                    .toString();

                final aggregate = _aggregateCylinderGroup(groupCylinders);
                final estimatedDaysLeft = aggregate.totalRemainingDays;
                final remainingPercentage =
                    aggregate.totalPercentage.toStringAsFixed(1);
                final estimatedRemainingRatio = aggregate.capacityFraction;
                final isTankEmptyState = aggregate.isEmpty;
                final isCriticalLow =
                    estimatedRemainingRatio <= 0.15 || isTankEmptyState;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$brandName $weight',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: context.colors.onSurface),
                        ),
                        Text(
                          isTankEmptyState
                              ? 'Imeisha / Empty (0%)'
                              : 'Zimebaki ~$estimatedDaysLeft Siku ($remainingPercentage%)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isCriticalLow
                                ? context.colors.error
                                : context.colors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: estimatedRemainingRatio,
                              backgroundColor: context.colors.surfaceContainerLow,
                              color: isCriticalLow ? context.colors.error : context.colors.primary,
                              minHeight: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(color: context.colors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    if (hasCylinders) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConsumerCylinderScreen(
                            initialCylinders: _myCylinders,
                            lastCompletedOrder: _lastCompletedOrder,
                          ),
                        ),
                      ).then((_) => _fetchUserCylinders());
                    } else {
                      _showGasSetupSheet();
                    }
                  },
                  icon: Icon(
                      hasCylinders
                          ? Icons.analytics_outlined
                          : Icons.add_circle_outline,
                      size: 16,
                      color: context.colors.primary),
                  label: Text(
                    hasCylinders ? 'Taarifa Zaidi' : 'Weka Sasa',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: context.colors.primary),
                  ),
                ),
              ),
              if (hasCylinders) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.primary,
                      foregroundColor: context.colors.onPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      final lastVendorId =
                          (_lastCompletedOrder?['vendor_id'] ?? '').toString();
                      final lastVendorName =
                          (_lastCompletedOrder?['vendor_name'] ?? '')
                              .toString();
                      if (lastVendorId.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VendorDetailScreen(
                                vendorId: lastVendorId,
                                businessName: lastVendorName),
                          ),
                        );
                      } else {
                        setState(() {
                          _selectedIntent = 'Refill';
                        });
                      }
                    },
                    icon: const Icon(Icons.bolt, size: 16),
                    label: const Text('Agiza Tena',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Aggregates a group of cylinders that share the same brand + weight into
  /// one collective reading using the shared FIFO rules from
  /// `utils/cylinder_fifo.dart`.
  ///
  /// - [FifoCollective.totalRemainingDays] is the SUM of the remaining days.
  /// - [FifoCollective.totalPercentage] is the SUM of the per-cylinder
  ///   percentages, so two full 30-day cylinders read 200%.
  /// - [FifoCollective.capacityFraction] is what the progress bar shows
  ///   (59 / 60 = 0.9833 for two cylinders after one day).
  ///
  /// Delivered orders are the source of truth (same as the Cylinder Smart
  /// Hub). Manually registered cylinders fall back to their saved units or
  /// lastRefillDate.
  FifoCollective _aggregateCylinderGroup(List<Map<String, dynamic>> group) {
    if (group.isEmpty) return calculateFifo(const []);

    final cycleDays = _cycleDaysFor(group.first);
    final targetBrand = _normalizeCylinderKey(group.first['brand'] ?? 'Gesi');
    final targetWeight = _normalizeCylinderKey(
        group.first['weight'] ?? group.first['size'] ?? '15kg');

    // 1. Delivered orders, exactly like the Smart Hub.
    final orderDates = <DateTime>[];
    for (final order in _deliveredOrders) {
      final orderBrand =
          _normalizeCylinderKey(order['brand'] ?? order['brand_name'] ?? '');
      final orderWeight =
          _normalizeCylinderKey(order['size'] ?? order['weight'] ?? '');
      if (orderBrand != targetBrand || orderWeight != targetWeight) continue;

      final date = _dateFor(order['delivered_at'] ??
          order['finalized_at'] ??
          order['created_at']);
      if (date != null) orderDates.add(date);
    }
    if (orderDates.isNotEmpty) {
      return calculateFifo(orderDates, cycleDays: cycleDays);
    }

    // 2. Manual / offline fallback from the saved cylinder document.
    final dates = <DateTime>[];
    for (final cylinder in group) {
      final units = cylinder['units'];
      if (units is List && units.isNotEmpty) {
        for (final unit in units) {
          if (unit is Map) {
            final date =
                _dateFor(unit['lastRefillDate'] ?? unit['purchase_date']);
            if (date != null) dates.add(date);
          }
        }
      } else {
        // A manually registered cylinder without a date is treated as full.
        dates.add(_dateFor(
                cylinder['lastRefillDate'] ?? cylinder['last_refill_date']) ??
            DateTime.now());
      }
    }
    return calculateFifo(dates, cycleDays: cycleDays);
  }

  String _normalizeCylinderKey(dynamic value) =>
      value.toString().replaceAll(RegExp(r'\s+'), '').toLowerCase();

  /// Reads a cylinder's refill cycle in days, accepting `30`, `'30'`,
  /// `'Every 30 days'`, etc. Defaults to 30 days.
  int _cycleDaysFor(Map<String, dynamic> cylinder) {
    return parseCycleDays(cylinder['refillCycle'] ??
        cylinder['refill_cycle'] ??
        cylinder['cycle']);
  }

  /// Converts a Firestore/JSON date field into a [DateTime].
  DateTime? _dateFor(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is String && raw.trim().isNotEmpty) {
      return DateTime.tryParse(raw.trim());
    }
    return null;
  }

  void _showGasSetupSheet() {
    String selectedBrand = AppConstants.gasBrands.first;
    List currentBrandWeights =
        AppConstants.brandSizes[selectedBrand] ?? ['6kg', '15kg', '38kg'];
    String selectedWeight = currentBrandWeights.first;
    String selectedCycle = 'Every 30 days';
    DateTime selectedDate = DateTime.now();

    // 🏷️ NEW: Controllers for home screen modal
    final TextEditingController supplierController = TextEditingController();
    final TextEditingController priceController = TextEditingController();

    final List cycles = [
      'Every 14 days',
      'Every 30 days',
      'Every 45 days',
      'Every 60 days'
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                  top: 20,
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Weka Mtungi & Makadirio ya Gesi',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedBrand,
                      decoration: const InputDecoration(
                          labelText: 'Chapa / Brand',
                          border: OutlineInputBorder()),
                      items: AppConstants.gasBrands
                          .map((brand) => DropdownMenuItem<String>(
                              value: brand, child: Text(brand)))
                          .toList(),
                      onChanged: (String? val) {
                        if (val != null) {
                          setModalState(() {
                            selectedBrand = val;
                            currentBrandWeights =
                                AppConstants.brandSizes[val] ??
                                    ['6kg', '15kg', '38kg'];
                            selectedWeight = currentBrandWeights.first;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedWeight,
                      decoration: const InputDecoration(
                          labelText: 'Uzito / Weight',
                          border: OutlineInputBorder()),
                      items: currentBrandWeights
                          .map((w) => DropdownMenuItem<String>(
                              value: w.toString(), child: Text(w.toString())))
                          .toList(),
                      onChanged: (String? val) {
                        if (val != null) {
                          setModalState(() => selectedWeight = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCycle,
                      decoration: const InputDecoration(
                          labelText: 'Mzunguko / Refill Cycle',
                          border: OutlineInputBorder()),
                      items: cycles
                          .map((c) => DropdownMenuItem<String>(
                              value: c.toString(), child: Text(c.toString())))
                          .toList(),
                      onChanged: (String? val) {
                        if (val != null) {
                          setModalState(() => selectedCycle = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: supplierController,
                      decoration: const InputDecoration(
                        labelText: 'Muuzaji / Depot (Supplier Name)',
                        hintText: 'Mf. Taifa Gas Agent',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Gharama / Price (TZS)',
                        hintText: 'Mf. 25000',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate:
                              DateTime.now().subtract(const Duration(days: 90)),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                            labelText: 'Tarehe ya mwisho ulipojaza',
                            border: OutlineInputBorder()),
                        child:
                            Text('${selectedDate.toLocal()}'.split(' ').first),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SWidthSaveButton(
                        selectedBrand,
                        selectedWeight,
                        selectedCycle,
                        selectedDate,
                        supplierController,
                        priceController),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget SWidthSaveButton(
      String brand,
      String weight,
      String cycle,
      DateTime date,
      TextEditingController supplierController,
      TextEditingController priceController) {
    bool isSaving = false;
    return StatefulBuilder(
      builder: (context, setModalState) {
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: context.colors.primary),
            onPressed: isSaving
                ? null
                : () async {
                    final uid = AuthService.instance.currentUserId;
                    if (uid == null || uid.isEmpty) return;
                    setModalState(() => isSaving = true);
                    try {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('cylinders')
                          .add({
                        'brand': brand,
                        'weight': weight,
                        'refillCycle': cycle,
                        'lastRefillDate': date.toIso8601String(),
                        'purchase_date': date.toIso8601String(),
                        'supplier_name':
                            supplierController.text.trim().isNotEmpty
                                ? supplierController.text.trim()
                                : 'Muuzaji wa Nje',
                        'price':
                            double.tryParse(priceController.text.trim()) ?? 0.0,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      await _fetchUserCylinders();
                      if (mounted) Navigator.pop(context);
                    } catch (e) {
                      if (mounted) setModalState(() => isSaving = false);
                    }
                  },
            child: isSaving
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: context.colors.onPrimary, strokeWidth: 2))
                : Text('Hifadhi Mtungi',
                    style: TextStyle(
                        color: context.colors.onPrimary, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final liveOffers = SessionData.instance.offers.where((offer) {
      final lowercaseIntent = _selectedIntent.toLowerCase();
      if (lowercaseIntent.contains('refill')) {
        return offer.weights.isNotEmpty;
      } else if (lowercaseIntent.contains('full') ||
          lowercaseIntent.contains('set')) {
        return offer.weights.isNotEmpty;
      } else if (lowercaseIntent.contains('service') ||
          lowercaseIntent.contains('technical')) {
        return offer.weights.isNotEmpty;
      }
      return true;
    }).toList();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Funga App / Exit App'),
            content: const Text('Unataka kufunga app?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Hapana')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Ndiyo')),
            ],
          ),
        );
        if (shouldExit == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          title: const Text(
            AppConstants.appName,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
          ),
          actions: [
            const ThemeModeButton(),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'Ondoka / Logout',
              onPressed: _handleLogout,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          color: Theme.of(context).colorScheme.primary,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const OfflineBanner(),
              // 🟢 DYNAMIC PERMANENT LIVE MULTI-ORDER INTERFACE CONTAINER BANNER TRACKER
              _buildPersistentOdaZanguBanner(),
              _buildGasEstimatorCard(),
              const SizedBox(height: 12),

              Text(
                'Unataka kufanya nini? / Choose Service',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),

              // ===== 2×2 CATEGORY GRID =====
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.6,
                children: [
                  _buildCategoryCard(
                    title: 'Refill',
                    subtitle: 'Kujaza',
                    icon: Icons.sync,
                    isSelected: _selectedIntent == 'Refill',
                    onTap: () => setState(() => _selectedIntent = 'Refill'),
                  ),
                  _buildCategoryCard(
                    title: 'Full Set',
                    subtitle: 'Mtungi + Gesi',
                    icon: Icons.inventory_2_outlined,
                    isSelected: _selectedIntent == 'Full Set',
                    onTap: () => setState(() => _selectedIntent = 'Full Set'),
                  ),
                  _buildCategoryCard(
                    title: 'Accessories',
                    subtitle: 'Vifaa',
                    icon: Icons.build_circle_outlined,
                    isSelected: _selectedIntent == 'Accessories',
                    onTap: () =>
                        setState(() => _selectedIntent = 'Accessories'),
                  ),
                  _buildCategoryCard(
                    title: 'Services',
                    subtitle: 'Matengenezo',
                    icon: Icons.handyman_outlined,
                    isSelected: _selectedIntent == 'Services',
                    onTap: () => setState(() => _selectedIntent = 'Services'),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ===== VERTICAL LIST TITLE =====
              Text(
                _getListTitle(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),

              // ===== VERTICAL LIST ITEMS =====
              ..._getListItems().map((item) => _buildVerticalItemCard(item)),

              const SizedBox(height: 24),

              // ===== NEARBY VENDORS (kept for now) =====
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Wauza Gesi Walio Karibu Nawe',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${liveOffers.length} Wauza Gesi',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
              else if (liveOffers.isEmpty)
                _buildEmptyVendorState()
              else
                ...liveOffers.map((offer) => _buildLiveVendorCard(offer)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveVendorCard(VendorOffer offer) {
    final vendor = offer.vendor;
    final minPrice = offer.summary.minPrice;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.colors.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VendorDetailScreen(
                vendorId: vendor.id,
                businessName: vendor.businessName,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: context.colors.primaryContainer,
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.storefront,
                    color: context.colors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.businessName.isNotEmpty
                          ? vendor.businessName
                          : 'Muuzaji Gesi',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '📍 ${vendor.area.isNotEmpty ? vendor.area : 'Dar es Salaam'}',
                      style: TextStyle(fontSize: 11, color: context.colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (vendor.verified)
                          const VerifiedBadge(
                            label: 'Verified Shop',
                            compact: true,
                          ),
                        if (minPrice > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '• Kuanzia TZS ${minPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: context.colors.primary),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.colors.onSurfaceVariant, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyVendorState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.store_mall_directory_outlined,
              size: 40, color: context.colors.outline),
          const SizedBox(height: 8),
          const Text('Hakuna Muuzaji Karibu Nawe',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            'Hakuna muuzaji aliyesajiliwa katika eneo lako kwa sasa. Huduma inazidi kusambaa.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: context.colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class ConsumerOrdersHistoryScreen extends StatelessWidget {
  final String consumerUid;

  const ConsumerOrdersHistoryScreen({super.key, required this.consumerUid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Historia ya Oda Zangu / Orders History',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: OrderService.instance.consumerOrders(consumerUid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: context.colors.primary));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64, color: context.colors.outline),
                  const SizedBox(height: 12),
                  Text('Huna historia ya oda bado',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.colors.onSurface)),
                  const SizedBox(height: 4),
                  Text('Oda zote utakazofanya zitaonekana hapa.',
                      style: TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final orderId = doc.id;
              final brand = data['brand'] ?? 'Gesi';
              final size = data['size'] ?? data['weight'] ?? '15kg';
              final total =
                  (data['total'] ?? data['total_price'] ?? 0).toDouble();
              final status =
                  (data['status'] ?? 'placed').toString().toLowerCase().trim();
              final intent = data['order_intent'] ?? 'new_asset';
              final createdAt = (data['created_at'] as Timestamp?)?.toDate() ??
                  DateTime.now();

              Color badgeColor = context.colors.primary;
              String statusLabel = 'Inasubiri';
              if (status == 'delivered' || status == 'completed') {
                badgeColor = context.gasColors.success;
                statusLabel = 'Imekamilika';
              } else if (status == 'on_the_way' || status == 'in_transit') {
                badgeColor = context.colors.tertiary;
                statusLabel = 'Ipo Njiani';
              } else if (status == 'confirmed' ||
                  status == 'accepted' ||
                  status == 'preparing') {
                badgeColor = context.colors.secondary;
                statusLabel = 'Inaandaliwa';
              } else if (status == 'cancelled' || status == 'rejected') {
                badgeColor = context.colors.error;
                statusLabel = 'Imekataliwa/Imeghairiwa';
              }

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: context.colors.outlineVariant),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConsumerOrderScreen(
                          orderId: orderId,
                          vendorId: data['vendor_id'] ?? '',
                          vendorName: data['vendor_name'] ?? 'Gas Vendor',
                          brandName: brand,
                          cylinderSize: size,
                          unitPrice: (data['unit_price'] ?? 0).toDouble(),
                          totalPrice: total,
                          deliveryAddress: data['delivery_address'] ?? '',
                          contactPhone: data['contact_phone'] ?? '',
                          paymentMethod: data['payment_method'] ?? 'cash',
                          quantity: (data['quantity'] ?? 1).toInt(),
                          specialRequests: data['special_requests'] ?? '',
                          receiverPhone: data['receiver_phone'] ?? '',
                          orderIntent: intent,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: context.colors.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.propane_tank,
                              color: context.colors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('$brand ($size)',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: context.colors.onSurface)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(statusLabel,
                                        style: TextStyle(
                                            color: badgeColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                  'TZS ${total.toStringAsFixed(0)} • ${intent == 'add_stock' ? 'Ongeza Akiba' : 'Mtungi Mpya'}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: context.colors.onSurfaceVariant)),
                              const SizedBox(height: 2),
                              Text(
                                  'Tarehe: ${createdAt.toLocal()}'
                                      .split('.')
                                      .first,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: context.colors.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right,
                            color: context.colors.onSurfaceVariant, size: 18),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
