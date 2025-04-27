import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:app/screens/map_screen.dart';

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

    // Escuchar las notificaciones cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(
        'Notificación recibida en primer plano: ${message.notification?.title}',
      );

      double latitude = double.tryParse(message.data['latitude'] ?? '0') ?? 0;
      double longitude = double.tryParse(message.data['longitude'] ?? '0') ?? 0;

      // Verifica si las coordenadas son válidas
      if (latitude != 0 && longitude != 0) {
        // Navegar a la pantalla del mapa con las coordenadas
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    MapScreen(latitude: latitude, longitude: longitude),
          ),
        );
      } else {
        // Si las coordenadas no son válidas, maneja el error o muestra un mensaje
        print("No se recibieron coordenadas válidas");
      }

      // Aquí puedes mostrar un Snackbar o actualizar la UI
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message.notification?.body ?? 'Sin título')),
      );
    });

    // Escuchar cuando la app se abre desde una notificación (en segundo plano o cerrada)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notificación abierta: ${message.notification?.title}');

      // Aquí puedes navegar a una pantalla específica de la app.
      // Por ejemplo, si tienes un `navigatorKey` global:
      // navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => SpecificPage()));

      // Acceder a los datos de la notificación
      double latitude = double.tryParse(message.data['latitude'] ?? '0') ?? 0;
      double longitude = double.tryParse(message.data['longitude'] ?? '0') ?? 0;

      // Verifica si las coordenadas son válidas
      if (latitude != 0 && longitude != 0) {
        // Navegar a la pantalla del mapa con las coordenadas
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    MapScreen(latitude: latitude, longitude: longitude),
          ),
        );
      } else {
        // Si las coordenadas no son válidas, maneja el error o muestra un mensaje
        print("No se recibieron coordenadas válidas");
      }
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
}
