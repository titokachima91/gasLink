/// ============================================================================
/// FILE: lib/screens/vendor/vendor_profile_screen.dart
///
/// SUMMARY:
/// Store Profile & Compliance Management screen for LPG vendors (Taarifa za Duka).
/// Uses `Vendor` model (`lib/models/vendor.dart`) as the single source of truth.
/// Captures store details, location, payment methods, photo proof URLs, and
/// customer extra services.
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/vendor.dart';
import '../../services/auth_service.dart';
import '../../services/vendor_image_service.dart';
import '../../utils/service_normalizer.dart';
import '../../core/constants.dart';
import '../../widgets/app_ui.dart';

import '../../core/theme_ext.dart';

class VendorProfileScreen extends StatefulWidget {
  const VendorProfileScreen({super.key});

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

// Add this variable at the top of _VendorProfileScreenState class:
final List<String> _availableServices = [
  'Ukaguzi wa Kuvuja kwa Gesi / Gas Leak Inspection',
  'Ufungaji wa Bure Nyumbani / Free Home Installation',
  'Ushauri wa Usalama wa Gesi / Gas Safety Advice',
  'Ubadilishaji wa Hose & Regulator / Hose Replacement',
  'Huduma ya Dharura Usiku / Emergency Night Delivery',
  'Matengenezo ya Jiko la Gesi / Gas Stove Maintenance',
  'Ubadilishaji wa Mpira wa Mtungi / O-Ring Replacement',
  'Tathmini ya Mfumo wa Gesi Nyumbani / Setup Inspection',
  'Mtungi wa Akiba kwa Shughuli au Dharula / Event or Emergency Supply',
  'Ukumbusho wa Kujaza Gesi / Auto-Refill Reminders',
];

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _uploadingImage = false;

  String get _uid =>
      FirebaseAuth.instance.currentUser?.uid ??
      AuthService.instance.currentUserId ??
      '';

  DocumentReference<Map<String, dynamic>> get _vendorDoc =>
      FirebaseFirestore.instance.collection('vendors').doc(_uid);

  Vendor? _currentVendor;

  // Section A: Business Essentials
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _secondaryPhoneController = TextEditingController();
  final _emailController = TextEditingController();

  // Section B: Location & Delivery
  final _regionController = TextEditingController(text: 'Dar es Salaam');
  final _districtController = TextEditingController();
  final _streetController = TextEditingController();
  final _areaTextController = TextEditingController();
  final _deliveryRadiusController = TextEditingController(text: '5.0');
  double? _latitude;
  double? _longitude;
  String _deliveryFeeModel = 'Flat Rate';

  // Section C: Operations & Payments
  final _openingHoursController =
      TextEditingController(text: '07:00 AM - 09:00 PM');
  bool _acceptsCash = true;
  bool _acceptsMobileMoney = false;
  final _lipaNumberController = TextEditingController();
  final _imageUrlController = TextEditingController();

  // Section D: Safety & Documents
  bool _hasOperationalScale = false;
  final _businessLicenseUrlController = TextEditingController();
  final _wmaStickerUrlController = TextEditingController();
  final _superDealerProofUrlController = TextEditingController();
  bool _agreedToConsumerProtection = false;

  // Section E: Extra Services Selection
  final Set<String> _offeredServices = {};

  @override
  void initState() {
    super.initState();
    _loadVendorProfile();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    _secondaryPhoneController.dispose();
    _emailController.dispose();
    _regionController.dispose();
    _districtController.dispose();
    _streetController.dispose();
    _areaTextController.dispose();
    _deliveryRadiusController.dispose();
    _openingHoursController.dispose();
    _lipaNumberController.dispose();
    _imageUrlController.dispose();
    _businessLicenseUrlController.dispose();
    _wmaStickerUrlController.dispose();
    _superDealerProofUrlController.dispose();
    super.dispose();
  }

