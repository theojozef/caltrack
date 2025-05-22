//import 'package:cal_track_v1/Pages/tableaudebord.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoadingScreen extends StatefulWidget {

  final Widget destination;
  const LoadingScreen({required this.destination, super.key});

   @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  bool isLoading = true;
  Map<String, dynamic>? userData;
  
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

    Future<void> _loadUserData() async {
    try {
      // Exemple : récupérer user Firebase
      final user = FirebaseAuth.instance.currentUser;

      // Exemple : récupérer des données utilisateur dans Firestore
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        userData = doc.data();
      }

      // Ici tu peux charger tout ce dont tu as besoin

    } catch (e) {

      // gérer les erreurs     
    }

    
    if (mounted) {
      setState(() {
        isLoading = false;
      });
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => widget.destination),
      );
    }


  }

  @override
  Widget build(BuildContext context) {    
    return Scaffold(
      backgroundColor: Colors.deepPurple, // Ou ton fond personnalisé
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF357E50)), // Ou un logo animé
      ),
    );
  }
}
