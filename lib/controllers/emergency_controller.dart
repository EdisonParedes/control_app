// /controllers/emergency_controller.dart

import 'package:app/models/emergency_model.dart';

class EmergencyController {
  final EmergencyModel _model = EmergencyModel();

  Future<void> sendEmergencyNotifications() async {
    await _model.sendEmergencyNotifications();
  }
}