  Widget _buildShopImagePreview() {
    final url = _imageUrlController.text.trim();
    return Container(
      width: 72,
      height: 72,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: url.isEmpty
          ? Icon(Icons.storefront, color: context.colors.outline, size: 30)
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.broken_image_outlined,
                color: context.colors.outline,
                size: 30,
              ),
            ),
    );
  }

  /// Picks a photo from the gallery and uploads it to Firebase Storage.
  /// The URL is saved to the vendor document immediately.
  Future<void> _pickAndUploadShopImage() async {
    final XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('Image picker error: $e');
      return;
    }
    if (file == null || !mounted) return;

    final sizeError = VendorImageService.validateSize(await file.length());
    if (sizeError != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sizeError),
          backgroundColor: context.colors.error,
        ),
      );
      return;
    }

    setState(() => _uploadingImage = true);
    try {
      final url = await VendorImageService.instance.uploadShopImage(
        vendorId: _uid,
        file: file,
      );
      _imageUrlController.text = url;
      await _vendorDoc.update({
        'imageUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Picha ya duka imewekwa! / Photo uploaded.'),
          backgroundColor: context.gasColors.success,
        ),
      );
    } catch (e) {
      debugPrint('Image upload error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imeshindikana kupakia picha / Upload failed: $e'),
          backgroundColor: context.colors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _loadVendorProfile() async {
    if (_uid.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final doc = await _vendorDoc.get();
      if (doc.exists) {
        _currentVendor = Vendor.fromDoc(doc);
        _businessNameController.text = _currentVendor!.businessName;
        _phoneController.text = _currentVendor!.phone;
        _secondaryPhoneController.text = _currentVendor!.secondaryPhone;
        _emailController.text = _currentVendor!.email;
        _regionController.text = _currentVendor!.region;
        _districtController.text = _currentVendor!.district;
        _streetController.text = _currentVendor!.street;
        _areaTextController.text = _currentVendor!.areaText;
        _latitude = _currentVendor!.latitude;
        _longitude = _currentVendor!.longitude;
        _deliveryRadiusController.text =
            _currentVendor!.deliveryRadiusKm.toString();
        _deliveryFeeModel = _currentVendor!.deliveryFeeModel;
        _openingHoursController.text = _currentVendor!.openingHours;
        _acceptsCash = _currentVendor!.acceptsCash;
        _acceptsMobileMoney = _currentVendor!.acceptsMobileMoney;
        _lipaNumberController.text = _currentVendor!.lipaNumber ?? '';
        _imageUrlController.text = _currentVendor!.imageUrl ?? '';
        _hasOperationalScale = _currentVendor!.hasOperationalScale;

        // FIXED: Normalize stored services to the canonical list so the
        // counter equals the number of genuinely ticked boxes. The weighing
        // consent is separate and never counted as a service.
        _offeredServices.clear();
        _offeredServices.addAll(
          normalizeOfferedServices(
            _currentVendor!.offeredServices,
            _availableServices,
          ),
        );

        _businessLicenseUrlController.text =
            _currentVendor!.businessLicenseUrl ?? '';
        _wmaStickerUrlController.text = _currentVendor!.wmaStickerUrl ?? '';
        _superDealerProofUrlController.text =
            _currentVendor!.superDealerProofUrl ?? '';
        _agreedToConsumerProtection =
            _currentVendor!.agreedToConsumerProtection;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hitilafu ya kupakia profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasOperationalScale) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Tafadhali thibitisha umiliki wa mizani halisi (Operational Scale Check).'),
          backgroundColor: context.colors.primary,
        ),
      );
      return;
    }
    if (_offeredServices.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Chagua angalau huduma 2 za nyongeza kwa mteja katika Huduma za Ziada.'),
          backgroundColor: context.colors.primary,
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final updatedVendor = Vendor(
        id: _uid,
        ownerUid: _uid,
        businessName: _businessNameController.text.trim(),
        phone: _phoneController.text.trim(),
        secondaryPhone: _secondaryPhoneController.text.trim(),
        email: _emailController.text.trim(),
        region: _regionController.text.trim(),
        district: _districtController.text.trim(),
        street: _streetController.text.trim(),
        areaText: _areaTextController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        deliveryRadiusKm:
            double.tryParse(_deliveryRadiusController.text.trim()) ?? 5.0,
        deliveryFeeModel: _deliveryFeeModel,
        openingHours: _openingHoursController.text.trim(),
        acceptsCash: _acceptsCash,
        acceptsMobileMoney: _acceptsMobileMoney,
        lipaNumber: _lipaNumberController.text.trim().isNotEmpty
            ? _lipaNumberController.text.trim()
            : null,
        imageUrl: _imageUrlController.text.trim().isNotEmpty
            ? _imageUrlController.text.trim()
            : null,
        hasOperationalScale: _hasOperationalScale,

        // FIXED: Clean and trim offeredServices list on save
        offeredServices: _offeredServices.map((e) => e.trim()).toList(),

        businessLicenseUrl: _businessLicenseUrlController.text.trim().isNotEmpty
            ? _businessLicenseUrlController.text.trim()
            : null,
        wmaStickerUrl: _wmaStickerUrlController.text.trim().isNotEmpty
            ? _wmaStickerUrlController.text.trim()
            : null,
        superDealerProofUrl:
            _superDealerProofUrlController.text.trim().isNotEmpty
                ? _superDealerProofUrlController.text.trim()
                : null,
        agreedToConsumerProtection: _agreedToConsumerProtection,
        completedOrders: _currentVendor?.completedOrders ?? 0,
        avgDeliveryTimeMinutes: _currentVendor?.avgDeliveryTimeMinutes ?? 0.0,
        createdAt: _currentVendor?.createdAt ?? DateTime.now(),
        currentTier: 1,
      );

      final mapPayload = updatedVendor.toMap();
      mapPayload['completionPercentage'] = updatedVendor.completionPercentage;
      mapPayload['currentTier'] = updatedVendor.calculatedTier;
      mapPayload['tier'] = updatedVendor.calculatedTier;
      mapPayload['badgeTier'] = updatedVendor.calculatedTier;
      mapPayload['updatedAt'] = FieldValue.serverTimestamp();

      await _vendorDoc.set(mapPayload, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Taarifa zimehifadhiwa kikamilifu! (${updatedVendor.completionPercentage}% Complete)',
            ),
            backgroundColor: context.gasColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hitilafu ya kuhifadhi: $e'),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: context.colors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Taarifa za Duka / Store Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // ── SECTION A: BUSINESS ESSENTIALS ────────────────────────
            _buildSectionHeader(
                'Taarifa Kuu / Business Essentials', Icons.store),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: context.colors.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _businessNameController,
                      decoration: const InputDecoration(
                        labelText: 'Jina la Duka / Shop Name *',
                        prefixIcon: Icon(Icons.business),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Ingiza jina la duka'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Namba ya Simu (Calls) *',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Ingiza namba ya simu'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _secondaryPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Namba ya Pili / WhatsApp',
                        prefixIcon: Icon(Icons.chat),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Barua Pepe / Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── SECTION B: LOCATION & DELIVERY ───────────────────────
            _buildSectionHeader(
                'Eneo & Maeneo ya Huduma / Location', Icons.location_on),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: context.colors.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _regionController,
                      decoration: const InputDecoration(
                        labelText: 'Mkoa / Region *',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: AppConstants.districts
                              .contains(_districtController.text.trim())
                          ? _districtController.text.trim()
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Wilaya / District *',
                        hintText: 'Chagua Wilaya',
                        prefixIcon: Icon(Icons.location_city_outlined,
                            color: context.colors.primary),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      items: AppConstants.districts.map((district) {
                        return DropdownMenuItem<String>(
                          value: district,
                          child: Text(district),
                        );
                      }).toList(),
                      onChanged: (selected) {
                        if (selected != null) {
                          setState(() => _districtController.text = selected);
                        }
                      },
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Chagua wilaya'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _streetController,
                      decoration: const InputDecoration(
                        labelText: 'Mtaa / Street Address *',
                        prefixIcon: Icon(Icons.place),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Ingiza Mtaa' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _areaTextController,
                      decoration: const InputDecoration(
                        labelText: 'Eneo / Landmark (Maelekezo ya eneo)',
                        prefixIcon: Icon(Icons.directions),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _deliveryRadiusController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Umbali wa Kuhudumia (Km / Delivery Radius)',
                        prefixIcon: Icon(Icons.radar),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── SECTION C: OPERATIONS & PAYMENTS ────────────────────
            _buildSectionHeader(
                'Mipangilio & Malipo / Operations', Icons.payment),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: context.colors.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _openingHoursController,
                      decoration: const InputDecoration(
                        labelText: 'Muda wa Kazi / Opening Hours',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Shop photo: upload to Storage or paste a URL manually.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildShopImagePreview(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _uploadingImage
                                ? null
                                : _pickAndUploadShopImage,
                            icon: _uploadingImage
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.add_a_photo_outlined),
                            label: Text(
                              _uploadingImage
                                  ? 'Inapakia… / Uploading…'
                                  : 'Chagua Picha / Choose Photo',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Picha ya Duka Front / Storefront Image URL',
                        prefixIcon: Icon(Icons.storefront),
                      ),
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      title: const Text('Cash on Delivery (Lipia Ukipokea)'),
                      value: _acceptsCash,
                      activeColor: context.colors.primary,
                      onChanged: (v) =>
                          setState(() => _acceptsCash = v ?? true),
                    ),
                    CheckboxListTile(
                      title: const Text('Mobile Money (M-Pesa / Tigo Pesa)'),
                      value: _acceptsMobileMoney,
                      activeColor: context.colors.primary,
                      onChanged: (v) =>
                          setState(() => _acceptsMobileMoney = v ?? false),
                    ),
                    if (_acceptsMobileMoney) ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _lipaNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Lipa Namba / Merchant Code',
                          prefixIcon: Icon(Icons.qr_code),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── SECTION D: SAFETY & DOCUMENTS ────────────────────────
            _buildSectionHeader(
                'Usalama & Nyaraka / Safety & Documents', Icons.verified_user),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: context.colors.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Uthibitisho wa Mizani / Scale Check:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                          'Thibitisha unamiliki mizani halisi inayofanya kazi (Operational Scale Check) *'),
                      value: _hasOperationalScale,
                      activeColor: context.colors.primary,
                      onChanged: (v) =>
                          setState(() => _hasOperationalScale = v ?? false),
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Picha na Nyaraka za Duka / Store Documents & Photos:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _wmaStickerUrlController,
                      decoration: const InputDecoration(
                        labelText:
                            'Picha ya Vibandiko vya Mizani (WMA Scale Sticker)',
                        prefixIcon: Icon(Icons.photo_camera_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _businessLicenseUrlController,
                      decoration: const InputDecoration(
                        labelText:
                            'Picha ya Leseni ya Biashara (Municipal License)',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _superDealerProofUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Picha ya Risiti/Invoisi ya Distributor',
                        prefixIcon: Icon(Icons.receipt_long_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                          'Nakubali kupima uzito wa gesi kabla ya kupokea malipo mteja akiomba'),
                      value: _agreedToConsumerProtection,
                      activeColor: context.colors.primary,
                      onChanged: (v) => setState(
                          () => _agreedToConsumerProtection = v ?? false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── SECTION E: EXTRA SERVICES ────────────────────────────
            _buildSectionHeader('Huduma za Ziada / Extra Services',
                Icons.room_service_outlined),
            const SizedBox(height: 8),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: context.colors.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Huduma Unazotoa kwa Wateja:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '${_offeredServices.length} zimechaguliwa',
                          style: TextStyle(
                              color: context.gasColors.success,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chagua angalau huduma 2 ili kukamilisha sehemu hii / Choose at least 2 services *:',
                      style: TextStyle(
                          fontSize: 12, color: context.colors.onSurfaceVariant),
                    ),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Single list loop for available services
                    ..._availableServices.map((service) {
                      final swahiliPart =
                          service.split('/').first.trim().toLowerCase();

                      // Checks if exact string or legacy variant exists in set
                      final isChecked = _offeredServices.any((item) {
                        final s = item.toLowerCase().trim();
                        return s == service.toLowerCase().trim() ||
                            s.contains(swahiliPart) ||
                            swahiliPart.contains(s);
                      });

                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          service,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        value: isChecked,
                        activeColor: context.colors.primary,
                        controlAffinity: ListTileControlAffinity.trailing,
                        onChanged: (bool? selected) {
                          setState(() {
                            if (selected == true) {
                              // Purge any legacy partial matches before adding standard string
                              _offeredServices.removeWhere((item) {
                                final s = item.toLowerCase().trim();
                                return s.contains(swahiliPart) ||
                                    swahiliPart.contains(s);
                              });
                              _offeredServices.add(service);
                            } else {
                              // Purge exact match AND any legacy variant completely
                              _offeredServices.removeWhere((item) {
                                final s = item.toLowerCase().trim();
                                return s == service.toLowerCase().trim() ||
                                    s.contains(swahiliPart) ||
                                    swahiliPart.contains(s);
                              });
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSaving
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: context.colors.onPrimary),
                    )
                  : Text(
                      'Hifadhi Taarifa / Save Profile',
                      style: TextStyle(
                          color: context.colors.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return AppSectionHeader(title: title, icon: icon);
  }
}
