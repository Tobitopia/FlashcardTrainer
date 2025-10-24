import 'package:flutter/material.dart';
import '../widgets/auth_wrapper.dart';
import 'navigation.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: AuthWrapper());
  }
}