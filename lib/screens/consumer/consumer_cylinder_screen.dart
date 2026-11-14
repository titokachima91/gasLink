// lib/screens/consumer/consumer_cylinder_screen.dart
// Central Smart Gas Hub Management Panel tracking multi-cylinder assets natively.
// Supports complete CRUD operations (Add/Edit/Delete) with direct cloud collection syncing.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../../utils/cylinder_fifo.dart';
import '../../widgets/app_ui.dart';

import '../../core/theme_ext.dart';

class ConsumerCylinderScreen extends StatefulWidget {
  final List<Map<String, dynamic>> initialCylinders;
  final Map<String, dynamic>? lastCompletedOrder;

  const ConsumerCylinderScreen({
    super.key,
    this.initialCylinders = const [],
    this.lastCompletedOrder,
  });

  @override
  State<ConsumerCylinderScreen> createState() => _ConsumerCylinderScreenState();
}

class _ConsumerCylinderScreenState extends State<ConsumerCylinderScreen> {
  List<Map<String, dynamic>> _allUserCylinders = [];
  bool _isLoading = false;
  int _expandedIndex = -1; // Tracks which card drawer is toggled open
  // Cached per-cylinder unit queries so rebuilding a card does not refire
  // Firestore reads or write to the database during build.
  final Map<String, Future<List<Map<String, dynamic>>>> _unitsCache = {};

  @override
  void initState() {
    super.initState();
    _allUserCylinders =
        List<Map<String, dynamic>>.from(widget.initialCylinders);
    _fetchCompleteCylinderStack();
  }

