import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String phone;
  final String name;
  final String role;
  final String address;
  final String locale;
  final String? fcmToken;

  UserModel({
    required this.uid,
    required this.phone,
    this.name = '',
    this.role = 'consumer',
    this.address = '',
    this.locale = 'sw',
    this.fcmToken,
  });

  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      phone: d['phone'] ?? '',
      name: d['name'] ?? '',
      role: d['role'] ?? 'consumer',
      address: d['address'] ?? '',
      locale: d['locale'] ?? 'sw',
      fcmToken: d['fcmToken'],
    );
  }

  Map<String, dynamic> toMap() => {
        'phone': phone,
        'name': name,
        'role': role,
        'address': address,
        'locale': locale,
        'fcmToken': fcmToken,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
