import 'package:cloud_firestore/cloud_firestore.dart';

/// Ad campaign record stored in `ad_placements/{id}`.
class AdPlacement {
  const AdPlacement({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.imageUrl,
    this.linkUrl,
    this.ctaText = '',
    this.active = true,
    this.audience = 'consumer',
    this.updatedAt,
  });

  final String id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String? linkUrl;
  final String ctaText;

  /// False hides the placement everywhere.
  final bool active;

  /// `consumer | vendor | both`.
  final String audience;
  final DateTime? updatedAt;

  bool get isActive => active && title.trim().isNotEmpty;

  Map<String, dynamic> toMap() => {
        'title': title,
        'subtitle': subtitle,
        'imageUrl': imageUrl,
        'linkUrl': linkUrl,
        'ctaText': ctaText,
        'active': active,
        'audience': audience,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory AdPlacement.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    final updated = d['updatedAt'] ?? d['updated_at'];
    return AdPlacement(
      id: doc.id,
      title: d['title'] as String? ?? '',
      subtitle: d['subtitle'] as String? ?? '',
      imageUrl: d['imageUrl'] as String?,
      linkUrl: d['linkUrl'] as String?,
      ctaText: d['ctaText'] as String? ?? '',
      active: d['active'] as bool? ?? true,
      audience: (d['audience'] as String? ?? 'consumer').toLowerCase(),
      updatedAt: updated is Timestamp ? updated.toDate() : null,
    );
  }
}

/// Stakeholder request stored in `ad_requests/{id}`.
class AdRequest {
  const AdRequest({
    required this.id,
    required this.company,
    required this.contactPhone,
    required this.audience,
    required this.placement,
    required this.message,
    this.budget = '',
    this.status = 'new',
    required this.createdAt,
  });

  final String id;
  final String company;
  final String contactPhone;
  final String audience;
  final String placement;
  final String message;
  final String budget;

  /// `new | contacted | approved | declined`.
  final String status;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'company': company,
        'contactPhone': contactPhone,
        'audience': audience,
        'placement': placement,
        'message': message,
        'budget': budget,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory AdRequest.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    final created = d['createdAt'];
    return AdRequest(
      id: doc.id,
      company: d['company'] as String? ?? '',
      contactPhone: d['contactPhone'] as String? ?? '',
      audience: (d['audience'] as String? ?? 'consumer').toLowerCase(),
      placement: d['placement'] as String? ?? '',
      message: d['message'] as String? ?? '',
      budget: d['budget'] as String? ?? '',
      status: d['status'] as String? ?? 'new',
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
    );
  }
}
