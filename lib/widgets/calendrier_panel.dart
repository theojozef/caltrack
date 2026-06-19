import 'package:flutter/material.dart';

class CalendrierPanel extends StatefulWidget {
  final DateTime dateSelectionnee;
  final Set<String> joursAvecDonnees; // format "yyyy-MM-dd"
  final Function(DateTime) onDateSelectionnee;

  const CalendrierPanel({
    super.key,
    required this.dateSelectionnee,
    required this.joursAvecDonnees,
    required this.onDateSelectionnee,
  });

  @override
  State<CalendrierPanel> createState() => _CalendrierPanelState();
}

class _CalendrierPanelState extends State<CalendrierPanel> {
  late DateTime _moisAffiche;

  static const _nomsMois = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
  ];

  static const _joursSemaine = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    _moisAffiche = DateTime(widget.dateSelectionnee.year, widget.dateSelectionnee.month);
  }

  static String _fmt(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  void _moisPrecedent() =>
      setState(() => _moisAffiche = DateTime(_moisAffiche.year, _moisAffiche.month - 1));

  void _moisSuivant() {
    final limite = DateTime.now().add(const Duration(days: 7));
    final next = DateTime(_moisAffiche.year, _moisAffiche.month + 1);
    if (next.year > limite.year || (next.year == limite.year && next.month > limite.month)) return;
    setState(() => _moisAffiche = next);
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final premierJour = DateTime(_moisAffiche.year, _moisAffiche.month, 1);
    final decalage = premierJour.weekday - 1; // lundi = 0
    final nbJours = DateTime(_moisAffiche.year, _moisAffiche.month + 1, 0).day;

    final dateLimite = todayOnly.add(const Duration(days: 7));
    final moisLimite = DateTime(dateLimite.year, dateLimite.month);
    final peutAvancer = DateTime(_moisAffiche.year, _moisAffiche.month).isBefore(moisLimite);

    final cellules = <Widget>[
      for (int i = 0; i < decalage; i++) const SizedBox(),
      for (int jour = 1; jour <= nbJours; jour++)
        _buildJour(jour, todayOnly, dateLimite),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF2E2E2E),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 16, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Poignée
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),

          // Navigation mois
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: _moisPrecedent,
              ),
              Text(
                '${_nomsMois[_moisAffiche.month - 1]} ${_moisAffiche.year}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: peutAvancer ? Colors.white : Colors.white24),
                onPressed: peutAvancer ? _moisSuivant : null,
              ),
            ],
          ),

          const SizedBox(height: 6),

          // En-têtes jours semaine
          Row(
            children: _joursSemaine
                .map((j) => Expanded(
                      child: Center(
                        child: Text(j,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ))
                .toList(),
          ),

          const SizedBox(height: 4),

          // Grille
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            childAspectRatio: 1.0,
            children: cellules,
          ),
        ],
      ),
    );
  }

  Widget _buildJour(int jour, DateTime todayOnly, DateTime dateLimite) {
    final date = DateTime(_moisAffiche.year, _moisAffiche.month, jour);
    final dateStr = _fmt(date);
    final estAujourdhui = date == todayOnly;
    final estSelectionne = _fmt(date) == _fmt(widget.dateSelectionnee);
    final aDonnees = widget.joursAvecDonnees.contains(dateStr);
    final estFutur = date.isAfter(dateLimite);

    return GestureDetector(
      onTap: estFutur ? null : () {
        widget.onDateSelectionnee(date);
        Navigator.pop(context);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: estSelectionne
                  ? const Color(0xFF357E50)
                  : estAujourdhui
                      ? const Color(0xFF357E50).withValues(alpha: 0.25)
                      : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$jour',
                style: TextStyle(
                  color: estFutur ? Colors.white24 : Colors.white,
                  fontSize: 13,
                  fontWeight: estAujourdhui || estSelectionne ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          // Pastille verte = données ce jour
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: aDonnees ? const Color(0xFF357E50) : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
