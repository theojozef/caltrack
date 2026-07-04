import 'package:cal_track_v1/models/aliment.dart';
import 'package:cal_track_v1/services/local_storage_service.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HistoriquePage extends StatefulWidget {
  const HistoriquePage({super.key});

  @override
  State<HistoriquePage> createState() => _HistoriquePageState();
}

class _HistoriquePageState extends State<HistoriquePage> {
  List<_JourneeSummary> _journees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerHistorique();
  }

  Future<void> _chargerHistorique() async {
    final userId = await LocalStorageService.getCurrentUserId();

    final dates = await LocalStorageService.getJoursAvecDonnees(userId);

    // Ne pas afficher aujourd'hui (déjà visible dans le dashboard)
    final aujourdHui = LocalStorageService.formatDate(DateTime.now());
    final datesPasse = dates.where((d) => d != aujourdHui).toList();

    final journees = <_JourneeSummary>[];

    for (final date in datesPasse) {
      final aliments = await LocalStorageService.loadAlimentsDuJour(userId, date);

      double calories = 0, proteines = 0, lipides = 0, glucides = 0;
      for (final a in aliments) {
        final macros = a.aliment.getMacrosPourQuantite(a.quantite);
        calories += macros['calories'] ?? 0;
        proteines += macros['proteines'] ?? 0;
        lipides += macros['lipides'] ?? 0;
        glucides += macros['glucides'] ?? 0;
      }

      journees.add(_JourneeSummary(
        date: date,
        aliments: aliments,
        calories: calories,
        proteines: proteines,
        lipides: lipides,
        glucides: glucides,
      ));
    }

    setState(() {
      _journees = journees;
      _isLoading = false;
    });
  }

  // "2026-06-04" → "4 juin 2026"
  String _formatDateFr(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length != 3) return dateStr;
    final day = int.parse(parts[2]);
    final month = int.parse(parts[1]);
    final year = parts[0];
    const mois = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '$day ${mois[month - 1]} $year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF393939),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Historique',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Liste des journées
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF357E50)),
                    )
                  : _journees.isEmpty
                      ? const Center(
                          child: Text(
                            'Aucun historique disponible.\nCommence à enregistrer tes repas !',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54, fontSize: 15),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _journees.length,
                          itemBuilder: (context, index) {
                            return _buildJourneeCard(_journees[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneeCard(_JourneeSummary journee) {
    return Card(
      color: const Color(0xFF4A4A4A),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        collapsedIconColor: Colors.white54,
        iconColor: const Color(0xFF357E50),

        title: Text(
          _formatDateFr(journee.date),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${journee.calories.toStringAsFixed(0)} kcal  ·  '
            'P ${journee.proteines.toStringAsFixed(0)} g  '
            'L ${journee.lipides.toStringAsFixed(0)} g  '
            'G ${journee.glucides.toStringAsFixed(0)} g',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),

        children: journee.aliments.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Aucun aliment enregistré ce jour.',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              ]
            : journee.aliments.map((a) {
                final macros = a.aliment.getMacrosPourQuantite(a.quantite);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${a.aliment.nom}  —  ${a.quantite.toStringAsFixed(0)} g',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                      Text(
                        '${macros['calories']?.toStringAsFixed(0)} kcal',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }).toList(),
      ),
    );
  }
}

class _JourneeSummary {
  final String date;
  final List<AlimentConsomme> aliments;
  final double calories;
  final double proteines;
  final double lipides;
  final double glucides;

  _JourneeSummary({
    required this.date,
    required this.aliments,
    required this.calories,
    required this.proteines,
    required this.lipides,
    required this.glucides,
  });
}
