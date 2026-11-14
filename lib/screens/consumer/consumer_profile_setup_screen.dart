// lib/screens/consumer/consumer_profile_setup_screen.dart
// First-run profile and cylinder capture. Required before a new consumer
// starts ordering; also reusable from Settings to complete or update details.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../core/constants.dart';
import '../../core/theme_ext.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_ui.dart';
import '../role_router.dart';

class ConsumerProfileSetupScreen extends StatefulWidget {
  final bool firstRun;

  const ConsumerProfileSetupScreen({super.key, this.firstRun = false});

  @override
  State<ConsumerProfileSetupScreen> createState() =>
      _ConsumerProfileSetupScreenState();
}

class _ConsumerProfileSetupScreenState
    extends State<ConsumerProfileSetupScreen> {
  final _nameCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController(text: '1');

  String _brand = AppConstants.gasBrands.first;
  String _size = '6kg';
  DateTime _lastRefill = DateTime.now();
  bool _orderNow = false;
  bool _loading = false;
  bool _loadingProfile = true;
  bool _saved = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _areaCtrl.dispose();
    _streetCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    final uid = AuthService.instance.currentUserId;
    if (uid == null || uid.isEmpty) {
      setState(() => _loadingProfile = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data() ?? {};
      final cylinders = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('cylinders')
          .limit(1)
          .get();
      final cylinder = cylinders.docs.isEmpty
          ? <String, dynamic>{}
          : cylinders.docs.first.data();
      if (!mounted) return;
      setState(() {
        _nameCtrl.text = (data['name'] ?? '').toString();
        _areaCtrl.text = (data['area'] ?? data['ward'] ?? '').toString();
        _streetCtrl.text = (data['street'] ?? data['address'] ?? '').toString();
        final brand = (cylinder['brand'] ?? data['preferredBrand'] ?? '').toString();
        if (AppConstants.gasBrands.contains(brand)) {
          _brand = brand;
          _size = AppConstants.brandSizes[brand]!.first;
        }
        final savedSize =
            (cylinder['size'] ?? cylinder['weight'] ?? data['preferredSize'] ?? '')
                .toString();
        if (AppConstants.brandSizes[_brand]!.contains(savedSize)) {
          _size = savedSize;
        }
        final savedDate =
            DateTime.tryParse((cylinder['lastRefillDate'] ?? '').toString());
        if (savedDate != null) _lastRefill = savedDate;
      });
    } catch (_) {
      // A missing profile is normal on first run.
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastRefill,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _lastRefill = picked);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameCtrl.text.trim();
    final area = _areaCtrl.text.trim();
    final street = _streetCtrl.text.trim();
    final quantity = int.tryParse(_quantityCtrl.text.trim()) ?? 1;

    if (name.length < 2) {
      setState(() => _error = l10n.yourName);
      return;
    }
    if (area.isEmpty) {
      setState(() => _error = l10n.areaLabel);
      return;
    }
    if (street.isEmpty) {
      setState(() => _error = l10n.addressRequiredShort);
      return;
    }

    final uid = AuthService.instance.currentUserId;
    if (uid == null || uid.isEmpty) {
      setState(() => _error = l10n.errorGeneric);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final db = FirebaseFirestore.instance;
      final address = '$street, $area';
      await db.collection('users').doc(uid).set({
        'name': name,
        'area': area,
        'street': street,
        'address': address,
        'preferredBrand': _brand,
        'preferredSize': _size,
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final existing = await db
          .collection('users')
          .doc(uid)
          .collection('cylinders')
          .limit(20)
          .get();
      final duplicate = existing.docs.any((doc) {
        final d = doc.data();
        return (d['brand'] ?? '').toString() == _brand &&
            ((d['size'] ?? d['weight'] ?? '').toString() == _size);
      });
      if (!duplicate) {
        await db.collection('users').doc(uid).collection('cylinders').add({
          'brand': _brand,
          'size': _size,
          'weight': _size,
          'quantity': quantity,
          'refillCycle': '30 days',
          'lastRefillDate': _lastRefill.toIso8601String(),
          'purchase_date': _lastRefill.toIso8601String(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      setState(() => _saved = true);
      if (widget.firstRun) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const RoleRouter(userRole: 'consumer'),
          ),
          (_) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileSetupSaved)),
        );
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = l10n.errorGeneric);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sizes = AppConstants.brandSizes[_brand] ?? const <String>['6kg'];
    if (!sizes.contains(_size)) _size = sizes.first;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileSetupTitle),
        automaticallyImplyLeading: !widget.firstRun,
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    l10n.profileSetupSubtitle,
                    style: TextStyle(color: context.colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: l10n.yourName,
                            prefixIcon: const Icon(Icons.person_outline),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _areaCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: l10n.areaLabel,
                            hintText: l10n.areaHint,
                            prefixIcon: const Icon(Icons.map_outlined),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _streetCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: l10n.streetLabel,
                            hintText: l10n.streetHint,
                            prefixIcon: const Icon(Icons.location_on_outlined),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppSectionHeader(
                    title: l10n.cylinderDetailsTitle,
                    icon: Icons.propane_tank_outlined,
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: _brand,
                          decoration: InputDecoration(
                            labelText: l10n.brandLabel,
                            border: const OutlineInputBorder(),
                          ),
                          items: AppConstants.gasBrands
                              .map((brand) => DropdownMenuItem(
                                    value: brand,
                                    child: Text(brand),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _brand = value;
                              _size = AppConstants.brandSizes[value]!.first;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _size,
                          decoration: InputDecoration(
                            labelText: l10n.weightLabel,
                            border: const OutlineInputBorder(),
                          ),
                          items: sizes
                              .map((size) => DropdownMenuItem(
                                    value: size,
                                    child: Text(size),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) setState(() => _size = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _quantityCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.quantityLabel,
                            prefixIcon: const Icon(Icons.numbers_outlined),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.event_outlined,
                            color: context.colors.primary,
                          ),
                          title: Text(l10n.lastRefillDateLabel),
                          subtitle: Text(
                            MaterialLocalizations.of(context)
                                .formatMediumDate(_lastRefill),
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 18),
                          onTap: _pickDate,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.orderNowQuestion),
                    subtitle: Text(l10n.orderNowHint),
                    value: _orderNow,
                    activeColor: context.colors.primary,
                    onChanged: (value) => setState(() => _orderNow = value),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(color: context.colors.error),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _loading || _saved ? null : _save,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(l10n.profileSetupSave),
                  ),
                ],
              ),
            ),
    );
  }
}
