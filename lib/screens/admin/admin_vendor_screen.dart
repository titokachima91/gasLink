import 'package:flutter/material.dart';

import '../../widgets/theme_mode_button.dart';

class AdminVendorScreen extends StatelessWidget {
  const AdminVendorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: const [ThemeModeButton()],
      ),
      body: const Center(
        child: Text('Admin panel coming soon.\nUse Firestore Console to create vendors.'),
      ),
    );
  }
}