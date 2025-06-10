import 'package:app/view/entry_exit/visitor_approval_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:app/view/map/map_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:app/services/serverkey.dart';
import '../main.dart';


class MyFirebaseMessagingService {
  static void setupFirebaseMessaging(BuildContext context) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Solicitar permisos para notificaciones
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Permiso de notificaciones concedido');
    } else {
      print('Permiso de notificaciones denegado');
    }

    // Escuchar cuando la app se abre desde una notificación (en segundo plano o cerrada)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notificación abierta: ${message.notification?.title}');
      final data = message.data;
      

      // 🔵 Si vienen coordenadas, abrimos el mapa
      if (data.containsKey('latitude') && data.containsKey('longitude')) {
        double latitude = double.tryParse(data['latitude'] ?? '0') ?? 0;
        double longitude = double.tryParse(data['longitude'] ?? '0') ?? 0;

        if (latitude != 0 && longitude != 0) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder:
                  (context) =>
                      MapScreen(latitude: latitude, longitude: longitude, fromNotification: true,),
            ),
          );
          return;
        }
      }

      // 🟡 Si vienen datos de visitante, abrimos pantalla de aprobación
      if (data.containsKey('visitorName') &&
          data.containsKey('visitorCi') &&
          data.containsKey('reason') &&
          data.containsKey('requestId')) {
        String visitorName = data['visitorName'];
        String visitorCi = data['visitorCi'];
        String reason = data['reason'];
        String requestId = data['requestId'];

        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder:
                (context) => VisitorApprovalScreen(
                  visitorName: visitorName,
                  visitorCi: visitorCi,
                  reason: reason,
                  requestId: requestId,
                ),
          ),
        );
        return;
      }

      print("No se recibieron datos válidos");
    });

    // Manejo de mensajes cuando la app está completamente cerrada
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Esta función maneja las notificaciones cuando la app está completamente cerrada o en segundo plano
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    print('Notificación en segundo plano: ${message.messageId}');
    // Aquí puedes manejar la notificación de fondo.
    // Por ejemplo, enviar un `local notification` o actualizar algo en la app.
  }

  static Future<void> sendPushNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final get = get_server_key();
    String serverKey = await get.server_token();
    try {
      await http.post(
        Uri.parse(
          'https://fcm.googleapis.com/v1/projects/apps-d19d9/messages:send',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode({
          'to': token,
          'notification': {'title': title, 'body': body},
          'data': data ?? {},
        }),
      );
    } catch (e) {
      print('Error enviando la notificación: $e');
    }
  }
}
