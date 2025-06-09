// lib/controller/auth_controller.dart

import 'package:app/services/auth_service.dart';
import 'package:app/model/user_model.dart';

class AuthController {
  final AuthService _authService = AuthService();

  Future<UserModel?> register({
    required String name,
    required String lastname,
    required String email,
    required String password,
    required String phone,
    required String rol,
    required String ci,
    String? fcmToken,
  }) async {
    return await _authService.registerUser(
      name: name,
      lastname: lastname,
      email: email,
      password: password,
      phone: phone,
      rol: rol,
      ci: ci,
      fcmToken: fcmToken,
    );
  }

  Future<UserModel?> login(String email, String password) async {
    return await _authService.loginUser(email, password);
  }

  Future<void> resetPassword(String email) async {
    await _authService.resetPassword(email);
  }

  Future<void> logout() async {
    await _authService.logout();
  }
}
