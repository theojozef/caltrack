import 'dart:async';

import 'package:cal_track_v1/Pages/scancode_page.dart';
import 'package:cal_track_v1/services/basededonnees.dart';
import 'package:cal_track_v1/models/aliment.dart';
import 'package:flutter/material.dart';
import 'package:cal_track_v1/widgets/quantite_aliment.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cal_track_v1/services/openfoodfacts_api.dart';


class ListeAlimentsPage extends StatefulWidget {
  // final Function(Aliment) onAlimentAjoute;
  final Function(Aliment, double, Portion) onAlimentAjoute;


  const ListeAlimentsPage({super.key, required this.onAlimentAjoute});

  @override
  State<ListeAlimentsPage> createState() => _ListeAlimentsPageState();
}

class _ListeAlimentsPageState extends State<ListeAlimentsPage> {
  List<Aliment> _aliments = [];
  List<Aliment> _alimentsFiltres = [];
  String _recherche = "";
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    chargerAlimentsDepuisCSV().then((liste) {
      setState(() {
        _aliments = liste;
        _alimentsFiltres = liste;
        // _alimentsFiltres = liste.where((a) => a.dejaAjoute).toList();

      });
    });
  }

  Timer? _debounce;
  
  void _filtrer(String recherche) async {
    // Annule le debounce précédent si l'utilisateur continue à taper
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Démarre un nouveau délai
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      // Mise à jour de la recherche courante
      setState(() {
        _recherche = recherche.toLowerCase();
        _isSearching = true;
      });
    
      // Si champ vide → reset    
      if (_recherche.isEmpty) {
        setState(() {
          // Revenir à la liste par défaut quand champ vide
          _alimentsFiltres = _aliments.where((aliment) => aliment.dejaAjoute).toList();
          _isSearching = false;
        });
        return;
      }
    
    // Capture la valeur de recherche au moment de l’appel
    final rechercheEnCours = _recherche;

    // Appel API
    final resultats = await OpenFoodFactsAPI.searchAliments(_recherche);
      
    // ⚡ Vérifie que la recherche n’a pas changé entre temps
    if (rechercheEnCours != _recherche) {
    return; // on ignore ce résultat car il est "périmé"
    }

  // Supprimer les aliments sans nom (nom vide ou uniquement des espaces)
  final String rechercheTrimmed = _recherche.trim().toLowerCase(); //_recherche.trim().toLowerCase();

  final filtresAvecNom = resultats.where((aliment) {
    final nom = aliment.nom.toLowerCase().trim(); //
    final contientNom = nom.contains(rechercheTrimmed);
    // final commenceParNom = nom.startsWith(rechercheTrimmed);
    final aEnergie = aliment.calories > 0;
    return contientNom && aEnergie;    
  }).toList();

  

filtresAvecNom.sort((a, b) {

  final nomA = a.nom.toLowerCase().trim();
  final nomB = b.nom.toLowerCase().trim();

  // 3️⃣ Priorité : correspondance exacte
  final aExact = nomA == rechercheTrimmed;
  final bExact = nomB == rechercheTrimmed;
  if (aExact && !bExact) return -1;
  if (!aExact && bExact) return 1;

  // 1️⃣ Priorité : commence par la recherche
  final commenceA = nomA.startsWith(rechercheTrimmed) ;
  final commenceB = nomB.startsWith(rechercheTrimmed) ;
  if (commenceA && !commenceB) return -1; // a avant b
  if (!commenceA && commenceB) return 1;  // b avant a

  // 2️⃣ Priorité : aliments déjà ajoutés
  if (a.dejaAjoute && !b.dejaAjoute) return -1;
  if (!a.dejaAjoute && b.dejaAjoute) return 1;



  // 4️⃣ Priorité : aliments avec portions et au moins un nom de portion
  final aHasPortionNom = a.portions.any((p) => p.nom.isNotEmpty);
  final bHasPortionNom = b.portions.any((p) => p.nom.isNotEmpty);
  if (aHasPortionNom && !bHasPortionNom) return -1;
  if (!aHasPortionNom && bHasPortionNom) return 1;

  // 5️⃣ Priorité : protéines décroissantes
  if (a.proteines != b.proteines) {
    return b.proteines.compareTo(a.proteines);
  }
  
  // 6️⃣ Tri alphabétique final
  return a.nom.compareTo(b.nom);  
});

// Déduplication
final Set<String> seen = {};
final List<Aliment> uniques = [];

for (final aliment in filtresAvecNom) {
  final key = '${aliment.nom.toLowerCase().trim()}|'
              '${aliment.calories.toStringAsFixed(1)}|'
              '${aliment.proteines.toStringAsFixed(1)}|'
              '${aliment.lipides.toStringAsFixed(1)}|'
              '${aliment.glucides.toStringAsFixed(1)}';

  if (!seen.contains(key)) {
    seen.add(key);
    uniques.add(aliment);
  }
}

setState(() {
  _alimentsFiltres = uniques;
  _isSearching = false;
});
}
);
}

  void _ajouterAliment(BuildContext context, Aliment aliment) async {
  final navigator = Navigator.of(context); // capture du Navigator AVANT le await
  
  final Map<String, dynamic>? result = await Navigator.push(    
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
    
    final Portion portionChoisie = result['portionChoisie'] as Portion;
    
    // ✅ Marquer comme déjà consommé
    setState(() {
    aliment.dejaAjoute = true;
    });
    
    
    widget.onAlimentAjoute(aliment, quantite, portionChoisie);
    
    // On utilise navigator.pop() plutôt que Navigator.pop(context)
    navigator.pop(); // Ferme la page ListeAlimentsPage  
  }
  
static const double heightsearch = 35;


  // BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(     
      backgroundColor: const Color(0xFF393939), // couleur de fond claire
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),            
            
            child: Row(
            children: [

              IconButton(
              icon: const Icon(Icons.chevron_left, 
              color: Colors.white,
              size: 30),
              onPressed: () {
                Navigator.pop(context);
              },
            ),              
              
              Expanded(
                child: SizedBox(
                  height: heightsearch,
              child: TextField(
                textAlignVertical: TextAlignVertical.center,
              cursorColor: Color(0xFF357E50),
              decoration: InputDecoration(  
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),              
                labelText: 'Rechercher un aliment',                
                labelStyle: const TextStyle(
                      color: Color(0x4CFFFFFF)), // Couleur du label quand le champ est **inactif**
                    floatingLabelStyle: const TextStyle(
                      color: Colors.white, // Couleur du label quand le champ est **focus**
                    ),
                prefixIcon: const Icon(Icons.search, color: Color(0x33D9D9D9)),
                
                
                //contentPadding: EdgeInsets.symmetric(vertical: 8),
                                
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(heightsearch),
                      borderSide: const BorderSide(color: Color(0x33D9D9D9), width: 2), // couleur personnalisée
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(heightsearch),
                        borderSide: const BorderSide(color: Color(0x33D9D9D9)),
                        ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0x33D9D9D9), width: 2),
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
              icon: SvgPicture.asset('images/icon_scan_6.svg',
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
            child: _isSearching
            ? const Center(child: CircularProgressIndicator(color: Color(0x3A0BE754)))
            : _alimentsFiltres.isEmpty
                ? const Center(child: Text("Aucun aliment trouvé"))
                : ListView.builder(
                  physics: BouncingScrollPhysics(),
                    itemCount: _alimentsFiltres.length,
                    itemBuilder: (context, index) {
                      final aliment = _alimentsFiltres[index];

return InkWell(
  onTap: () => _ajouterAliment(context, aliment),
  borderRadius: BorderRadius.circular(12),
  child: Card(
    color: Colors.grey[800], //900
    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.add,
            size: 34,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              
              children: [
                //NOM DE L'ALIMENT
                Text(
                  aliment.nom,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),    

                // PORTION
                if (aliment.portions.isNotEmpty)
                  Text(() {
                    final nomPortion = aliment.portions.first.nom.trim();
                    if (nomPortion.isEmpty) {
                      return 'Portion (${aliment.portions.first.poids} g)';
                      } else {
                        return '$nomPortion (${aliment.portions.first.poids} g)';
                        }
                   }(),
                   style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                
                const SizedBox(height: 4),
                
                Text(
                  '${aliment.calories.toStringAsFixed(0)} kcal - '
                  'P: ${aliment.proteines.toStringAsFixed(1)} | '
                  'L: ${aliment.lipides.toStringAsFixed(1)} | '
                  'G: ${aliment.glucides.toStringAsFixed(1)}'
                  // ' | F: ${aliment.fibres}'
                  // '${aliment.portions.isNotEmpty ? ' (Portion: ${aliment.portions.first.poids} g)' : ''}',
                  ,
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