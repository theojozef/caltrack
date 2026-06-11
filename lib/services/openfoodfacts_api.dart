import 'package:flutter/foundation.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import '../models/aliment.dart';

class OpenFoodFactsAPI {
  static bool _configured = false;

  static void _configure() {
    if (_configured) return;
    _configured = true;
    OpenFoodAPIConfiguration.userAgent = UserAgent(
      name: 'flexfood.ctv2',
      version: '1.0.0',
    );
  }

  static Future<List<Aliment>> searchAliments(String query) async {
    _configure();
    try {
      final SearchResult result = await OpenFoodAPIClient.searchProducts(
        const User(userId: '', password: ''),
        ProductSearchQueryConfiguration(
          parametersList: <Parameter>[
            SearchTerms(terms: [query]),
            PageSize(size: 30),
            PageNumber(page: 1),
          ],
          language: OpenFoodFactsLanguage.FRENCH,
          country: OpenFoodFactsCountry.FRANCE,
          fields: [
            ProductField.NAME,
            ProductField.NAME_IN_LANGUAGES,
            ProductField.NUTRIMENTS,
            ProductField.SERVING_SIZE,
            ProductField.SERVING_QUANTITY,
          ],
          version: ProductQueryVersion.v3,
        ),
      );

      if (result.products == null) return [];

      return result.products!.map<Aliment?>((product) {
        try {
          final nutriments = product.nutriments;
          if (nutriments == null) return null;

          double calories =
              nutriments.getValue(Nutrient.energyKCal, PerSize.oneHundredGrams) ?? 0.0;
          if (calories <= 0) {
            final kj = nutriments.getValue(Nutrient.energyKJ, PerSize.oneHundredGrams) ?? 0.0;
            if (kj > 0) calories = kj / 4.184;
          }
          if (calories <= 0) return null;

          final nom = product.getBestProductName(OpenFoodFactsLanguage.FRENCH);
          if (nom.isEmpty) return null;

          final portions = <Portion>[];
          final qty = product.servingQuantity;
          if (qty != null && qty > 0) {
            portions.add(Portion(nom: product.servingSize ?? '', poids: qty));
          }

          return Aliment(
            nom: nom,
            calories: calories,
            proteines: nutriments.getValue(Nutrient.proteins, PerSize.oneHundredGrams) ?? 0.0,
            lipides: nutriments.getValue(Nutrient.fat, PerSize.oneHundredGrams) ?? 0.0,
            glucides: nutriments.getValue(Nutrient.carbohydrates, PerSize.oneHundredGrams) ?? 0.0,
            fibres: nutriments.getValue(Nutrient.fiber, PerSize.oneHundredGrams) ?? 0.0,
            sucresLibres: 0.0,
            portions: portions,
          );
        } catch (_) {
          return null;
        }
      }).whereType<Aliment>().toList();
    } catch (e) {
      debugPrint('[OFF] searchAliments erreur: $e');
      return [];
    }
  }
}
