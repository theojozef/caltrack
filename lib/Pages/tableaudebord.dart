import 'dart:math' as math;
import 'dart:ui';
import 'package:cal_track_v1/Pages/connexion_page.dart';
import 'package:cal_track_v1/Pages/donnees_utilisateur.dart';
import 'package:cal_track_v1/Pages/guide_page.dart';
import 'package:cal_track_v1/Pages/stats_page.dart';
import 'package:cal_track_v1/Pages/liste_aliments_page.dart';
import 'package:cal_track_v1/models/user_data.dart';
import 'package:cal_track_v1/services/formules_calories.dart';
import 'package:cal_track_v1/services/local_storage_service.dart';
import 'package:cal_track_v1/models/aliment.dart';
import 'package:cal_track_v1/widgets/calendrier_panel.dart';
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
  late double fibresMin;
  late double fibresMax;

  double compteurkcal = 0;
  double compteurProteines = 0;
  double compteurLipides = 0;
  double compteurGlucides = 0;
  double compteurFibres = 0;
  // double compteurSucresLibres = 0;

  UserModel? _userData;

  DateTime _dateSelectionnee = DateTime.now(); // jour affiché (today par défaut)
  Set<String> _joursAvecDonnees = {};          // dates avec au moins un aliment

  DateTime? _derniereDateMaj;

  final List<AlimentConsomme> _alimentsDuJour = [];

  // true = liste visible, false = rétractée (ouvert par défaut)
  final Map<String, bool> _repasExpanded = {
    for (final r in Repas.values) r.name: true,
  };

  bool _isLoading = false;
  bool _ajustementDebloque = false;
  bool _macrosLocalesExistantes = false;

  // Date du jour affiché (peut être un jour passé)
  String get _dateCourante => LocalStorageService.formatDate(_dateSelectionnee);
  // Vrai uniquement si on consulte la journée en cours
  bool get _estAujourdhui =>
      _dateCourante == LocalStorageService.formatDate(DateTime.now());
  // Vrai si le jour affiché est strictement dans le passé
  bool get _estPasse {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dateOnly = DateTime(_dateSelectionnee.year, _dateSelectionnee.month, _dateSelectionnee.day);
    return dateOnly.isBefore(todayOnly);
  }

  // Vrai si on a atteint la limite de navigation future (+7 jours)
  bool get _estALimite {
    final today = DateTime.now();
    final dateLimite = DateTime(today.year, today.month, today.day).add(const Duration(days: 7));
    final dateOnly = DateTime(_dateSelectionnee.year, _dateSelectionnee.month, _dateSelectionnee.day);
    return !dateOnly.isBefore(dateLimite);
  }

  @override
  void initState() {
    super.initState();

    _initializeData();
  }

Future<void> _initializeData() async {
  
  final userId = FirebaseAuth.instance.currentUser?.uid;
  
  // Si pas d'utilisateur connecté, retourner à la page de connexion
  if (userId == null) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ConnexionPage()),
    );
    return;
  }

  setState(() { _isLoading = true; });


  // ÉRAPE 1 : Charger données locales
  
  final localUser = await LocalStorageService.loadUserData(userId);
  final localMacros = await LocalStorageService.loadMacros(userId);
  final aliments = await LocalStorageService.loadAlimentsDuJour(userId, _dateCourante);

  if (localUser != null) {
    _userData = localUser;
    // N'écrase les macros sauvegardées que s'il n'en existe pas déjà en local
    if (localMacros == null) {
      _mettreAJourDonneesUtilisateur(localUser);
    }
  }


  if (localMacros != null) {
    _macrosLocalesExistantes = true;
    caloriesMin = localMacros['calories_min']!.toDouble();
    caloriesMax = localMacros['calories_max']!.toDouble();
    protMin = localMacros['prot_min']!.toDouble();
    protMax = localMacros['prot_max']!.toDouble();
    lipidesMin = localMacros['lipides_min']!.toDouble();
    lipidesMax = localMacros['lipides_max']!.toDouble();
    glucidesMin = localMacros['glucides_min']!.toDouble();
    glucidesMax = localMacros['glucides_max']!.toDouble();
    fibresMin = localMacros['fibres_min']!.toDouble();
    fibresMax = localMacros['fibres_max']!.toDouble();
  } else {
      // 2) Si pas de macros locales, tenter de récupérer depuis Firebase
      final fetched = await fetchUserData(); // <-- votre méthode existante
      if (fetched != null) {
        _userData = fetched;
        _mettreAJourDonneesUtilisateur(fetched);
      } else {
        // Pas de données en base : forcer la déconnexion et retourner à la connexion
        if (!mounted) return;
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (_) => const ConnexionPage()),
        );
        return;
      }
    }

  // if (localMacros == null) {_mettreAJourDepuisFirebase(userId);}

  await _chargerAlimentsEtCompteurs(aliments); //!! AJOUTER FONCTION ??

  // Initialiser _derniereDateMaj AVANT la vérification pour ne pas effacer
  // les aliments qu'on vient de charger (sinon la condition "null" déclencherait toujours le clear)
  final maintenant = DateTime.now();
  _derniereDateMaj = DateTime(maintenant.year, maintenant.month, maintenant.day);

  // ÉTAPE 2 : Vérifier changement de jour

  await _verifierEtReinitialiserAliments();
  
  setState(() => _isLoading = false);

  // ÉTAPE 3 : Mise à jour Firebase (asynchrone, ne bloque pas l'UI)
  _mettreAJourDepuisFirebase(userId);

  // Charger les jours avec données pour le calendrier
  _chargerJoursAvecDonnees(userId);
}
  
  // Charger données Firebase (prioritaire)
  Future<void> _mettreAJourDepuisFirebase(String userId) async {

  final userFromFirebase = await fetchUserData();

  if (userFromFirebase != null) {
    if (_macrosLocalesExistantes) {
      // Des macros ajustées existent : on met à jour le profil sans écraser les macros
      setState(() {
        _userData = userFromFirebase;
        _isLoading = false;
      });
    } else {
      setState(() {
        _userData = userFromFirebase;
        _mettreAJourDonneesUtilisateur(userFromFirebase); // => sauvegarde aussi les macros localement
        _isLoading = false;
      });
    }
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
    compteurFibres = 0;
    // compteurSucresLibres = 0;

    for (var aliment in aliments) {
      final macros = aliment.aliment.getMacrosPourQuantite(aliment.quantite);
      compteurkcal += macros['calories'] ?? 0;
      compteurProteines += macros['proteines'] ?? 0;
      compteurLipides += macros['lipides'] ?? 0;
      compteurGlucides += macros['glucides'] ?? 0;
      compteurFibres += macros['fibres'] ?? 0;
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

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;
    
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
    fibresMin = macros['fibres_min']!.toDouble();
    fibresMax = macros['fibres_max']!.toDouble();
  });

    final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId != null) {
    LocalStorageService.saveMacros(userId, macros);
  }
  }

