// /models/emergency_model.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:app/services/location_permission_service.dart';
import 'package:app/services/serverkey.dart';

class EmergencyModel {
  Future<void> sendEmergencyNotifications() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    final message = 'Emergencia activada en la comunidad Llimpe Grande.';
    String serverKey = await get_server_key().server_token();

    Position? position;
    try {
      position = await LocationPermissionService.requestLocationPermission();
    } catch (e) {
      print('Error al obtener ubicación: $e');
    }

    double latitude = position?.latitude ?? 0;
    double longitude = position?.longitude ?? 0;

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    String userId = user.uid;
    String userName = 'Usuario';

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      final data = userDoc.data()!;
      userName = '${data['nombre'] ?? 'Usuario'} ${data['apellido'] ?? ''}';
    }

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final token = data['fcmToken'];
      if (token != null && token.toString().isNotEmpty) {
        await _sendPushMessage(
          token,
          '$message - $userName',
          latitude,
          longitude,
          serverKey,
          userId,
        );
      }
    }
  }

  Future<void> _sendPushMessage(
    String token,
    String message,
    double latitude,
    double longitude,
    String serverKey,
    String userId,
  ) async {
    final url = Uri.parse('https://fcm.googleapis.com/v1/projects/apps-d19d9/messages:send');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $serverKey',
      },
      body: jsonEncode({
        'message': {
          'token': token,
          'notification': {'title': '¡Alerta de Emergencia!', 'body': message},
          'data': {
            "latitude": latitude.toString(),
            "longitude": longitude.toString(),
            "story_id": "story_12345",
            "senderId": userId,
          },
        },
      }),
    );

    if (response.statusCode == 200) {
      print('Notificación enviada correctamente');
    } else {
      print('Error al enviar notificación: ${response.body}');
    }
  }
}
