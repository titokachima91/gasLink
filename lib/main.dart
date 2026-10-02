//This is main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
//import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await AuthService.instance.seedUser('+255777000777', '1234', 'vendor');
  runApp(const GasLinkApp());
}
