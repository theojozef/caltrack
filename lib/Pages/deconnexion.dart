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

  static const double fontsize = 10;
  static const double spaceBTW = 18;

  // Définis un mapping entre les valeurs internes et les textes affichés
  final Map<String, String> objectifsMapping = {
    "déficit": "Perdre du poids",
    "maintien": "Maintenir son poids",
    "pdm": "Prendre du poids",
  };

  final Map<String, String> typeSportMapping = {
    "pas": "Pas ou peu de sport",
    "loisir": "Sport de loisir",
    "endurance": "Sport d'endurance",
    "force": "Sport de force",
  };

  final Map<String, String> niveauActiviteMapping = {
    "sédentaire": "Sédentaire",
    "modéré": "Modérément actif",
    "actif": "Actif",
    "très actif": "Très actif",
    "extrêmement actif":"Extrêmement actif",
  };


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
      
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
      
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [

        Container(
          alignment: Alignment.centerLeft, 
          height: 60,
          child: IconButton(
              icon: const Icon(Icons.chevron_left, 
              color: Colors.white,
              size: 30),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
        ),

        // const SizedBox(height: 16),  

        Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16), // marge sous le container
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4A4A4A), // fond légèrement différent
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.transparent,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
                                 
        child: Column(
          //mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          
          children: [      

            if (userData != null) ...[
              Text('${userData!['prenom'] ?? "Non renseigné"}',
                  style: const TextStyle(color: Colors.white, fontSize: 18)),

              const SizedBox(height: 30),

              Row(                
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [ 

              Text(
                'Taille',
                  style: const TextStyle(color: Colors.white, fontSize: fontsize)),
              
              Text(
                '${userData!['Taille'] ?? "Non renseigné"} cm',
                  style: const TextStyle(color: Colors.white, fontSize: fontsize)),

                ],
              ),
              const Divider(
                color: Color(0x07FFFFFF),  // Couleur de la ligne
                thickness: 1,        // Épaisseur de la ligne
                height: 10,          // Hauteur totale prise par le Divider (espace vertical)
                ),
              const SizedBox(height: spaceBTW),

              SizedBox(height: 1,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [ 
                  
              Text(
                'Poids',
                  style: const TextStyle(color: Colors.white, fontSize: fontsize)),
              
              Text(
                '${userData!['Poids'] ?? "Non renseigné"} kg',
                  style: const TextStyle(color: Colors.white, fontSize: fontsize)),

                ],
              ),
              const Divider(
                color: Color(0x07FFFFFF),  // Couleur de la ligne
                thickness: 1,        // Épaisseur de la ligne
                height: 10,          // Hauteur totale prise par le Divider (espace vertical)
                ),
              const SizedBox(height: spaceBTW),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [ 
                  
              Text(
                'Âge',
                  style: const TextStyle(color: Colors.white, fontSize: fontsize)),
              
              Text(
                '${userData!['Âge'] ?? "Non renseigné"} ans',
                  style: const TextStyle(color: Colors.white, fontSize: fontsize)),

                ],
              ),
              const Divider(
                color: Color(0x07FFFFFF),  // Couleur de la ligne
                thickness: 1,        // Épaisseur de la ligne
                height: 10,          // Hauteur totale prise par le Divider (espace vertical)
                ),
              const SizedBox(height: spaceBTW),       

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [ 
                  
              Text(
                'Niveau d\'activité physique',
                  style: const TextStyle(color: Colors.white, fontSize: fontsize)),
              
              Text(
                niveauActiviteMapping[userData!['Niveau d\'activité physique']] ?? userData!['Niveau d\'activité physique'] ?? "Non renseigné",
                  style: const TextStyle(color: Colors.white, fontSize: fontsize)),

                ],
              ),
              const Divider(
                color: Color(0x07FFFFFF),  // Couleur de la ligne
                thickness: 1,        // Épaisseur de la ligne
                height: 10,          // Hauteur totale prise par le Divider (espace vertical)
                ),
              const SizedBox(height: spaceBTW),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [ 
                  
              Text(
                'Type d\'activité physique',
                  style: const TextStyle(color: Colors.white, fontSize: fontsize)),
              
              Text(
                  typeSportMapping[userData!['Type d\'activité physique']] ?? userData!['Type d\'activité physique'] ?? "Non renseigné",
                  style: const TextStyle(color: Colors.white, fontSize: fontsize)),              
                ],
              ),

              const Divider(
                color: Color(0x07FFFFFF),  // Couleur de la ligne
                thickness: 1,        // Épaisseur de la ligne
                height: 10,          // Hauteur totale prise par le Divider (espace vertical)
                ),
              const SizedBox(height: 2*spaceBTW),       

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [ 
                  
              Text(
                'Objectif',
                  style: const TextStyle(color: Colors.white, fontSize: fontsize)),
              
              
              Text(
                objectifsMapping[userData!['Objectif']] ?? userData!['Objectif'] ?? "Non renseigné",
                style: const TextStyle(color: Colors.white, fontSize: fontsize)),
                            
                ],
              ),
              
              const SizedBox(height: 30),

            ] else
              const Text(
                'Aucune donnée utilisateur trouvée.',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
        
        
        Center(
          child:
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
        ),
          ]
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
