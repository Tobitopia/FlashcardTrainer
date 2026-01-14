import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/my_app.dart';
import 'app/locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  setupLocator();
  runApp(const MyApp());
}
