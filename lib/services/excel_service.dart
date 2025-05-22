import 'package:flutter/services.dart';
import 'package:excel/excel.dart';

class ExcelService {
  Future<Map<String, Map<String, double>>> liremacros() async {
    final data = await rootBundle.load('assets/calcul_calories.xlsx');
    final bytes = data.buffer.asUint8List();
    final excel = Excel.decodeBytes(bytes);

    final sheet = excel['macros'];
    Map<String, Map<String, double>> macros = {};

     // On suppose que chaque ligne contient : nutriment | min | max
    for (var row in sheet.rows.skip(1)) {
      final nom = row[0]?.value?.toString().trim().toLowerCase();
      final min = _toDouble(row[1]?.value);
      final max = _toDouble(row[2]?.value);

      if (nom != null && ['calories', 'protéines', 'lipides', 'glucides'].contains(nom)) {
        macros[nom] = {
          'min': min,
          'max': max,
        };
      }
    }

    return macros;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    return 0.0;
  }
}