import 'dart:ui';

import 'package:cal_track_v1/Pages/connexion_page.dart';
import 'package:cal_track_v1/Pages/tableaudebord.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cal_track_v1/models/user_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cal_track_v1/services/local_storage_service.dart';

class DonneesUtilisateurPage extends StatefulWidget {
  
  final bool fromInscription;
  const DonneesUtilisateurPage({super.key, this.fromInscription = false});

  @override
  State<DonneesUtilisateurPage> createState() => _DonneesUtilisateurPageState();
}

class _DonneesUtilisateurPageState extends State<DonneesUtilisateurPage> {
  final _formKey = GlobalKey<FormState>();
  final _poidsController = TextEditingController(); //(text: "75");
  final _tailleController = TextEditingController(); //(text: "180");
  final _ageController = TextEditingController(); //(text: "27");
  
  String? _sexe; // = 'homme';
  String? _niveauActivite; // = 'actif'; // état local
  String? _sport; // = 'force';
  String? _objectif;

  bool _isLoading = true;

UserModel? _enregistrerDonnees() {
  double poids = double.tryParse(_poidsController.text) ?? 0;
  double taille = double.tryParse(_tailleController.text) ?? 0;
  int age = int.tryParse(_ageController.text) ?? 0;

  return UserModel(
    poids: poids,
    taille: taille,
    age: age,
    sexe: _sexe ?? 'homme',
    nActivite: _niveauActivite ?? 'actif',
    typeSport: _sport ?? 'loisir',
    objectif: _objectif ?? 'maintien',
  );  
}


@override
void initState() {
  super.initState();
  _loadUserData();
}

Future<void> _loadUserData() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  // 1. LocalStorageService (même source que tableaudebord)
  final localUser = await LocalStorageService.loadUserData(uid);
  if (localUser != null) {
    setState(() {
      _poidsController.text = localUser.poids.toString();
      _tailleController.text = localUser.taille.toString();
      _ageController.text = localUser.age.toString();
      _sexe = localUser.sexe;
      _niveauActivite = localUser.nActivite;
      _sport = localUser.typeSport;
      _objectif = localUser.objectif;
      _isLoading = false;
    });
    return;
  }

  // 2. Fallback : clés plates (ancienne version)
  final prefs = await SharedPreferences.getInstance();
  // Essaie de charger les données localement d'abord
  final poidsLocal = prefs.getDouble('${uid}_poids');
  final tailleLocal = prefs.getDouble('${uid}_taille');
  final ageLocal = prefs.getInt('${uid}_age');
  final sexeLocal = prefs.getString('${uid}_sexe');
  final niveauActiviteLocal = prefs.getString('${uid}_niveauActivite');
  final sportLocal = prefs.getString('${uid}_sport');
  final objectifLocal = prefs.getString('${uid}_objectif');

  if (poidsLocal != null &&
      tailleLocal != null &&
      ageLocal != null &&
      sexeLocal != null &&
      niveauActiviteLocal != null &&
      sportLocal != null &&
      objectifLocal != null) {
    // Données locales présentes -> utiliser celles-ci
    setState(() {
      _poidsController.text = poidsLocal.toString();
      _tailleController.text = tailleLocal.toString();
      _ageController.text = ageLocal.toString();
      _sexe = sexeLocal;
      _niveauActivite = niveauActiviteLocal;
      _sport = sportLocal;
      _objectif = objectifLocal;
      _isLoading = false;
    });
    return; // On s’arrête ici car on a les données locales
  }

  // 3. Sinon on charge depuis Firestore
  final doc = await FirebaseFirestore.instance
  .collection('users')
  .doc(uid)
  .get();
  
