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
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));
  runApp(const MyApp());
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
          // Empêche l'agrandissement de police système d'impacter l'UI
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                textScaler: TextScaler.linear(
                  mq.textScaler.scale(1.0).clamp(0.8, 1.0),
                ),
              ),
              child: child!,
            );
          },
          // home: const TableauDeBord(),
          // home: const ConnexionPage(),
          home: const SplashScreen(),

    );
      },
    );
  }
}
