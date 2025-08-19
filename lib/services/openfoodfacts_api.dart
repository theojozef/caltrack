import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/aliment.dart';

class OpenFoodFactsAPI {
  static const String _baseUrl = 'https://world.openfoodfacts.org/cgi/search.pl';

  // Helper robuste pour convertir dynamic -> double
  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) {
      final cleaned = v.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9\.\-]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  // Récupère l'énergie en kcal depuis le map 'nutriments', avec fallback / conversion kJ -> kcal
  static double _getEnergyKcalFromNutriments(Map<String, dynamic>? nutriments) {
    if (nutriments == null) return 0.0;
    // clés probables (ordre d'essai)
    final keys = ['energy-kcal_100g', 'energy-kcal', 'energy_100g'];
    for (final key in keys) {
      if (nutriments.containsKey(key) && nutriments[key] != null) {
        final val = _toDouble(nutriments[key]);
        if (key == 'energy_100g') {
          // très probablement en kJ : conversion kJ -> kcal (1 kcal = 4.184 kJ)
          if (val > 0) return val / 4.184;
        }
        return val;
      }
    }
    return 0.0;
  }

  static Future<List<Aliment>> searchAliments(String query) async {
    final uri = Uri.parse('$_baseUrl?search_terms=$query&search_simple=1&action=process&json=1');
    final response = await http.get(uri);

    if (response.statusCode != 200) throw Exception("Erreur API OFF: ${response.statusCode}");

    final data = jsonDecode(response.body);
    final List produits = data['products'] ?? [];

    return produits.map<Aliment?>((item) {
      final nutriments = (item['nutriments'] as Map?)?.cast<String, dynamic>();

      if (nutriments == null) return null;

      try {
        final jsonData = {
          // correspond aux clés attendues par Aliment.fromJson
          'nom': item['product_name'] ?? item['product_name_fr'] ?? item['product_name_en'] ?? 'Sans nom',
          'calories': _getEnergyKcalFromNutriments(nutriments),
          'proteines': _toDouble(nutriments['proteins_100g']),
          'lipides': _toDouble(nutriments['fat_100g']),
          'glucides': _toDouble(nutriments['carbohydrates_100g']),
          // transmettre les informations de portion (string et quantité numérique si dispo)
          'serving_size': item['serving_size'],
          'serving_quantity': item['serving_quantity'] != null ? _toDouble(item['serving_quantity']) : null,
        };

        return Aliment.fromJson(jsonData);
      } catch (e) {        
        return null;
      }
    }).whereType<Aliment>().toList();
  }
}
