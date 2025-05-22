// import 'package:cal_track_v1/Pages/tableaudebord.dart';
//import 'package:cal_track_v1/Pages/loading_screen.dart';
import 'package:cal_track_v1/Pages/connexion_page.dart';
//import 'package:cal_track_v1/Pages/tableaudebord.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
//import 'package:cal_track_v1/Pages/connexion_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,  // Initialisation de Firebase avec le fichier options
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mon App',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      /*home: const TableauDeBord(),*/
      home: const ConnexionPage(),

    );
  }
}
