import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfGenerator {
  static const List<String> _headers = [
    'Cédula',
    'Nombre',
    'Apellido',
    'Fecha y Hora Ingreso',
    'Fecha y Hora Salida',
    'CheckList',
  ];

  /// Genera un documento PDF con los datos de accesos.
  static Future<Uint8List> generatePdf(
    List<Map<String, dynamic>> accessDataList,
  ) async {
    if (accessDataList.isEmpty) {
      throw Exception("No hay datos para generar el PDF.");
    }

    final pdf = pw.Document();
    final user = FirebaseAuth.instance.currentUser;

    // Cargar logo desde assets
    final logoData = await rootBundle.load('assets/images/Logo.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context context) => _buildHeader(context, logoImage),
        footer: (pw.Context context) => _buildFooter(context, user?.email),
        build:
            (pw.Context context) => [
              pw.SizedBox(height: 20),
              _buildAccessTable(accessDataList),
            ],
      ),
    );

    return pdf.save();
  }

  /// Construye el encabezado del PDF.
  static pw.Widget _buildHeader(pw.Context context, pw.MemoryImage logoImage) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Image(logoImage, width: 50, height: 50),
        pw.Text(
          'Ingreso y salida \n Comunidad Llimpe Grande',
          style: pw.TextStyle(fontSize: 18),
          textAlign: pw.TextAlign.center,
        ),
        pw.Text(
          'Página ${context.pageNumber} de ${context.pagesCount}',
          style: pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  /// Construye el pie de página del PDF.
  static pw.Widget _buildFooter(pw.Context context, String? userEmail) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Impreso por: ${userEmail ?? 'Desconocido'}',
        style: pw.TextStyle(fontSize: 10),
      ),
    );
  }

  /// Formatea la fecha en formato dd/MM/yyyy -- HH:mm
  static String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'Sin fecha';
    final dateTime = DateTime.tryParse(dateTimeStr);
    if (dateTime == null) return 'Sin fecha';
    return "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} -- ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  /// Construye la tabla de accesos.
  static pw.Widget _buildAccessTable(List<Map<String, dynamic>> data) {
    final tableData =
        data
            .map(
              (entry) => [
                entry['cedula'] ?? '---',
                entry['nombre'] ?? '---',
                entry['apellido'] ?? '---',
                _formatDateTime(entry['horaIngreso']),
                _formatDateTime(entry['horaSalida']),
                pw.Container(
                  width: 20,
                  height: 20,
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                ),
              ],
            )
            .toList();

    // ignore: deprecated_member_use
    return pw.Table.fromTextArray(
      headers: _headers,
      data: tableData,
      headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      cellStyle: pw.TextStyle(fontSize: 9),
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignment: pw.Alignment.centerLeft,
      cellAlignments: {5: pw.Alignment.center},
    );
  }
}
