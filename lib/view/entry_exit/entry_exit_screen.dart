import 'package:app/view/export/excel_preview_screen.dart';
import 'package:app/view/manager/manager_visit_reasons.dart';
import 'package:app/services/firebase_service.dart';
import 'package:app/services/user_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app/view/export/pdf_generation.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:app/services/serverkey.dart';
import 'package:app/view/qr/scan_qr_screen.dart';
import 'package:provider/provider.dart';

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
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _isExportingPdf = false;
  List<String> tiposAcceso = ['Ingreso', 'Salida'];
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  String _accessType = 'Ingreso';
  String _personType = 'Residente';
  String? _selectedReason;
  late List<String> _motivosVisita = [];

  @override
  void initState() {
    super.initState();
    _cargarMotivosVisita();
    final now = DateTime.now();
    _fechaInicio = DateTime(now.year, now.month, now.day);
    _fechaFin = DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  Future<void> _registerAccess() async {
    final session = context.read<UserSession>();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String dni = _idController.text.trim();
    String residentPhone = _phoneController.text.trim();
    String name = _nameController.text.trim();
    String lastname = _lastnameController.text.trim();
    String plate = _plateController.text.trim();

    if (_accessType == 'Ingreso') {
      // Validar ingreso duplicado
      if (await cedulaTieneIngresoSinSalidaHoy(dni)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Esta cédula ya tiene un ingreso sin salida.'),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      if (session.esVisitante()) {
        if (_selectedReason == null || _selectedReason!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Debe seleccionar un motivo de visita.')),
          );
          setState(() => _isLoading = false);
          return;
        }

        if (!RegExp(r'^\d{10}$').hasMatch(residentPhone)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Número de teléfono inválido.')),
          );
          setState(() => _isLoading = false);
          return;
        }

        final token = await getFcmTokenByPhoneNumber(residentPhone);
        if (token == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se encontró token del residente.')),
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
              'visitorName': name,
              'visitorCi': dni,
              'reason': _selectedReason,
              'status': 'Pendiente',
              'createdAt': Timestamp.now(),
            });

        // 2. Enviar notificación push
        await sendPushMessage(
          token,
          name,
          dni,
          _selectedReason!,
          requestId,
          userId,
        );

        // 3. Escuchar aprobación
        FirebaseFirestore.instance
            .collection('access_requests')
            .doc(requestId)
            .snapshots()
            .listen((snapshot) async {
              if (!snapshot.exists) return;
              final status = snapshot.data()?['status'];
              if (status == 'Aprobado') {
                await FirebaseFirestore.instance.collection('access').add({
                  'name': name,
                  'lastname': lastname,
                  'dni': dni,
                  'plate': plate,
                  'reason': _selectedReason,
                  'phone': residentPhone,
                  'dateIn': Timestamp.now(),
                  'dateOut': null,
                  'timestamp': FieldValue.serverTimestamp(),
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ingreso aprobado y registrado.')),
                );
                _formKey.currentState!.reset();
                _clearControllers();
                setState(() => _isLoading = false);
              } else if (status == 'Rechazado') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('El residente rechazó el ingreso.')),
                );
                setState(() => _isLoading = false);
              }
            });

        return;
      }

      // Si es residente, registrar directamente
      await FirebaseFirestore.instance.collection('access').add({
        'name': name,
        'lastname': lastname,
        'dni': dni,
        'plate': plate,
        'reason': 'Residente',
        'phone': null,
        'dateIn': Timestamp.now(),
        'dateOut': null,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ingreso de residente registrado.')),
      );
    } else {
      // Salida
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
          SnackBar(content: Text('No se encontró un ingreso pendiente.')),
        );
        setState(() => _isLoading = false);
        return;
      }

      await query.docs.first.reference.update({'dateOut': Timestamp.now()});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Salida registrada exitosamente.')),
      );
    }

    _formKey.currentState!.reset();
    _clearControllers();
    setState(() => _isLoading = false);
  }

  Future<void> _seleccionarFechas(BuildContext context) async {
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fechaInicio!, end: _fechaFin!),
    );

    if (rango != null) {
      setState(() {
        _fechaInicio = rango.start;
        _fechaFin = rango.end.add(
          const Duration(hours: 23, minutes: 59, seconds: 59),
        );
      });
    }
  }

  Future<bool> isAuthorizedUser() async {
    final session = context.read<UserSession>();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      return session.esAdmin() || session.esRepresentante();
    }
    return false;
  }

  String? validateCedulaEcuatoriana(String? cedula) {
    if (cedula == null || cedula.isEmpty)
      return 'El campo de cédula no puede estar vacío';
    if (!RegExp(r'^\d{10}$').hasMatch(cedula))
      return 'La cédula debe tener 10 dígitos numéricos';

    final digits = cedula.split('').map(int.parse).toList();
    final provinceCode = int.parse(cedula.substring(0, 2));
    final thirdDigit = digits[2];

    if (provinceCode < 1 || provinceCode > 24)
      return 'Código de provincia inválido';
    if (thirdDigit >= 6)
      return 'Tercer dígito inválido para cédula ecuatoriana';

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

    if (verificador != digits[9]) return 'La cédula ingresada no es válida';
    return null;
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

  Future<List<Map<String, dynamic>>> obtenerDatosDeAccesos({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('access')
            .where('timestamp', isGreaterThanOrEqualTo: fechaInicio)
            .where('timestamp', isLessThanOrEqualTo: fechaFin)
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

  Future<void> _exportToPdf() async {
    if (_fechaInicio == null || _fechaFin == null) return;

    final datos = await obtenerDatosDeAccesos(
      fechaInicio: _fechaInicio!,
      fechaFin: _fechaFin!,
    );

    if (datos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay datos en el rango seleccionado.')),
      );
      return;
    }

    final pdfData = await PdfGenerator.generatePdf(datos);
    await Printing.layoutPdf(onLayout: (format) async => pdfData);
  }

  Future<void> _exportToExcel() async {
    if (_fechaInicio == null || _fechaFin == null) return;

    final data = await obtenerDatosDeAccesos(
      fechaInicio: _fechaInicio!,
      fechaFin: _fechaFin!,
    );

    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay datos en el rango seleccionado.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExcelPreviewScreen(ingresos: data)),
    );
  }

  void _clearControllers() {
    _nameController.clear();
    _lastnameController.clear();
    _idController.clear();
    _plateController.clear();
    _reasonController.clear();
    _selectedReason = null;
    _personType = 'Residente';
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool obscureText = false,
    String? hintText,
    String? Function(String?)? validator,
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
        onPressed: _isLoading ? null : _registerAccess,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child:
            _isLoading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : const Text(
                  'Registrar',
                  style: TextStyle(color: Colors.white70),
                ),
      ),
    );
  }

  Widget _buildExportPdfButton() {
    return ElevatedButton.icon(
      onPressed: _isExportingPdf ? null : _exportToPdfC,
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

  Future<void> _exportToPdfC() async {
    setState(() {
      _isExportingPdf = true;
    });

    try {
      // Tu lógica para generar y abrir el PDF aquí
      await _exportToPdf(); // reemplaza por tu función real
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al exportar el PDF: $e')));
    } finally {
      setState(() {
        _isExportingPdf = false;
      });
    }
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

  void _abrirCrudMotivos() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: ManagerVisitReasons(
              onActualizar: () async {
                final motivosActualizados =
                    await FirebaseService.getVisitReasons();
                setState(() => _motivosVisita = motivosActualizados);
              },
            ),
          ),
    );
  }

  void _cargarMotivosVisita() async {
    final motivos = await FirebaseService.getVisitReasons();
    setState(() {
      _motivosVisita = motivos;
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    final session = context.read<UserSession>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      const SizedBox(height: 30),
                      const Center(
                        child: Text(
                          'Control de Ingreso y Salida',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Tipo de acceso
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
                                tiposAcceso
                                    .map(
                                      (tipo) => DropdownMenuItem(
                                        value: tipo,
                                        child: Text(tipo),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              setState(() {
                                _accessType = value!;
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Datos solo para ingreso
                      if (_accessType == 'Ingreso') ...[
                        Center(child: _buildQrScanButton()),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                'Nombre',
                                _nameController,
                                validator:
                                    (v) =>
                                        v!.isEmpty ? 'Campo requerido' : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField(
                                'Apellido',
                                _lastnameController,
                                validator:
                                    (v) =>
                                        v!.isEmpty ? 'Campo requerido' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Cédula
                      _buildTextField(
                        'Cédula',
                        _idController,
                        validator: validateCedulaEcuatoriana,
                      ),

                      const SizedBox(height: 16),

                      // Datos adicionales solo para ingreso
                      if (_accessType == 'Ingreso') ...[
                        // Tipo de persona
                        Row(
                          children: [
                            const Text(
                              'Tipo de persona:',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 10),
                            DropdownButton<String>(
                              value: _personType,
                              items:
                                  ['Residente', 'Visitante']
                                      .map(
                                        (tipo) => DropdownMenuItem(
                                          value: tipo,
                                          child: Text(tipo),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _personType = value!;
                                  _selectedReason = null;
                                });
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        _buildTextField(
                          'Placa del vehículo (opcional)',
                          _plateController,
                        ),

                        const SizedBox(height: 16),

                        // Motivo de visita y teléfono del residente (solo si es visitante)
                        if (_personType == 'Visitante') ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
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
                                    if (session.esVisitante() &&
                                        (value == null || value.isEmpty)) {
                                      return 'Debe seleccionar un motivo';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              if (session.esRepresentante() ||
                                  session.esGuardia())
                                IconButton(
                                  icon: const Icon(Icons.settings),
                                  onPressed: _abrirCrudMotivos,
                                ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          _buildTextField(
                            'Teléfono del residente',
                            _phoneController,
                            validator: (v) {
                              if (_personType == 'Visitante') {
                                if (v == null || v.trim().isEmpty)
                                  return 'Campo requerido';
                                if (!RegExp(r'^\d{10}$').hasMatch(v))
                                  return 'Número inválido';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),
                        ],
                      ],

                      // Botón registrar
                      Center(child: _buildRegisterButton()),

                      const SizedBox(height: 10),

                      // Botones de exportar (solo usuarios autorizados)
                      FutureBuilder<bool>(
                        future: isAuthorizedUser(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasData &&
                              snapshot.data == true) {
                            return Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Desde: ${_fechaInicio?.toLocal().toString().split(' ')[0]}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Hasta: ${_fechaFin?.toLocal().toString().split(' ')[0]}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: () => _seleccionarFechas(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cambiar fechas',
                                    style: TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildExportPdfButton(),
                                    const SizedBox(width: 5),
                                    _buildExportExcelButton(),
                                  ],
                                ),
                              ],
                            );
                          } else {
                            return const SizedBox();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrScanButton() {
    return SizedBox(
      width: 150,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScanQRScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueGrey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
        label: const Text('Código QR', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

Future<String?> getFcmTokenByPhoneNumber(String phoneNumber) async {
  try {
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: phoneNumber)
            .limit(1)
            .get();

    if (querySnapshot.docs.isNotEmpty) {
      final data = querySnapshot.docs.first.data();
      return data['fcmToken'] as String?;
    } else {
      print('No user found with phone number $phoneNumber');
      return null;
    }
  } catch (e) {
    print('Error fetching FCM token from users: $e');
    return null;
  }
}

Future<void> sendPushMessage(
  String token,
  String visitorName,
  String visitorCi,
  String reason,
  String requestId,
  String userId,
) async {
  final get = get_server_key();
  String serverKey = await get.server_token();
  final url = Uri.parse(
    'https://fcm.googleapis.com/v1/projects/apps-d19d9/messages:send',
  );
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $serverKey',
    },
    body: jsonEncode({
      'message': {
        'token': token,
        'notification': {
          'title': 'Solicitud de ingreso',
          'body': '$visitorName solicita ingresar como $reason.',
        },
        'data': {
          'visitorName': visitorName,
          'visitorCi': visitorCi,
          'reason': reason,
          'requestId': requestId,
          'senderId': userId,
        },
      },
    }),
  );

  if (response.statusCode == 200) {
    print('Notificación enviada correctamente');
  } else {
    print('Error al enviar notificación: ${response.body}');
  }
}
