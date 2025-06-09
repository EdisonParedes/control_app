import 'dart:typed_data';
import 'package:excel/excel.dart';

class ExcelGenerator {
  static Future<Uint8List> generateExcel(List<Map<String, dynamic>> ingresos) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Encabezados similares al PDF
    sheet.appendRow([
      'Cédula',
      'Nombre',
      'Apellido',
      'Fecha Ingreso',
      'Hora',
      'CheckList'
    ]);

    for (var ingreso in ingresos) {
      final fechaIngreso = DateTime.tryParse(ingreso['dateIn'] ?? '') ?? DateTime.now();
      final fechaFormateada =
          "${fechaIngreso.day}/${fechaIngreso.month}/${fechaIngreso.year}";
      final horaFormateada =
          "${fechaIngreso.hour}:${fechaIngreso.minute.toString().padLeft(2, '0')}";

      sheet.appendRow([
        ingreso['id'] ?? 'Desconocido',
        ingreso['name'] ?? '',
        ingreso['lastname'] ?? '',
        fechaFormateada,
        horaFormateada,
        '', 
      ]);
    }

    final fileBytes = excel.save();
    return Uint8List.fromList(fileBytes!);
  }
}
