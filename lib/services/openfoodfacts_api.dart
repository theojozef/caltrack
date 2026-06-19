import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/aliment.dart';

class OpenFoodFactsAPI {
  static Future<List<Aliment>> searchAliments(String query) async {
    try {
      // Étape 1 : recherche Elasticsearch (bonne pertinence, trouve Oreo/Prince etc.)
      final searchUri = Uri.parse('https://search.openfoodfacts.org/search').replace(
        queryParameters: {
          'q': query,
          'fields': 'product_name,nutriments,code,completeness',
          'page_size': '50',
          'page': '1',
        },
      );

      final searchResponse = await http.get(searchUri).timeout(const Duration(seconds: 15));
      if (searchResponse.statusCode != 200) {
        debugPrint('[OFF] recherche statut: ${searchResponse.statusCode}');
        return [];
      }

      final searchData = jsonDecode(searchResponse.body) as Map<String, dynamic>;
      final hits = (searchData['hits'] as List<dynamic>?) ?? [];
      if (hits.isEmpty) return [];

      hits.sort((a, b) {
        final ca = (a as Map<String, dynamic>)['completeness'] as num? ?? 0;
        final cb = (b as Map<String, dynamic>)['completeness'] as num? ?? 0;
        return cb.compareTo(ca);
      });

      // Étape 2 : récupérer les portions via les codes barres (un seul appel)
      final codes = hits
          .map((h) => (h as Map<String, dynamic>)['code'] as String?)
          .where((c) => c != null && c.isNotEmpty)
          .cast<String>()
          .toList();

      final Map<String, Map<String, dynamic>> servingMap = {};
      if (codes.isNotEmpty) {
        try {
          final portionsUri = Uri.parse('https://world.openfoodfacts.org/api/v2/search').replace(
            queryParameters: {
              'code': codes.join(','),
              'fields': 'code,serving_size,serving_quantity',
              'page_size': '30',
              'json': '1',
            },
          );
          final portionsResponse = await http.get(portionsUri).timeout(const Duration(seconds: 10));
          if (portionsResponse.statusCode == 200) {
            final portionsData = jsonDecode(portionsResponse.body) as Map<String, dynamic>;
            final products = (portionsData['products'] as List<dynamic>?) ?? [];
            for (final p in products) {
              final map = p as Map<String, dynamic>;
              final code = map['code'] as String?;
              if (code != null) servingMap[code] = map;
            }
          }
        } catch (e) {
          debugPrint('[OFF] portions erreur: $e');
        }
      }

      // Étape 3 : fusionner et parser
      return hits.map<Aliment?>((h) {
        final map = Map<String, dynamic>.from(h as Map<String, dynamic>);
        final code = map['code'] as String?;
        if (code != null && servingMap.containsKey(code)) {
          map['serving_size'] = servingMap[code]!['serving_size'];
          map['serving_quantity'] = servingMap[code]!['serving_quantity'];
        }
        return _parseProduct(map);
      }).whereType<Aliment>().toList();
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
      final servingSizeStr = (p['serving_size'] as String?)?.trim() ?? '';
      final weightRegex = RegExp(
        r'(\d+(?:[.,]\d+)?)\s*(g|grammes|ml|millilitres?|oz|ounces?)',
        caseSensitive: false,
      );

      if (servingQty != null && servingQty > 0) {
        String nomPortion = servingSizeStr.isNotEmpty
            ? servingSizeStr
                .replaceAll(weightRegex, '')
                .replaceAll(RegExp(r'^[,\(\)\s]+|[,\(\)\s]+$'), '')
                .trim()
            : '';
        portions.add(Portion(nom: nomPortion, poids: servingQty));
      } else if (servingSizeStr.isNotEmpty) {
        final match = weightRegex.firstMatch(servingSizeStr);
        if (match != null) {
          final poids = double.tryParse(match.group(1)!.replaceAll(',', '.'));
          if (poids != null && poids > 0) {
            String nomPortion = servingSizeStr
                .replaceFirst(match.group(0)!, '')
                .replaceAll(RegExp(r'^[,\(\)\s]+|[,\(\)\s]+$'), '')
                .trim();
            portions.add(Portion(nom: nomPortion, poids: poids));
          }
        }
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
        completeness: _toDouble(p['completeness']) ?? 0.0,
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
