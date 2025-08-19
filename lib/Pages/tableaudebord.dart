import 'dart:ui';
import 'package:cal_track_v1/Pages/deconnexion.dart';
import 'package:cal_track_v1/Pages/donnees_utilisateur.dart';
import 'package:cal_track_v1/Pages/liste_aliments_page.dart';
import 'package:cal_track_v1/models/user_data.dart';
import 'package:cal_track_v1/services/formules_calories.dart';
import 'package:cal_track_v1/services/local_storage_service.dart';
import 'package:cal_track_v1/models/aliment.dart';
import 'package:cal_track_v1/widgets/quantite_aliment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cal_track_v1/widgets/groupe_barre.dart';

// import 'connexion_page.dart';

//import 'connexion_page.dart';
//import 'package:shared_preferences/shared_preferences.dart';


class TableauDeBord extends StatefulWidget {    
  const TableauDeBord({super.key});  
  
  @override
  State<TableauDeBord> createState() => _TableauDeBordState();
}

class _TableauDeBordState extends State<TableauDeBord> {
  
  //late UserModel user;
  late Map<String, int> macros;
  late double protMax;
  late double protMin;
  late double lipidesMin;
  late double lipidesMax;
  late double glucidesMin;
  late double glucidesMax;
  late double caloriesMin;
  late double caloriesMax;
  // late double fibresMin;
  // late double fibresMax;
  
  double compteurkcal = 0;
  double compteurProteines = 0;
  double compteurLipides = 0;
  double compteurGlucides = 0;
  // double compteurFibres = 0;
  // double compteurSucresLibres = 0;

  UserModel? _userData;
  
  DateTime? _derniereDateMaj;

  final List<AlimentConsomme> _alimentsDuJour = [];  

  bool _isLoading = false;

  

  @override
  void initState() {
    super.initState();

    

    _initializeData();
  }

Future<void> _initializeData() async {
  
  final userId = FirebaseAuth.instance.currentUser?.uid;
  
  /* if (FirebaseAuth.instance.currentUser != null) {
      
      Future.microtask(() {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ConnexionPage()),
        );
      });
    } */

  setState(() { _isLoading = true; });


  // ÉRAPE 1 : Charger données locales
  
  final localUser = await LocalStorageService.loadUserData(userId!);
  final localMacros = await LocalStorageService.loadMacros(userId);
  final aliments = await LocalStorageService.loadAlimentsDuJour(userId);

  if (localUser != null) {
    _userData = localUser;
    _mettreAJourDonneesUtilisateur(localUser);
  }

  if (localMacros != null) {
    caloriesMin = localMacros['calories_min']!.toDouble();
    caloriesMax = localMacros['calories_max']!.toDouble();
    protMin = localMacros['prot_min']!.toDouble();
    protMax = localMacros['prot_max']!.toDouble();
    lipidesMin = localMacros['lipides_min']!.toDouble();
    lipidesMax = localMacros['lipides_max']!.toDouble();
    glucidesMin = localMacros['glucides_min']!.toDouble();
    glucidesMax = localMacros['glucides_max']!.toDouble();
    // fibresMin = localMacros['fibres_min']!.toDouble();
    // fibresMax = localMacros['fibres_max']!.toDouble();
  }

  if (localMacros == null) {_mettreAJourDepuisFirebase(userId);}

  _chargerAlimentsEtCompteurs(aliments); //!! AJOUTER FONCTION ??

  // ÉTAPE 2 : Vérifier changement de jour
  
  await _verifierEtReinitialiserAliments();
  
  setState(() => _isLoading = false);

  // ÉTAPE 3 : Mise à jour Firebase (asynchrone, ne bloque pas l'UI)
  //_mettreAJourDepuisFirebase(userId);
}
  
  // Charger données Firebase (prioritaire)
  Future<void> _mettreAJourDepuisFirebase(String userId) async {
    
  final userFromFirebase = await fetchUserData();

  if (userFromFirebase != null) {
    setState(() {
    _userData = userFromFirebase;
    _mettreAJourDonneesUtilisateur(userFromFirebase); // => sauvegarde aussi les macros localement
    _isLoading = false;
  });  
  }  
  }
   
