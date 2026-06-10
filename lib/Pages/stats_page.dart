import 'package:cal_track_v1/models/aliment.dart';
import 'package:cal_track_v1/services/local_storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
  Map<String, double>? _objectifs;

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

    final objectifs = await LocalStorageService.loadMacros(userId);
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
      _objectifs = objectifs;
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
      listes.add(await LocalStorageService.loadAlimentsDuJour(userId, d));
    }
    final total = _somme(listes);
    return _StatsMacros(
      total.calories / dates.length,
      total.proteines / dates.length,
      total.lipides / dates.length,
      total.glucides / dates.length,
      total.fibres / dates.length,
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
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Stats',
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
                        _buildOnglet(_statJour!, "Totaux du jour"),
                        _buildOnglet(_statSemaine!, "Moyenne sur 7 jours"),
                        _buildOnglet(_statMois!, "Moyenne sur 30 jours"),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnglet(_StatsMacros stats, String sousTitre) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text(
          sousTitre,
          style: const TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 0.5),
        ),
        const SizedBox(height: 24),
        _buildLigne('Calories',  stats.calories,  _objectifs?['calories_max'],  'kcal', const Color(0xFF357E50)),
        _buildLigne('Protéines', stats.proteines, _objectifs?['prot_max'],      'g',    const Color(0xFF5B9BD5)),
        _buildLigne('Lipides',   stats.lipides,   _objectifs?['lipides_max'],   'g',    const Color(0xFFE8874A)),
        _buildLigne('Glucides',  stats.glucides,  _objectifs?['glucides_max'],  'g',    const Color(0xFFD4A843)),
        _buildLigne('Fibres',    stats.fibres,    _objectifs?['fibres_max'],    'g',    const Color(0xFF5BBFA8)),
      ],
    );
  }

  Widget _buildLigne(String nom, double valeur, double? objectif, String unite, Color couleur) {
    final ratio = (objectif != null && objectif > 0)
        ? (valeur / objectif).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(nom,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: valeur.toStringAsFixed(0),
                      style: TextStyle(color: couleur, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    if (objectif != null)
                      TextSpan(
                        text: ' / ${objectif.toStringAsFixed(0)} $unite',
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      )
                    else
                      TextSpan(
                        text: ' $unite',
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(couleur),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsMacros {
  final double calories, proteines, lipides, glucides, fibres;

  _StatsMacros(this.calories, this.proteines, this.lipides, this.glucides, this.fibres);

  factory _StatsMacros.zero() => _StatsMacros(0, 0, 0, 0, 0);
}
