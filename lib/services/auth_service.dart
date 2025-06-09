// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/model/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Registro de usuario
  Future<UserModel?> registerUser({
    required String name,
    required String lastname,
    required String email,
    required String password,
    required String phone,
    required String rol,
    required String ci,
    String? fcmToken,
  }) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;

      UserModel user = UserModel(
        uid: uid,
        name: name,
        lastname: lastname,
        email: email,
        phone: phone,
        rol: rol,
        ci: ci,
        fcmToken: fcmToken,
      );

      await _firestore.collection('users').doc(uid).set(user.toMap());

      return user;
    } catch (e) {
      print('Error en registerUser: $e');
      return null;
    }
  }

  // Login de usuario
  Future<UserModel?> loginUser(String email, String password) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;

      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      data['uid'] = uid; // Aseguramos el UID

      return UserModel.fromMap(data);
    } catch (e) {
      print('Error en loginUser: $e');
      return null;
    }
  }

  // Reset de contraseña
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}
