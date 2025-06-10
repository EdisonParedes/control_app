import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:app/controllers/qr_controller.dart';
import 'package:app/view/entry_exit/approve_entry_QR_screen.dart';

class ScanQRScreen extends StatefulWidget {
  const ScanQRScreen({super.key});

  @override
  State<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  void _onQRViewCreated(QRViewController qrController) {
    controller = qrController;
    final qrCtrl = QRController();

    qrController.scannedDataStream.listen((scanData) async {
      controller?.pauseCamera();
      final data = qrCtrl.parseQRData(scanData.code);

      if (data != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ApproveEntryScreen(
              name: data.name,
              lastname: data.lastname,
              ci: data.id,
              type: data.type,
              phone: data.phone,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR inválido o datos incompletos')),
        );
        await Future.delayed(const Duration(seconds: 2));
        controller?.resumeCamera();
      }
    });
  }

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

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