  if (doc.exists) {
    final data = doc.data()!;
    setState(() {
      _poidsController.text = data['Poids'] != null ? data['Poids'].toString() : '';
      _tailleController.text = data['Taille'] != null ? data['Taille'].toString() : '';
      _ageController.text = data['Âge'] != null ? data['Âge'].toString() : '';
      _sexe = data['Sexe']; // ?? 'homme';
      _niveauActivite = data['Niveau d\'activité physique']; // ?? 'actif';
      _sport = data['Type d\'activité physique']; // ?? 'force';
      _objectif = data['Objectif']; // ?? 'maintien';
      _isLoading = false;
    });
  } else {
    setState(() => _isLoading = false);
  }
}


  bool _isSaving = false;
  String? _errorMessage;

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF393939),
        title: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
        content: const Text('Voulez-vous vraiment vous déconnecter ?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Se déconnecter', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ConnexionPage()),
    );
  }

  @override
  void dispose() {
    _poidsController.dispose();
    _tailleController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  double _calculIMC() {
    final poids = double.tryParse(_poidsController.text) ?? 0;
    final taille = double.tryParse(_tailleController.text) ?? 0;
    if (taille == 0) return 0;
    final tailleM = taille / 100;
    return poids / (tailleM * tailleM);
  }

  Future<void> _verifierAlerte() async {
    final imc = _calculIMC();
    if (imc > 0 && imc < 18.5 && _objectif == 'déficit') {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const _AlertePreventionDialog(),
      );
    }
  }

  Future<void> _saveUserData() async {
    
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() => _errorMessage = "Utilisateur non connecté.");
        return;
      }

      final utilisateur = _enregistrerDonnees();
      if (utilisateur == null) {
        setState(() => _errorMessage = "Erreur : données invalides.");
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'Poids': utilisateur.poids,
        'Taille': utilisateur.taille,
        'Âge': utilisateur.age,
        'Sexe': utilisateur.sexe,
        'Niveau d\'activité physique': _niveauActivite,
        'Type d\'activité physique' : _sport,
        'Objectif' : _objectif,      
      });

      // Sauvegarde locale dans SharedPreferences
      // Clés avec underscore + minuscule pour correspondre à _loadUserData()
      final prefs = await SharedPreferences.getInstance();
      //final uid = FirebaseAuth.instance.currentUser!.uid;
      await prefs.setDouble('${uid}_poids', utilisateur.poids);
      await prefs.setDouble('${uid}_taille', utilisateur.taille);
      await prefs.setInt('${uid}_age', utilisateur.age);
      await prefs.setString('${uid}_sexe', utilisateur.sexe);
      await prefs.setString('${uid}_niveauActivite', _niveauActivite ?? '');
      await prefs.setString('${uid}_sport', _sport ?? '');
      await prefs.setString('${uid}_objectif', _objectif ?? '');

      // Mise à jour de userData_$userId pour rester synchronisé avec tableaudebord
      await LocalStorageService.saveUserData(uid, utilisateur);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Données enregistrées avec succès")),
      );

      // Vérification préventive avant de naviguer
      await _verifierAlerte();
      if (!mounted) return;

      // 🔁 Redirection selon contexte
      if (widget.fromInscription) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TableauDeBord()),
          );
      } else {
        // Retourner les données à la page précédente
        Navigator.pop(context, _enregistrerDonnees());
      }
   
    } catch (e) {
      setState(() => _errorMessage = "Erreur lors de l'enregistrement");
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  static const double gap = 20;
  static const double paddingH = 20;
  static const double pctScreen = 0.10;
  double saveHeight = 50;


  @override
  Widget build(BuildContext context) {
  final double fieldWidth = MediaQuery.of(context).size.width * 0.85;

  if (_isLoading) {
  return const Scaffold(
    body: Center(child: CircularProgressIndicator(color: Color(0xFF357E50))
    ),
    );
  }

return Theme(
    data: Theme.of(context).copyWith(
      /*primaryColor: Colors.amberAccent, // couleur du curseur et ligne active
      colorScheme: Theme.of(context).colorScheme.copyWith(
        primary: Color(0xFF357E50), // couleur active des éléments
        secondary: Color(0xFF357E50),
      ),*/
      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF357E50), width: 2),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        labelStyle: TextStyle(color: Colors.deepOrange),        
      ),
      scaffoldBackgroundColor: Color(0xFF393939), // fond de la page
      textTheme: Theme.of(context).textTheme.copyWith(
        bodyMedium: TextStyle(color: Colors.white),  // pour le texte saisi dans TextFormField
      ),
      highlightColor: Color(0xF0284834),
    ),