  Future<void> _chargerAlimentsEtCompteurs(List<AlimentConsomme> aliments) async {
  // final maintenant = DateTime.now();
  // final _derniereDateMaj = DateTime(maintenant.year, maintenant.month, maintenant.day);
  
       
  _alimentsDuJour
    ..clear()
    ..addAll(aliments);

    compteurkcal = 0;
    compteurProteines = 0;
    compteurLipides = 0;
    compteurGlucides = 0;
    // compteurFibres = 0;
    // compteurSucresLibres = 0;

    for (var aliment in aliments) {
      final macros = aliment.aliment.getMacrosPourQuantite(aliment.quantite);
      compteurkcal += macros['calories'] ?? 0;
      compteurProteines += macros['proteines'] ?? 0;
      compteurLipides += macros['lipides'] ?? 0;
      compteurGlucides += macros['glucides'] ?? 0;
      // compteurFibres += macros['fibres'] ?? 0;
      // compteurSucresLibres += macros['sucres'] ?? 0;

    }
  }
  
/*Future<void> _loadUserData() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  
  if (doc.exists) {
    final data = doc.data()!;
    setState(() {
      _poidsController.text = (data['Poids'] ?? 72).toString();
      _tailleController.text = (data['Taille'] ?? 180).toString();
      _ageController.text = (data['Âge'] ?? 27).toString();
      _sexe = data['Sexe'] ?? 'homme';
      _niveauActivite = data['Niveau d\'activité physique'] ?? 'actif';
      _sport = data['Type d\'activité physique'] ?? 'force';
      _objectif = data['Objectif'] ?? 'maintien';
      _isLoading = false;
    });
  } else {
    setState(() => _isLoading = false);
  }
}*/

// PEUT ETRE A SUPPRIMER !!!
  Future<UserModel?> fetchUserData() async {
  
    final userId = FirebaseAuth.instance.currentUser!.uid;
    
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (userDoc.exists) {
      final data = userDoc.data()!;
      final userModel = UserModel.fromJson(data);
      // Sauvegarde en local après récupération
      await LocalStorageService.saveUserData(userId, userModel);
      //return UserModel.fromJson(data);
      return userModel;  
    }  
  return null;
}

  void _mettreAJourDonneesUtilisateur(UserModel user) {
  
  final calculateur = CalculateurNutrition(user);
  final macros = calculateur.getMacros();
    
 setState(() {
    caloriesMin = macros['calories_min']!.toDouble();
    caloriesMax = macros['calories_max']!.toDouble();
    protMin = macros['prot_min']!.toDouble();
    protMax = macros['prot_max']!.toDouble();
    lipidesMin = macros['lipides_min']!.toDouble();
    lipidesMax = macros['lipides_max']!.toDouble();
    glucidesMin = macros['glucides_min']!.toDouble();
    glucidesMax = macros['glucides_max']!.toDouble();
    // fibresMin = macros['fibres_min']!.toDouble();
    // fibresMax = macros['fibres_max']!.toDouble();
  });

    final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId != null) {
    LocalStorageService.saveMacros(userId, macros);
  }
  }

