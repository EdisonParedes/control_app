import 'package:app/screens/ExcelPreviewScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app/screens/pdf_Generation.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class EntryExitScreen extends StatefulWidget {
  const EntryExitScreen({super.key});

  @override
  State<EntryExitScreen> createState() => _EntryExitScreenState();
}

class _EntryExitScreenState extends State<EntryExitScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  bool _isLoading = false;

  String _accessType = 'Ingreso';

  Future<void> _registerAccess() async {
    String cedula = _idController.text.trim();

    if (!_formKey.currentState!.validate()) return;

    final dni = _idController.text.trim();

    if (_accessType == 'Ingreso') {
      if (await cedulaTieneIngresoSinSalidaHoy(cedula)) {
        // Mostrar alerta
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Esta cédula ya fue registrada hoy.')),
        );
        _clearControllers();
        return;
      }

      await FirebaseFirestore.instance.collection('access').add({
        'name': _nameController.text.trim(),
        'lastname': _lastnameController.text.trim(),
        'dni': dni,
        'plate': _plateController.text.trim(),
        'reason': _reasonController.text.trim(),
        'dateIn': Timestamp.now(),
        'dateOut': null,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ingreso registrado exitosamente.')),
      );
    } else {
      // Lógica para registrar SALIDA
      final query =
          await FirebaseFirestore.instance
              .collection('access')
              .where('dni', isEqualTo: dni)
              .where('dateOut', isNull: true)
              .orderBy('dateIn', descending: true)
              .limit(1)
              .get();

      if (query.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se encontró un ingreso pendiente para esta cédula.',
            ),
          ),
        );
        _clearControllers();
        return;
      }

      final docRef = query.docs.first.reference;

      await docRef.update({'dateOut': Timestamp.now()});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Salida registrada exitosamente.')),
      );
    }

    _formKey.currentState!.reset();
    _clearControllers();
  }

  Future<bool> isAuthorizedUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final userRole = doc.data()?['rol'];

      return userRole == 'admin';
    }

    return false;
  }

  String? validateCedulaEcuatoriana(String? cedula) {
    if (cedula == null || cedula.isEmpty) {
      return 'El campo de cédula no puede estar vacío';
    }
    if (!RegExp(r'^\d{10}$').hasMatch(cedula)) {
      return 'La cédula debe tener exactamente 10 dígitos \nnuméricos';
    }

    final digits = cedula.split('').map(int.parse).toList();
    final provinceCode = int.parse(cedula.substring(0, 2));
    final thirdDigit = digits[2];

    if (provinceCode < 1 || provinceCode > 24) {
      return 'El código de provincia (dos primeros dígitos)\n no es válido';
    }
    if (thirdDigit >= 6) {
      return 'El tercer dígito no es válido para una cédula\n ecuatoriana';
    }
    // Algoritmo de validación del dígito verificador (módulo 10)
    int suma = 0;
    for (int i = 0; i < 9; i++) {
      int valor = digits[i];
      if (i % 2 == 0) {
        valor *= 2;
        if (valor > 9) valor -= 9;
      }
      suma += valor;
    }
    int verificador = 10 - (suma % 10);
    if (verificador == 10) verificador = 0;

    if (verificador != digits[9]) {
      return 'La cédula ingresada no es válida';
    }
    return null; // ✅ Cédula válida
  }

  Future<List<Map<String, dynamic>>> obtenerDatosDeAccesos() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('access')
            .orderBy('timestamp', descending: true)
            .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'nombre': data['name'],
        'apellido': data['lastname'],
        'cedula': data['dni'],
        'placa': data['plate'],
        'motivo': data['reason'],
        'horaIngreso':
            data['dateIn'] != null
                ? (data['dateIn'] as Timestamp).toDate().toString()
                : '',
        'horaSalida':
            data['dateOut'] != null
                ? (data['dateOut'] as Timestamp).toDate().toString()
                : '',
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
                const SizedBox(width: 20),
                Row(
                  children: [
                    const Text(
                      'Tipo de acceso:',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: _accessType,
                      items:
                          ['Ingreso', 'Salida'].map((tipo) {
                            return DropdownMenuItem(
                              value: tipo,
                              child: Text(tipo),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _accessType = value!;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Solo si es INGRESO
                if (_accessType == 'Ingreso') ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          'Nombre',
                          _nameController,
                          validator:
                              (value) =>
                                  value!.isEmpty
                                      ? 'Este campo es obligatorio'
                                      : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTextField(
                          'Apellido',
                          _lastnameController,
                          validator:
                              (value) =>
                                  value!.isEmpty
                                      ? 'Este campo es obligatorio'
                                      : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // Siempre mostrar cédula
                _buildTextField(
                  'Cédula',
                  _idController,
                  validator: validateCedulaEcuatoriana,
                ),
                const SizedBox(height: 20),

                // Solo si es INGRESO
                if (_accessType == 'Ingreso') ...[
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
                ],

                // Botón Registrar
                Center(child: _buildRegisterButton()),
                const SizedBox(height: 10),

                // Botones visibles solo para usuarios autorizados
                FutureBuilder<bool>(
                  future: isAuthorizedUser(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasData && snapshot.data == true) {
                      return Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildExportPdfButton(),
                            const SizedBox(width: 5),
                            _buildExportExcelButton(),
                          ],
                        ),
                      );
                    } else {
                      return const SizedBox(); // No muestra nada si no es autorizado
                    }
                  },
                ),
              ],
            ),
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

  Future<bool> cedulaTieneIngresoSinSalidaHoy(String cedula) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final query =
        await FirebaseFirestore.instance
            .collection('access')
            .where('dni', isEqualTo: cedula)
            .where(
              'dateIn',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
            )
            .where('dateIn', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
            .where('dateOut', isNull: true)
            .get();

    return query.docs.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getIngresos() async {
    List<Map<String, dynamic>> ingresosList = [];
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('access').get();

      for (var doc in querySnapshot.docs) {
        ingresosList.add(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print('Error al obtener ingresos: $e');
    }
    return ingresosList;
  }

  Future<void> _exportToPdf() async {
    final datos = await obtenerDatosDeAccesos();
    final pdfData = await PdfGenerator.generatePdf(datos);
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfData);
  }

  Future<void> _exportToExcel() async {
    final data = await obtenerDatosDeAccesos();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExcelPreviewScreen(ingresos: data)),
    );
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

  void _clearControllers() {
    _nameController.clear();
    _lastnameController.clear();
    _idController.clear();
    _plateController.clear();
    _reasonController.clear();
  }
}
