import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserSession with ChangeNotifier {
  String? uid;
  String? userId;
  String? nombre;
  String? apellido;
  String? email;
  String? telefono;
  String? rol;

  // Llama esta función una sola vez al iniciar sesión
  Future<void> cargarDatosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      uid = user.uid;

      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();

      if (data != null) {
        userId = uid;
        nombre = data['nombre'];
        apellido = data['apellido'];
        email = data['email'];
        telefono = data['telefono'];
        rol = data['rol'];
        notifyListeners();  // Notifica a los consumidores que los datos han cambiado
      }
    }
  }

  // Métodos de utilidad para verificar el rol del usuario
  bool esAdmin() => rol == 'admin';

  bool esRepresentante() => rol == 'representante';

  bool esGuardia() => rol == 'guardia';

  bool esVisitante() => rol == 'visitante';

  String nombreCompleto() => "${nombre ?? ''} ${apellido ?? ''}".trim();
}
