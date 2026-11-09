import 'package:flutter/material.dart';

class AdminVendorScreen extends StatelessWidget {
  const AdminVendorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Admin panel coming soon.\nUse Firestore Console to create vendors.'),
      ),
    );
  }
}