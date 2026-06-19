import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//import 'package:flutter_svg/flutter_svg.dart';

// Animation de transition réutilisable (curseur oscillant → s'arrête à 50%).
// Accepte soit une [destination] directe, soit un [resolver] async pour
// déterminer la page cible pendant que l'animation tourne.
class SplashTransition extends StatefulWidget {
  final Widget? destination;
  final Future<Widget> Function()? resolver;

  const SplashTransition({super.key, this.destination, this.resolver})
      : assert(destination != null || resolver != null,
            'destination ou resolver obligatoire');

  @override
  State<SplashTransition> createState() => _SplashTransitionState();
}

class _SplashTransitionState extends State<SplashTransition>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _animation;

  // Levé quand la destination est connue.
  // La navigation se déclenche quand le curseur repasse à 50% en phase retour.
  bool _readyToNavigate = false;
  bool _navigationTriggered = false;
  Widget? _nextPage;

  static const double _sliderW = 30; //20
  static const double _sliderH = _sliderW * 3.5; // 52
  static const double _sliderRadius = _sliderW * 2;

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
          .animateTo(0.5,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut)
          .then((_) => _goTo(_nextPage!));
    }
  }

  Future<void> _initializeApp() async {
    if (widget.resolver != null) {
      final dest = await widget.resolver!();
      if (!mounted) return;
      _nextPage = dest;
    } else {
      _nextPage = widget.destination;
    }
    _readyToNavigate = true; //pour bloquer sur le splashcreen
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
    const colorLeft   = Color.fromARGB(138, 188, 140, 86); // brun 0xFFBC8C56
    const colorMiddle = Color.fromARGB(131, 11, 231, 84); // vert 0xFF0BE754
    const colorRight  = Color.fromARGB(131, 188, 89, 86); // rouge 0xFFBC5A56
    const base        = Color(0xFF393939); // fond gris 0xFF393939

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
                        blurRadius: 2, // 4
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
               /*Positioned(
                 left: 0,
                 right: 0,
                 bottom: 100,
                 child: Center(
                   child: SvgPicture.asset(
                     'assets/images/typo forkshot.svg',
                     width: size.width * 0.35,
                     colorFilter: const ColorFilter.mode(Color(0xFF2E2E2E), BlendMode.srcIn),
                   ),
                 ),
               ),*/
            ],
          ),
        );
      },
    );
  }
}
