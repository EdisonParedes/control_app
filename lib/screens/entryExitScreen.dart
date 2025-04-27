import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class EntryExitScreen extends StatefulWidget {
  const EntryExitScreen({super.key});

  @override
  State<EntryExitScreen> createState() => _EntryExitScreenState();
}

class _EntryExitScreenState extends State<EntryExitScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  String _accessType = 'Ingreso';

  void _registerAccess() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final now = DateTime.now();
        final dateFormatted =
            now.toIso8601String(); // o usa un formato más limpio si deseas

        // Crea el nuevo documento para obtener su ID
        final docRef = FirebaseFirestore.instance.collection('access').doc();

        // Construye el mapa de datos
        final accessData = {
          'accessId': docRef.id,
          'dateIn': _accessType == 'Ingreso' ? dateFormatted : '',
          'dateOut': _accessType == 'Salida' ? dateFormatted : '',
          'status': _accessType == 'Ingreso' ? 'Dentro' : 'Fuera',
          'userId': user.uid,
          'vehicleId':
              _plateController.text.trim().isNotEmpty
                  ? _plateController.text.trim()
                  : '', // o un ID real si manejas una colección `vehicles`
        };

        // Guarda en Firestore
        await docRef.set(accessData);

        // Limpiar campos
        _nameController.clear();
        _idController.clear();
        _plateController.clear();
        _reasonController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Acceso registrado correctamente')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Debe iniciar sesión')));
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al registrar acceso')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //ppBar: AppBar(title: const Text('Control de Ingreso y Salida')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Text(
                  'Control de Ingreso y Salida',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Tipo de acceso:', style: TextStyle(fontSize: 16)),
              DropdownButton<String>(
                value: _accessType,
                items:
                    ['Ingreso', 'Salida']
                        .map(
                          (tipo) =>
                              DropdownMenuItem(value: tipo, child: Text(tipo)),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    _accessType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'Nombre completo',
                _nameController,
                validator:
                    (value) =>
                        value!.isEmpty ? 'Este campo es obligatorio' : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                'Cédula',
                _idController,
                validator:
                    (value) =>
                        value!.isEmpty ? 'Este campo es obligatorio' : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                'Placa del vehículo (opcional)',
                _plateController,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                'Motivo de la visita',
                _reasonController,
                validator:
                    (value) =>
                        value!.isEmpty ? 'Este campo es obligatorio' : null,
              ),
              const SizedBox(height: 24),
              Center(child: _buildRegisterButton()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool obscureText = false,
    String? hintText,
    String? Function(String?)? validator, // Agregamos el validator aquí
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hintText,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 12.0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black, width: 1.1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black, width: 1.1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black, width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: 150,
      child: ElevatedButton(
        onPressed: _registerAccess,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text('Registrar', style: TextStyle(color: Colors.white70)),
      ),
    );
  }
}
