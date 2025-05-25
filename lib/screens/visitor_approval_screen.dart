import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VisitorApprovalScreen extends StatefulWidget {
  final String visitorName;
  final String visitorCi;
  final String reason;
  final String requestId; // ID del documento de solicitud en Firestore

  const VisitorApprovalScreen({
    super.key,
    required this.visitorName,
    required this.visitorCi,
    required this.reason,
    required this.requestId,
  });

  @override
  State<VisitorApprovalScreen> createState() => _VisitorApprovalScreenState();
}

class _VisitorApprovalScreenState extends State<VisitorApprovalScreen> {
  bool _loading = false;

  Future<void> _respondToRequest(bool approved) async {
    setState(() => _loading = true);

    try {
      await FirebaseFirestore.instance
          .collection('access_requests')
          .doc(widget.requestId)
          .update({
            'status': approved ? 'Aprobado' : 'Rechazado',
            'responseTime': Timestamp.now(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approved ? 'Ingreso aprobado' : 'Ingreso rechazado'),
          backgroundColor: approved ? Colors.green : Colors.red,
        ),
      );

      Navigator.of(context).pop(); // volver a la pantalla anterior
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitud de ingreso')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nombre del visitante: ${widget.visitorName}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'CI: ${widget.visitorCi}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Motivo: ${widget.reason}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _respondToRequest(true),
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: const Text('Aceptar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _respondToRequest(false),
                          icon: const Icon(Icons.close, color: Colors.white),
                          label: const Text('Rechazar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
    );
  }
}