  Future<List<Map<String, dynamic>>> _fetchUnitsForCylinder(
    String brand,
    String weight, {
    int cycleDays = 30,
    Map<String, dynamic>? fallbackCylinder,
  }) async {
    final uid = AuthService.instance.currentUserId;
    if (uid == null || uid.isEmpty) return [];

    try {
      final orderDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      try {
        final snap = await FirebaseFirestore.instance
            .collection('orders')
            .where('consumer_uid', isEqualTo: uid)
            .where('status', isEqualTo: 'delivered')
            .get();
        orderDocs.addAll(snap.docs);
      } catch (e) {
        // Missing index / offline: the saved cylinder data below still works.
        debugPrint('Error fetching order history: $e');
      }

      final targetBrand = _normalizeKey(brand);
      final targetWeight = _normalizeKey(weight);

      final rawUnits = <Map<String, dynamic>>[];

      for (final doc in orderDocs) {
        final data = doc.data();
        final orderBrand =
            _normalizeKey(data['brand'] ?? data['brand_name'] ?? '');
        final orderWeight = _normalizeKey(data['size'] ?? data['weight'] ?? '');

        if (orderBrand != targetBrand || orderWeight != targetWeight) continue;

        // Real vendor name from order, then from vendor document
        String vendorName = (data['vendor_name'] ??
                data['shop_name'] ??
                data['vendorName'] ??
                data['businessName'] ??
                '')
            .toString()
            .trim();

        if (vendorName.isEmpty) {
          final vendorId =
              (data['vendor_id'] ?? data['vendorId'] ?? '').toString();
          if (vendorId.isNotEmpty) {
            try {
              final vDoc = await FirebaseFirestore.instance
                  .collection('vendors')
                  .doc(vendorId)
                  .get();
              if (vDoc.exists) {
                final vData = vDoc.data() ?? {};
                vendorName = (vData['businessName'] ??
                        vData['business_name'] ??
                        vData['shop_name'] ??
                        '')
                    .toString();
              }
            } catch (_) {}
          }
        }
        if (vendorName.isEmpty) vendorName = 'Muuzaji Rasmi';

        final price =
            (data['total_price'] ?? data['totalPrice'] ?? data['total'] ?? 0)
                .toDouble();

        final date = _dateFor(data['delivered_at']) ??
            _dateFor(data['finalized_at']) ??
            _dateFor(data['created_at']);
        if (date == null) continue;

        rawUnits.add({
          'id': doc.id,
          'supplier_name': vendorName,
          'price': price,
          'lastRefillDate': date.toIso8601String(),
          'purchase_date': date.toIso8601String(),
          'deliveryDate': date,
        });
      }

      // No delivered order for this brand/size: fall back to the cylinder
      // document itself (manual entry or pre-order data).
      if (rawUnits.isEmpty && fallbackCylinder != null) {
        final savedUnits = fallbackCylinder['units'];
        if (savedUnits is List && savedUnits.isNotEmpty) {
          for (final unit in savedUnits) {
            if (unit is! Map) continue;
            final date =
                _dateFor(unit['lastRefillDate'] ?? unit['purchase_date']);
            if (date == null) continue;
            rawUnits.add({
              'id': unit['id'] ?? date.millisecondsSinceEpoch.toString(),
              'supplier_name': unit['supplier_name'] ??
                  fallbackCylinder['supplier_name'] ??
                  'Muuzaji Rasmi',
              'price': unit['price'] ?? fallbackCylinder['price'] ?? 0.0,
              'lastRefillDate':
                  unit['lastRefillDate'] ?? date.toIso8601String(),
              'purchase_date': unit['purchase_date'] ?? date.toIso8601String(),
              'deliveryDate': date,
            });
          }
        }

        if (rawUnits.isEmpty) {
          final date = _dateFor(fallbackCylinder['lastRefillDate'] ??
                  fallbackCylinder['purchase_date']) ??
              DateTime.now();
          rawUnits.add({
            'id': fallbackCylinder['id'] ??
                date.millisecondsSinceEpoch.toString(),
            'supplier_name':
                fallbackCylinder['supplier_name'] ?? 'Muuzaji Rasmi',
            'price': fallbackCylinder['price'] ?? 0.0,
            'lastRefillDate': date.toIso8601String(),
            'purchase_date': date.toIso8601String(),
            'deliveryDate': date,
          });
        }
      }

      // Oldest first, then let the shared FIFO model deplete them.
      rawUnits.sort((a, b) {
        final da = a['deliveryDate'] as DateTime;
        final db = b['deliveryDate'] as DateTime;
        return da.compareTo(db);
      });

      final fifo = calculateFifo(
        rawUnits.map((unit) => unit['deliveryDate'] as DateTime).toList(),
        cycleDays: cycleDays,
      );

      final units = <Map<String, dynamic>>[];
      for (var i = 0; i < rawUnits.length; i++) {
        final raw = rawUnits[i];
        final computed = fifo.units[i];
        units.add({
          'id': raw['id'],
          'supplier_name': raw['supplier_name'],
          'price': raw['price'],
          'lastRefillDate': raw['lastRefillDate'],
          'purchase_date': raw['purchase_date'],
          'remainingDays': computed.remainingDays,
          'percentage': computed.percentage,
          'cycleDays': cycleDays,
        });
      }

      return units;
    } catch (e) {
      debugPrint('Error fetching units from orders: $e');
      return [];
    }
  }

  String _normalizeKey(dynamic value) =>
      value.toString().replaceAll(RegExp(r'\s+'), '').toLowerCase();

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

  Future<List<Map<String, dynamic>>> _unitsForCylinder(
    Map<String, dynamic> cylinder,
    String brand,
    String weight,
    int cycleDays,
  ) {
    final key = (cylinder['id'] ?? '$brand|$weight').toString();
    return _unitsCache.putIfAbsent(
      key,
      () => _fetchUnitsForCylinder(
        brand,
        weight,
        cycleDays: cycleDays,
        fallbackCylinder: cylinder,
      ),
    );
  }

  /// Sums FIFO units into the collective reading.
  ///
  /// - days: sum of remaining days.
  /// - percentage: sum of per-unit percentages (2 full = 200%).
  /// - fraction: remaining capacity ÷ total capacity (2 full = 1.0).
  ({int days, double percentage, double fraction}) _collectiveFromUnits(
      List<Map<String, dynamic>> units, int cycleDays) {
    int days = 0;
    double percentage = 0.0;
    int capacityDays = 0;

    for (final unit in units) {
      days += (unit['remainingDays'] as num?)?.toInt() ?? 0;
      percentage += (unit['percentage'] as num?)?.toDouble() ?? 0.0;
      capacityDays += (unit['cycleDays'] as num?)?.toInt() ?? cycleDays;
    }

    final fraction = capacityDays > 0
        ? (days / capacityDays).clamp(0.0, 1.0).toDouble()
        : 0.0;

    return (days: days, percentage: percentage, fraction: fraction);
  }

