import 'package:app/screens/emergency_button.dart';
import 'package:app/screens/home_page.dart';
import 'package:app/services/location_permission_service.dart';
import 'package:flutter/material.dart';
import 'auth/login_page.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app/services/my_firebase_messaging_service.dart';

// Definir el GlobalKey para el navigator globalmente
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await EmergencyButton.init();

  runApp(const MyApp());

  WidgetsBinding.instance.addPostFrameCallback((_) {
    MyFirebaseMessagingService.setupFirebaseMessaging(
      navigatorKey.currentContext!,
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey:
          navigatorKey, // Usamos el navigatorKey para la navegación global
      title: 'App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginPage(), // Cambié HomePage por LoginPage si necesitas
    );
  }
}
