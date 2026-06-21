//import 'package:cal_track_v1/Pages/loading_screen.dart';
import 'package:cal_track_v1/Pages/splash_transition.dart';
import 'package:cal_track_v1/Pages/tableaudebord.dart';
import 'package:cal_track_v1/models/user_data.dart';
import 'package:cal_track_v1/services/local_storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:cal_track_v1/models/user_data.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'inscription_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ConnexionPage extends StatefulWidget {
  const ConnexionPage({super.key});

  @override
  State<ConnexionPage> createState() => _ConnexionPageState();
}

class _ConnexionPageState extends State<ConnexionPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  TextEditingController? _autocompleteEmailController;

  List<String> _savedEmails = [];

  String? _errorMessage;
  bool _obscurePassword = true; // état initial
  
  Future<void> saveUserDataLocally(UserModel user) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;
  await LocalStorageService.saveUserData(userId, user);
  }


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
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return null;

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
    
    _loadSavedEmails();    
  }
  
  // SIGN IN
  Future<void> _resetPassword() async {
    final email = (_autocompleteEmailController?.text ?? _emailController.text).trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = "Entrez votre email pour réinitialiser le mot de passe.");
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF393939),
          title: const Text("Email envoyé", style: TextStyle(color: Colors.white)),
          content: const Text(
            "Si un compte est associé à cette adresse, un email de réinitialisation vient d'être envoyé. Pensez à vérifier vos spam.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK", style: TextStyle(color: Color(0xFF357E50))),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (_) {
      setState(() => _errorMessage = "Erreur lors de l'envoi. Réessayez dans quelques instants.");
    }
  }

  Future<void> _signIn() async {
    setState(() => _errorMessage = null);
    try {
      final emailValue = (_autocompleteEmailController?.text ?? _emailController.text).trim();
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailValue,
        password: _passwordController.text.trim(),
      );

      await _saveEmail(emailValue); // Sauvegarder l'email

      final userData = await fetchUserData();

      if (!mounted) return;
      
      if (userData != null) {
        await saveUserDataLocally(userData); // ⬅️ Ajoutez ceci
      // Passe userData à la page TableauDeBord      
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SplashTransition(destination: TableauDeBord())),
      );
      } else {
      setState(() {
        _errorMessage = "Impossible de récupérer les données utilisateur.";
      });
    }

    } on FirebaseAuthException catch (e) {
      final String message;
      switch (e.code) {
        case 'user-not-found':
          message = "Aucun profil trouvé pour cette adresse. Vérifiez l'orthographe ou créez un nouveau compte.";
          break;
        case 'wrong-password':
          message = "mot de passe incorrect";
          break;
        case 'invalid-email':
          message = "Adresse email invalide.";
          break;
        default:
          message = 'email ou mot de passe incorrect';
      }
      setState(() => _errorMessage = message);
    }
  }

  Future<void> _loadSavedEmails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedEmails = prefs.getStringList('emails') ?? [];
    });
  }

  Future<void> _saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    if (!_savedEmails.contains(email)) {
      _savedEmails.add(email);
      await prefs.setStringList('emails', _savedEmails);
    }
  }

final double fieldHeight = 40;
static const double gap = 15;
static const double arrondi = 10;

