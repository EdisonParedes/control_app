// models/user_model.dart
class UserModel {
  final String uid;
  final String name;
  final String lastname;
  final String phone;
  final String email;
  final String rol;
  final String ci;
  final String? fcmToken;

  UserModel({
    required this.uid,
    required this.name,
    required this.lastname,
    required this.phone,
    required this.email,
    required this.rol,
    required this.ci,
    this.fcmToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'lastname': lastname,
      'phone': phone,
      'email': email,
      'rol': rol,
      'ci': ci,
      'fcmToken': fcmToken,
    };
  }

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      lastname: map['lastname'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      rol: map['rol'] ?? '',
      ci: map['ci'] ?? '',
      fcmToken: map['fcmToken'],
    );
  }
}
