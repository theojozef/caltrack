import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/aliment.dart';

class OpenFoodFactsAPI {
  static const String _baseUrl =
      'https://world.openfoodfacts.org/api/v2/search';

  static Future<List<Aliment>> searchAliments(String query) async {
    try {
      // Uri.replace(query:) preserve les virgules non encodées dans fields
      final uri = Uri.parse(_baseUrl).replace(
        query: 'search_terms=${Uri.encodeQueryComponent(query)}'
            '&fields=product_name,nutriments,serving_size,serving_quantity'
            '&json=1&page_size=30&lc=fr&cc=fr&page=1',
      );

      final response = await http.get(uri, headers: {
        'User-Agent': 'flexfood.ctv2/1.0.0 (martin.to@orange.fr)',
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint('[OFF] statut: ${response.statusCode}');
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final products = data['products'] as List<dynamic>?;
      if (products == null || products.isEmpty) return [];

      return products
          .map<Aliment?>((p) => _parseProduct(p as Map<String, dynamic>))
          .whereType<Aliment>()
          .toList();
    } catch (e) {
      debugPrint('[OFF] searchAliments erreur: $e');
      return [];
    }
  }

  static Aliment? _parseProduct(Map<String, dynamic> p) {
    try {
      final nutriments = p['nutriments'] as Map<String, dynamic>?;
      if (nutriments == null) return null;

      double calories = _toDouble(nutriments['energy-kcal_100g']) ?? 0.0;
      if (calories <= 0) {
        final kj = _toDouble(nutriments['energy-kj_100g']) ?? 0.0;
        if (kj > 0) calories = kj / 4.184;
      }
      if (calories <= 0) return null;

      final nom = ((p['product_name'] as String?) ?? '').trim();
      if (nom.isEmpty) return null;

      final portions = <Portion>[];
      final servingQty = _toDouble(p['serving_quantity']);
      if (servingQty != null && servingQty > 0) {
        portions
            .add(Portion(nom: (p['serving_size'] as String?) ?? '', poids: servingQty));
      }

      return Aliment(
        nom: nom,
        calories: calories,
        proteines: _toDouble(nutriments['proteins_100g']) ?? 0.0,
        lipides: _toDouble(nutriments['fat_100g']) ?? 0.0,
        glucides: _toDouble(nutriments['carbohydrates_100g']) ?? 0.0,
        fibres: _toDouble(nutriments['fiber_100g']) ?? 0.0,
        sucresLibres: 0.0,
        portions: portions,
      );
    } catch (_) {
      return null;
    }
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
