import 'dart:async';

import 'package:cal_track_v1/Pages/scancode_page.dart';
import 'package:cal_track_v1/services/basededonnees.dart';
import 'package:cal_track_v1/models/aliment.dart';
import 'package:cal_track_v1/services/local_storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cal_track_v1/widgets/quantite_aliment.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cal_track_v1/services/openfoodfacts_api.dart';


class ListeAlimentsPage extends StatefulWidget {
  // final Function(Aliment) onAlimentAjoute;
  final Function(Aliment, double, Portion, Repas?) onAlimentAjoute;
  final Repas? repasPreselectionne; // repas déjà connu (depuis le bouton + de la section)

  const ListeAlimentsPage({super.key, required this.onAlimentAjoute, this.repasPreselectionne});

  @override
  State<ListeAlimentsPage> createState() => _ListeAlimentsPageState();
}

class _ListeAlimentsPageState extends State<ListeAlimentsPage> {
  List<Aliment> _aliments = [];
  List<Aliment> _alimentsFiltres = [];
  List<Aliment> _recents = [];
  String _recherche = "";
  bool _isSearching = false;
  Set<String> _favoris = {};

  @override
  void initState() {
    super.initState();
    _chargerAliments();
  }

  Future<void> _chargerAliments() async {
    // Charger les favoris persistants avant la liste CSV
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _favoris = await LocalStorageService.loadFavoris(userId);
      _recents = await LocalStorageService.loadRecents(userId);
    }

    final liste = await chargerAlimentsDepuisCSV();
    // Marquer les aliments déjà ajoutés par le passé
    for (final a in liste) {
      if (_favoris.contains(a.nom)) a.dejaAjoute = true;
    }