child: PopScope(
  canPop: !widget.fromInscription,
  onPopInvokedWithResult: (didPop, result) {
    if (!didPop && widget.fromInscription) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez d'abord compléter vos données.")),
      );
    }
  },

    child: Scaffold(
      backgroundColor: const Color(0xFF393939),     
      
      body: SafeArea(

     
        
      child: Stack( //Stack
            children: [

              /* Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
              icon: const Icon(Icons.chevron_left, 
              color: Colors.white,
              size: 30),
              onPressed: () {
                Navigator.pop(context);
              },
            ),    

               Text("Mon profil"),
              ],
              ), */

              // Contenu scrollable
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: paddingH),// pour ne pas cacher le contenu
        
        child: Form(
          key: _formKey,
          
          child: ListView(
            physics: BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16), //16
            children: [
              
              SizedBox(height: MediaQuery.of(context).size.height * pctScreen),

              const SizedBox(height: gap),
              Row(
                children: [
                  const Icon(Icons.account_circle, color: Colors.white70, size: 32),
                  const SizedBox(width: 10),
                  Text(
                    FirebaseAuth.instance.currentUser?.displayName ?? '',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: gap),

              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),

              // champs poids
              Center(
                child: SizedBox(
                width: fieldWidth,
              child: TextFormField(
                controller: _poidsController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Poids (kg)',
                  labelStyle: TextStyle(fontSize: 16, color: const Color(0xFFFFFFFF))),

                keyboardType: TextInputType.number,
                validator: (value) {
                  final v = double.tryParse(value ?? '');
                  if (v == null) return 'Champ requis';
                  if (v < 30 || v > 300) return 'Valeur entre 30 et 300 kg';
                  return null;
                },
              ),
              ),
              ),
              const SizedBox(height: gap),
              
              // champs taille
              Center(
                child: SizedBox(
                width: fieldWidth,
                child: TextFormField(
                controller: _tailleController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Taille (cm)',
                  labelStyle: TextStyle(fontSize: 16, color: const Color(0xFFFFFFFF))),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final v = double.tryParse(value ?? '');
                  if (v == null) return 'Champ requis';
                  if (v < 100 || v > 250) return 'Valeur entre 100 et 250 cm';
                  return null;
                },
              ),
              ),
              ),
              const SizedBox(height: gap),
              
              // champs age
              Center(
                child: SizedBox(
                width: fieldWidth,
                
                child: TextFormField(
                controller: _ageController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Âge',
                  labelStyle: TextStyle(fontSize: 16, color: const Color(0xFFFFFFFF))),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final v = int.tryParse(value ?? '');
                  if (v == null) return 'Champ requis';
                  if (v < 10 || v > 100) return 'Valeur entre 10 et 100 ans';
                  return null;
                },
              ),
              ),
              ),
              const SizedBox(height: gap),
              
              // menu déroulant sexe
              Center( 
                child: SizedBox(
                width: fieldWidth,
                
                child: DropdownButtonFormField<String>(
                value: _sexe,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Sexe',
                  labelStyle: TextStyle(fontSize: 16, color: const Color(0xFFFFFFFF))),
                dropdownColor: Colors.grey[900],
                items: const [
                  DropdownMenuItem(value: 'homme', child: Text('Homme')),
                  DropdownMenuItem(value: 'femme', child: Text('Femme')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _sexe = value;
                    });
                  }
                },
              ),
              ),
              ),
              const SizedBox(height: gap),

              // menu déroulant niveau activité
              Center( 
                child: SizedBox(
                width: fieldWidth,
                child: DropdownButtonFormField<String>(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Niveau d\'activité physique',
                  labelStyle: TextStyle(fontSize: 16, color: const Color(0xFFFFFFFF))),
                dropdownColor: Colors.grey[900],
                value: _niveauActivite,
                onChanged: (value) {
                  setState(() {
                    _niveauActivite = value!;
                  });
                },
                
                items: const [
                  DropdownMenuItem(value: 'sédentaire', child: Text('Sédentaire')),
                  DropdownMenuItem(value: 'modéré', child: Text('Modéré')),
                  DropdownMenuItem(value: 'actif', child: Text('Actif')),
                  DropdownMenuItem(value: 'très actif', child: Text('Très actif')),
                  DropdownMenuItem(value: 'extrêmement actif', child: Text('Extrêmement actif')),
                ],
              ),
              ),
              ),
              const SizedBox(height: gap),

              // menu déroulant type de sport
              Center( 
                child: SizedBox(
                width: fieldWidth,
                child: DropdownButtonFormField<String>(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Type d\'activité physique',
                  labelStyle: TextStyle(fontSize: 16, color: const Color(0xFFFFFFFF))),
                dropdownColor: Colors.grey[900],
                value: _sport,
                onChanged: (value) {
                  setState(() {
                    _sport = value!;
                  });
                },
                
                items: const [
                  DropdownMenuItem(value: 'pas', child: Text('Pas ou peu de sport')),
                  DropdownMenuItem(value: 'loisir', child: Text('Sport de loisir')),
                  DropdownMenuItem(value: 'endurance', child: Text('Sport d\'endurance')),
                  DropdownMenuItem(value: 'force', child: Text('Sport de force')),
                ],
              ),
              ),
              ),
              
              const SizedBox(height: gap * 2),

              // menu déroulant objectif
              Center(
                child: SizedBox(
                width: fieldWidth,
                child: DropdownButtonFormField<String>(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Objectif',
                  labelStyle: TextStyle(fontSize: 16, color: const Color(0xFFFFFFFF)),
                  ),
                dropdownColor: Colors.grey[900],
                  
                                                                    
                value: _objectif,
                onChanged: (value) {
                  setState(() {
                    _objectif = value!;
                  });
                },
                
                items: const [
                  DropdownMenuItem(value: 'déficit', child: Text('Perdre du poids')),
                  DropdownMenuItem(value: 'maintien', child: Text('Maintenir mon poids')),
                  DropdownMenuItem(value: 'pdm', child: Text('Prendre du poids')),
                ],
              ),
              ),
              ),
              
              // SizedBox(height: saveHeight + (4*paddingH)),
              SizedBox(height: saveHeight + 2*paddingH),

              
              

            ],
          ),
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
                  height: MediaQuery.of(context).size.height * pctScreen,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  alignment: Alignment.bottomCenter,
                  color: const Color(0xFF393939),
                  child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    IconButton(
                      icon: const Icon(Icons.chevron_left, 
                      color: Colors.white, size: 30),
                      
                      onPressed: () {
                        Navigator.pop(context);
                        },
                    ),

                    const Text(
                    "Mon profil",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white,
                    ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.red, size: 24),
                      onPressed: _signOut,
                      tooltip: 'Se déconnecter',
                    ),

                  ],
                  ),
                  
                  
                  

                  
                ),
              ),
            ),
          ),
          


      // BOUTON ENREGISTRER
      Align(
      alignment: Alignment.bottomCenter,
      child: ClipRect(
        child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Padding(
          padding: const EdgeInsets.all(paddingH),
          child: SizedBox(
                width: fieldWidth,
                height: saveHeight,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveUserData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF357E50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isSaving
                    ? const CircularProgressIndicator(color: Color(0xFF357E50))
                    : const Text("Enregistrer", style: TextStyle(color: Colors.white)),
                ),
              ),
        ),
      ),
              ),
      ),

              // const SizedBox(height: 40),
            
            
            
            
            ],
    ),
    
      ),
      ),
),

    );

  }
}

