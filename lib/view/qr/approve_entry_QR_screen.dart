import 'package:app/view/entry_exit/entry_exit_screen.dart';
import 'package:app/services/user_session.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/services/my_firebase_messaging_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/view/entry_exit/visitor_approval_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:app/services/firebase_service.dart';
import 'package:provider/provider.dart';

class ApproveEntryScreen extends StatefulWidget {
  final String name;
  final String lastname;
  final String ci;
  final String type;
  final String phone;

  const ApproveEntryScreen({
    super.key,
    required this.name,
    required this.lastname,
    required this.ci,
    required this.type,
    required this.phone,
  });

  @override
  State<ApproveEntryScreen> createState() => _ApproveEntryScreenState();
}

class _ApproveEntryScreenState extends State<ApproveEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  String? _selectedReason;

  List<String> _motivosVisita = [];

  @override
  void initState() {
    super.initState();
    _cargarMotivosVisita();
  }

  @override
  void dispose() {
    _plateController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _cargarMotivosVisita() async {
    final motivos = await FirebaseService.getVisitReasons();
    setState(() {
      _motivosVisita = motivos;
    });
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: validator,
    );
  }

  Future<void> _registerAccess() async {
    setState(() => _isLoading = true);

    if (!_formKey.currentState!.validate()) return;

    final String plate = _plateController.text.trim();
    final String phone = _phoneController.text.trim();

    final existingEntry =
        await FirebaseFirestore.instance
            .collection('access')
            .where('dni', isEqualTo: widget.ci)
            .where('dateOut', isNull: true)
            .limit(1)
            .get();

    if (existingEntry.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta persona ya se encuentra dentro.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    if (widget.type == 'visitante') {
      if (_selectedReason == null || _selectedReason!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debe seleccionar un motivo')),
        );
        setState(() => _isLoading = false);
        return;
      }

      if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Número de teléfono inválido')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final token = await getFcmTokenByPhoneNumber(phone);
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró token del residente')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final requestId = DateTime.now().millisecondsSinceEpoch.toString();
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      // 1. Crear solicitud en Firestore
      await FirebaseFirestore.instance
          .collection('access_requests')
          .doc(requestId)
          .set({
            'visitorName': widget.name,
            'visitorCi': widget.ci,
            'reason': _selectedReason,
            'status': 'Pendiente',
            'createdAt': Timestamp.now(),
          });

      // 2. Enviar notificación
      await sendPushMessage(
        token,
        widget.ci,
        widget.name,
        _selectedReason!,
        requestId,
        userId,
      );

      // 3. Escuchar la respuesta del residente
      FirebaseFirestore.instance
          .collection('access_requests')
          .doc(requestId)
          .snapshots()
          .listen((snapshot) async {
            if (!snapshot.exists) return;

            final status = snapshot.data()?['status'];
            if (status == 'Aprobado') {
              // Registrar ingreso
              await FirebaseFirestore.instance.collection('access').add({
                'name': widget.name,
                'lastname': widget.lastname,
                'dni': widget.ci,
                'plate': plate,
                'reason': _selectedReason,
                'phone': widget.phone,
                'dateIn': Timestamp.now(),
                'dateOut': null,
                'timestamp': FieldValue.serverTimestamp(),
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ingreso aprobado y registrado')),
              );
              setState(() => _isLoading = false);
            } else if (status == 'Rechazado') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('El residente rechazó el ingreso'),
                ),
              );
              setState(() => _isLoading = false);
            }
          });

      return; // Salir para no registrar el ingreso hasta que aprueben
    }

    // Si no es visitante, registrar directamente
    await FirebaseFirestore.instance.collection('access').add({
      'name': widget.name,
      'lastname': widget.lastname,
      'dni': widget.ci,
      'plate': plate,
      'reason': 'Residente',
      'phone': widget.phone,
      'dateIn': Timestamp.now(),
      'dateOut': null,
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ingreso registrado exitosamente')),
    );

    setState(() => _isLoading = false);
    _formKey.currentState!.reset();
    _plateController.clear();
    _phoneController.clear();
    setState(() => _selectedReason = null);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Aprobar ingreso")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_isLoading) const Center(child: CircularProgressIndicator()),
              Text("Nombre: ${widget.name}"),
              Text("Apellido: ${widget.lastname}"),
              Text("CI: ${widget.ci}"),
              Text("Tipo: ${widget.type}"),
              Text("Teléfono: ${widget.phone}"),
              const SizedBox(height: 20),
              _buildTextField(
                'Placa del vehículo (opcional)',
                _plateController,
              ),
              const SizedBox(height: 16),
              if (widget.type == 'visitante') ...[
                DropdownButtonFormField<String>(
                  value: _selectedReason,
                  decoration: InputDecoration(
                    labelText: 'Motivo de la visita',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items:
                      _motivosVisita
                          .map(
                            (motivo) => DropdownMenuItem(
                              value: motivo,
                              child: Text(motivo),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedReason = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Debe seleccionar un motivo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Teléfono del residente',
                  _phoneController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Campo requerido';
                    }
                    if (!RegExp(r'^\d{10}$').hasMatch(v)) {
                      return 'Número inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: 150,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registerAccess,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Registrar',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
