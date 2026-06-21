// import 'package:cal_track_v1/Pages/tableaudebord.dart';
//import 'package:cal_track_v1/Pages/loading_screen.dart';

// import 'package:cal_track_v1/Pages/connexion_page.dart';
import 'package:cal_track_v1/Pages/splashscreen.dart';
// import 'package:cal_track_v1/Pages/tableaudebord.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
//import 'package:cal_track_v1/Pages/connexion_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Forcer l'orientation portrait uniquement
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    // DeviceOrientation.portraitDown, // optionnel si vous voulez autoriser le portrait inversé
  ]);
    
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,  // Initialisation de Firebase avec le fichier options
  );

  // Mode immersif : contenu derrière la barre de statut et de navigation
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,              // barre heure/batterie transparente
    statusBarIconBrightness: Brightness.light,       // icônes blanches (fond sombre)
    systemNavigationBarColor: Colors.transparent,    // barre de navigation Android transparente
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 667), // iPhone SE (ou ta maquette de référence)
      minTextAdapt: true,
      builder: (context, child) {    
        return MaterialApp(
          title: 'forkshot',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.green,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF357E50),
              primary: const Color(0xFF357E50),
            ),
            textSelectionTheme: const TextSelectionThemeData(
              selectionColor: Color(0x80357E50),
              selectionHandleColor: Color(0xFF357E50),
              cursorColor: Color(0xFF357E50),
            ),
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.android: ZoomPageTransitionsBuilder(),
              },
            ),
          ),
          // home: const TableauDeBord(),
          // home: const ConnexionPage(),
          home: const SplashScreen(),

    );
      },
    );
  }
}
