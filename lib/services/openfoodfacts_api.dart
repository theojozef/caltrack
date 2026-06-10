import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/aliment.dart';

class OpenFoodFactsAPI {
  // static const String _baseUrl = 'https://world.openfoodfacts.org/cgi/search.pl'; // v1 - pas de CORS, 503 fréquent

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

  // Récupère les fibres depuis le map 'nutriments' (clé variable selon les produits)
  static double _getFiberFromNutriments(Map<String, dynamic>? nutriments) {
    if (nutriments == null) return 0.0;
    // Essaie les clés dans l'ordre, prend la première valeur > 0
    final keys = ['fiber_100g', 'fiber-100g', 'fiber', 'fibers_100g', 'dietary-fiber_100g'];
    for (final key in keys) {
      if (nutriments.containsKey(key) && nutriments[key] != null) {
        final val = _toDouble(nutriments[key]);
        if (val > 0) return val;
      }
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

  // Tente un GET et retourne null si erreur ou statut != 200
  static Future<http.Response?> _tryGet(Uri uri) async {
    try {
      final r = await http.get(uri).timeout(const Duration(seconds: 8));
      return r.statusCode == 200 ? r : null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Aliment>> searchAliments(String query) async {
    final directUri = Uri(
      scheme: 'https',
      host: 'world.openfoodfacts.org',
      path: '/api/v2/search',
      queryParameters: {
        'q': query,
        'fields': 'product_name,product_name_fr,product_name_en,nutriments,serving_size,serving_quantity',
        'page_size': '30',
      },
    );

    // 1. Accès direct — l'API v2 expose CORS nativement, fonctionne en mobile
    //    et souvent en web sans proxy
    http.Response? response = await _tryGet(directUri);

    // 2. Sur le web, si l'accès direct échoue (CORS bloqué), essayer des proxies
    //    dans l'ordre ; on s'arrête au premier qui répond 200
    if (response == null && kIsWeb) {
      final encoded = Uri.encodeComponent(directUri.toString());
      final proxies = [
        'https://api.allorigins.win/raw?url=$encoded',
        'https://corsproxy.io/?$encoded',
      ];
      for (final proxyUrl in proxies) {
        response = await _tryGet(Uri.parse(proxyUrl));
        if (response != null) break;
      }
    }

    if (response == null) return [];

    final data = jsonDecode(response.body);
    final List produits = data['products'] ?? [];


    return produits.map<Aliment?>((item) {
      final nutriments = (item['nutriments'] as Map?)?.cast<String, dynamic>();

      if (nutriments == null) return null;

      try {
        final jsonData = {
          // correspond aux clés attendues par Aliment.fromJson
          'nom': item['product_name_fr'] ?? item['product_name'] ?? item['product_name_en'] ?? 'Sans nom',
          'calories': _getEnergyKcalFromNutriments(nutriments),
          'proteines': _toDouble(nutriments['proteins_100g']),
          'lipides': _toDouble(nutriments['fat_100g']),
          'glucides': _toDouble(nutriments['carbohydrates_100g']),
          'fibres': _getFiberFromNutriments(nutriments),
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
