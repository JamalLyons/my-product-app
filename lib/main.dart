import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'auth_flow.dart';
import 'auth_service.dart';
import 'firebase_options.dart';
import 'product_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(ProductApp(authService: AuthService()));
  } catch (error) {
    runApp(ProductApp(firebaseSetupError: error.toString()));
  }
}

class ProductApp extends StatelessWidget {
  const ProductApp({super.key, this.firebaseSetupError, this.authService});

  final String? firebaseSetupError;
  final AuthService? authService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth Activity 13',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.deepOrange, useMaterial3: true),
      home: firebaseSetupError != null || authService == null
          ? const ProductPage(firebaseSetupError: 'Firebase is unavailable.')
          : AuthGate(authService: authService!),
    );
  }
}
