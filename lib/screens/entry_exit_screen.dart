import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:app/screens/pdf_Generation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:app/screens/ExcelGenerator.dart';
import 'package:share_plus/share_plus.dart'; 

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

  bool _isAuthorizedUser() {
    final user = FirebaseAuth.instance.currentUser;
    // Aquí deberías tener cargado el "rol" del usuario.
    // Simulamos por ahora que el rol está guardado en alguna variable.
    String? userRole =
        'admin'; // <-- Simulación. Luego debes traer el rol real.

    return userRole == 'admin' ||
        userRole == 'representante' ||
        userRole == 'guardia' ||
        userRole == 'supervisor';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
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
              const SizedBox(height: 10),

              if (_isAuthorizedUser())
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildExportPdfButton(),
                      const SizedBox(width: 5),
                      _buildExportExcelButton(),
                    ],
                  ),
                ),
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

  Future<void> _exportToPdf() async {
    final pdfData = await PdfGenerator.generatePdf();

    // Mostrar el PDF o imprimirlo directamente
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfData);
  }

  Future<void> _exportToExcel() async {
  final excelData = await ExcelGenerator.generateExcel();

  // Guardarlo temporalmente
  final directory = await getTemporaryDirectory();
  final filePath = '${directory.path}/reporte.xlsx';
  final file = File(filePath);
  await file.writeAsBytes(excelData);

  // Compartirlo o abrirlo
  await Share.shareXFiles([XFile(filePath)], text: 'Aquí está el reporte Excel 📄');
}


  Widget _buildExportPdfButton() {
    return ElevatedButton.icon(
      onPressed: _exportToPdf,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: const Icon(Icons.picture_as_pdf, color: Colors.white70),
      label: const Text(
        'Exportar PDF',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _buildExportExcelButton() {
    return ElevatedButton.icon(
      onPressed: _exportToExcel,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: const Icon(Icons.grid_on, color: Colors.white70),
      label: const Text(
        'Exportar Excel',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }
}