// Vérifier si les aliments du jour doivent être réinitialisés (nouvelle journée)
  Future<void> _verifierEtReinitialiserAliments() async {
  // Pas de réinitialisation si on consulte un jour passé
  if (!_estAujourdhui) return;

  final userId = FirebaseAuth.instance.currentUser?.uid ?? "offline_user";
    
  final maintenant = DateTime.now();
  final aujourdHui = DateTime(maintenant.year, maintenant.month, maintenant.day);

  if (_derniereDateMaj == null ||
      _derniereDateMaj!.year != aujourdHui.year ||
      _derniereDateMaj!.month != aujourdHui.month ||
      _derniereDateMaj!.day != aujourdHui.day) {

    // Figer les macros du jour qui se termine avant de passer au suivant
    if (_derniereDateMaj != null) {
      final hierStr = LocalStorageService.formatDate(_derniereDateMaj!);
      await LocalStorageService.saveMacrosSnapshot(userId, hierStr, {
        'calories_min': caloriesMin.round(),
        'calories_max': caloriesMax.round(),
        'prot_min': protMin.round(),
        'prot_max': protMax.round(),
        'lipides_min': lipidesMin.round(),
        'lipides_max': lipidesMax.round(),
        'glucides_min': glucidesMin.round(),
        'glucides_max': glucidesMax.round(),
        'fibres_min': fibresMin.round(),
        'fibres_max': fibresMax.round(),
      });
    }

    setState(() {
      _alimentsDuJour.clear();
      compteurkcal = 0;
      compteurProteines = 0;
      compteurLipides = 0;
      compteurGlucides = 0;
      compteurFibres = 0;
      // compteurSucresLibres = 0;

      _derniereDateMaj = aujourdHui;
    });

  // Sauvegarder liste vide uniquement après avoir confirmé nouvelle journée
  await LocalStorageService.saveAlimentsDuJour(userId, _alimentsDuJour, _dateCourante);

    }
  }

  // Volet de sélection du repas avant d’ouvrir la liste d’aliments
  void _ouvrirChoixRepas() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2E2E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Ajouter à quel repas ?",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ...Repas.values.map((repas) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    _ouvrirListeAliments(repas);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A4A4A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.restaurant_menu, color: Color(0xFF357E50), size: 18),
                        const SizedBox(width: 12),
                        Text(
                          repas.label,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
                      ],
                    ),
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  // repas est optionnel : fourni par le bouton + d’une section, null si ajout général
  void _ouvrirListeAliments([Repas? repas]) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 750), // 320
        reverseTransitionDuration: const Duration(milliseconds: 300), // 280
        pageBuilder: (context, animation, secondaryAnimation) => ListeAlimentsPage(
          repasPreselectionne: repas,
          onAlimentAjoute: (Aliment aliment, double quantite, Portion portionChoisie, Repas? repasChoisi) {

            // Convertir la quantité en grammes
            double quantiteEnGrammes;
            if (portionChoisie.nom == "g") {
              quantiteEnGrammes = quantite;
            } else {
              quantiteEnGrammes = quantite * portionChoisie.poids;
            }

            _ajouterAliment(aliment,
                            quantiteEnGrammes,
                            aliment.getMacrosPourQuantite(quantiteEnGrammes),
                            repasChoisi);
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
      ),
    );
  }

  void _ajouterAliment(Aliment aliment, double quantite, Map<String, double> macros, [Repas? repas]) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() {

      // ✅ Marquer l’aliment comme déjà ajouté
      aliment.dejaAjoute = true;

      // Ajouter à la liste du jour avec le repas sélectionné
      _alimentsDuJour.add(AlimentConsomme(aliment, quantite, repas: repas));
      
      // Mise à jour des compteurs
      compteurkcal += macros['calories'] ?? 0;
      compteurProteines += macros['proteines'] ?? 0;
      compteurGlucides += macros['glucides'] ?? 0;
      compteurLipides += macros['lipides'] ?? 0;
      compteurFibres += macros['fibres'] ?? 0;
      // compteurSucresLibres += macros['sucres'] ?? 0;
      
    });

    await LocalStorageService.saveAlimentsDuJour(userId, _alimentsDuJour, _dateCourante);
  }

  void _supprimerAliment(AlimentConsomme alimentConsomme) async {
    setState(() {
      _alimentsDuJour.remove(alimentConsomme);

      final macros = alimentConsomme.aliment.getMacrosPourQuantite(alimentConsomme.quantite);

      compteurkcal -= macros['calories'] ?? 0;
      compteurProteines -= macros['proteines'] ?? 0;
      compteurGlucides -= macros['glucides'] ?? 0;
      compteurLipides -= macros['lipides'] ?? 0;
      compteurFibres -= macros['fibres'] ?? 0;
      // compteurSucresLibres -= macros['sucres'] ?? 0;

      // Empêche des valeurs négatives dues aux arrondis
      compteurkcal = compteurkcal.clamp(0, double.infinity);
      compteurProteines = compteurProteines.clamp(0, double.infinity);
      compteurGlucides = compteurGlucides.clamp(0, double.infinity);
      compteurLipides = compteurLipides.clamp(0, double.infinity);
      compteurFibres = compteurFibres.clamp(0, double.infinity);
      // compteurSucresLibres = compteurSucresLibres.clamp(0, double.infinity);
    });

    // Sauvegarde après suppression (manquait avant)
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await LocalStorageService.saveAlimentsDuJour(userId, _alimentsDuJour, _dateCourante);
    }
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
      compteurFibres = (compteurFibres - (oldMacros['fibres'] ?? 0) + (newMacros['fibres'] ?? 0)).clamp(0, double.infinity);
      // compteurLipides = compteurLipides - (oldMacros['sucres'] ?? 0) + (newMacros['sucres'] ?? 0);
    });

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await LocalStorageService.saveAlimentsDuJour(userId, _alimentsDuJour, _dateCourante);
    }
  }
}

  void _mettreAJourQuantite(AlimentConsomme alimentConsomme, double nouvelleQuantite) async {
    final oldMacros = alimentConsomme.aliment.getMacrosPourQuantite(alimentConsomme.quantite);
    final newMacros = alimentConsomme.aliment.getMacrosPourQuantite(nouvelleQuantite);

    setState(() {
      alimentConsomme.quantite = nouvelleQuantite;
      compteurkcal      = (compteurkcal      - (oldMacros['calories']  ?? 0) + (newMacros['calories']  ?? 0)).clamp(0, double.infinity);
      compteurProteines = (compteurProteines - (oldMacros['proteines'] ?? 0) + (newMacros['proteines'] ?? 0)).clamp(0, double.infinity);
      compteurGlucides  = (compteurGlucides  - (oldMacros['glucides']  ?? 0) + (newMacros['glucides']  ?? 0)).clamp(0, double.infinity);
      compteurLipides   = (compteurLipides   - (oldMacros['lipides']   ?? 0) + (newMacros['lipides']   ?? 0)).clamp(0, double.infinity);
      compteurFibres    = (compteurFibres    - (oldMacros['fibres']    ?? 0) + (newMacros['fibres']    ?? 0)).clamp(0, double.infinity);
    });

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await LocalStorageService.saveAlimentsDuJour(userId, _alimentsDuJour, _dateCourante);
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
      fibresMin = nouvellesMacros['fibres_min']!.toDouble();
      fibresMax = nouvellesMacros['fibres_max']!.toDouble();

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
      'fibres_min': fibresMin.round(),
      'fibres_max': fibresMax.round(),
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
      fibresMin = nouvellesMacros['fibres_min']!.toDouble();
      fibresMax = nouvellesMacros['fibres_max']!.toDouble();
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
      'fibres_min': fibresMin.round(),
      'fibres_max': fibresMax.round(),
    });
  }
  }


  static const double gap = 40; // 40
  static const double ajustBoutonheight = 30; // 30
  static const double topBarH = 85; // 85
  static const double ajustBoutonWidth = 50; // 50

  // ── Calendrier & navigation par date ────────────────────────────────────

  Future<void> _chargerJoursAvecDonnees(String userId) async {
    final dates = await LocalStorageService.getJoursAvecDonnees(userId);
    if (mounted) setState(() => _joursAvecDonnees = dates.toSet());
  }

  // Recharge les aliments pour la date sélectionnée (sans toucher aux macros/profil)
  Future<void> _chargerDonneesPourDate() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);

    final aliments = await LocalStorageService.loadAlimentsDuJour(userId, _dateCourante);
    await _chargerAlimentsEtCompteurs(aliments);

    if (_estPasse) {
      // Jour passé : charger le snapshot figé (ou le plus proche disponible)
      final macrosDuJour = await LocalStorageService.loadMacrosForDate(userId, _dateCourante);
      if (macrosDuJour != null) {
        setState(() {
          caloriesMin = macrosDuJour['calories_min']!;
          caloriesMax = macrosDuJour['calories_max']!;
          protMin = macrosDuJour['prot_min']!;
          protMax = macrosDuJour['prot_max']!;
          lipidesMin = macrosDuJour['lipides_min']!;
          lipidesMax = macrosDuJour['lipides_max']!;
          glucidesMin = macrosDuJour['glucides_min']!;
          glucidesMax = macrosDuJour['glucides_max']!;
          fibresMin = macrosDuJour['fibres_min']!;
          fibresMax = macrosDuJour['fibres_max']!;
        });
      } else if (_userData != null) {
        // Pas de snapshot : afficher les macros calculées depuis le profil
        // sans sauvegarder (ne doit pas écraser les ajustements d'aujourd'hui)
        final calculateur = CalculateurNutrition(_userData!);
        final macrosCalculees = calculateur.getMacros();
        setState(() {
          caloriesMin = macrosCalculees['calories_min']!.toDouble();
          caloriesMax = macrosCalculees['calories_max']!.toDouble();
          protMin = macrosCalculees['prot_min']!.toDouble();
          protMax = macrosCalculees['prot_max']!.toDouble();
          lipidesMin = macrosCalculees['lipides_min']!.toDouble();
          lipidesMax = macrosCalculees['lipides_max']!.toDouble();
          glucidesMin = macrosCalculees['glucides_min']!.toDouble();
          glucidesMax = macrosCalculees['glucides_max']!.toDouble();
          fibresMin = macrosCalculees['fibres_min']!.toDouble();
          fibresMax = macrosCalculees['fibres_max']!.toDouble();
        });
      }
    } else {
      // Aujourd'hui ou futur : restaurer les macros courantes
      final macrosCourantes = await LocalStorageService.loadMacros(userId);
      if (macrosCourantes != null) {
        setState(() {
          caloriesMin = macrosCourantes['calories_min']!;
          caloriesMax = macrosCourantes['calories_max']!;
          protMin = macrosCourantes['prot_min']!;
          protMax = macrosCourantes['prot_max']!;
          lipidesMin = macrosCourantes['lipides_min']!;
          lipidesMax = macrosCourantes['lipides_max']!;
          glucidesMin = macrosCourantes['glucides_min']!;
          glucidesMax = macrosCourantes['glucides_max']!;
          fibresMin = macrosCourantes['fibres_min']!;
          fibresMax = macrosCourantes['fibres_max']!;
        });
      }
    }

    if (_estAujourdhui) {
      final now = DateTime.now();
      _derniereDateMaj = DateTime(now.year, now.month, now.day);
      await _verifierEtReinitialiserAliments();
    }

    setState(() => _isLoading = false);
  }

  void _selectionnerDate(DateTime date) {
    setState(() {
      _dateSelectionnee = date;
      _ajustementDebloque = false;
    });
    _chargerDonneesPourDate();
  }

  // "Mar. 3 juin" pour les jours passés dans la top bar
  String _formatDateCourte(DateTime date) {
    const jours = ['Lun.', 'Mar.', 'Mer.', 'Jeu.', 'Ven.', 'Sam.', 'Dim.'];
    const mois = ['jan.', 'fév.', 'mars', 'avr.', 'mai', 'juin',
                  'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
    return '${jours[date.weekday - 1]} ${date.day} ${mois[date.month - 1]}';
  }

  void _ouvrirCalendrier() async {
    // Recharger la liste fraîche avant d'ouvrir
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final dates = await LocalStorageService.getJoursAvecDonnees(userId);
      if (mounted) setState(() => _joursAvecDonnees = dates.toSet());
    }
    if (!mounted) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, _, __) => Align(
        alignment: Alignment.topCenter,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            child: CalendrierPanel(
              dateSelectionnee: _dateSelectionnee,
              joursAvecDonnees: _joursAvecDonnees,
              onDateSelectionnee: _selectionnerDate,
            ),
          ),
        ),
      ),
      transitionBuilder: (ctx, anim, _, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }

  // ── Helpers liste aliments ──────────────────────────────────────────────

  // Une boîte par repas, toujours visibles
  List<Widget> _buildGroupedList() {
    final cards = <Widget>[
      for (final repas in Repas.values) _buildRepasCard(repas),
    ];

    // Boîte "Non catégorisé" uniquement s'il y a des aliments sans repas
    final sansCategorie = _alimentsDuJour.where((a) => a.repas == null).toList();
    if (sansCategorie.isNotEmpty) {
      cards.add(_buildRepasCardGenerique('Non catégorisé', sansCategorie));
    }

    return cards;
  }

  Widget _buildRepasCard(Repas repas) {
    final groupe = _alimentsDuJour.where((a) => a.repas == repas).toList();
    return _buildRepasCardGenerique(repas.label, groupe, repas: repas);
  }

  Widget _buildRepasCardGenerique(String label, List<AlimentConsomme> aliments, {Repas? repas}) {
    final totalKcal = aliments.fold<double>(
      0,
      (acc, a) => acc + (a.aliment.getMacrosPourQuantite(a.quantite)['calories'] ?? 0),
    );
    final totalProt = aliments.fold<double>(
      0,
      (acc, a) => acc + (a.aliment.getMacrosPourQuantite(a.quantite)['proteines'] ?? 0),
    );
    final totalLip = aliments.fold<double>(
      0,
      (acc, a) => acc + (a.aliment.getMacrosPourQuantite(a.quantite)['lipides'] ?? 0),
    );
    final totalGluc = aliments.fold<double>(
      0,
      (acc, a) => acc + (a.aliment.getMacrosPourQuantite(a.quantite)['glucides'] ?? 0),
    );

    const colorVert  = Color(0xFF0BE754);
    const colorRouge = Color(0xFFBC5A56);
    const colorMarron = Color(0xFFBC8C56); // 0x3ABC8C56
    final pctProt = totalKcal > 0 ? totalProt * 4 / totalKcal * 100 : 0;
    final pctLip  = totalKcal > 0 ? totalLip  * 9 / totalKcal * 100 : 0;
    final pctGluc = totalKcal > 0 ? totalGluc * 4 / totalKcal * 100 : 0;
    final colorP = pctProt >= 15 ? colorVert : colorMarron;
    final colorL = pctLip  <= 40 ? colorVert : colorRouge;
    final colorG = pctGluc <= 60 ? colorVert : colorRouge;

    // La clé dans _repasExpanded : nom de l'enum pour les repas, label sinon
    final expandedKey = repas?.name ?? label;
    final ouvert = _repasExpanded[expandedKey] ?? true;

    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF4A4A4A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : chevron + nom/kcal + bouton +
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Row(
              children: [
                // Chevron rotatif dans une zone carrée fixe
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _repasExpanded[expandedKey] = !ouvert),
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: Center(
                      child: AnimatedRotation(
                        turns: ouvert ? 0.25 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: const Icon(
                          Icons.chevron_right,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        '${totalKcal.toStringAsFixed(0)} kcal',
                        style: const TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (aliments.isNotEmpty) ...[
                  _MacroChip(label: 'P', value: totalProt, pct: pctProt.round(), color: colorP),
                  const SizedBox(width: 6),
                  _MacroChip(label: 'L', value: totalLip, pct: pctLip.round(), color: colorL),
                  const SizedBox(width: 6),
                  _MacroChip(label: 'G', value: totalGluc, pct: pctGluc.round(), color: colorG),
                  const SizedBox(width: 6),
                ],
                if (repas != null)
                  GestureDetector(
                    onTap: () => _ouvrirListeAliments(repas),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF357E50),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 18),
                    ),
                  ),
              ],
            ),
          ),
          // Aliments de ce repas (animés)
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: ouvert && aliments.isNotEmpty
                ? Column(
                    children: [
                      const Divider(color: Color(0x18FFFFFF), height: 1),
                      ...aliments.map(_buildAlimentTile),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildAlimentTile(AlimentConsomme a) {
    return _SwipeableAlimentTile(
      key: ObjectKey(a),
      alimentConsomme: a,
      onDelete: () => _supprimerAliment(a),
      onModify: () => _modifierAliment(a),
      onUpdateQuantite: (q) => _mettreAJourQuantite(a, q),
    );
  }

  // UI
  @override
  Widget build(BuildContext context) {

    final double barWidth = (MediaQuery.of(context).size.width * 0.85).clamp(0.0, 420.0);
    final double separatorWidth = (0.5 * barWidth) - ajustBoutonWidth;

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
            SizedBox(height: topBarH + 20), // ← zone vide pour ne pas recouvrir la zone floutée
            
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
              barWidth: barWidth,
            ),        
            
            const SizedBox(height: 7),

            //BOUTONS D'AJUSTEMENT — masqués sur les jours passés
            if (!_estPasse) Column(
  children: [
    SizedBox(
      height: ajustBoutonheight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          // Bouton gauche (-) — actif seulement si débloqué
          SizedBox(
            width: ajustBoutonWidth, //(dashbarWidth - (separatorWidth) ) /2,
            child: GestureDetector(
              onTap: _ajustementDebloque ? _baisserCalories : null, // 👇 Personnalise ici le comportement du bouton -
              child: Container(
                decoration: BoxDecoration(
                  color: _ajustementDebloque
                      ? const Color.fromARGB(115, 43, 43, 43)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(ajustBoutonheight
                    // topLeft: Radius.circular(ajustBoutonheight),
                    // bottomLeft: Radius.circular(ajustBoutonheight),
                  ),
                  //border: Border.all(color: Colors.white, width: 1),
                ),
                child: Center(
                  child: Icon(
                    Icons.arrow_drop_down,
                    color: _ajustementDebloque ? Colors.white : Colors.transparent,
                  ),
                ),
              ),
            ),
          ),

          // Centre : "Ajuster les besoins" (bloqué) ou "Valider" (débloqué)
          SizedBox(
            width: separatorWidth,
            height: ajustBoutonheight,
            child: Center(
              child: _ajustementDebloque
                  ? GestureDetector(
                      onTap: () => setState(() => _ajustementDebloque = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF357E50),
                          borderRadius: BorderRadius.circular(ajustBoutonheight),
                        ),
                        child: Text(
                          "Valider",
                          style: TextStyle(
                            fontSize: ajustBoutonheight / 3,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: () => setState(() => _ajustementDebloque = true),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(115, 43, 43, 43),
                          borderRadius: BorderRadius.circular(ajustBoutonheight),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Ajuster les besoins",
                          style: TextStyle(
                            fontSize: ajustBoutonheight / 3,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
            ),
          ),

          // Bouton droit (+) — actif seulement si débloqué
          SizedBox(
            width: ajustBoutonWidth, //(dashbarWidth - separatorWidth) /2,
            child: GestureDetector(
              onTap: _ajustementDebloque ? _monterCalories : null, // 👇 Personnalise ici le comportement du bouton +
              child: Container(
                decoration: BoxDecoration(
                  color: _ajustementDebloque
                      ? const Color.fromARGB(115, 43, 43, 43)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(ajustBoutonheight
                    // topRight: Radius.circular(ajustBoutonheight),
                    // bottomRight: Radius.circular(ajustBoutonheight),
                  ),
                  //border: Border.all(color: Colors.white, width: 1),
                ),
                child: Center(
                  child: Icon(
                    Icons.arrow_drop_up,
                    color: _ajustementDebloque ? Colors.white : Colors.transparent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),

    // Bouton "Calcul automatique" — visible uniquement en mode débloqué
    if (_ajustementDebloque) ...[
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () {
          if (_userData != null) {
            _mettreAJourDonneesUtilisateur(_userData!);
          }
          setState(() => _ajustementDebloque = false);
        },
        child: Container(
          height: ajustBoutonheight,
          width: 2 * ajustBoutonWidth + separatorWidth,
          decoration: BoxDecoration(
            color: const Color.fromARGB(115, 43, 43, 43),
            borderRadius: BorderRadius.circular(ajustBoutonheight),
          ),
          alignment: Alignment.center,
          child: Text(
            "Calcul automatique",
            style: TextStyle(
              fontSize: ajustBoutonheight / 3,
              color: Colors.white54,
            ),
          ),
        ),
      ),
    ],
  ],
),

            const SizedBox(height: 2*gap/3),
            
            GroupeBarre(
              titre: "Protéines",
              valeurMin: protMin,
              valeurMax: protMax,
              compteurCalories: compteurProteines,
              barWidth: barWidth,
            ),
            const SizedBox(height: gap),

            GroupeBarre(
              titre: "Lipides",
              valeurMin: lipidesMin,
              valeurMax: lipidesMax,
              compteurCalories: compteurLipides,
              barWidth: barWidth,
            ),
            
            const SizedBox(height: gap),

            GroupeBarre(
              titre: "Glucides",
              valeurMin: glucidesMin,
              valeurMax: glucidesMax,
              compteurCalories: compteurGlucides,
              barWidth: barWidth,
            ),
            
            const SizedBox(height: gap),

            GroupeBarre(
              titre: "Fibres",
              valeurMin: fibresMin,
              valeurMax: fibresMax,
              compteurCalories: compteurFibres,
              barWidth: barWidth,
            ),

            // const SizedBox(height: gap),

            // Center(
            //   child : SizedBox(
            //   width: 50,
            //   height: 50,
            //   child: ElevatedButton(
            //     onPressed: _ouvrirListeAliments,
            //     style: ElevatedButton.styleFrom(
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(15), // optionnel : coins arrondis
            //       ),
            //       backgroundColor: Color(0xFF357E50), // couleur de fond optionnelle
            //       // elevation: 4, // ombre optionnelle
            //       padding: EdgeInsets.zero,
            //     ),
            //     child: const Center(
            //       child: Icon(
            //         Icons.add,
            //         color: Colors.black,
            //         size: 40,
            //       ),
            //     ),
            //   ),
            // ),

            const SizedBox(height: gap),
            
            // const SizedBox(height: 50),

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

            // Chaque repas a sa propre boîte (cf. _buildGroupedList)
            Center(
              child: Column(
                children: _buildGroupedList(),
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
                  color: Colors.black.withAlpha(0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Flèche jour précédent
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.chevron_left, color: Colors.white, size: 22),
                        onPressed: () => _selectionnerDate(
                          _dateSelectionnee.subtract(const Duration(days: 1))),
                      ),
                      const SizedBox(width: 16),
                      // Date — tap pour ouvrir le calendrier
                      GestureDetector(
                        onTap: _ouvrirCalendrier,
                        child: Text(
                          _estAujourdhui
                              ? "Aujourd’hui"
                              : _formatDateCourte(_dateSelectionnee),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Flèche jour suivant (grisée si aujourd’hui)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.chevron_right,
                            color: _estALimite ? Colors.white24 : Colors.white, size: 22),
                        onPressed: _estALimite
                            ? null
                            : () => _selectionnerDate(
                                _dateSelectionnee.add(const Duration(days: 1))),
                      ),
                    ],
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
        height: 62,
        padding: EdgeInsets.zero,
        color: Color(0xFF676464).withAlpha(150),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _NavItem(
              label: 'Profil',
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DonneesUtilisateurPage()),
                );
                if (result != null && result is UserModel) {
                  setState(() {
                    _userData = result;
                    _mettreAJourDonneesUtilisateur(_userData!);
                  });
                }
              },
              icon: const Icon(Icons.person, color: Colors.white, size: 22),
            ),

            _NavItem(
              label: 'Journal',
              icon: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 20, height: 3, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 4),
                  Container(width: 14, height: 3, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 4),
                  Container(width: 17, height: 3, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                ],
              ),
            ),

            _NavItem(
              label: '',
              onTap: _ouvrirChoixRepas,
              icon: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white, // Colors.black
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(Icons.add, color: Color(0xFF066A2D), size: 30), // size: 25
                ),
              ),
            ),

            _NavItem(
              label: 'Analytique',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StatsPage()),
              ),
              icon: const _PieChartIcon(),
            ),

            _NavItem(
              label: 'Guide',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GuidePage()),
              ),
              icon: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
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

