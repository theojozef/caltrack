import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DonneesPage extends StatefulWidget {
  const DonneesPage({super.key});

  @override
  State<DonneesPage> createState() => _DonneesPageState();
}

class _DonneesPageState extends State<DonneesPage> {
  final Map<String, TextEditingController> _controllers = {
    'Nom': TextEditingController(),
    'Sexe': TextEditingController(),
    'Date de naissance': TextEditingController(),
    'Niveau d activité': TextEditingController(),
    'Taille': TextEditingController(),
    'Poids': TextEditingController(),
    'Objectif': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    final prefs = await SharedPreferences.getInstance();
    _controllers.forEach((key, controller) {
      controller.text = prefs.getString(key) ?? '';
    });
    setState(() {}); // Force le rebuild si jamais c'est modifié après init
  }

  Future<void> _sauvegarderDonnees() async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in _controllers.entries) {
      await prefs.setString(entry.key, entry.value.text);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Données sauvegardées")),        
    );
  }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    } 
    super.dispose();
  }  
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Données personnelles'),
        backgroundColor: const Color(0xFF676464),
        /*actions: [
          Padding(
          padding : const EdgeInsets.only(right: 16.0),
          child: IconButton(
            icon: const Icon(Icons.save),
            onPressed: _sauvegarderDonnees,
            tooltip: 'Sauvegarder',
          )
          )
        ],*/
      ),
      backgroundColor: const Color(0xFF393939),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              ..._controllers.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: DonneeInput(
                  label: entry.key,
                  controller: entry.value,
                ),
              );
            }),

            // Bouton de mise à jour des données
            const SizedBox(height: 50),
            Center(
              child: ElevatedButton(
                onPressed: _sauvegarderDonnees,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0x3A0BE754),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))
                ),
                child: const Text(
                'Mettre à jour les données',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
              
            ),
            ],
          ),
        ),
      ),
    );
  }
}


class DonneeInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const DonneeInput({
    super.key, 
    required this.label,
    required this.controller,
    });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller, 
      keyboardType: (label == 'Taille' || label == 'Poids')
      ? TextInputType.number
      : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
        ),
      ),
    );
  }
}
