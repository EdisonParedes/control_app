import 'package:app/screens/approve_entry_QR_screen.dart';
import 'package:app/screens/emergency_button.dart';
import 'package:app/screens/home_page.dart';
import 'package:app/services/location_permission_service.dart';
import 'package:flutter/material.dart';
import 'auth/login_page.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app/services/my_firebase_messaging_service.dart';
import 'package:provider/provider.dart';
import 'package:app/services/user_session.dart';

// Definir el GlobalKey para el navigator globalmente
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await EmergencyButton.init();

  runApp(
    ChangeNotifierProvider(
      create: (context) => UserSession(),
      child: const MyApp(),
    ),
  );

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
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginPage(),
    );
  }
}
