//import 'package:cal_track_v1/Pages/loading_screen.dart';
import 'package:cal_track_v1/Pages/tableaudebord.dart';
import 'package:cal_track_v1/models/user_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:cal_track_v1/models/user_data.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'inscription_page.dart';

class ConnexionPage extends StatefulWidget {
  const ConnexionPage({super.key});

  @override
  State<ConnexionPage> createState() => _ConnexionPageState();
}

class _ConnexionPageState extends State<ConnexionPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;







/*Future<void> _chargerDonnees() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final doc = await FirebaseFirestore.instance
  .collection('users')
  .doc(uid)
  .get();
  
  if (doc.exists) {
    final data = doc.data()!;
    setState(() {
      _poids = (data['Poids'] ?? 72);
      _taille= (data['Taille'] ?? 180);
      _age = (data['Âge'] ?? 27);
      _sexe = data['Sexe'] ?? 'homme';
      _niveauActivite = data['Niveau d\'activité physique'] ?? 'actif';
      _sport = data['Type d\'activité physique'] ?? 'force';
      _objectif = data['Objectif'] ?? 'maintien';
      //_isLoading = false;
    });
  } else {
    setState(() => _charge = false);
  }
}*/


Future<UserModel?> fetchUserData() async {
  final userId = FirebaseAuth.instance.currentUser!.uid;

  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .get();

  if (userDoc.exists) {
    final data = userDoc.data()!;
    return UserModel.fromJson(data);
  }
  return null;
}

  
  
  
  
  
  
  
  @override
  void initState() {
    super.initState();

    // Redirige automatiquement si l'utilisateur est déjà connecté
    if (FirebaseAuth.instance.currentUser != null) {
      
      Future.microtask(() {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TableauDeBord()),
        );
      });
    }
  }
  
  // SIGN IN
  Future<void> _signIn() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final userData = await fetchUserData();

      if (!mounted) return;
      
      if (userData != null) {
      // Passe userData à la page TableauDeBord      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => TableauDeBord()),
      );
} else {
      setState(() {
        _errorMessage = "Impossible de récupérer les données utilisateur.";
      });
    }

    } on FirebaseAuthException catch (e) {
      
      setState(() {
          switch (e.code) {
    case 'user-not-found':
      _errorMessage = "Aucun compte trouvé avec cet email.";
      break;
    case 'wrong-password':
      _errorMessage = "Mot de passe incorrect.";
      break;
    case 'invalid-email':
      _errorMessage = "Adresse email invalide.";
      break;
    default:
      _errorMessage = e.message ?? 'Une erreur est survenue.';
  }
      });
    }
  }

final double fieldWidth = 300; 
static const double gap = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF393939), // Couleur de fond personnalisée
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            width: fieldWidth,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: const Color(0xFF393939),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Connexion',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                
                const SizedBox(height: gap),
                
                Center(                   
                  child : SizedBox( 
                    width: fieldWidth,
                    child: TextField(
                  controller: _emailController,
                  cursorColor: Color(0xFF357E50), // couleur du curseur
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: const TextStyle(
                      color: Color(0x4CFFFFFF)), // Couleur du label quand le champ est **inactif**
                    floatingLabelStyle: const TextStyle(
                      color: Colors.white, // Couleur du label quand le champ est **focus**
                    ),
                    
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF357E50), width: 2), // couleur personnalisée
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade600),
                        ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF357E50), width: 2),
                              ),                      
                  ),
                  style: const TextStyle(color: Colors.white), // texte en blanc

                ),
                  ),
                ),

                const SizedBox(height: 16),
                
                Center( 
                  child: SizedBox( 
                    width: fieldWidth,
                    child: TextField(
                  controller: _passwordController,
                  cursorColor: Color(0xFF357E50), // couleur du curseur
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    labelStyle: const TextStyle(
                      color: Color(0x4CFFFFFF), // Couleur du label quand le champ est **inactif**
                    ),
                    floatingLabelStyle: const TextStyle(
                      color: Colors.white, // Couleur du label quand le champ est **focus**
                    ),
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF357E50), width: 2), // couleur personnalisée                    
                    ),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade600),
                    ),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF357E50), width: 2),
                    ),
                  ),
                    style: const TextStyle(color: Colors.white), // texte en blanc
                ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                
                // SE CONNECTER
                Center( 
                  child : SizedBox( 
                  child : ElevatedButton(
                  onPressed: _signIn,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    backgroundColor: Color(0xFF357E50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Se connecter',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // PAS ENCORE DE COMPTE
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    //const Text("Pas encore de compte ?"),
                    
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const InscriptionPage()),
                        );
                      },
                      style: TextButton.styleFrom(
                        textStyle: const TextStyle(),
                        splashFactory: NoSplash.splashFactory,
                        overlayColor: Colors.transparent
                        ),
                    child: const Text("Créer un compte",
                    style: TextStyle(color: Colors.white)
                    
                    ),
                     
                    ),
                  ],
                ),
                  
                

              ],
            ),
          ),
        ),
      ),
    );
  }
}
