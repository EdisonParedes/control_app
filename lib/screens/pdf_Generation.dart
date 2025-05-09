import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfGenerator {
  static Future<Uint8List> generatePdf(
    List<Map<String, dynamic>> datosAccesos,
  ) async {
    final pdf = pw.Document();
    final user = FirebaseAuth.instance.currentUser;

    // Cargar logo
    final logoData = await rootBundle.load('assets/images/Logo.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header:
            (pw.Context context) => pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Image(logoImage, width: 50, height: 50),
                pw.Text(
                  'Ingreso y salida \n Comunidad Llimpe Grande',
                  style: pw.TextStyle(fontSize: 18,),
                  textAlign: pw.TextAlign.center
                ),
                pw.Text(
                  'Página ${context.pageNumber} de ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
        footer:
            (pw.Context context) => pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Impreso por: ${user?.email ?? 'Desconocido'}',
                style: pw.TextStyle(fontSize: 10),
              ),
            ),
        build:
            (pw.Context context) => [
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: [
                  'Cédula',
                  'Nombre',
                  'Apellido',
                  'Fecha y Hora Ingreso',
                  'Fecha y Hora Salida',
                  'CheckList',
                ],
                data:
                    datosAccesos.map((data) {
                      final dateIn =
                          data['horaIngreso'] != null
                              ? DateTime.tryParse(data['horaIngreso'])
                              : null;
                      final dateOut =
                          data['horaSalida'] != null
                              ? DateTime.tryParse(data['horaSalida'])
                              : null;

                      final fechaHoraIngreso =
                          dateIn != null
                              ? "${dateIn.day.toString().padLeft(2, '0')}/${dateIn.month.toString().padLeft(2, '0')}/${dateIn.year} -- ${dateIn.hour.toString().padLeft(2, '0')}:${dateIn.minute.toString().padLeft(2, '0')}"
                              : 'Sin fecha';

                      final fechaHoraSalida =
                          dateOut != null
                              ? "${dateOut.day.toString().padLeft(2, '0')}/${dateOut.month.toString().padLeft(2, '0')}/${dateOut.year} -- ${dateOut.hour.toString().padLeft(2, '0')}:${dateOut.minute.toString().padLeft(2, '0')}"
                              : 'Sin salida';

                      return [
                        data['cedula'] ?? '---',
                        data['nombre'] ?? '---',
                        data['apellido'] ?? '---',
                        fechaHoraIngreso,
                        fechaHoraSalida,
                        pw.Container(
                          width: 20,
                          height: 20,
                          decoration: pw.BoxDecoration(border: pw.Border.all()),
                        ),
                      ];
                    }).toList(),
                headerStyle: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
                cellStyle: pw.TextStyle(fontSize: 9),
                headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: {
                  6: pw.Alignment.center, // Centra la columna "CheckList"
                },
              ),
            ],
      ),
    );

    return pdf.save();
  }
}
