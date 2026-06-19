import 'dart:convert';
import 'package:cal_track_v1/models/aliment.dart';
import 'package:cal_track_v1/widgets/quantite_aliment.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool _isProcessing = false;

  Future<Aliment?> _fetchFromOpenFoodFacts(String code) async {
    try {
      final uri = Uri.parse(
        'https://world.openfoodfacts.org/api/v2/product/$code.json',
      ).replace(queryParameters: {
        'fields': 'product_name,nutriments,serving_size,serving_quantity,completeness',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 1) return null;
      final product = data['product'] as Map<String, dynamic>?;
      if (product == null) return null;
      return _parseProduct(product);
    } catch (_) {
      return null;
    }
  }

  Aliment? _parseProduct(Map<String, dynamic> p) {
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
            final nomPortion = servingSizeStr
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

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;

    setState(() => _isProcessing = true);

    final aliment = await _fetchFromOpenFoodFacts(code);

    if (!mounted) return;

    if (aliment != null) {
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(builder: (_) => QuantiteAliment(aliment: aliment)),
      );

      if (mounted && result != null) {
        Navigator.pop(context, {
          'aliment': aliment,
          'quantite': result['quantite'],
          'portionChoisie': result['portionChoisie'],
        });
      } else {
        // Retour sans validation → autoriser un nouveau scan
        if (mounted) setState(() => _isProcessing = false);
      }
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF393939),
          title: const Text('Produit non trouvé', style: TextStyle(color: Colors.white)),
          content: Text(
            'Aucune donnée nutritionnelle disponible pour ce produit (code : $code).',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (mounted) setState(() => _isProcessing = false);
              },
              child: const Text('OK', style: TextStyle(color: Color(0xFF357E50))),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF393939),
      appBar: AppBar(
        backgroundColor: const Color(0xFF393939),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Scanner un produit', style: TextStyle(color: Colors.white)),
      ),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF357E50)),
            ),
        ],
      ),
    );
  }
}