// ── Item de navigation avec icône + label ────────────────────────────────────

class _NavItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onTap;

  const _NavItem({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: label.isEmpty ? 40 : 26, child: Center(child: icon)),
            if (label.isNotEmpty) const SizedBox(height: 2),
            if (label.isNotEmpty) Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 9,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Icône diagramme circulaire (stats) ───────────────────────────────────────

class _PieChartIcon extends StatelessWidget {
  const _PieChartIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(22, 22),
      painter: _PieChartPainter(),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final rect = Rect.fromCircle(center: c, radius: r);

    // Segment A — 55 % (blanc plein)
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * 0.55, true,
        Paint()..color = Colors.white);

    // Segment B — 28 % (blanc à 55 %)
    canvas.drawArc(rect, -math.pi / 2 + 2 * math.pi * 0.55, 2 * math.pi * 0.28, true,
        Paint()..color = Colors.white.withAlpha(140));

    // Segment C — 17 % (blanc à 28 %)
    canvas.drawArc(rect, -math.pi / 2 + 2 * math.pi * 0.83, 2 * math.pi * 0.17, true,
        Paint()..color = Colors.white.withAlpha(70));

    // Lignes de séparation dans la couleur du fond
    final sep = Paint()
      ..color = const Color(0xFF676464)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(c, c + Offset(0, -r), sep);

    final a1 = -math.pi / 2 + 2 * math.pi * 0.55;
    canvas.drawLine(c, c + Offset(r * math.cos(a1), r * math.sin(a1)), sep);

    final a2 = -math.pi / 2 + 2 * math.pi * 0.83;
    canvas.drawLine(c, c + Offset(r * math.cos(a2), r * math.sin(a2)), sep);
  }

  @override
  bool shouldRepaint(_PieChartPainter old) => false;
}

