import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:cal_track_v1/widgets/aliment.dart';

Future<List<Aliment>> chargerAlimentsDepuisCSV() async {
  final data = await rootBundle.loadString('data/ciqual4.csv');
  final csvTable = const CsvToListConverter(fieldDelimiter: ';', eol: '\n').convert(data);

  // On récupère les entêtes pour trouver les bonnes colonnes
  final headers = csvTable.first;
  final int nomIndex = headers.indexOf('alim_nom_fr');
  final int kcalIndex = headers.indexWhere((e) => e.toString().contains('Energie'));
  final int protIndex = headers.indexWhere((e) => e.toString().contains('Protéines'));
  final int glucIndex = headers.indexWhere((e) => e.toString().contains('Glucides'));
  final int lipIndex = headers.indexWhere((e) => e.toString().contains('Lipides'));

  // On transforme chaque ligne en objet Aliment
  return csvTable.skip(1).map((row) {
    try {
      return Aliment(
        nom: row[nomIndex].toString(),
        calories: double.tryParse(row[kcalIndex].toString().replaceAll(',', '.')) ?? 0,
        proteines: double.tryParse(row[protIndex].toString().replaceAll(',', '.')) ?? 0,
        glucides: double.tryParse(row[glucIndex].toString().replaceAll(',', '.')) ?? 0,
        lipides: double.tryParse(row[lipIndex].toString().replaceAll(',', '.')) ?? 0,
      );
    } catch (e) {
      return null;
    }
  }).whereType<Aliment>().toList();
}
