// lib/screens/consumer/consumer_home_screen.dart
// Consumer Discovery & Tracking Dashboard for LPG consumers in Dar es Salaam.
// Integrates persistent "Oda Zangu" mini-order tracking banners, live gauges, and real-time synchronizations.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/constants.dart';
import '../../core/session_data.dart';
import '../../core/session_gate.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../utils/cylinder_fifo.dart';
import '../auth/landing_screen.dart';
import '../auth/register_screen.dart';
import 'consumer_cylinder_screen.dart';
import 'consumer_order_screen.dart';
import 'consumer_profile_screen.dart';
import 'consumer_settings_screen.dart';
import 'vendor_detail_screen.dart';
import '../../models/order.dart' as models;
import '../../widgets/ad_slot.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/referral_card.dart';
import '../../widgets/root_back_guard.dart';
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

  static const int _stockPageSize = 10;
  int _visibleItemCount = _stockPageSize;

  void _selectIntent(String intent) {
    setState(() {
      _selectedIntent = intent;
      _visibleItemCount = _stockPageSize;
    });
  }

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
          color: isSelected
              ? context.colors.primaryContainer
              : context.colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? context.colors.primary
                : context.colors.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isSelected
                    ? context.colors.primary
                    : context.colors.onSurfaceVariant,
                size: 26),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected
                    ? context.colors.primary
                    : context.colors.onSurface,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? context.colors.primary
                    : context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getListTitle(AppLocalizations l10n) {
    switch (_selectedIntent) {
      case 'Full Set':
        return l10n.selectBrandFullSet;
      case 'Accessories':
        return l10n.selectAccessory;
      case 'Services':
        return l10n.selectService;
      default:
        return l10n.selectBrandRefill;
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
        trailing:
            Icon(Icons.chevron_right, color: context.colors.onSurfaceVariant),
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
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logoutTitle),
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                Text(l10n.logout, style: TextStyle(color: context.colors.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LandingScreen()),
          (route) => false,
        );
      }
    }
  }

  /// 🟢 PERSISTENT "ODA ZANGU" WORKSPACE TRACKER BANNER
  Widget _buildPersistentOdaZanguBanner() {
    final l10n = AppLocalizations.of(context);
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

        String displayStatus = l10n.orderPlacedSubtitle;
        Color statusTextColor = context.colors.primary;
        IconData statusIcon = Icons.access_time_rounded;
        int currentStepIndex = 0;

        if (rawStatus == 'seen') {
          displayStatus = l10n.orderSeenChecking;
          statusTextColor = context.gasColors.info;
          statusIcon = Icons.visibility_outlined;
          currentStepIndex = 0;
        } else if (rawStatus == 'accepted' ||
            rawStatus == 'confirmed' ||
            rawStatus == 'preparing') {
          displayStatus = l10n.orderAcceptedSubtitle;
          statusTextColor = context.colors.secondary;
          statusIcon = Icons.inventory_2_outlined;
          currentStepIndex = 1;
        } else if (rawStatus == 'on_the_way' ||
            rawStatus == 'dispatched' ||
            rawStatus == 'in_transit') {
          displayStatus = l10n.orderOnTheWaySubtitle;
          statusTextColor = context.colors.tertiary;
          statusIcon = Icons.two_wheeler;
          currentStepIndex = 2;
        } else if (rawStatus == 'delivered_pending') {
          displayStatus = l10n.orderArrivedConfirm;
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
                          Icon(statusIcon,
                              color: context.colors.primary, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            l10n.activeTracker,
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
                            color: isDone
                                ? context.colors.primary
                                : context.colors.outlineVariant,
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
                            ? '🔄 ${l10n.orderAddStock}'
                            : '📦 ${l10n.orderNewCylinder}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        l10n.tapToOpenDetails,
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
    final l10n = AppLocalizations.of(context);
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
                        l10n.orderHistoryCenter,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: context.colors.onSurface),
                      ),
                      SizedBox(height: 2),
                      Text(
                        l10n.noActiveOrder,
                        style: TextStyle(
                            fontSize: 11,
                            color: context.colors.onSurfaceVariant),
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
                label: Text(
                  l10n.openAllOrdersHistory,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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
              (data['vendor_name'] ?? data['vendorName'] ??
                      AppLocalizations.of(context).vendorFallback)
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

  /// Compact overview of the consumer's registered cylinders. Tapping through
  /// opens the Smart Hub (or the setup sheet when nothing is registered yet).
  Widget _buildMyCylindersOverview() {
    final l10n = AppLocalizations.of(context);
    final hasCylinders = _myCylinders.isNotEmpty;
    final labels = <String>{};
    for (final cylinder in _myCylinders) {
      final brand = (cylinder['brand'] ?? 'Gesi').toString();
      final weight =
          (cylinder['weight'] ?? cylinder['size'] ?? '').toString().trim();
      labels.add(weight.isEmpty ? brand : '$brand $weight');
    }

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.propane_tank_outlined,
              size: 24,
              color: context.colors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasCylinders
                      ? l10n.cylindersRegistered(_myCylinders.length)
                      : l10n.noCylinderRegistered,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasCylinders
                      ? labels.join(' · ')
                      : l10n.registerCylinderHint,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
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
            child: Text(hasCylinders ? l10n.manage : l10n.setUp),
          ),
        ],
      ),
    );
  }

  Widget _buildGasEstimatorCard() {
    final l10n = AppLocalizations.of(context);
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
            l10n.gasEstimate,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: context.colors.onSurface,
                letterSpacing: 0.3),
          ),
          const SizedBox(height: 16),
          if (!hasCylinders) ...[
            Text(
              l10n.noCylinderRegistered,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.colors.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.registerCylinderToEstimate,
              style: TextStyle(
                  fontSize: 12, color: context.colors.onSurfaceVariant),
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
                      children: [
                        Expanded(
                          child: Text(
                            '$brandName $weight',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: context.colors.onSurface),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            isTankEmptyState
                                ? l10n.emptyPercent
                                : l10n.daysLeft(estimatedDaysLeft,
                                    remainingPercentage),
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isCriticalLow
                                  ? context.colors.error
                                  : context.colors.primary,
                            ),
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
                              backgroundColor:
                                  context.colors.surfaceContainerLow,
                              color: isCriticalLow
                                  ? context.colors.error
                                  : context.colors.primary,
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
                    hasCylinders ? l10n.moreInfo : l10n.setNow,
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
                        _selectIntent('Refill');
                      }
                    },
                    icon: const Icon(Icons.bolt, size: 16),
                    label: Text(l10n.reorder,
                        style: const TextStyle(
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
        final l10n = AppLocalizations.of(context);
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
                    Text(l10n.addCylinderEstimateTitle,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedBrand,
                      decoration: InputDecoration(
                          labelText: l10n.brandLabel,
                          border: const OutlineInputBorder()),
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
                      decoration: InputDecoration(
                          labelText: l10n.weightLabel,
                          border: const OutlineInputBorder()),
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
                      decoration: InputDecoration(
                          labelText: l10n.refillCycleLabel,
                          border: const OutlineInputBorder()),
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
                      decoration: InputDecoration(
                        labelText: l10n.supplierLabel,
                        hintText: l10n.supplierHint,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.priceLabel,
                        hintText: l10n.priceHint,
                        border: const OutlineInputBorder(),
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
                        decoration: InputDecoration(
                            labelText: l10n.lastRefillDateLabel,
                            border: const OutlineInputBorder()),
                        child: Text(
                            MaterialLocalizations.of(context)
                                .formatMediumDate(selectedDate.toLocal())),
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
            style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary),
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
                : Text(AppLocalizations.of(context).saveCylinder,
                    style: TextStyle(
                        color: context.colors.onPrimary,
                        fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Future<void> _leaveGuestMode() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final guestMode = AuthService.instance.isGuest;
    final allItems = _getListItems();
    final visibleItemCount = _visibleItemCount < allItems.length
        ? _visibleItemCount
        : allItems.length;
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
    return RootBackGuard(
      onBack: guestMode ? _leaveGuestMode : null,
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
            IconButton(
              icon: const Icon(Icons.person_outline, color: Colors.white),
              tooltip: l10n.profile,
              onPressed: () async {
                if (await SessionGate.requireConsumer(context)) {
                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ConsumerProfileScreen(),
                    ),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              tooltip: l10n.settings,
              onPressed: () async {
                if (await SessionGate.requireConsumer(context)) {
                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ConsumerSettingsScreen(),
                    ),
                  );
                }
              },
            ),
            const ThemeModeButton(),
            if (guestMode)
              IconButton(
                icon: const Icon(Icons.login, color: Colors.white),
                tooltip: l10n.login,
                onPressed: () async {
                  await SessionGate.requireConsumer(context);
                },
              )
            else
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: l10n.logout,
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
              AppSectionHeader(
                title: l10n.welcomeTitle,
                subtitle: l10n.welcomeSubtitle,
                icon: Icons.local_fire_department,
              ),
              const SizedBox(height: 12),
              if (guestMode) ...[
                _buildGuestBanner(),
                const SizedBox(height: 12),
              ] else ...[
                AppSectionHeader(
                  title: l10n.myOrders,
                  subtitle: l10n.myOrdersSubtitle,
                  icon: Icons.local_shipping_outlined,
                ),
                const SizedBox(height: 10),
                // 🟢 DYNAMIC PERMANENT LIVE MULTI-ORDER INTERFACE CONTAINER BANNER TRACKER
                _buildPersistentOdaZanguBanner(),
                const SizedBox(height: 16),
                AppSectionHeader(
                  title: l10n.myCylinders,
                  subtitle: l10n.myCylindersSubtitleHome,
                  icon: Icons.propane_tank_outlined,
                ),
                const SizedBox(height: 10),
                _buildMyCylindersOverview(),
                const SizedBox(height: 16),
                AppSectionHeader(
                  title: l10n.gasEstimator,
                  subtitle: l10n.gasEstimatorSubtitle,
                  icon: Icons.speed_outlined,
                ),
                const SizedBox(height: 10),
                _buildGasEstimatorCard(),
                const SizedBox(height: 12),
              ],

              if (!guestMode) ...[
                ReferralCard(
                  uid: AuthService.instance.currentUserId ?? '',
                  role: 'consumer',
                  showVendorInvite: true,
                ),
                const SizedBox(height: 20),
              ],

              AppSectionHeader(
                title: l10n.chooseService,
                icon: Icons.grid_view_outlined,
              ),
              const SizedBox(height: 10),

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
                    subtitle: l10n.refillSubtitle,
                    icon: Icons.sync,
                    isSelected: _selectedIntent == 'Refill',
                    onTap: () => _selectIntent('Refill'),
                  ),
                  _buildCategoryCard(
                    title: 'Accessories',
                    subtitle: l10n.accessoriesSubtitle,
                    icon: Icons.build_circle_outlined,
                    isSelected: _selectedIntent == 'Accessories',
                    onTap: () => _selectIntent('Accessories'),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ===== VERTICAL LIST TITLE =====
              AppSectionHeader(
                title: _getListTitle(l10n),
                icon: Icons.category_outlined,
              ),
              const SizedBox(height: 10),

              // ===== VERTICAL LIST ITEMS (10 at a time) =====
              ...allItems
                  .take(visibleItemCount)
                  .map((item) => _buildVerticalItemCard(item)),

              if (visibleItemCount < allItems.length) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    l10n.showingItems(visibleItemCount, allItems.length),
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => _visibleItemCount += _stockPageSize),
                    icon: const Icon(Icons.expand_more),
                    label: Text(l10n.viewMore),
                  ),
                ),
              ],

              const SizedBox(height: 20),
              const AdSlot(placementId: 'consumer_home'),
              const SizedBox(height: 24),

              // ===== NEARBY VENDORS =====
              AppSectionHeader(
                title: l10n.nearbyVendors,
                subtitle: l10n.nearbyVendorsSubtitle,
                icon: Icons.storefront_outlined,
                trailing: AppStatusPill(
                  label: l10n.vendorsCount(liveOffers.length),
                  color: context.colors.primary,
                ),
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

  /// Guest-only card: explains the visitor mode and pushes account creation.
  /// Replaces the order tracker and cylinder gauges for unregistered users.
  Widget _buildGuestBanner() {
    final l10n = AppLocalizations.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.colors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.visibility_outlined,
                    color: context.colors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.browsingAsGuest,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.browsingAsGuestBody,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LandingScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.login, size: 18),
                    label: Text(l10n.login),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.person_add_alt, size: 18),
                    label: Text(l10n.createAccount),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveVendorCard(VendorOffer offer) {
    final l10n = AppLocalizations.of(context);
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
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                    color: context.colors.primaryContainer,
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.storefront,
                    color: context.colors.primary, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.businessName.isNotEmpty
                          ? vendor.businessName
                          : l10n.vendorFallback,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '📍 ${vendor.area.isNotEmpty ? vendor.area : 'Dar es Salaam'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11, color: context.colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (vendor.verified)
                          VerifiedBadge(
                            label: l10n.verifiedShop,
                            compact: true,
                          ),
                        if (minPrice > 0)
                          AppStatusPill(
                            label: l10n
                                .fromPrice(minPrice.toStringAsFixed(0)),
                            icon: Icons.local_offer_outlined,
                            color: context.colors.primary,
                          ),
                      ],
                    ),
                    if (offer.vendorBrands.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final brand in offer.vendorBrands.take(3))
                            AppStatusPill(
                              label: brand,
                              color: context.colors.onSurfaceVariant,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: context.colors.onSurfaceVariant, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyVendorState() {
    final l10n = AppLocalizations.of(context);
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
          Text(l10n.noVendorsTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            l10n.noVendorsBody,
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 11, color: context.colors.onSurfaceVariant),
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.ordersHistoryTitle,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: OrderService.instance.consumerOrders(consumerUid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: context.colors.primary),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: l10n.noOrderHistory,
              message: l10n.noOrderHistoryBody,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSectionHeader(
                      title: l10n.historyAllOrdersTitle,
                      subtitle: l10n.historyOrdersFound(docs.length),
                      icon: Icons.receipt_long_outlined,
                      trailing: AppStatusPill(
                        label: '${docs.length}',
                        icon: Icons.list_alt,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }

              final doc = docs[index - 1];
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final orderId = doc.id;
              final brand = (data['brand'] ?? 'Gesi').toString();
              final size =
                  (data['size'] ?? data['weight'] ?? '15kg').toString();
              final total = ((data['total'] ?? data['total_price'] ?? 0) as num)
                  .toDouble();
              final status =
                  (data['status'] ?? 'placed').toString().toLowerCase().trim();
              final intent = (data['order_intent'] ?? 'new_asset').toString();
              final createdAt = (data['created_at'] as Timestamp?)?.toDate() ??
                  DateTime.now();

              final statusStyle = _statusStyle(context, status, l10n);

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
                          vendorId:
                              (data['vendor_id'] ?? data['vendorId'] ?? '')
                                  .toString(),
                          vendorName: (data['vendor_name'] ??
                                  data['vendorName'] ??
                                  l10n.vendorFallback)
                              .toString(),
                          brandName: brand,
                          cylinderSize: size,
                          unitPrice:
                              (data['unit_price'] as num?)?.toDouble() ?? 0.0,
                          totalPrice: total,
                          deliveryAddress: (data['delivery_address'] ??
                                  data['deliveryAddress'] ??
                                  '')
                              .toString(),
                          contactPhone: (data['contact_phone'] ??
                                  data['consumerPhone'] ??
                                  '')
                              .toString(),
                          paymentMethod:
                              (data['payment_method'] ?? 'cash').toString(),
                          quantity: (data['quantity'] as num?)?.toInt() ?? 1,
                          specialRequests:
                              (data['special_requests'] ?? '').toString(),
                          receiverPhone:
                              (data['receiver_phone'] ?? '').toString(),
                          orderIntent: intent,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: context.colors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.propane_tank_outlined,
                            color: context.colors.primary,
                            size: 23,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '$brand ($size)',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                        color: context.colors.onSurface,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  AppStatusPill(
                                    label: statusStyle.$1,
                                    icon: statusStyle.$2,
                                    color: statusStyle.$3,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'TZS ${_formatMoney(total)} · ${intent == 'add_stock' ? l10n.orderAddStock : l10n.orderNewCylinder}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _formatOrderDate(context, createdAt),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: context.colors.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.chevron_right,
                          color: context.colors.onSurfaceVariant,
                          size: 18,
                        ),
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

  static (String, IconData, Color) _statusStyle(
    BuildContext context,
    String status,
    AppLocalizations l10n,
  ) {
    if (status == 'delivered' || status == 'completed') {
      return (
        l10n.orderStatusDelivered,
        Icons.check_circle_outline,
        context.gasColors.success,
      );
    }
    if (status == 'on_the_way' || status == 'in_transit') {
      return (
        l10n.orderStatusOnTheWay,
        Icons.local_shipping_outlined,
        context.colors.tertiary,
      );
    }
    if (status == 'confirmed' ||
        status == 'accepted' ||
        status == 'preparing' ||
        status == 'seen') {
      return (
        l10n.orderStatusPreparing,
        Icons.hourglass_top,
        context.colors.secondary,
      );
    }
    if (status == 'cancelled' || status == 'rejected' || status == 'refused') {
      return (
        l10n.orderStatusCancelled,
        Icons.cancel_outlined,
        context.colors.error,
      );
    }
    return (
      l10n.orderStatusPending,
      Icons.schedule,
      context.colors.primary,
    );
  }

  static String _formatOrderDate(BuildContext context, DateTime date) {
    final local = date.toLocal();
    final dateLabel = MaterialLocalizations.of(context).formatMediumDate(local);
    final timeLabel = TimeOfDay.fromDateTime(local).format(context);
    return '$dateLabel · $timeLabel';
  }

  static String _formatMoney(double value) {
    final whole = value.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      final remaining = whole.length - i;
      buffer.write(whole[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
    }
    return buffer.toString();
  }
}