// ── Mini-chip de macronutriment pour l'en-tête de repas ──────────────────────

class _MacroChip extends StatelessWidget {
  final String label;
  final double value;
  final int pct;
  final Color color;

  const _MacroChip({required this.label, required this.value, required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(70), width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: '$label ',
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
              ),
              TextSpan(
                text: '$pct%',
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ]),
          ),
          Text(
            '${value.toStringAsFixed(0)}g',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Tuile d'aliment avec swipe gauche pour révéler le bouton de suppression ──

class _SwipeableAlimentTile extends StatefulWidget {
  final AlimentConsomme alimentConsomme;
  final VoidCallback onDelete;
  final VoidCallback onModify;
  final Function(double) onUpdateQuantite;

  const _SwipeableAlimentTile({
    super.key,
    required this.alimentConsomme,
    required this.onDelete,
    required this.onModify,
    required this.onUpdateQuantite,
  });

  @override
  State<_SwipeableAlimentTile> createState() => _SwipeableAlimentTileState();
}

class _SwipeableAlimentTileState extends State<_SwipeableAlimentTile>
    with SingleTickerProviderStateMixin {
  static const double _revealWidth = 64.0;

  late final AnimationController _ctrl;
  late Animation<double> _anim;
  double _offset = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _anim = Tween<double>(begin: 0, end: 0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _snapTo(double target) {
    _anim = Tween<double>(begin: _offset, end: target)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl
      ..value = 0
      ..forward();
    _anim.addListener(() {
      if (mounted) setState(() => _offset = _anim.value);
    });
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_ctrl.isAnimating) _ctrl.stop();
    setState(() {
      _offset = (_offset + d.delta.dx).clamp(-_revealWidth, 0);
    });
  }

  void _onDragEnd(DragEndDetails d) {
    final velocity = d.primaryVelocity ?? 0;
    final shouldOpen =
        velocity < -300 || (_offset < -_revealWidth / 2 && velocity <= 300);
    _snapTo(shouldOpen ? -_revealWidth : 0);
  }

  Widget _macroCell(String label, double? value, Color labelColor, double width, {bool isKcal = false}) {
    const fontSize = 11.0; // ← taille de la ligne macro
    final valStr = value?.toStringAsFixed(0) ?? '0';
    return SizedBox(
      width: width,
      child: RichText(
        text: TextSpan(children: isKcal
          ? [
              TextSpan(text: valStr, style: const TextStyle(color: Colors.grey, fontSize: fontSize, fontWeight: FontWeight.w500)),
              TextSpan(text: ' kcal', style: const TextStyle(color: Colors.grey, fontSize: fontSize, fontWeight: FontWeight.w400)),
            ]
          : [
              TextSpan(text: '$label ', style: TextStyle(color: labelColor, fontSize: fontSize, fontWeight: FontWeight.w700)),
              TextSpan(text: valStr, style: const TextStyle(color: Colors.grey, fontSize: fontSize, fontWeight: FontWeight.w500)),
              TextSpan(text: 'g', style: const TextStyle(color: Colors.grey, fontSize: fontSize, fontWeight: FontWeight.w400)),
            ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.alimentConsomme;
    final macros = a.aliment.getMacrosPourQuantite(a.quantite);

    return ClipRect(
      child: Stack(
        children: [
          // Zone de suppression (derrière la carte, côté droit)
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: widget.onDelete,
                child: Container(
                  width: _revealWidth,
                  color: const Color(0xFF4A4A4A),
                  child: const Icon(Icons.close, color: Colors.red, size: 20),
                ),
              ),
            ),
          ),
          // Carte principale (glissable)
          Transform.translate(
            offset: Offset(_offset, 0),
            child: GestureDetector(
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              child: Container(
                color: const Color(0xFF4A4A4A),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  titleAlignment: ListTileTitleAlignment.top,
                  title: Text(
                    a.aliment.nom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  subtitle: Transform.translate(
                    offset: const Offset(0, -4),
                    child: () {
                      const hue = 151.0;
                      const sat = 0.5;
                      final couleurP = HSLColor.fromAHSL(1.0, hue, sat, 0.80).toColor();
                      final couleurL = HSLColor.fromAHSL(1.0, hue, sat, 0.60).toColor();
                      final couleurG = HSLColor.fromAHSL(1.0, hue, sat, 0.40).toColor();
                      return Row(children: [
                        _macroCell('kcal', macros['calories'], Colors.white, 50, isKcal: true), //58
                        /*const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 0), //4
                          
                        ),*/
                        SizedBox(width:5),
                        Text('·', style: TextStyle(color: Colors.white38, fontSize: 30, height: 1)),
                        SizedBox(width:5),
                        _macroCell('P', macros['proteines'], couleurP, 35),
                        SizedBox(width:5),
                        Text('·', style: TextStyle(color: Colors.white38, fontSize: 30, height: 1)),
                        SizedBox(width:5),
                        _macroCell('L', macros['lipides'], couleurL, 35),
                        SizedBox(width:5),
                        Text('·', style: TextStyle(color: Colors.white38, fontSize: 30, height: 1)),
                        SizedBox(width:5),
                        _macroCell('G', macros['glucides'], couleurG, 35),
                        SizedBox(width:5),
                      ]);
                    }(),
                  ),
                  trailing: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    color: const Color(0xFF4A4A4A),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    onSelected: (value) {
                      if (value == 'custom') {
                        widget.onModify();
                      } else if (value == 'portion') {
                        widget.onUpdateQuantite(a.aliment.portions.first.poids);
                      } else {
                        widget.onUpdateQuantite(double.parse(value));
                      }
                    },
                    itemBuilder: (context) => [
                      if (a.aliment.portions.isNotEmpty) ...[
                        () {
                          final p = a.aliment.portions.first;
                          return PopupMenuItem<String>(
                            value: 'portion',
                            child: Text(
                              p.nom.isNotEmpty
                                  ? '${p.nom} (${p.poids.toStringAsFixed(0)} g)'
                                  : '${p.poids.toStringAsFixed(0)} g',
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }(),
                        const PopupMenuDivider(),
                      ],
                      const PopupMenuItem(value: '5',   child: Text('5 g',   style: TextStyle(color: Colors.white))),
                      const PopupMenuItem(value: '10',  child: Text('10 g',  style: TextStyle(color: Colors.white))),
                      const PopupMenuItem(value: '20',  child: Text('20 g',  style: TextStyle(color: Colors.white))),
                      const PopupMenuItem(value: '50',  child: Text('50 g',  style: TextStyle(color: Colors.white))),
                      const PopupMenuItem(value: '100', child: Text('100 g', style: TextStyle(color: Colors.white))),
                      const PopupMenuItem(value: '150', child: Text('150 g', style: TextStyle(color: Colors.white))),
                      const PopupMenuItem(value: 'custom', child: Icon(Icons.edit, color: Colors.white, size: 18)),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A4A4A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF357E50)),
                      ),
                      child: Text(
                        '${a.quantite.toStringAsFixed(0)} g',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
