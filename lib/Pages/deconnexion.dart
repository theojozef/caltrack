import 'package:cal_track_v1/Pages/connexion_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LogoutPage extends StatefulWidget {
  const LogoutPage({super.key});

  @override
  State<LogoutPage> createState() => _LogoutPageState();
}

class _LogoutPageState extends State<LogoutPage> {
  
    User? currentUser;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users') // Collection où sont stockées les données utilisateurs
          .doc(currentUser!.uid)
          .get();

      if (userDoc.exists) {
        userData = userDoc.data() as Map<String, dynamic>;
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  
  
  
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ConnexionPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF393939),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    
    
    return Scaffold(
      backgroundColor: const Color(0xFF393939),
      body: Center(
        child: 
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (userData != null) ...[
              Text('${userData!['prenom'] ?? "Non renseigné"}',
                  style: const TextStyle(color: Colors.white, fontSize: 18)),

              const SizedBox(height: 30),

              Text('Taille: ${userData!['Taille'] ?? "Non renseigné"} cm',
                  style: const TextStyle(color: Colors.white, fontSize: 18)),
              Text('Poids: ${userData!['Poids'] ?? "Non renseigné"} kg',
                  style: const TextStyle(color: Colors.white, fontSize: 18)),
              Text('Âge: ${userData!['Âge'] ?? "Non renseigné"} ans',
                  style: const TextStyle(color: Colors.white, fontSize: 18)),
              Text('Niveau d\'activité physique: ${userData!['Niveau d\'activité physique'] ?? "Non renseigné"}',
                  style: const TextStyle(color: Colors.white, fontSize: 18)),
              Text('Type d\'activité physique: ${userData!['Type d\'activité physique'] ?? "Non renseigné"}',
                  style: const TextStyle(color: Colors.white, fontSize: 18)),
              Text('Objectif: ${userData!['Objectif'] ?? "Non renseigné"}',
                  style: const TextStyle(color: Colors.white, fontSize: 18)),

              const SizedBox(height: 30),
            ] else
              const Text(
                'Aucune donnée utilisateur trouvée.',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
        
        
        TextButton(
          onPressed: signOut,
          style: TextButton.styleFrom(
            //foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 18),
             splashFactory: NoSplash.splashFactory,
             overlayColor: Colors.transparent,
          ),
          child: const Text('Se déconnecter',
          style: TextStyle(color: Colors.red)
          ),
        ),
          ]
        ),
      ),
    );
  }
}
