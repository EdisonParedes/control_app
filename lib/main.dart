import 'package:app/view/qr/approve_entry_QR_screen.dart';
import 'package:app/view/emergency/emergency_button.dart';
import 'package:app/view/dashboard/home_page.dart';
import 'package:app/services/location_permission_service.dart';
import 'package:flutter/material.dart';
import 'view/auth/login_page.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    final context = navigatorKey.currentContext;
    if (context != null) {
      MyFirebaseMessagingService.setupFirebaseMessaging(context);
    }
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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasData) {
            return const HomePage(); // Usuario autenticado
          } else {
            return const LoginPage(); // Usuario no autenticado
          }
        },
      ),
    );
  }
}
