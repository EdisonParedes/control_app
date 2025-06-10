import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:app/models/visitor_qr_model.dart';
import 'package:app/controllers/qr_controller.dart';

class GenerateQRScreen extends StatelessWidget {
  final String name;
  final String lastname;
  final String id;
  final String type;
  final String phone;

  const GenerateQRScreen({
    super.key,
    required this.name,
    required this.lastname,
    required this.id,
    required this.type,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    final controller = QRController();
    final qrData = controller.generateQRData(
      VisitorQR(
        name: name,
        lastname: lastname,
        id: id,
        type: type,
        phone: phone,
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Código QR')),
      body: Center(
        child: QrImageView(
          data: qrData,
          version: QrVersions.auto,
          size: 250.0,
        ),
      ),
    );
  }
}
