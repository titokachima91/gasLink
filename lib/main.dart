//This is main.dart
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
//import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Fire-and-forget: never blocks the UI, failures are logged not thrown
  unawaited(_seedDebugUser());

  runApp(const GasLinkApp());
}

Future<void> _seedDebugUser() async {
  try {
    await AuthService.instance.seedUser('+255777000777', '1234', 'vendor');
    debugPrint('Seed OK');
  } catch (e) {
    debugPrint('Seed failed (check internet / Firestore rules): $e');
  }
}
