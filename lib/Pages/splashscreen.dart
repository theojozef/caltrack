import 'package:cal_track_v1/Pages/connexion_page.dart';
import 'package:cal_track_v1/Pages/tableaudebord.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // plus utilisé dans la logique simplifiée
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _animation;

  // Levé par _initializeApp() quand l'app est prête.
  // La navigation se déclenche quand le curseur repasse à 50% en phase retour.
  bool _readyToNavigate = false;
  bool _navigationTriggered = false;
  Widget? _nextPage;

  static const double _sliderW = 14;
  static const double _sliderH = 52;
  static const double _sliderRadius = 20;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _animation.addListener(_checkForExit);
    _controller.repeat(reverse: true);
    _initializeApp();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values, // restaure heure + batterie pour le reste de l'app
    );
    _controller.dispose();
    super.dispose();
  }

  // Appelé à chaque frame : déclenche la navigation quand le curseur repasse
  // à 50% en phase retour (droite → gauche), fond vert, transition naturelle.
  void _checkForExit() {
    if (_navigationTriggered || !_readyToNavigate || _nextPage == null) return;
    if (_controller.status == AnimationStatus.reverse && _animation.value <= 0.5) {
      _navigationTriggered = true;
      _animation.removeListener(_checkForExit);
      // Glisse fluidement jusqu'au centre (t=0.5) avant de naviguer
      _controller
          .animateTo(0.5, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut)
          .then((_) => _goTo(_nextPage!));
    }
  }

  Future<void> _initializeApp() async {
    // Délai minimal pour que l'écran de splash soit visible
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;

    // On stocke la destination sans naviguer : c'est _checkForExit() qui
    // déclenchera la navigation quand le curseur repassera à 50% en phase retour.
    _nextPage = user == null ? const ConnexionPage() : const TableauDeBord();
    _readyToNavigate = true;

    // Utilisateur connecté → tableau de bord
    // Le tableau de bord gère lui-même le chargement des données (local + Firebase)

    // --- Ancienne logique (conservée pour référence) ---
    // try {
    //   final prefs = await SharedPreferences.getInstance();
    //   final caloriesMin = prefs.getInt('caloriesMin');   // ancienne clé, obsolète
    //   final caloriesMax = prefs.getInt('caloriesMax');
    //   final alimentsDuJour = prefs.getStringList('alimentsDuJour') ?? [];
    //   if (caloriesMin == null || caloriesMax == null || alimentsDuJour.isEmpty) {
    //     final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    //     if (!doc.exists) { FirebaseAuth.instance.signOut(); _goTo(const ConnexionPage()); return; }
    //     ...
    //   }
    //   _goTo(const TableauDeBord());
    // } catch (e) {
    //   FirebaseAuth.instance.signOut();
    //   _goTo(const ConnexionPage());
    // }
  }

  void _goTo(Widget page) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  // Mêmes couleurs que les barres (color_utils.dart), zones de transition
  // élargies à 35% de part et d'autre pour un fondu progressif sur le splash.
  Color _bgColor(double t) {
    const colorLeft   = Color(0xFFBC8C56); // brun
    const colorMiddle = Color(0xFF0BE754); // vert
    const colorRight  = Color(0xFFBC5A56); // rouge
    const base        = Color(0xFF393939); // fond gris

    final Color tinted;
    if (t < 0.35) {
      tinted = Color.lerp(colorLeft, colorMiddle, t / 0.35)!;
    } else if (t <= 0.65) {
      tinted = colorMiddle;
    } else {
      tinted = Color.lerp(colorMiddle, colorRight, (t - 0.65) / 0.35)!;
    }

    return Color.lerp(base, tinted, 0.45)!;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final t = _animation.value;
        // Curseur : amplitude 50% de l'écran, centré horizontalement
        final cursorLeft = size.width * 0.25 + t * size.width * 0.5 - _sliderW / 2;
        final cursorTop  = size.height / 2 - _sliderH / 2;

        return Scaffold(
          backgroundColor: _bgColor(t),
          body: Stack(
            children: [
              Positioned(
                left: cursorLeft,
                top: cursorTop,
                child: Container(
                  width: _sliderW,
                  height: _sliderH,
                  decoration: BoxDecoration(
                    color: const Color(0x32D9D9D9),
                    borderRadius: BorderRadius.circular(_sliderRadius),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
