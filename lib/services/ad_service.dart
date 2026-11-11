import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ad_models.dart';

/// Data access for placements and stakeholder ad requests.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _placements =>
      _db.collection('ad_placements');
  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection('ad_requests');

  /// Pure audience check: does [placementAudience] target [role]?
  ///
  /// `both` matches every role; `consumer` and `vendor` match only their own.
  static bool matchesAudience(String placementAudience, String? role) {
    final audience = placementAudience.toLowerCase();
    if (audience == 'both') return true;
    if (audience == 'vendor') return role == 'vendor';
    return role == 'consumer' || role == 'guest';
  }

  Future<AdPlacement?> fetchPlacement(String placementId) async {
    final doc = await _placements.doc(placementId).get();
    if (!doc.exists) return null;
    final placement = AdPlacement.fromDoc(doc);
    return placement.isActive ? placement : null;
  }

  Future<void> submitAdRequest({
    required String company,
    required String contactPhone,
    required String audience,
    required String placement,
    required String message,
    String budget = '',
  }) async {
    if (company.trim().isEmpty || contactPhone.trim().isEmpty) {
      throw ArgumentError('Company and contact phone are required');
    }
    final request = AdRequest(
      id: '',
      company: company.trim(),
      contactPhone: contactPhone.trim(),
      audience: audience,
      placement: placement,
      message: message.trim(),
      budget: budget.trim(),
      createdAt: DateTime.now(),
    );
    await _requests.add(request.toMap());
  }

  Stream<List<AdRequest>> streamAdRequests() {
    return _requests.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map(AdRequest.fromDoc).toList(),
        );
  }

  Future<void> updateAdRequestStatus(String id, String status) async {
    await _requests.doc(id).update({'status': status});
  }
}
