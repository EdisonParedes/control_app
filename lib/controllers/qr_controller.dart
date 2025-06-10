import 'dart:convert';
import 'package:app/models/visitor_qr_model.dart';

class QRController {
  String generateQRData(VisitorQR visitor) {
    return jsonEncode(visitor.toJson());
  }

  VisitorQR? parseQRData(String? qrCode) {
    try {
      if (qrCode == null) return null;
      final Map<String, dynamic> json = jsonDecode(qrCode);
      return VisitorQR.fromJson(json);
    } catch (e) {
      return null;
    }
  }
}
