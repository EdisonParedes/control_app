import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart'; // Para compartir
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ExcelPreviewScreen extends StatefulWidget {
  final List<Map<String, dynamic>> ingresos;

  const ExcelPreviewScreen({Key? key, required this.ingresos})
    : super(key: key);

  @override
  State<ExcelPreviewScreen> createState() => _ExcelPreviewScreenState();
}

class _ExcelPreviewScreenState extends State<ExcelPreviewScreen> {
  Future<void> _exportAndShareExcel(BuildContext context) async {
    final excelData = await _generateExcelData(widget.ingresos);

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/ingresos.xlsx');
    await file.writeAsBytes(excelData);

    Share.shareXFiles([XFile(file.path)], text: 'Archivo Excel de ingresos');
  }

  Future<Uint8List> _generateExcelData(ingresos) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Agregar encabezado en negrita
    sheet.appendRow([
      'Cédula',
      'Nombre',
      'Apellido',
      'Fecha y Hora Ingreso',
      'Fecha y Hora Salida',
      'CheckList',
    ]);

    // Agregar los datos de ingresos
    for (var ingreso in ingresos) {
      final fechaIngreso =
          DateTime.tryParse(ingreso['fechaIngreso'] ?? '') ?? DateTime.now();
      final fechaSalida =
          DateTime.tryParse(ingreso['fechaSalida'] ?? '') ?? DateTime.now();

      final fechaHoraIngreso =
          "${fechaIngreso.day.toString().padLeft(2, '0')}/${fechaIngreso.month.toString().padLeft(2, '0')}/${fechaIngreso.year} -- ${fechaIngreso.hour.toString().padLeft(2, '0')}:${fechaIngreso.minute.toString().padLeft(2, '0')}";
      final fechaHoraSalida =
          "${fechaSalida.day.toString().padLeft(2, '0')}/${fechaSalida.month.toString().padLeft(2, '0')}/${fechaSalida.year} -- ${fechaSalida.hour.toString().padLeft(2, '0')}:${fechaSalida.minute.toString().padLeft(2, '0')}";

      sheet.appendRow([
        ingreso['id'] ?? 'Desconocido',
        ingreso['name'] ?? '',
        ingreso['lastname'] ?? '',
        fechaHoraIngreso,
        fechaHoraSalida,
        '',
      ]);
    }

    // Convertir el archivo Excel a bytes
    final fileBytes = excel.save();
    return Uint8List.fromList(fileBytes!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          Padding(padding: EdgeInsets.all(0)),
          const SizedBox(height: 10),
          const Text(
            'Vista previa de Ingreso y salida \n Comunidad Llimpe Grande',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Cédula')),
                  DataColumn(label: Text('Nombre')),
                  DataColumn(label: Text('Apellido')),
                  DataColumn(label: Text('Fecha Ingreso')),
                  DataColumn(label: Text('Fecha Salida')),
                  DataColumn(label: Text('CheckList')),
                ],
                rows:
                    widget.ingresos.map((ingreso) {
                      final fechaIngreso =
                          ingreso['horaIngreso'] != null
                              ? DateTime.tryParse(ingreso['horaIngreso'])
                              : null;
                      final fechaSalida =
                          ingreso['horaSalida'] != null
                              ? DateTime.tryParse(ingreso['horaSalida'])
                              : null;

                      final fechaHoraIngreso =
                          fechaIngreso != null
                              ? "${fechaIngreso.day.toString().padLeft(2, '0')}/${fechaIngreso.month.toString().padLeft(2, '0')}/${fechaIngreso.year} -- ${fechaIngreso.hour.toString().padLeft(2, '0')}:${fechaIngreso.minute.toString().padLeft(2, '0')}"
                              : 'Sin fecha';

                      final fechaHoraSalida =
                          fechaSalida != null
                              ? "${fechaSalida.day.toString().padLeft(2, '0')}/${fechaSalida.month.toString().padLeft(2, '0')}/${fechaSalida.year} -- ${fechaSalida.hour.toString().padLeft(2, '0')}:${fechaSalida.minute.toString().padLeft(2, '0')}"
                              : 'Sin salida';
                      return DataRow(
                        cells: [
                          DataCell(Text(ingreso['cedula'] ?? '')),
                          DataCell(Text(ingreso['nombre'] ?? '')),
                          DataCell(Text(ingreso['apellido'] ?? '')),
                          DataCell(Text(fechaHoraIngreso)),
                          DataCell(Text(fechaHoraSalida)),
                          DataCell(Text('')), // CheckList vacío por ahora
                        ],
                      );
                    }).toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: _buildExportExcelButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildExportExcelButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _exportAndShareExcel(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: const Icon(Icons.file_copy, color: Colors.white70),
      label: const Text(
        'Exportar y compartir Excel',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }
}