  /// 🔄 Pulls all saved tank entries flat from subcollection
  Future<void> _fetchCompleteCylinderStack() async {
    final uid = AuthService.instance.currentUserId;
    if (uid == null || uid.isEmpty) return;
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      _unitsCache.clear();
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('cylinders')
          .orderBy('createdAt', descending: true)
          .get();

      if (mounted) {
        setState(() {
          _allUserCylinders = snap.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 🚨 Erases an entry completely from cloud database node
  Future<void> _deleteCylinderNode(String docId) async {
    final uid = AuthService.instance.currentUserId;
    if (uid == null || uid.isEmpty || docId.isEmpty) return;

    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteCylinderTitle),
        content: Text(l10n.deleteCylinderBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete,
                style: TextStyle(
                    color: context.colors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('cylinders')
            .doc(docId)
            .delete();
        await _fetchCompleteCylinderStack();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.cylinderDeleted)));
        }
      } catch (e) {
        debugPrint('Delete error: $e');
      }
    }
  }

  /// ⚙️ Unified sheet tray context manager forms for Add and Edit modes
  void _showCylinderFormModal({Map<String, dynamic>? existingCylinder}) {
    final isEditing = existingCylinder != null;
    String selectedBrand =
        (existingCylinder?['brand'] ?? AppConstants.gasBrands.first).toString();
    List<String> currentWeights =
        AppConstants.brandSizes[selectedBrand] ?? ['6kg', '15kg', '38kg'];
    String selectedWeight =
        (existingCylinder?['weight'] ?? currentWeights.first).toString();
    String selectedCycle =
        (existingCylinder?['refillCycle'] ?? 'Every 30 days').toString();
    DateTime selectedDate =
        DateTime.tryParse(existingCylinder?['lastRefillDate'] ?? '') ??
            DateTime.now();

    // 🏷️ NEW: Controllers for manual supplier name and price inputs
    final TextEditingController supplierController = TextEditingController(
      text: (existingCylinder?['supplier_name'] ?? '').toString(),
    );
    final TextEditingController priceController = TextEditingController(
      text: existingCylinder?['price'] != null
          ? existingCylinder!['price'].toString()
          : '',
    );

    final List<String> cycles = [
      'Every 14 days',
      'Every 30 days',
      'Every 45 days',
      'Every 60 days'
    ];
    bool isSavingNode = false;

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
                    Text(
                        isEditing
                            ? l10n.editCylinderTitle
                            : l10n.addCylinderTitle,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedBrand,
                      decoration: InputDecoration(
                          labelText: l10n.brandLabel,
                          border: const OutlineInputBorder()),
                      items: AppConstants.gasBrands
                          .map(
                              (b) => DropdownMenuItem(value: b, child: Text(b)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedBrand = val;
                            currentWeights = AppConstants.brandSizes[val] ??
                                ['6kg', '15kg', '38kg'];
                            selectedWeight = currentWeights.first;
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
                      items: currentWeights
                          .map(
                              (w) => DropdownMenuItem(value: w, child: Text(w)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null)
                          setModalState(() => selectedWeight = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCycle,
                      decoration: InputDecoration(
                          labelText: l10n.refillCycleLabel,
                          border: const OutlineInputBorder()),
                      items: cycles
                          .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null)
                          setModalState(() => selectedCycle = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    // 🏷️ NEW: Supplier Name Text Field
                    TextField(
                      controller: supplierController,
                      decoration: InputDecoration(
                        labelText: l10n.supplierLabel,
                        hintText: l10n.supplierHint,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 🏷️ NEW: Price Text Field
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
                          initialDate: selectedDate,
                          firstDate:
                              DateTime.now().subtract(const Duration(days: 90)),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null)
                          setModalState(() => selectedDate = picked);
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
                        isSavingNode,
                        setModalState,
                        isEditing,
                        selectedBrand,
                        selectedWeight,
                        selectedCycle,
                        selectedDate,
                        supplierController,
                        priceController,
                        existingCylinder),
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
      bool isSavingNode,
      StateSetter setModalState,
      bool isEditing,
      String brand,
      String weight,
      String cycle,
      DateTime date,
      TextEditingController supplierController,
      TextEditingController priceController,
      Map<String, dynamic>? existing) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style:
            ElevatedButton.styleFrom(backgroundColor: context.colors.primary),
        onPressed: isSavingNode
            ? null
            : () async {
                final uid = AuthService.instance.currentUserId;
                if (uid == null || uid.isEmpty) return;
                setModalState(() => isSavingNode = true);
                try {
                  final payload = {
                    'brand': brand,
                    'weight': weight,
                    'refillCycle': cycle,
                    'lastRefillDate': date.toIso8601String(),
                    'purchase_date': date.toIso8601String(),
                    'supplier_name': supplierController.text.trim().isNotEmpty
                        ? supplierController.text.trim()
                        : 'Muuzaji wa Nje',
                    'price':
                        double.tryParse(priceController.text.trim()) ?? 0.0,
                    'createdAt': FieldValue.serverTimestamp(),
                  };
                  final collectionRef = FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('cylinders');
                  if (isEditing && existing != null) {
                    await collectionRef.doc(existing['id']).update(payload);
                  } else {
                    await collectionRef.add(payload);
                  }
                  await _fetchCompleteCylinderStack();
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  setModalState(() => isSavingNode = false);
                }
              },
        child: isSavingNode
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: context.colors.onPrimary, strokeWidth: 2))
            : Text(
                isEditing
                    ? AppLocalizations.of(context).saveChanges
                    : AppLocalizations.of(context).saveCylinder,
                style: TextStyle(
                    color: context.colors.onPrimary,
                    fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // We no longer rely on lastCompletedOrder for display.
// Each cylinder now carries its own supplier_name and price.
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(l10n.cylinderHubTitle,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionHeader(
              title: l10n.cylinderHubTitle,
              subtitle: l10n.cylinderHubSubtitle,
              icon: Icons.propane_tank_outlined,
              trailing: TextButton.icon(
                onPressed: () => _showCylinderFormModal(),
                icon: Icon(Icons.add, size: 16, color: context.colors.primary),
                label: Text(
                  l10n.addAction,
                  style: TextStyle(
                    color: context.colors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_isLoading)
              Center(
                  child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(
                          color: context.colors.primary)))
            else if (_allUserCylinders.isEmpty)
              AppEmptyState(
                icon: Icons.propane_tank_outlined,
                title: l10n.noCylindersTitle,
                message: l10n.noCylindersBody,
                actionLabel: l10n.addCylinderAction,
                onAction: _showCylinderFormModal,
              )
            else
              ..._allUserCylinders.asMap().entries.map((entry) {
                final idx = entry.key;
                final cylinder = entry.value;
                final isExpanded = _expandedIndex == idx;
                return _buildDynamicAssetCard(idx, cylinder, isExpanded);
              }),
            const SizedBox(height: 24),
            AppSectionHeader(
              title: l10n.smartFeaturesTitle,
              subtitle: l10n.smartFeaturesSubtitle,
              icon: Icons.auto_awesome_outlined,
            ),
            const SizedBox(height: 10),
            _buildMenuCard(
                l10n.featureDishLogger, l10n.featureDishLoggerShort),
            _buildMenuCard(
                l10n.featureLpgMatrix, l10n.featureLpgMatrixShort),
            _buildMenuCard(
                l10n.featureBrandSwap, l10n.featureBrandSwapShort),
            _buildMenuCard(
                l10n.featureTrivia, l10n.featureTriviaShort),
            _buildMenuCard(
                l10n.featureFraudShield, l10n.featureFraudShieldShort),
            _buildMenuCard(
                l10n.featureBubbleTest, l10n.featureBubbleTestShort),
            _buildMenuCard(
                l10n.featureCarbonTracker, l10n.featureCarbonTrackerShort),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicAssetCard(
      int idx, Map<String, dynamic> cyl, bool isExpanded) {
    final l10n = AppLocalizations.of(context);
    final String brand = (cyl['brand'] ?? 'Gesi').toString();
    final String weight = (cyl['weight'] ?? cyl['size'] ?? '').toString();
    final int cycleDays = parseCycleDays(cyl['refillCycle']);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.colors.outlineVariant),
      ),
      child: Column(
        children: [
          // ===== HEADER (always visible) =====
          ListTile(
            onTap: () => setState(() => _expandedIndex = isExpanded ? -1 : idx),
            leading: Icon(Icons.propane_tank,
                color: context.colors.primary, size: 28),
            title: Text(
              '$brand ($weight)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: FutureBuilder<List<Map<String, dynamic>>>(
              future: _unitsForCylinder(cyl, brand, weight, cycleDays),
              builder: (context, snapshot) {
                final waiting =
                    snapshot.connectionState == ConnectionState.waiting;
                final units = snapshot.data ?? const <Map<String, dynamic>>[];

                // Fall back to the stored document values only while the
                // FIFO query is still running.
                final collective = waiting || units.isEmpty
                    ? (
                        days: (cyl['remainingDays'] as num?)?.toInt() ?? 0,
                        percentage:
                            (cyl['percentage'] as num?)?.toDouble() ?? 0.0,
                        fraction:
                            (((cyl['percentage'] as num?)?.toDouble() ?? 0.0) /
                                    100.0)
                                .clamp(0.0, 1.0)
                                .toDouble(),
                      )
                    : _collectiveFromUnits(units, cycleDays);

                final isEmpty = collective.days <= 0;
                final isCritical = collective.fraction <= 0.15 || isEmpty;

                return Text(
                  isExpanded
                      ? l10n.tapToClose
                      : (isEmpty
                          ? l10n.emptyPercent
                          : l10n.daysLeft(
                              collective.days,
                              collective.percentage.toStringAsFixed(1))),
                  style: TextStyle(
                    fontSize: 11,
                    color: isCritical
                        ? context.colors.error
                        : context.colors.onSurfaceVariant,
                    fontWeight:
                        isCritical ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              },
            ),
            trailing: Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: context.colors.onSurfaceVariant,
            ),
          ),

          // ===== EXPANDED CONTENT =====
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== REAL UNITS FROM ORDER HISTORY (FIFO) =====
// ===== REAL UNITS + COLLECTIVE (no mocks) =====
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _unitsForCylinder(cyl, brand, weight, cycleDays),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: context.colors.primary,
                              ),
                            ),
                          ),
                        );
                      }

                      final units = snapshot.data ?? [];

                      // Same FIFO sums as the home gauge.
                      final collective = _collectiveFromUnits(units, cycleDays);
                      final int collectiveDays = collective.days;
                      final double collectivePercentage = collective.percentage;

                      // The bar shows remaining capacity, not the summed
                      // percentage: two full cylinders = 1.0, and after one
                      // day 59/60 = 0.9833 even though the text says 196.7%.
                      final double collectiveRatio = collective.fraction;
                      final bool isCollectiveEmpty = collectiveDays <= 0;
                      final bool isCollectiveCritical =
                          collectiveRatio <= 0.15 || isCollectiveEmpty;

                      if (units.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            l10n.noCylinderHistory,
                            style: TextStyle(
                                fontSize: 12,
                                color: context.colors.onSurfaceVariant),
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Collective header (from real units only)
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.collectiveLevel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: context.colors.onSurfaceVariant),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  isCollectiveEmpty
                                      ? l10n.emptyPercent
                                      : l10n.daysLeft(
                                          collectiveDays,
                                          collectivePercentage
                                              .toStringAsFixed(1)),
                                  textAlign: TextAlign.end,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isCollectiveCritical
                                        ? context.colors.error
                                        : context.colors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: collectiveRatio,
                              backgroundColor:
                                  context.colors.surfaceContainerLow,
                              color: isCollectiveCritical
                                  ? context.colors.error
                                  : context.colors.primary,
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Individual units
                          ...units.asMap().entries.map((entry) {
                            final unitIndex = entry.key;
                            final unit = entry.value;
                            final int unitDays =
                                (unit['remainingDays'] as num?)?.toInt() ?? 0;
                            final double unitPct =
                                (unit['percentage'] as num?)?.toDouble() ?? 0.0;
                            final double unitRatio =
                                (unitPct / 100.0).clamp(0.0, 1.0);
                            final bool unitEmpty = unitDays <= 0;
                            final String unitDateRaw =
                                (unit['lastRefillDate'] ?? '')
                                    .toString()
                                    .split('T')
                                    .first;
                            final DateTime? unitDateParsed =
                                DateTime.tryParse(unitDateRaw);
                            final String unitDate = unitDateParsed == null
                                ? unitDateRaw
                                : MaterialLocalizations.of(context)
                                    .formatMediumDate(unitDateParsed);
                            final String unitSupplier =
                                (unit['supplier_name'] ?? 'Muuzaji Rasmi')
                                    .toString();
                            final num unitPrice =
                                (unit['price'] as num?) ?? 0.0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: context.colors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: context.colors.outlineVariant),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    unitIndex == 0
                                        ? l10n.unitOldest(unitIndex + 1)
                                        : l10n.unitLabel(unitIndex + 1),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: context.colors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(l10n.levelLabel,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: context
                                                    .colors.onSurfaceVariant)),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          unitEmpty
                                              ? l10n.emptyPercent
                                              : l10n.daysLeft(unitDays,
                                                  unitPct.toStringAsFixed(1)),
                                          textAlign: TextAlign.end,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: unitEmpty
                                                ? context.colors.error
                                                : context.colors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: unitRatio,
                                      backgroundColor:
                                          context.colors.outlineVariant,
                                      color: unitEmpty
                                          ? context.colors.error
                                          : context.colors.primary,
                                      minHeight: 6,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildFactLine(l10n.dateLabel, unitDate),
                                  const SizedBox(height: 2),
                                  _buildFactLine(l10n.vendorLabel, unitSupplier),
                                  const SizedBox(height: 2),
                                  _buildFactLine(
                                    l10n.costLabel,
                                    unitPrice > 0
                                        ? 'TZS ${unitPrice.toStringAsFixed(0)}'
                                        : '—',
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      TextButton.icon(
                                        onPressed: () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    l10n.editUnitComingSoon)),
                                          );
                                        },
                                        icon: Icon(Icons.edit_outlined,
                                            size: 16,
                                            color: context.gasColors.info),
                                        label: Text(l10n.edit,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: context.gasColors.info)),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        onPressed: () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    l10n.markEmptyComingSoon)),
                                          );
                                        },
                                        icon: Icon(Icons.inventory_2_outlined,
                                            size: 16,
                                            color: context.colors.error),
                                        label: Text(l10n.markEmpty,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: context.colors.error)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    },
                  ),

                  // Global delete for the whole stack
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.colors.error,
                        side: BorderSide(color: context.colors.error),
                      ),
                      onPressed: () => _deleteCylinderNode(cyl['id'] ?? ''),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: Text(
                        l10n.deleteEntireStack,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFactLine(String label, String value) {
    return Row(children: [
      Expanded(
        child: Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant)),
      ),
      const SizedBox(width: 8),
      Flexible(
        child: Text(value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: context.colors.onSurface)),
      ),
    ]);
  }

  Widget _buildMenuCard(String title, String screenKey) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: context.colors.outlineVariant)),
      child: ListTile(
        title: Text(title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.chevron_right,
            size: 18, color: context.colors.onSurfaceVariant),
        onTap: () => _navigateToEmptyScreen(screenKey),
      ),
    );
  }

  void _navigateToEmptyScreen(String featureTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(featureTitle,
                style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.construction_outlined,
                      size: 48, color: context.colors.outline),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context).featureEmpty(featureTitle),
                    style: TextStyle(
                        fontSize: 14,
                        color: context.colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
