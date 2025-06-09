import 'package:app/screens/manager_type_news.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Asegúrate de importar Provider
import 'package:app/services/user_session.dart'; // Asegúrate de importar UserSession
import 'package:app/services/firebase_service.dart';

class NewNewsScreen extends StatefulWidget {
  const NewNewsScreen({super.key});

  @override
  State<NewNewsScreen> createState() => _NewNewsScreenState();
}

class _NewNewsScreenState extends State<NewNewsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _fuenteController = TextEditingController();
  late Future<void> _cargarDatosFuturo;

  String? _tipoNoticiaSeleccionado;

  List<String> _tiposNoticia = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosFuturo = context.read<UserSession>().cargarDatosUsuario();
    _obtenerListaTipoNoticias();
  }

  Future<void> _guardarNoticia() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final docRef = FirebaseFirestore.instance.collection('news').doc();

      await docRef.set({
        'id': docRef.id,
        'title': _tituloController.text.trim(),
        'description': _descripcionController.text.trim(),
        'source': _fuenteController.text.trim(),
        'type': _tipoNoticiaSeleccionado,
        'date': FieldValue.serverTimestamp(),
        'userId': context.read<UserSession>().userId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Noticia agregada exitosamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool obscureText = false,
    String? hintText,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 12,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildSubmitButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child:
            _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
      ),
    );
  }

  void _obtenerListaTipoNoticias() async {
    final tipoNoticias = await FirebaseService.getNewsTypes();
    setState(() {
      _tiposNoticia = tipoNoticias;
    });
  }

  void _crudTypeNews() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: ManagerTypeNews(
              onActualizar: () async {
                final tiposNoticiaActualizado =
                    await FirebaseService.getVisitReasons();
                setState(() => _tiposNoticia = tiposNoticiaActualizado);
              },
            ),
          ),
    );
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _fuenteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Noticia')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(
                'Título',
                _tituloController,
                hintText: 'Ej: Robo en zona centro',
                validator:
                    (value) => value!.isEmpty ? 'Ingrese un título' : null,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                'Descripción',
                _descripcionController,
                hintText: 'Detalle breve de la noticia...',
                maxLines: 3,
                validator:
                    (value) =>
                        value!.isEmpty ? 'Ingrese una descripción' : null,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                'Fuente',
                _fuenteController,
                hintText: 'Ej: Policía Nacional',
                validator:
                    (value) => value!.isEmpty ? 'Ingrese una fuente' : null,
              ),
              const SizedBox(height: 30),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _tipoNoticiaSeleccionado,
                      items:
                          _tiposNoticia
                              .map(
                                (tipo) => DropdownMenuItem(
                                  value: tipo,
                                  child: Text(tipo),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() {
                          _tipoNoticiaSeleccionado = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Tipo de noticia',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator:
                          (value) =>
                              value == null
                                  ? 'Seleccione un tipo de noticia'
                                  : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: _crudTypeNews,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _buildSubmitButton('Guardar Noticia', _guardarNoticia),
            ],
          ),
        ),
      ),
    );
  }
}
