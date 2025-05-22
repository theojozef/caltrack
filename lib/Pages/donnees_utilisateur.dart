import 'package:cal_track_v1/Pages/tableaudebord.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cal_track_v1/models/user_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final prefs = await SharedPreferences.getInstance();
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

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
  
  // Sinon on charge depuis Firestore
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

  @override
  void dispose() {
    _poidsController.dispose();
    _tailleController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _saveUserData() async {
    
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

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
      final prefs = await SharedPreferences.getInstance();
      //final uid = FirebaseAuth.instance.currentUser!.uid;
      await prefs.setDouble('${uid}Poids', utilisateur.poids);
      await prefs.setDouble('${uid}Taille', utilisateur.taille);
      await prefs.setInt('$uidÂge', utilisateur.age);
      await prefs.setString('${uid}Sexe', utilisateur.sexe);
      await prefs.setString('${uid}niveauActivite', _niveauActivite ?? '');
      await prefs.setString('${uid}sport', _sport ?? '');
      await prefs.setString('${uid}objectif', _objectif ?? '');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Données enregistrées avec succès")),
      );
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
  final double fieldWidth = 310;

  @override
  Widget build(BuildContext context) {

    if (_isLoading) {
  return const Scaffold(
    body: Center(child: CircularProgressIndicator(color: Color(0xFF357E50))),
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
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: Color(0xFF357E50), // curseur texte
        selectionColor: Colors.grey[900],
        selectionHandleColor: Colors.deepOrange,
      ),
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
      appBar: AppBar(title: const Text("Données utilisateur")),
      
      body: SafeArea(
      //child: Padding( //Padding
        
        child: Form(
          key: _formKey,
          
          child: ListView(
            physics: BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            children: [
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
                validator: (value) =>
                    value == null || value.isEmpty ? 'Champ requis' : null,
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
                validator: (value) =>
                    value == null || value.isEmpty ? 'Champ requis' : null,
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
                validator: (value) =>
                    value == null || value.isEmpty ? 'Champ requis' : null,
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
                  DropdownMenuItem(value: 'déficit', child: Text('Perte de gras')),
                  DropdownMenuItem(value: 'maintien', child: Text('Maintien')),
                  DropdownMenuItem(value: 'pdm', child: Text('Prise de masse musculaire')),
                ],
              ),
              ),
              ),
              
              const SizedBox(height: gap * 2),


              Center(                 
                child: SizedBox(
                  width: fieldWidth, 
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveUserData,
                  style: ElevatedButton.styleFrom(
                    //padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    backgroundColor: Color(0xFF357E50),
                    //shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                    child: _isSaving
                    ? const CircularProgressIndicator(color: Color(0xFF357E50))
                    : const Text("Enregistrer",
                    style: TextStyle(color: Colors.white),
                    ),
                    
              ),
                ),
              ),

              const SizedBox(height: 40),

            ],
          ),
        ),
      
    ),
    ),
    ),
    );
  }
}
