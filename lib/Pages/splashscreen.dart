// import 'package:cal_track_v1/Pages/connexion_page.dart';
import 'package:cal_track_v1/Pages/donnees_utilisateur.dart';
import 'package:cal_track_v1/Pages/splash_transition.dart';
import 'package:cal_track_v1/Pages/tableaudebord.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // plus utilisé dans la logique simplifiée
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:cal_track_v1/services/local_storage_service.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SplashTransition(
      resolver: () async {
        // Délai minimal pour que l'écran de splash soit visible
        await Future.delayed(const Duration(milliseconds: 1500));

        // Guest-first : pas de vérification Firebase.
        // Si un profil local existe (guest ou compte) → tableau de bord.
        // Sinon → saisie du profil (première ouverture).
        final userId = await LocalStorageService.getCurrentUserId();
        final localUser = await LocalStorageService.loadUserData(userId);

        // On stocke la destination sans naviguer : c'est _checkForExit() dans
        // SplashTransition qui déclenchera la navigation quand le curseur
        // repassera à 50% en phase retour.
        return localUser != null
            ? const TableauDeBord()
            : const DonneesUtilisateurPage(fromInscription: true);

        // --- Ancienne logique (conservée pour référence) ---
        // final user = FirebaseAuth.instance.currentUser;
        // return user == null ? const ConnexionPage() : const TableauDeBord();
        // try {
        //   final prefs = await SharedPreferences.getInstance();
        //   final caloriesMin = prefs.getInt('caloriesMin');   // ancienne clé, obsolète
        //   final caloriesMax = prefs.getInt('caloriesMax');
        //   final alimentsDuJour = prefs.getStringList('alimentsDuJour') ?? [];
        //   if (caloriesMin == null || caloriesMax == null || alimentsDuJour.isEmpty) {
        //     final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        //     if (!doc.exists) { FirebaseAuth.instance.signOut(); _goTo(const ConnexionPage()); return; }
        //     ...
        //   }
        //   _goTo(const TableauDeBord());
        // } catch (e) {
        //   FirebaseAuth.instance.signOut();
        //   _goTo(const ConnexionPage());
        // }
      },
    );
  }
}
