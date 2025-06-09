import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:app/view/qr/approve_entry_QR_screen.dart'; 

class ScanQRScreen extends StatefulWidget {
  const ScanQRScreen({super.key});

  @override
  State<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Escanear QR del visitante")),
      body: QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
        overlay: QrScannerOverlayShape(
          borderColor: Colors.blue,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: 250,
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      controller.pauseCamera(); // Pausar la cámara después de escanear

      try {
        // Decodificar el QR escaneado (json)
        final Map<String, dynamic> data = jsonDecode(scanData.code ?? '{}');

        // Verificar si los datos contienen las claves esperadas
        if (data.containsKey('name') &&
            data.containsKey('lastname') &&
            data.containsKey('id') &&
            data.containsKey('type') &&
            data.containsKey('phone')) {
          // Navegar a la pantalla de aprobación de ingreso
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ApproveEntryScreen(
                    name: data['name'] ?? '',
                    lastname: data['lastname'] ?? '',
                    ci: data['id'] ?? '',
                    type: data['type'] ?? '',
                    phone: data['phone'] ?? ''
                  ),
            ),
          );
        } else {
          // Si faltan datos, mostrar un mensaje de error
          throw Exception('Campos faltantes');
        }
      } catch (e) {
        // Mostrar un SnackBar si ocurre un error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR inválido o datos incompletos')),
        );
        await Future.delayed(const Duration(seconds: 2)); // Esperar 2 segundos
        controller.resumeCamera(); // Reanudar la cámara para otro escaneo
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose(); // Liberar los recursos de la cámara
    super.dispose();
  }
}
