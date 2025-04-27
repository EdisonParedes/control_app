import 'package:geolocator/geolocator.dart';

class LocationPermissionService {
  // Verifica si el permiso de ubicación está habilitado y lo solicita si es necesario
  static Future<Position?> requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verifica si el servicio de ubicación está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('El servicio de ubicación está deshabilitado');
    }

    // Verifica los permisos de ubicación
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return Future.error('Permiso de ubicación denegado');
      }
    }

    // Si el permiso es concedido, obtenemos la ubicación actual
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return position;
    }

    return null;
  }
}