class _AlertePreventionDialog extends StatelessWidget {
  const _AlertePreventionDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2C2C2C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 26),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Information santé',
              style: TextStyle(color: Colors.white, fontSize: 17),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'D\'après les informations que vous avez renseignées, votre indice de masse corporelle (IMC) indique que vous êtes actuellement en sous-poids. Dans ce contexte, un objectif de perte de poids pourrait être néfaste pour votre santé.\n\nNous vous encourageons vivement à consulter un professionnel de santé avant de modifier votre alimentation.',
              style: TextStyle(color: Colors.white70, height: 1.5, fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 8),
            const Text(
              'Conseils & ressources',
              style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            _infoItem(Icons.local_hospital_outlined, 'Consultez votre médecin ou un nutritionniste avant tout rééquilibrage alimentaire.'),
            _infoItem(Icons.swap_vert_rounded, 'Un objectif "Maintien" ou "Prise de poids" serait plus adapté à votre profil actuel.'),
            _infoItem(Icons.self_improvement, 'Privilégiez une alimentation variée et équilibrée, sans restriction sévère.'),
            const SizedBox(height: 12),
            const Text(
              'Si vous traversez des difficultés avec votre rapport à l\'alimentation ou à votre corps :',
              style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 8),
            _ressourceItem('ANAB — Anorexie Boulimie', '0 800 008 008 · gratuit & anonyme'),
            _ressourceItem('Fédération Française Anorexie Boulimie', 'ffab.fr'),
            _ressourceItem('Manger Bouger (ANSES)', 'mangerbouger.fr'),
          ],
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF357E50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Compris', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _infoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white54, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _ressourceItem(String label, String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• $label', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          Text('  $detail', style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