final _passwordFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final double fieldWidth = MediaQuery.of(context).size.width * 0.85;
    return Scaffold(
      backgroundColor: const Color(0xFF393939), // Couleur de fond personnalisée
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'forkshot',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                
                const SizedBox(height: 25),
                
                //CHAMPS EMAIL
                Center(                   
                  child : SizedBox( 
                    width: fieldWidth,
                    height: fieldHeight,
                    child: Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return _savedEmails;
                        }

                        return _savedEmails.where((email) => email
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()));
                      },
                      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                        _autocompleteEmailController = controller;

                    return TextField(
                      textAlignVertical: TextAlignVertical.center,
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () {
                    focusNode.unfocus();
                    FocusScope.of(context).requestFocus(_passwordFocusNode);
                  },           
                                    
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                    filled: true,
                    fillColor: Color(0x0CFFFFFF),
                    labelText: 'votre@email.com',
                    labelStyle: const TextStyle(
                      color: Color(0x4CFFFFFF)), // Couleur du label quand le champ est **inactif**
                    floatingLabelStyle: const TextStyle(
                      color: Colors.white, // Couleur du label quand le champ est **focus**
                    ),
                    
                    prefixIcon: const Icon(Icons.email, color: Color(0x80000000)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(arrondi),
                      borderSide: const BorderSide(color: Color(0xFF357E50), width: 2), // couleur personnalisée
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(arrondi),
                        borderSide: BorderSide.none,
                        ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(arrondi),
                              borderSide: const BorderSide(color: Color(0xFF357E50), width: 2),
                              ),                      
                  ),
                  style: const TextStyle(color: Colors.white), // texte en blanc
                    );
                      },
                  onSelected: (String selection) {
                        // L'Autocomplete met à jour son controller automatiquement
                      },
                  
                  optionsViewBuilder: (context, onSelected, options) {
                    return ClipRRect(
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                      child: Material(                        
                          color: Colors.grey[700],
                                                    
                        
                        child: ListView(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          children: options.map((option) {
                            return ListTile(
                              title: Text(option, style: TextStyle(color: Colors.white)),
                              onTap: () => onSelected(option),
                            );
                          }).toList(),
                      ),
                      ),                    
                    );
                  },
                    )
                    )
                ),                
                

                const SizedBox(height: gap),
                
                //CHAMPS MDP
                Center( 
                  child: SizedBox( 
                    width: fieldWidth,
                    height: fieldHeight,
                    
                    child: TextField(
                      textAlignVertical: TextAlignVertical.center,
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      
                      onEditingComplete: _signIn,

                      obscureText: _obscurePassword, // 👈 lié à ton booléen

                      textInputAction: TextInputAction.done, // <-- permet d’afficher "Entrée/Done"
                      onSubmitted: (_) => _signIn(),         // <-- déclenche la connexion quand on appuie sur Entrée
                  
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                    filled: true,
                    fillColor: Color(0x0CFFFFFF),
                    labelText: 'motdepasse',
                    
                    labelStyle: const TextStyle(
                      color: Color(0x4CFFFFFF), // Couleur du label quand le champ est **inactif**
                    ),
                    floatingLabelStyle: const TextStyle(
                      color: Colors.white, // Couleur du label quand le champ est **focus**
                    ),
                    prefixIcon: const Icon(Icons.lock, color: Color(0x80000000)),

                    // 👇 Ajout de l’icône œil
                    suffixIcon: Listener(
                      
                      onPointerDown: (_) {
                        setState(() => _obscurePassword = false); // quand on appuie
                      },
                      
                      onPointerUp: (_) {
                        setState(() => _obscurePassword = true);  // quand on relâche
                      },
                      
                      child: Padding(
                        padding: EdgeInsets.all(12), // espace autour de l'icône
                        
                        child:
                        _obscurePassword 
                        
                        ? ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: fieldHeight * 0.25,                            
                          ), 
                          
                          child: SvgPicture.asset('assets/images/icon-oeil-ouvert.svg',
                          colorFilter: ColorFilter.mode(Colors.grey,
                          BlendMode.srcIn,
                          ),
                          )
                        )
                        
                        : ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: fieldHeight * 0.5,                            
                          ), 
                          
                          child: SvgPicture.asset('assets/images/icon-oeil-ferme.svg',
                          colorFilter: ColorFilter.mode(Colors.grey,
                          BlendMode.srcIn,
                          ),
                          )
                        )
                      
                    ),
                    ),
                    
                    
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(arrondi),
                      borderSide: const BorderSide(color: Color(0xFF357E50), width: 2), // couleur personnalisée                    
                    ),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(arrondi),
                        borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(arrondi),
                        borderSide: const BorderSide(color: Color(0xFF357E50), width: 2),
                    ),
                  ),
                    style: const TextStyle(color: Colors.white), // texte en blanc
                ),
                  ),
                ),
                
                const SizedBox(height: gap),
                
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
    
                
                // SE CONNECTER
                Center(
                  child : SizedBox(
                    width: fieldWidth,
                    height: fieldHeight,
                  child : ElevatedButton(

                  onPressed: _signIn,

                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 0),
                    backgroundColor: Color(0xFF357E50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(arrondi)),
                  ),
                  child: const Text(
                    'Se connecter',
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
                  ),
                ),
                
                // Mot de passe oublié
                TextButton(
                  onPressed: _resetPassword,
                  child: const Text(
                    "Mot de passe oublié ?",
                    style: TextStyle(color: Color(0xFF357E50), fontSize: 13),
                  ),
                ),

                const SizedBox(height: 10),

                //OU
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.85,
                  child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    
                    Expanded(
                      child: 
                    Container(
                      height: 1, // épaisseur de la ligne
                      color: Colors.white,
                    ),
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child:  Text('ou', style: TextStyle(color: Color(0xFF828282)),
                    ),
                    ),
                    
                    Expanded(
                      child: Container(
                      height: 1, // épaisseur de la ligne
                      color: Colors.white,
                    ),
                    ),

                  ]
                ),
                ),

                const SizedBox(height: 25),

                // PAS ENCORE DE COMPTE
                Center(
                  child: SizedBox(
                    width: fieldWidth,
                    height: fieldHeight,

                    child:
                    //const Text("Pas encore de compte ?"),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const InscriptionPage()),
                        );
                      },

                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 0),
                        backgroundColor: (Colors.black),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(arrondi)),
                      
                      ),                        
                      
                      child: const Text("Créer votre compte",
                      style: TextStyle(color: Colors.white)
                    
                    ),
                     
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
