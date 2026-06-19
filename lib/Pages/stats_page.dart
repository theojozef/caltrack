import 'dart:math';
import 'package:cal_track_v1/models/aliment.dart';
import 'package:cal_track_v1/models/user_data.dart';
import 'package:cal_track_v1/services/formules_calories.dart';
import 'package:cal_track_v1/services/local_storage_service.dart';
import 'package:cal_track_v1/widgets/groupe_barre.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Palette camaïeu macros — modifier ces constantes puis faire 'r' pour voir le changement
const double _macroHue = 151; //30 ou 30  
// 0 Rouge - 30 Orange - 60 Jaune - 120 Vert - 180 Cyan - 240 Bleu - 300 Magenta - 360 Rouge

const double _macroSat = 0.85;

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  _StatsMacros? _statJour;
  _StatsMacros? _statSemaine;
  _StatsMacros? _statMois;
  UserModel? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _chargerStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _chargerStats() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final userData = await LocalStorageService.loadUserData(userId);
    final allDates = await LocalStorageService.getJoursAvecDonnees(userId);
    final today = LocalStorageService.formatDate(DateTime.now());

    // Onglet Jour : totaux d'aujourd'hui
    final alimentsJour = await LocalStorageService.loadAlimentsDuJour(userId, today);
    final statJour = _somme([alimentsJour]);

    // Onglet Semaine : moyenne sur les 7 derniers jours
    final dates7 = _filtrerDates(allDates, 7);
    final statSemaine = await _chargerMoyenne(userId, dates7);

    // Onglet Mois : moyenne sur les 30 derniers jours
    final dates30 = _filtrerDates(allDates, 30);
    final statMois = await _chargerMoyenne(userId, dates30);

    setState(() {
      _statJour = statJour;
      _statSemaine = statSemaine;
      _statMois = statMois;
      _userData = userData;
      _isLoading = false;
    });
  }

  List<String> _filtrerDates(List<String> dates, int jours) {
    final now = DateTime.now();
    final limite = now.subtract(Duration(days: jours));
    return dates.where((d) {
      try {
        final date = DateTime.parse(d);
        return !date.isAfter(DateTime(now.year, now.month, now.day)) &&
               date.isAfter(limite.subtract(const Duration(days: 1)));
      } catch (_) {
        return false;
      }
    }).toList();
  }

  Future<_StatsMacros> _chargerMoyenne(String userId, List<String> dates) async {
    if (dates.isEmpty) return _StatsMacros.zero();
    final listes = <List<AlimentConsomme>>[];
    for (final d in dates) {
      final aliments = await LocalStorageService.loadAlimentsDuJour(userId, d);
      if (aliments.isNotEmpty) listes.add(aliments);
    }
    if (listes.isEmpty) return _StatsMacros.zero();
    final total = _somme(listes);
    final joursRenseignes = listes.length;
    return _StatsMacros(
      total.calories / joursRenseignes,
      total.proteines / joursRenseignes,
      total.lipides / joursRenseignes,
      total.glucides / joursRenseignes,
      total.fibres / joursRenseignes,
    );
  }

  _StatsMacros _somme(List<List<AlimentConsomme>> listes) {
    double cal = 0, prot = 0, lip = 0, gluc = 0, fib = 0;
    for (final liste in listes) {
      for (final a in liste) {
        final m = a.aliment.getMacrosPourQuantite(a.quantite);
        cal  += m['calories']  ?? 0;
        prot += m['proteines'] ?? 0;
        lip  += m['lipides']   ?? 0;
        gluc += m['glucides']  ?? 0;
        fib  += m['fibres']    ?? 0;
      }
    }
    return _StatsMacros(cal, prot, lip, gluc, fib);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF393939),
      body: SafeArea(
        child: Column(
          children: [
            // Header avec titre centré
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Text(
                    'Analytiques',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Onglets
            TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF357E50),
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              overlayColor: WidgetStateProperty.all(const Color(0xFF357E50).withValues(alpha: 0.15)),
              tabs: const [
                Tab(text: 'Aujourd\'hui'),
                Tab(text: 'Semaine'),
                Tab(text: 'Mois'),
              ],
            ),

            const SizedBox(height: 4),

            // Contenu
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF357E50)))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOnglet(_statJour!, 'Totaux du jour'),
                        _buildOnglet(_statSemaine!, 'Moyenne sur 7 jours'),
                        _buildOnglet(_statMois!, 'Moyenne sur 30 jours'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnglet(_StatsMacros stats, String sousTitre) {
    final couleurProt = HSLColor.fromAHSL(1.0, _macroHue, _macroSat, 0.80).toColor();
    final couleurLip  = HSLColor.fromAHSL(1.0, _macroHue, _macroSat, 0.50).toColor();
    final couleurGluc = HSLColor.fromAHSL(1.0, _macroHue, _macroSat, 0.20).toColor();

    final kcalProt = stats.proteines * 4;
    final kcalLip  = stats.lipides  * 9;
    final kcalGluc = stats.glucides * 4;
    final totalKcal = kcalProt + kcalLip + kcalGluc;
    final pctProt = totalKcal > 0 ? (kcalProt / totalKcal * 100) : 0.0;
    final pctLip  = totalKcal > 0 ? (kcalLip  / totalKcal * 100) : 0.0;
    final pctGluc = totalKcal > 0 ? (kcalGluc / totalKcal * 100) : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text(
          sousTitre,
          style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.5),
        ),
        const SizedBox(height: 20),

        // Calories + Donut + Macros
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          decoration: BoxDecoration(
            color: const Color(0xFF393939), // même couleur que le fond de page
            // color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Calories',
                style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 1),
              ),
              const SizedBox(height: 2),
              Text(
                '${stats.calories.toStringAsFixed(0)} kcal',
                style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CustomPaint(
                      painter: _DonutPainter(
                        valeurs: [kcalProt, kcalLip, kcalGluc],
                        couleurs: [couleurProt, couleurLip, couleurGluc],
                      ),
                    ),
                  ),
                  const SizedBox(width: 25),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMacroInfo('Protéines', pctProt, stats.proteines, couleurProt),
                      const SizedBox(height: 10),
                      _buildMacroInfo('Lipides',   pctLip,  stats.lipides,   couleurLip),
                      const SizedBox(height: 10),
                      _buildMacroInfo('Glucides',  pctGluc, stats.glucides,  couleurGluc),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Barres macros avec bornes basées sur la moyenne calorique
        if (_userData != null) ...[
          LayoutBuilder(builder: (context, constraints) {
            final cal = stats.calories.round();
            final bornes = CalculateurNutrition(_userData!).getMacrosNewCalories(cal, cal);
            return Column(
              children: [
                GroupeBarre(
                  titre: 'Protéines',
                  valeurMin: bornes['prot_min']!.toDouble(),
                  valeurMax: bornes['prot_max']!.toDouble(),
                  compteurCalories: stats.proteines,
                  barWidth: constraints.maxWidth,
                  compteurFontSize: 16,
                  compteurFontWeight: FontWeight.bold,
                  borneFontSize: 14,
                ),
                const SizedBox(height: 24),
                GroupeBarre(
                  titre: 'Lipides',
                  valeurMin: bornes['lipides_min']!.toDouble(),
                  valeurMax: bornes['lipides_max']!.toDouble(),
                  compteurCalories: stats.lipides,
                  barWidth: constraints.maxWidth,
                  compteurFontSize: 16,
                  compteurFontWeight: FontWeight.bold,
                  borneFontSize: 14,
                ),
                const SizedBox(height: 24),
                GroupeBarre(
                  titre: 'Glucides',
                  valeurMin: bornes['glucides_min']!.toDouble(),
                  valeurMax: bornes['glucides_max']!.toDouble(),
                  compteurCalories: stats.glucides,
                  barWidth: constraints.maxWidth,
                  compteurFontSize: 16,
                  compteurFontWeight: FontWeight.bold,
                  borneFontSize: 14,
                ),
              ],
            );
          }),
          const SizedBox(height: 24),
        ],

        // Fibres
        LayoutBuilder(
          builder: (context, constraints) => GroupeBarre(
            titre: 'Fibres',
            valeurMin: stats.calories * 0.0125,
            valeurMax: stats.calories * 0.015,
            compteurCalories: stats.fibres,
            barWidth: constraints.maxWidth,
            compteurFontSize: 16,
            compteurFontWeight: FontWeight.bold,
            borneFontSize: 14,
          ),
        ),
      ],
    );
  }


  Widget _buildMacroInfo(String nom, double pct, double grammes, Color couleur) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(nom, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
        Text(
          '${grammes.toStringAsFixed(0)}g / ${pct.toStringAsFixed(0)}%',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

}


class _StatsMacros {
  final double calories, proteines, lipides, glucides, fibres;

  _StatsMacros(this.calories, this.proteines, this.lipides, this.glucides, this.fibres);

  factory _StatsMacros.zero() => _StatsMacros(0, 0, 0, 0, 0);
}

class _DonutPainter extends CustomPainter {
  final List<double> valeurs;
  final List<Color> couleurs;

  const _DonutPainter({required this.valeurs, required this.couleurs});

  @override
  void paint(Canvas canvas, Size size) {
    final total = valeurs.fold(0.0, (a, b) => a + b);
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.20; // 20% du diamètre — ajuster ce ratio pour changer l'épaisseur
    final radius = size.width / 2 - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    if (total == 0) {
      canvas.drawCircle(center, radius,
        Paint()
          ..color = Colors.white10
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
      return;
    }

    // Arcs continus sans gap angulaire
    double startAngle = -pi / 2;
    for (int i = 0; i < valeurs.length; i++) {
      final sweep = (valeurs[i] / total) * (2 * pi);
      canvas.drawArc(rect, startAngle, sweep, false,
        Paint()
          ..color = couleurs[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt,
      );
      startAngle += sweep;
    }

    // Séparateurs radiaux — largeur constante, vraiment parallèles
    final sepPaint = Paint()
      ..color = const Color(0xFF393939) // même couleur que le fond de page
      // ..color = const Color(0xFF454545)
      ..strokeWidth = 8 //5
      ..strokeCap = StrokeCap.butt;

    startAngle = -pi / 2;
    for (int i = 0; i < valeurs.length; i++) {
      final innerR = radius - strokeWidth / 2 - 2.0;
      final outerR = radius + strokeWidth / 2 + 2.0;
      final p1 = Offset(center.dx + innerR * cos(startAngle), center.dy + innerR * sin(startAngle));
      final p2 = Offset(center.dx + outerR * cos(startAngle), center.dy + outerR * sin(startAngle));
      canvas.drawLine(p1, p2, sepPaint);
      startAngle += (valeurs[i] / total) * (2 * pi);
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.valeurs != valeurs || old.couleurs != couleurs;
}