    if (!mounted) return;
    setState(() {
      _aliments = liste;
      _alimentsFiltres = _recents; // liste vide au départ → affiche les récents
    });
  }

  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // Retourne true si le nom contient tous les mots du query (peu importe l'ordre)
  bool _nomContientTousLesMots(String nom, List<String> mots) {
    return mots.every((mot) => nom.contains(mot));
  }

  // Clé de déduplication basée sur les valeurs nutritionnelles
  String _cle(Aliment a) => [
    a.nom.toLowerCase().trim(),
    a.calories.toStringAsFixed(1),
    a.proteines.toStringAsFixed(1),
    a.lipides.toStringAsFixed(1),
    a.glucides.toStringAsFixed(1),
  ].join("|");

  // Filtre, trie et déduplique les résultats LOCAUX (CIQUAL) par correspondance de nom
  List<Aliment> _trierEtDedupliquer(List<Aliment> aliments, String query) {
    final mots = query.split(' ').where((m) => m.isNotEmpty).toList();

    final filtres = aliments
        .where((a) => _nomContientTousLesMots(a.nom.toLowerCase().trim(), mots) && a.calories > 0)
        .toList();

    filtres.sort((a, b) {
      final nomA = a.nom.toLowerCase().trim();
      final nomB = b.nom.toLowerCase().trim();
      // 1. Correspondance exacte (query complet)
      final aExact = nomA == query;
      final bExact = nomB == query;
      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;
      // 2. Commence par le premier mot de la recherche
      final premierMot = mots.isNotEmpty ? mots.first : query;
      if (nomA.startsWith(premierMot) && !nomB.startsWith(premierMot)) return -1;
      if (!nomA.startsWith(premierMot) && nomB.startsWith(premierMot)) return 1;
      // 3. Déjà ajoutés en premier
      if (a.dejaAjoute && !b.dejaAjoute) return -1;
      if (!a.dejaAjoute && b.dejaAjoute) return 1;
      // 4. Avec portion nommée en premier
      final aPortionNom = a.portions.any((p) => p.nom.isNotEmpty);
      final bPortionNom = b.portions.any((p) => p.nom.isNotEmpty);
      if (aPortionNom && !bPortionNom) return -1;
      if (!aPortionNom && bPortionNom) return 1;
      // 5. Protéines décroissantes
      if (a.proteines != b.proteines) return b.proteines.compareTo(a.proteines);
      // 6. Alphabétique
      return a.nom.compareTo(b.nom);
    });

    final Set<String> seen = {};
    final List<Aliment> uniques = [];
    for (final a in filtres) {
      final key = _cle(a);
      if (!seen.contains(key)) { seen.add(key); uniques.add(a); }
    }
    return uniques;
  }

  void _filtrer(String recherche) {
    final query = recherche.toLowerCase().trim();

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Champ vide → afficher les aliments récemment ajoutés
    if (query.isEmpty) {
      setState(() {
        _recherche = query;
        _alimentsFiltres = _recents;
        _isSearching = false;
      });
      return;
    }

    // ÉTAPE 1 : Résultats CIQUAL locaux immédiats (base en mémoire, 0 ms)
    final locaux = _trierEtDedupliquer(_aliments, query);
    setState(() {
      _recherche = query;
      _alimentsFiltres = locaux;
      _isSearching = true; // barre discrète pendant l’appel API
    });

    // ÉTAPE 2 : Compléter avec OpenFoodFacts après debounce (400 ms)
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final rechercheEnCours = query;

      List<Aliment> apiResultats;
      try {
        apiResultats = await OpenFoodFactsAPI.searchAliments(query);
      } catch (e) {
        if (mounted) setState(() => _isSearching = false);
        return;
      }

      // Ignorer si la recherche a changé pendant l’attente
      if (rechercheEnCours != _recherche || !mounted) return;

      // Les résultats API sont déjà filtrés par OpenFoodFacts — on ne refiltre
      // pas par nom (évite de rejeter des produits dont le nom est en anglais
      // ou utilise des termes différents). On déduplique seulement.
      final seen = {for (final a in locaux) _cle(a)};
      final apiUniques = apiResultats
          .where((a) => a.calories > 0)
          .where((a) {
            final k = _cle(a);
            if (seen.contains(k)) return false;
            seen.add(k);
            return true;
          })
          .toList();

      setState(() {
        _alimentsFiltres = [...locaux, ...apiUniques];
        _isSearching = false;
      });
    });
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
    
    // Repas déjà connu via le bouton + de la section correspondante
    final Repas? repasChoisi = widget.repasPreselectionne;

    // ✅ Marquer comme déjà consommé + persister dans les favoris et récents
    setState(() { aliment.dejaAjoute = true; });
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _favoris.add(aliment.nom);
      LocalStorageService.saveFavoris(userId, _favoris);

      // Placer l'aliment en tête des récents (dédoublonné par nom, max 20)
      _recents = [
        aliment,
        ..._recents.where((a) => a.nom != aliment.nom),
      ].take(20).toList();
      LocalStorageService.saveRecents(userId, _recents);
    }

    widget.onAlimentAjoute(aliment, quantite, portionChoisie, repasChoisi);

    // On utilise navigator.pop() plutôt que Navigator.pop(context)
    navigator.pop(); // Ferme la page ListeAlimentsPage
  }

  // Ancien picker repas (bottom sheet) — conservé en commentaire comme référence
  // Future<Repas?> _choisirRepas() {
  //   return showModalBottomSheet<Repas>(
  //     context: context,
  //     backgroundColor: const Color(0xFF393939),
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (ctx) => Padding(
  //       padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         crossAxisAlignment: CrossAxisAlignment.stretch,
  //         children: [
  //           const Text("Quel repas ?", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
  //           const SizedBox(height: 16),
  //           ...Repas.values.map((r) => _repasTile(ctx, r)),
  //           const SizedBox(height: 4),
  //           TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Passer", style: TextStyle(color: Colors.white54))),
  //         ],
  //       ),
  //     ),
  //   ).then((v) => v);
  // }
  // Widget _repasTile(BuildContext ctx, Repas repas) {
  //   return ListTile(
  //     contentPadding: EdgeInsets.zero,
  //     title: Text(repas.label, style: const TextStyle(color: Colors.white, fontSize: 15)),
  //     onTap: () => Navigator.pop(ctx, repas),
  //   );
  // }
  
static const double heightsearch = 35;


  // BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(     
      backgroundColor: const Color(0xFF393939), // couleur de fond claire
      body: SafeArea( 
        child: Column(
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
                autofocus: true,
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
              icon: SvgPicture.asset('assets/images/icon_scan_6.svg',
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
            child: Column(
              children: [
                // Barre de chargement discrète pendant l'appel API (résultats locaux déjà visibles)
                if (_isSearching)
                  const LinearProgressIndicator(
                    minHeight: 2,
                    color: Color(0xFF357E50),
                    backgroundColor: Colors.transparent,
                  ),
                Expanded(
                  child: _alimentsFiltres.isEmpty && !_isSearching
                    ? const Center(child: Text("Aucun aliment trouvé", style: TextStyle(color: Colors.white)))
                    : ListView.builder(
                      physics: const BouncingScrollPhysics(),
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
                  'P: ${aliment.proteines.toStringAsFixed(0)} | '
                  'L: ${aliment.lipides.toStringAsFixed(0)} | '
                  'G: ${aliment.glucides.toStringAsFixed(0)}'
                  '${aliment.fibres > 0 ? ' | F: ${aliment.fibres.toStringAsFixed(0)}' : ''}'
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
                    ),          // ListView.builder
                  ),            // inner Expanded
                ],              // Column children
              ),                // Column
          ),                    // outer Expanded

                  ],
  
      ),
    ),
    );
}
}