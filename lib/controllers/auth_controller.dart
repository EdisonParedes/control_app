// controllers/auth_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user_model.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final String? fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      await _firestore.collection('users').doc(credential.user!.uid).update({
        'fcmToken': fcmToken,
      });
    }

    return credential.user;
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<User?> register(UserModel user, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: user.email,
      password: password,
    );

    final String? fcmToken = await FirebaseMessaging.instance.getToken();

    await _firestore.collection('users').doc(credential.user!.uid).set({
      ...user.toMap(),
      'fcmToken': fcmToken,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return credential.user;
  }

  void setupFCMTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': newToken,
        });
      }
    });
  }
}