// Vérifier si les aliments du jour doivent être réinitialisés (nouvelle journée)
  Future<void> _verifierEtReinitialiserAliments() async {
  final userId = FirebaseAuth.instance.currentUser?.uid ?? "offline_user";
    
  final maintenant = DateTime.now();
  final aujourdHui = DateTime(maintenant.year, maintenant.month, maintenant.day);

  if (_derniereDateMaj == null ||
      _derniereDateMaj!.year != aujourdHui.year ||
      _derniereDateMaj!.month != aujourdHui.month ||
      _derniereDateMaj!.day != aujourdHui.day) {
    setState(() {
      _alimentsDuJour.clear();
      compteurkcal = 0;
      compteurProteines = 0;
      compteurLipides = 0;
      compteurGlucides = 0;
      // compteurFibres = 0;
      // compteurSucresLibres = 0;
      
      _derniereDateMaj = aujourdHui;
    });
    
  // Sauvegarder liste vide uniquement après avoir confirmé nouvelle journée
  await LocalStorageService.saveAlimentsDuJour(userId, _alimentsDuJour);

    }
  }

  void _ouvrirListeAliments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListeAlimentsPage(
          onAlimentAjoute: (Aliment aliment, double quantite, Portion portionChoisie) {
          
          // Convertir la quantité en grammes
          double quantiteEnGrammes;
          if (portionChoisie.nom == "g") {
            quantiteEnGrammes = quantite; // déjà en grammes
          } else {
            quantiteEnGrammes = quantite * portionChoisie.poids;
          }            
        
        // Gère ici l’ajout avec la bonne quantité
        _ajouterAliment(aliment, 
                        quantiteEnGrammes, 
                        aliment.getMacrosPourQuantite(quantiteEnGrammes));
          },
          ),
      ),
    );
  }

  void _ajouterAliment(Aliment aliment, double quantite, Map<String, double> macros) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    setState(() {

      // ✅ Marquer l’aliment comme déjà ajouté
      aliment.dejaAjoute = true;

      // Ajouter à la liste du jour
      _alimentsDuJour.add(AlimentConsomme(aliment, quantite));      
      
      // Mise à jour des compteurs
      compteurkcal += macros['calories'] ?? 0;
      compteurProteines += macros['proteines'] ?? 0;
      compteurGlucides += macros['glucides'] ?? 0;
      compteurLipides += macros['lipides'] ?? 0;
      // compteurFibres += macros['fibres'] ?? 0;
      // compteurSucresLibres += macros['sucres'] ?? 0;
      
    });

    await LocalStorageService.saveAlimentsDuJour(userId, _alimentsDuJour);
  }

  void _supprimerAliment(AlimentConsomme alimentConsomme) {
    setState(() {
      _alimentsDuJour.remove(alimentConsomme);

      final macros = alimentConsomme.aliment.getMacrosPourQuantite(alimentConsomme.quantite);
      
      compteurkcal -= macros['calories'] ?? 0;
      compteurProteines -= macros['proteines'] ?? 0;
      compteurGlucides -= macros['glucides'] ?? 0;
      compteurLipides -= macros['lipides'] ?? 0;
      // compteurFibres -= macros['fibres'] ?? 0;
      // compteurSucresLibres -= macros['sucres'] ?? 0;
     
      // Empêche des valeurs négatives dues aux arrondis
      compteurkcal = compteurkcal.clamp(0, double.infinity);
      compteurProteines = compteurProteines.clamp(0, double.infinity);
      compteurGlucides = compteurGlucides.clamp(0, double.infinity);
      compteurLipides = compteurLipides.clamp(0, double.infinity); 
      // compteurFibres = compteurFibres.clamp(0, double.infinity);
      // compteurSucresLibres = compteurSucresLibres.clamp(0, double.infinity);   
  });
  }
  
  void _modifierAliment(AlimentConsomme alimentConsomme) async {

    final result = await Navigator.push(
      context,
    MaterialPageRoute(
      builder: (_) => QuantiteAliment(
        aliment: alimentConsomme.aliment,
           // passer la portion initiale
      ),
    ),
  );


  // CORRECT !! 
  if (result != null && result['quantite'] != null) {

    double nouvelleQuantite = result['quantite'];
    Portion? nouvellePortion = result['portionChoisie'];

    // Calcul de la quantité en grammes selon la portion
    double quantiteEnGrammes;
    if (nouvellePortion != null && nouvellePortion.nom != "g") {
      quantiteEnGrammes = nouvelleQuantite * nouvellePortion.poids;
    } else {
      quantiteEnGrammes = nouvelleQuantite;
    }
    
    final oldMacros = alimentConsomme.aliment.getMacrosPourQuantite(alimentConsomme.quantite);
    final newMacros = alimentConsomme.aliment.getMacrosPourQuantite(quantiteEnGrammes);

    setState(() {
      // Mettre à jour la quantité
      alimentConsomme.quantite = quantiteEnGrammes;

      // Ajuster les compteurs
      compteurkcal = compteurkcal - (oldMacros['calories'] ?? 0) + (newMacros['calories'] ?? 0);
      compteurProteines = compteurProteines - (oldMacros['proteines'] ?? 0) + (newMacros['proteines'] ?? 0);
      compteurGlucides = compteurGlucides - (oldMacros['glucides'] ?? 0) + (newMacros['glucides'] ?? 0);
      compteurLipides = compteurLipides - (oldMacros['lipides'] ?? 0) + (newMacros['lipides'] ?? 0);
      // compteurFibres = compteurFibres - (oldMacros['fibres'] ?? 0) + (newMacros['fibres'] ?? 0);
      // compteurLipides = compteurLipides - (oldMacros['sucres'] ?? 0) + (newMacros['sucres'] ?? 0);
    });

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await LocalStorageService.saveAlimentsDuJour(userId, _alimentsDuJour);
    }
  }
}

  int _arrondir100(double valeur) {
  return (valeur / 100).round() * 100;
  }

  Future<void> _baisserCalories() async {
  // Diminue les calories min/max de 100
  setState(() {
    caloriesMin = (caloriesMin - 100).clamp(0, double.infinity);
    caloriesMax = (caloriesMax - 100).clamp(0, double.infinity);

    if (caloriesMin < (4*protMin + 9*lipidesMin)) {
    caloriesMin = _arrondir100(4*protMin + 9*lipidesMin).toDouble();
    caloriesMax = _arrondir100(caloriesMin + 200).toDouble();    
    }
 

    // Recalcule les macros proportionnellement
    if (_userData != null) {
      final calculateur = CalculateurNutrition(_userData!);
      final nouvellesMacros = calculateur.getMacrosNewCalories(caloriesMin.round(), caloriesMax.round());

      protMin = nouvellesMacros['prot_min']!.toDouble();
      protMax = nouvellesMacros['prot_max']!.toDouble();
      lipidesMin = nouvellesMacros['lipides_min']!.toDouble();
      lipidesMax = nouvellesMacros['lipides_max']!.toDouble();
      glucidesMin = nouvellesMacros['glucides_min']!.toDouble();
      glucidesMax = nouvellesMacros['glucides_max']!.toDouble();
      // fibresMin = nouvellesMacros['fibres_min']!.toDouble();
      // fibresMax = nouvellesMacros['fibres_max']!.toDouble();

    }

  });

  // Sauvegarde en local
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId != null) {
    await LocalStorageService.saveMacros(userId,  {
      'calories_min': caloriesMin.round(),
      'calories_max': caloriesMax.round(),
      'prot_min': protMin.round(),
      'prot_max': protMax.round(),
      'lipides_min': lipidesMin.round(),
      'lipides_max': lipidesMax.round(),
      'glucides_min': glucidesMin.round(),
      'glucides_max': glucidesMax.round(),
      // 'fibres_min': fibresMin.round(),
      // 'fibres_max': fibresMax.round(),
    });
  }
  }
  
  Future<void> _monterCalories() async {
  // Augmente les calories min/max de 100
  setState(() {
    caloriesMin = (caloriesMin + 100).clamp(0, double.infinity);
    caloriesMax = (caloriesMax + 100).clamp(0, double.infinity);

    if (glucidesMax == 1000) {       
            
      caloriesMax = _arrondir100((4*glucidesMax) + (4 * protMin) + (9 * lipidesMin)).toDouble();

      caloriesMin = caloriesMax - 200;
    }

    // Recalcule les macros proportionnellement
    if (_userData != null) {
      final calculateur = CalculateurNutrition(_userData!);
      final nouvellesMacros = calculateur.getMacrosNewCalories(caloriesMin.round(), caloriesMax.round());

      protMin = nouvellesMacros['prot_min']!.toDouble();
      protMax = nouvellesMacros['prot_max']!.toDouble();
      lipidesMin = nouvellesMacros['lipides_min']!.toDouble();
      lipidesMax = nouvellesMacros['lipides_max']!.toDouble();
      glucidesMin = nouvellesMacros['glucides_min']!.toDouble();
      glucidesMax = nouvellesMacros['glucides_max']!.toDouble();
      // fibresMin = nouvellesMacros['fibres_min']!.toDouble();
      // fibresMax = nouvellesMacros['fibres_max']!.toDouble();
    }
    
  });

  // Sauvegarde en local
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId != null) {
    await LocalStorageService.saveMacros(userId, {
      'calories_min': caloriesMin.round(),
      'calories_max': caloriesMax.round(),
      'prot_min': protMin.round(),
      'prot_max': protMax.round(),
      'lipides_min': lipidesMin.round(),
      'lipides_max': lipidesMax.round(),
      'glucides_min': glucidesMin.round(),
      'glucides_max': glucidesMax.round(),
      // 'fibres_min': fibresMin.round(),
      // 'fibres_max': fibresMax.round(),
    });
  }
  }


  static const double gap = 40;
  static const double ajustBoutonheight = 30;
  static const double dashbarWidth = 320.0;
  static const double separatorWidth = ((0.5*dashbarWidth) - ajustBoutonWidth) ;
  static const double topBarH = 85;
  static const double ajustBoutonWidth = 50;

  // UI
  @override
  Widget build(BuildContext context) {

    // double screenWidth = MediaQuery.of(context).size.width; // TAILLE DE L'ECRAN pour RESPONSIVE

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF393939),
        body: const Center(
      child: CircularProgressIndicator(color: Color(0xFF357E50)),
    ),
  );
}


  
    return Scaffold(
      backgroundColor: const Color(0xFF393939),
      body: SafeArea(

      child: Center( // Centre horizontalement
      child: ConstrainedBox(
        constraints: BoxConstraints(
          //maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
            child: Stack( //Column
              //crossAxisAlignment: CrossAxisAlignment.center,
          children: [          
        
        Padding(
              padding: const EdgeInsets.only(top: 0), // espace en haut pour le texte + zone floutée 
          child: ListView(
          physics: BouncingScrollPhysics(), //Column
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.15), // ← zone vide pour ne pas recouvrir la zone floutée
            
            //BOX COULEUR TEST REPSONSIVE
            /*SizedBox(
                width: screenWidth * 0.85,
                height: 50,
                child: Container(
                  color: Colors.red
                  )
            ),
            */                   

            GroupeBarre(
              titre: "Calories",
              valeurMin: caloriesMin,
              valeurMax: caloriesMax,
              compteurCalories: compteurkcal,
              barWidth: dashbarWidth,
            ),        
            
            const SizedBox(height: 7),

            //BOUTONS D'AJUSTEMENT
            SizedBox(  
  height: ajustBoutonheight,
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      
      // Bouton gauche (-)
      SizedBox(
        width: ajustBoutonWidth, //(dashbarWidth - (separatorWidth) ) /2,
        child: GestureDetector(
          onTap:

            _baisserCalories, // 👇 Personnalise ici le comportement du bouton -
          
          child: Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(115, 43, 43, 43),
              borderRadius: BorderRadius.circular(ajustBoutonheight
                // topLeft: Radius.circular(ajustBoutonheight),
                // bottomLeft: Radius.circular(ajustBoutonheight),
              ),
              //border: Border.all(color: Colors.white, width: 1),
            ),
            child: const Center(
              child: Icon(
                Icons.arrow_drop_down, 
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),

      // Séparation visible entre les deux
      Container(        
        width: separatorWidth,
        alignment: Alignment.center,                    
        color: Colors.transparent, //const Color(0xFF393939),
        child: Text("Ajuster les besoins",
        style: TextStyle(fontSize: ajustBoutonheight/3, 
        color: Colors.white)        )      
      ),

      // Bouton droit (+)
      SizedBox(
        width: ajustBoutonWidth, //(dashbarWidth - separatorWidth) /2,
        child: GestureDetector(
          onTap: 

          _monterCalories, // 👇 Personnalise ici le comportement du bouton +
          
          child: Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(115, 43, 43, 43),
              borderRadius: BorderRadius.circular(ajustBoutonheight
                // topRight: Radius.circular(ajustBoutonheight),
                // bottomRight: Radius.circular(ajustBoutonheight),
              ),
              //border: Border.all(color: Colors.white, width: 1),
            ),
            child: const Center(
              child: Icon(Icons.arrow_drop_up, color: Colors.white),
            ),
          ),
        ),
      ),
    ],
  ),
),

            const SizedBox(height: gap),
            
            GroupeBarre(
              titre: "Protéines",
              valeurMin: protMin,
              valeurMax: protMax,
              compteurCalories: compteurProteines,
              barWidth: dashbarWidth,
            ),
            const SizedBox(height: gap),

            GroupeBarre(
              titre: "Lipides",
              valeurMin: lipidesMin,
              valeurMax: lipidesMax,
              compteurCalories: compteurLipides,
              barWidth: dashbarWidth,
            ),
            
            const SizedBox(height: gap),

            GroupeBarre(
              titre: "Glucides",
              valeurMin: glucidesMin,
              valeurMax: glucidesMax,
              compteurCalories: compteurGlucides,
              barWidth: dashbarWidth,
            ),
            
            // const SizedBox(height: gap),

            /* //BARRE FIBRE
            GroupeBarre(
              titre: "Fibres",
              valeurMin: fibresMin,
              valeurMax: fibresMax,
              compteurCalories: compteurFibres,
              barWidth: dashbarWidth,
            ), */

            const SizedBox(height: gap),

            Center(
              child : SizedBox(
              width: 50,
              height: 50,
              child: ElevatedButton(
                
                onPressed: _ouvrirListeAliments,

              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15), // optionnel : coins arrondis
                  ),
                  backgroundColor: Color(0xFF357E50), // couleur de fond optionnelle
                  // elevation: 4, // ombre optionnelle
                  padding: EdgeInsets.zero, // Important : enlève le padding interne
                  ),
                  child: const Center(
                  child: Icon(
                    Icons.add,
                    color: Colors.black, // couleur personnalisée de l'icône
                    size: 40, // 30 taille de l'icône
                    ),
            ),
              ),
            ),
            ),

            const SizedBox(height: gap),
            
            const SizedBox(height: 50),

            Center(
              
              child : const Text(
              'Aliments consommés',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            ),
            
            const SizedBox(height: 10),

            Center(
              child: 
              Container(
              width: MediaQuery.of(context).size.width * 0.85, // 90% de la largeur de l’écran,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: Color(0x3B000000)),
              borderRadius: BorderRadius.circular(25),
              ),

              child: _alimentsDuJour.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucun aliment ajouté.',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : Column( //ListView
                      children: _alimentsDuJour.map((a) {
                        //final index = entry.key;
                        //final aliment = entry.value;
                        final macros = a.aliment.getMacrosPourQuantite(a.quantite);

                        return ListTile(
                          title: Text(
                            "${a.aliment.nom} - ${a.quantite.toStringAsFixed(0)}g",
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            '${macros['calories']?.toStringAsFixed(0)} kcal - '
                            'P. ${macros['proteines']?.toStringAsFixed(0)}' 
                            ' | L. ${macros['lipides']?.toStringAsFixed(0)}' 
                            ' | G. ${macros['glucides']?.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          
                          trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFFBC8C56)),
                              onPressed: () {                                
                                  
                                  _modifierAliment(a);

                              },
                            ),
                          
                          
                          
                          
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Colors.red,                            
                            ),
                            onPressed: () => _supprimerAliment(a),
                          ),
                          ]
                          ),
                        );
                      }).toList(),
                    ),
            ),
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            
          ],
        ),
        ),

        Positioned(
            top: 0, // Espace par rapport au haut de l'écran
            left: 0,
            right: 0,
            child: ClipRect( // obligatoire pour BackdropFilter
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: topBarH,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.bottomCenter,
                  color: Colors.black.withAlpha(0), // Couleur semi-transparente
                  child: const Text(
                    "Aujourd’hui",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),



          //],
      //),
      //),
            //),
     
      //),
      
      //BOTTOM BAR
      Positioned(
        left: 0, 
        right: 0,
        bottom: 0,
        child: ClipRRect( //bottomNavigationBar:
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20)
        ),

        child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      
      child: BottomAppBar(
        height: 50, //50
        color: Color(0xFF676464).withAlpha(150), // const Color(0x00676464),
        
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          //crossAxisAlignment: CrossAxisAlignment.,
          children: [
            // bouton dashboard
            /*IconButton(
              icon: const Icon(Icons.density_medium_rounded, color: Colors.white),
              // assignment
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TableauDeBord())
                  );
              }
              ),*/

            // bouton PROFIL (données utilisateur)
            IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.person, color: Colors.black, size: 25),
              onPressed: () async {
                 final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DonneesUtilisateurPage()),
          );
              if (result != null && result is UserModel) {
                // Ici tu peux faire quelque chose avec le résultat renvoyé de DonneesUtilisateurPage
                setState(() {
                  _userData = result;
                  _mettreAJourDonneesUtilisateur(_userData!);
                });
                // Par exemple mettre à jour l'état avec setState
              }
        },
      ),

            // texte Appli
            Center(
              child: GestureDetector( 
                onTap: () {
                  _ouvrirListeAliments();
                },
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                
                child: const Center(
                  child: Icon(
                    Icons.add, 
                    color: Color(0xFF066A2D),
                    size: 25,
                  ),
                ),              
                ),
              ),
            ),

            // icône data
            /*Positioned(
              right: 10,
              top: 20,
              child: IconButton(
                icon: const Icon(Icons.data_usage, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DonneesPage()),
                  );
                },
              ),
            ),*/

            // icône paramètres
            Center (
              child : IconButton(
                padding: EdgeInsets.zero,
              icon: const Icon(Icons.settings, color: Colors.black, size: 25),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LogoutPage())
                  );
              }
            ),
            ),
          ],
        ),
      ),
      ),
      ),
            ),
          ],
      ),
      ),
      ),
      ),
    );
  }
}

/*class AlimentConsomme {
  final Aliment aliment;
  double quantite;

  AlimentConsomme(this.aliment, this.quantite);
}*/
