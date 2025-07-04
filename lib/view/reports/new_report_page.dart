import 'package:app/controllers/report_controller.dart';
import 'package:flutter/material.dart';
import 'my_reports_page.dart';

class NewReportPage extends StatefulWidget {
  const NewReportPage({super.key});

  @override
  State<NewReportPage> createState() => _NewReportPageState();
}

class _NewReportPageState extends State<NewReportPage> {
  final TextEditingController _incidentNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  bool _isLoading = false;

  final ReportController _controller = ReportController();

  @override
  void dispose() {
    _incidentNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final title = _incidentNameController.text.trim();
    final description = _descriptionController.text.trim();
    final location = _locationController.text.trim();

    if (title.isEmpty || description.isEmpty || location.isEmpty) {
      _showSnackbar('Por favor, completa todos los campos');
      return;
    }
    setState(() => _isLoading = true);

    try {
      await _controller.submitReport(
        title: title,
        description: description,
        location: location,
      );

      _showSnackbar('Reporte enviado exitosamente');
      _clearForm();
    } catch (e) {
      debugPrint('Error al enviar el reporte: $e');
      _showSnackbar('Ocurrió un error al enviar el reporte');
    }
  }

  void _clearForm() {
    _incidentNameController.clear();
    _descriptionController.clear();
    _locationController.clear();
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    // MISMO WIDGET TREE que el original
    // (omitido aquí por espacio, puedes copiar el que ya tienes arriba sin cambios)
    // Solo reemplaza el método _submitReport y todo lo demás queda igual.
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _buildListReportsButton(),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Nuevo Reporte',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 40),
              _buildLabel('Nombre del Incidente'),
              _buildTextField(
                controller: _incidentNameController,
                label: 'Ej. Robo en la vía pública',
              ),
              const SizedBox(height: 20),
              _buildLabel('Descripción'),
              _buildTextField(
                controller: _descriptionController,
                label: 'Detalles del incidente',
                maxLines: 5,
              ),
              const SizedBox(height: 20),
              _buildLabel('Ubicación'),
              _buildTextField(
                controller: _locationController,
                label: 'Ej. Calle 123, Ciudad',
              ),
              const SizedBox(height: 20),
              Center(child: _buildSubmitButton()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.bold));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: 150,
      child: ElevatedButton(
        onPressed: _isLoading ? null :_submitReport,
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
                  'Enviar Reporte',
                  style: TextStyle(color: Colors.white70),
                ),
      ),
    );
  }

  Widget _buildListReportsButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.list, size: 16, color: Colors.white70),
      label: const Text('Reportes', style: TextStyle(color: Colors.white70)),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyReportsPage()),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
