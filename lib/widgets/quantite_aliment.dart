import 'package:flutter/material.dart';
import 'aliment.dart';

class QuantiteAliment extends StatefulWidget {
  //final String nom;
  //final double calories;
  //final double proteines;
  //final double lipides;
  //final double glucides;
  final Aliment aliment;

  const QuantiteAliment({
    super.key,
    //required this.nom,
    //required this.calories,
    //required this.proteines,
    //required this.lipides,
    //required this.glucides,
    required this.aliment,
  }); 

  @override
  State<QuantiteAliment> createState() => _QuantiteAlimentState();
}

class _QuantiteAlimentState extends State<QuantiteAliment> {
  late TextEditingController quantiteController;
  double? calories;
  double? proteines;
  double? lipides;
  double? glucides;


  @override
  void initState() {
    super.initState();
    quantiteController = TextEditingController(text: '100');
    _recalculerMacros(100);
  }

  void _recalculerMacros(double quantite) {
    setState(() {
      calories = (widget.aliment.calories * quantite) / 100;
      proteines = (widget.aliment.proteines * quantite) / 100;
      lipides = (widget.aliment.lipides * quantite) / 100;
      glucides = (widget.aliment.glucides * quantite) / 100;
    });
  }

  void _validerModifications() {
    Navigator.pop(context, {
      'quantite': double.tryParse(quantiteController.text) ?? 100, // Ajout de la quantité
      //'calories': calories ?? 0,
      //'proteines': proteines ?? 0,
      //'lipides': lipides ?? 0,
      //'glucides': glucides ?? 0,
    });
  }

  @override
  void dispose() {
    quantiteController.dispose();    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modifier ${widget.aliment.nom}'),      
        backgroundColor: const Color(0xFF393939),
      ),
      backgroundColor: const Color(0xFF393939),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildQuantiteInput("Quantité (g)", quantiteController),
            const SizedBox(height: 24),
            _buildResult("Calories", calories),
            _buildResult("Protéines (g)", proteines),
            _buildResult("Lipides (g)", lipides),
            _buildResult("Glucides (g)", glucides),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _validerModifications,
              child: const Text("Ajouter à la journée"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantiteInput(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white),
      onChanged: (value) {
        final double? quantite = double.tryParse(value);
        if (quantite != null) {
          _recalculerMacros(quantite);
        }
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white70),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildResult(String label, double? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        "$label : ${value?.toStringAsFixed(1) ?? '0'}",
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}