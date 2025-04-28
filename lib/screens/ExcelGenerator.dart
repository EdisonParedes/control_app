import 'dart:typed_data';
import 'package:excel/excel.dart';

class ExcelGenerator {
  static Future<Uint8List> generateExcel() async {
    final excel = Excel.createExcel(); // Crea un nuevo archivo Excel
    final sheet = excel['Sheet1'];      // Accede a la hoja por defecto

    // Escribe datos (puedes personalizar)
    sheet.appendRow(['Nombre', 'Edad', 'Correo']);
    sheet.appendRow(['Juan Pérez', 28, 'juan@example.com']);
    sheet.appendRow(['Ana López', 32, 'ana@example.com']);
    sheet.appendRow(['Carlos Ruiz', 24, 'carlos@example.com']);

    final fileBytes = excel.save();
    return Uint8List.fromList(fileBytes!); // Retorna como Uint8List
  }
}
