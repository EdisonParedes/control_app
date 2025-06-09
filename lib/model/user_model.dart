// lib/model/user_model.dart

class UserModel {
  final String uid;
  final String name;
  final String lastname;
  final String email;
  final String phone;
  final String rol;
  final String ci;
  final String? fcmToken;

  UserModel({
    required this.uid,
    required this.name,
    required this.lastname,
    required this.email,
    required this.phone,
    required this.rol,
    required this.ci,
    this.fcmToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'lastname': lastname,
      'email': email,
      'phone': phone,
      'rol': rol,
      'ci': ci,
      'fcmToken': fcmToken,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      lastname: map['lastname'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      rol: map['rol'] ?? '',
      ci: map['ci'] ?? '',
      fcmToken: map['fcmToken'],
    );
  }
}
