import 'package:cal_track_v1/Pages/deconnexion.dart';
import 'package:cal_track_v1/Pages/donnees_utilisateur.dart';
import 'package:cal_track_v1/Pages/liste_aliments_page.dart';
import 'package:cal_track_v1/models/user_data.dart';
import 'package:cal_track_v1/services/formules_calories.dart';
import 'package:cal_track_v1/services/local_storage_service.dart';
import 'package:cal_track_v1/widgets/aliment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cal_track_v1/widgets/groupe_barre.dart';
//import 'package:shared_preferences/shared_preferences.dart';



class TableauDeBord extends StatefulWidget {
  //final User? user;
  
  const TableauDeBord({super.key});

  //final UserModel userData;
  
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
  
  double compteurkcal = 0;
  double compteurProteines = 0;
  double compteurLipides = 0;
  double compteurGlucides = 0;

  UserModel? _userData; // UserModel? _userData;
  
  DateTime? _derniereDateMaj;

  final List<AlimentConsomme> _alimentsDuJour = [];  

  bool _isLoading = false;

  

  @override
  void initState() {
    super.initState();

    _initializeData();

  // Essaye de charger en local d'abord
  /*LocalStorageService.loadUserData().then((localUser) {
    if (localUser != null) {
      setState(() {
        _userData = localUser;
        _mettreAJourDonneesUtilisateur(localUser);
        _verifierEtReinitialiserAliments();
        _isLoading = false;
      });
    }
  });*/

  // Charge ensuite les données Firebase à jour et écrase si besoin    
  /*fetchUserData().then((user) {    
    
      setState(() {
        _userData = user;        
        _isLoading = false;
        // Mettre à jour l'affichage si nécessaire
          
    if (user != null) {
      _mettreAJourDonneesUtilisateur(user); // <- Important, ici on initialise les macros
      _verifierEtReinitialiserAliments();
    }
    });
  });*/

/*
  LocalStorageService.loadAlimentsDuJour().then((aliments) {
  final maintenant = DateTime.now();
  final aujourdHui = DateTime(maintenant.year, maintenant.month, maintenant.day);
  setState(() {
    _derniereDateMaj = aujourdHui;
    _alimentsDuJour.clear();
    _alimentsDuJour.addAll(aliments);
    for (var aliment in aliments) {
      final macros = aliment.aliment.getMacrosPourQuantite(aliment.quantite);
      compteurkcal += macros['calories'] ?? 0;
      compteurProteines += macros['proteines'] ?? 0;
      compteurLipides += macros['lipides'] ?? 0;
      compteurGlucides += macros['glucides'] ?? 0;
    }
  });
});
*/

//_loadUserDataAndCalculate();

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

// PEUT ETRE PA SUPPRIMER !!!
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

/*Future<void> _loadUserDataAndCalculate() async {
    // Exemple avec SharedPreferences
    final prefs = await SharedPreferences.getInstance();


    final user = await LocalStorageService.loadUserData(userId);
    
    _mettreAJourDonneesUtilisateur(user);
    _verifierEtReinitialiserAliments();

  }*/

Future<void> _initializeData() async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  setState(() {
    _isLoading = true;
  });

  // Charger user data localement
  final localUser = await LocalStorageService.loadUserData(userId);
  
  // Charger données Firebase (prioritaire)
  final userFromFirebase = await fetchUserData();

  if (userFromFirebase != null) {
    setState(() {
    _userData = userFromFirebase;
    _mettreAJourDonneesUtilisateur(userFromFirebase); // => sauvegarde aussi les macros localement
    _isLoading = false;
  });
  
   } else if (localUser != null) {
    setState(() {
      _userData = localUser;
      _mettreAJourDonneesUtilisateur(localUser);
      _isLoading = false;
    });
  } else {   
   // Pas de données utilisateur, garder _isLoading false
    setState(() {
      _isLoading = false;
    });   
  }

  // Étape 2 : Charger les macros calculées (après maj)
  /*final localMacros = await LocalStorageService.loadMacros(userId);
  if (localMacros != null) {
    
    setState(() {
    caloriesMin = localMacros['calories_min']!;
    caloriesMax = localMacros['calories_max']!;
    protMin = localMacros['prot_min']!;
    protMax = localMacros['prot_max']!;
    lipidesMin = localMacros['lipides_min']!;
    lipidesMax = localMacros['lipides_max']!;
    glucidesMin = localMacros['glucides_min']!;
    glucidesMax = localMacros['glucides_max']!;
  });
}*/

  // Étape 3 : Charger les aliments du jour (après avoir chargé user et macros)
  final aliments = await LocalStorageService.loadAlimentsDuJour(userId);
  final maintenant = DateTime.now();
  final aujourdHui = DateTime(maintenant.year, maintenant.month, maintenant.day);

  setState(() {
    _derniereDateMaj = aujourdHui;    
    _alimentsDuJour.clear();
    _alimentsDuJour.addAll(aliments);

    compteurkcal = 0;
    compteurProteines = 0;
    compteurLipides = 0;
    compteurGlucides = 0;

    for (var aliment in aliments) {
      final macros = aliment.aliment.getMacrosPourQuantite(aliment.quantite);
      compteurkcal += macros['calories'] ?? 0;
      compteurProteines += macros['proteines'] ?? 0;
      compteurLipides += macros['lipides'] ?? 0;
      compteurGlucides += macros['glucides'] ?? 0;
    }
  });

  _verifierEtReinitialiserAliments();

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
  });

    final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId != null) {
    LocalStorageService.saveMacros(userId, macros);
  }
  }

  void _ouvrirListeAliments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListeAlimentsPage(
          onAlimentAjoute: (Aliment aliment, double quantite) {
        // Gère ici l’ajout avec la bonne quantité
        _ajouterAliment(aliment, quantite, aliment.getMacrosPourQuantite(quantite));
          },
          ),
      ),
    );
  }

  void _ajouterAliment(Aliment aliment, double quantite, Map<String, double> macros) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    setState(() {
      _alimentsDuJour.add(AlimentConsomme(aliment, quantite));      
      // Mise à jour des compteurs
      compteurkcal += macros['calories'] ?? 0;
      compteurProteines += macros['proteines'] ?? 0;
      compteurGlucides += macros['glucides'] ?? 0;
      compteurLipides += macros['lipides'] ?? 0;
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
     
      // Empêche des valeurs négatives dues aux arrondis
      compteurkcal = compteurkcal.clamp(0, double.infinity);
      compteurProteines = compteurProteines.clamp(0, double.infinity);
      compteurGlucides = compteurGlucides.clamp(0, double.infinity);
      compteurLipides = compteurLipides.clamp(0, double.infinity);    
  });
  }
  
  void _verifierEtReinitialiserAliments() {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  
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
      _derniereDateMaj = aujourdHui;
    });
  }

  LocalStorageService.saveAlimentsDuJour(userId!, _alimentsDuJour);
  
}

  static const double gap = 40;

  // barres de progressions
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
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),

        child: ListView(
          physics: BouncingScrollPhysics(), //Column
          children: [
            const SizedBox(height: 40),
            
            //BOX COULEUR TEST REPSONSIVE
            /*SizedBox(
                width: screenWidth * 0.85,
                height: 50,
                child: Container(
                  color: Colors.red
                  )
            ),
            */
                
            SizedBox(
              width: 300,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Text('Aujourd\'hui',
                style : const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 12,
                ),
              ), 
              
                ]     
              ),
            ),



            const SizedBox(height: 40),

            GroupeBarre(
              titre: "Calories",
              valeurMin: caloriesMin,
              valeurMax: caloriesMax,
              compteurCalories: compteurkcal,
            ),
            const SizedBox(height: gap),

            GroupeBarre(
              titre: "Protéines",
              valeurMin: protMin,
              valeurMax: protMax,
              compteurCalories: compteurProteines,
            ),
            const SizedBox(height: gap),

            GroupeBarre(
              titre: "Lipides",
              valeurMin: lipidesMin,
              valeurMax: lipidesMax,
              compteurCalories: compteurLipides,
            ),
            
            const SizedBox(height: gap),

            GroupeBarre(
              titre: "Glucides",
              valeurMin: glucidesMin,
              valeurMax: glucidesMax,
              compteurCalories: compteurGlucides,
            ),
            
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
                    size: 30, // taille de l'icône
                    ),
            ),
              ),
            ),
            ),

            const SizedBox(height: gap),

            SizedBox(
              height: 1,
              child: Container(
                color: Colors.grey,
              )
                            
            ),
            
            const SizedBox(height: 50),

            Center(
              child : const Text(
              'Aliments ajoutés',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            ),
            
            const SizedBox(height: 10),

            SizedBox(
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
                          trailing: IconButton(
                            icon: const Icon(Icons.minimize_rounded, color: Colors.red),
                            onPressed: () => _supprimerAliment(a),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
            ),
     
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20)
        ),
      
      child: BottomAppBar(
        height: 78,
        color: const Color(0xFF676464),
        
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
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
              icon: const Icon(Icons.person, color: Colors.white),
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
              child: 
              const Text(
                'Cal Track',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
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
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LogoutPage())
                  );
              }
            ),
          ],
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
