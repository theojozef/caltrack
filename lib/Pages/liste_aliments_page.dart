import 'package:cal_track_v1/Pages/scancode_page.dart';
import 'package:cal_track_v1/services/basededonnees.dart';
import 'package:cal_track_v1/widgets/aliment.dart';
import 'package:flutter/material.dart';
import 'package:cal_track_v1/widgets/quantite_aliment.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ListeAlimentsPage extends StatefulWidget {
  // final Function(Aliment) onAlimentAjoute;
  final Function(Aliment, double) onAlimentAjoute;


  const ListeAlimentsPage({super.key, required this.onAlimentAjoute});

  @override
  State<ListeAlimentsPage> createState() => _ListeAlimentsPageState();
}

class _ListeAlimentsPageState extends State<ListeAlimentsPage> {
  List<Aliment> _aliments = [];
  List<Aliment> _alimentsFiltres = [];
  String _recherche = "";

  @override
  void initState() {
    super.initState();
    chargerAlimentsDepuisCSV().then((liste) {
      setState(() {
        _aliments = liste;
        _alimentsFiltres = liste;
      });
    });
  }
  
  void _filtrer(String recherche) {
    setState(() {
      _recherche = recherche.toLowerCase();
      _alimentsFiltres = _aliments.where((a) => a.nom.toLowerCase().contains(_recherche)).toList();
    });
  }

  void _ajouterAliment(BuildContext context, Aliment aliment) async {
  final navigator = Navigator.of(context); // capture du Navigator AVANT le await
  final Map<String, double>? result = await Navigator.push(    
    context,
    MaterialPageRoute(
    builder: (context) => QuantiteAliment(
      aliment: aliment,
      ),
    ),
   );
   
   if (result == null || !mounted) return;
    //final macros = aliment.getMacrosPourQuantite(result); // Utilisation de la méthode qui calcule les macros
    final quantite = result['quantite']!; 
    /*final alimentModifie = Aliment(
      nom: aliment.nom,
      calories: result['calories']!,
      proteines: result['proteines']!,
      lipides: result['lipides']!,
      glucides: result['glucides']!,
    );*/
    
    widget.onAlimentAjoute(aliment, quantite);
    
    // On utilise navigator.pop() plutôt que Navigator.pop(context)
    navigator.pop(); // Ferme la page ListeAlimentsPage
    

  
  }
  
static const double heightsearch = 50;

  // BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un aliment')),      
      backgroundColor: const Color(0xFF393939), // couleur de fond claire
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            
            
            child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: heightsearch,
              child: TextField(
              cursorColor: Color(0xFF357E50),
              decoration: InputDecoration(
                labelText: 'Rechercher un aliment',
                labelStyle: const TextStyle(
                      color: Color(0x4CFFFFFF)), // Couleur du label quand le champ est **inactif**
                    floatingLabelStyle: const TextStyle(
                      color: Colors.white, // Couleur du label quand le champ est **focus**
                    ),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                
                //contentPadding: EdgeInsets.symmetric(vertical: 8),
                                
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.grey, width: 2), // couleur personnalisée
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.grey),
                        ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.grey, width: 2),
                ),
              
              ),
              style: const TextStyle(color: Colors.white), // texte en blanc
              onChanged: _filtrer,
              ),
                ),
            ),

            const SizedBox(width: 8),

            // icône SCAN CODE         
            IconButton(
              icon: SvgPicture.asset('images/icon_scan_2.svg',
              //width: 30,
              height: heightsearch,
              fit: BoxFit.contain,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ScanPage())
                  );
              }
              ),
            
            
            ]
            ),
             
        
          ),
          Expanded(
            child: _alimentsFiltres.isEmpty
                ? const Center(child: Text("Aucun aliment trouvé"))
                : ListView.builder(
                  physics: BouncingScrollPhysics(),
                    itemCount: _alimentsFiltres.length,
                    itemBuilder: (context, index) {
                      final aliment = _alimentsFiltres[index];

return Card(
  color: Colors.grey[900],
  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // BOUTON +
        IconButton(
          iconSize: 34, // ↔️ Modifie ici la taille du bouton
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: () => _ajouterAliment(context, aliment),
        ),
        const SizedBox(width: 12),

        // INFOS ALIMENT
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                aliment.nom,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${aliment.calories.toStringAsFixed(0)} kcal - '
                'P: ${aliment.proteines} | '
                'L: ${aliment.lipides} | '
                'G: ${aliment.glucides}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
);

                    },
                  ),
          ),
 
                  ],
  
      ),
    );
}
}