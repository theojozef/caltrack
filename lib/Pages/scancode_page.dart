import 'package:cal_track_v1/widgets/aliment.dart';
import 'package:cal_track_v1/widgets/quantite_aliment.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';



class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool _isProcessing = false;
  final Map<String, Aliment> baseProduits = {
    '3017620422003': Aliment( // Ex: Nutella
      nom: 'Nutella',
      calories: 530,
      proteines: 6,
      lipides: 31,
      glucides: 57,
    ),
    '1234567890123': Aliment(
      nom: 'Pâtes complètes',
      calories: 350,
      proteines: 12,
      lipides: 2,
      glucides: 70,
    ),
  };

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final code = capture.barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _isProcessing = true);

    if (baseProduits.containsKey(code)) {
      final aliment = baseProduits[code]!;

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuantiteAliment(aliment: aliment),
        ),
      );

      if (mounted && result != null) {
        Navigator.pop(context, {
          'aliment': aliment,
          'quantite': result['quantite'],
        });
      }
    } else {
      // Produit non trouvé
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Produit inconnu"),
          content: Text("Le code-barres $code n'est pas dans la base."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => _isProcessing = false);
              },
              child: const Text("OK"),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner un produit'),
        backgroundColor: const Color(0xFF393939),
      ),
      backgroundColor: const Color(0xFF393939),
      body: MobileScanner(        
        onDetect: _onDetect,
      ),
    );
  }
}
