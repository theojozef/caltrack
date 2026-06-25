import 'dart:async';

import 'package:cal_track_v1/Pages/scancode_page.dart';
import 'package:cal_track_v1/services/basededonnees.dart';
import 'package:cal_track_v1/models/aliment.dart';
import 'package:cal_track_v1/services/local_storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cal_track_v1/widgets/quantite_aliment.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cal_track_v1/services/openfoodfacts_api.dart';


class ListeAlimentsPage extends StatefulWidget {
  // final Function(Aliment) onAlimentAjoute;
  final Function(Aliment, double, Portion, Repas?) onAlimentAjoute;
  final Repas? repasPreselectionne; // repas déjà connu (depuis le bouton + de la section)

  const ListeAlimentsPage({super.key, required this.onAlimentAjoute, this.repasPreselectionne});

  @override
  State<ListeAlimentsPage> createState() => _ListeAlimentsPageState();
}

class _ListeAlimentsPageState extends State<ListeAlimentsPage> {
  List<Aliment> _aliments = [];
  List<Aliment> _alimentsFiltres = [];
  List<Aliment> _recents = [];
  Map<String, Map<String, dynamic>> _recentsQuantites = {};
  String _recherche = "";
  bool _isSearching = false;
  Set<String> _favoris = {};

  // Buffer d'aliments en attente de validation (ajout multi-aliments)
  // Chaque entrée : {'aliment': Aliment, 'quantite': double, 'portionChoisie': Portion, 'repasChoisi': Repas?}
  final List<Map<String, dynamic>> _alimentsEnAttente = [];

  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _chargerAliments();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  Future<void> _chargerAliments() async {
    // Charger les favoris persistants avant la liste CSV
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _favoris = await LocalStorageService.loadFavoris(userId);
      _recents = await LocalStorageService.loadRecents(userId);
      _recentsQuantites = await LocalStorageService.loadRecentsQuantites(userId);
    }

    final liste = await chargerAlimentsDepuisCSV();
    // Marquer les aliments déjà ajoutés par le passé
    for (final a in liste) {
      if (_favoris.contains(a.nom)) a.dejaAjoute = true;
    }

    if (!mounted) return;
    setState(() {
      _aliments = liste;
      _alimentsFiltres = _recents; // liste vide au départ → affiche les récents
    });
  }

  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Vrai si la chaîne contient au moins un caractère accentué
  bool _aDesAccents(String s) =>
      RegExp(r'[àáâãäèéêëìíîïòóôõöùúûüýÿçñæœ]').hasMatch(s);

  // Supprime les diacritiques pour une comparaison accent-insensible
  String _normaliser(String s) => s
      .replaceAll(RegExp(r'[àáâãä]'), 'a')
      .replaceAll(RegExp(r'[èéêë]'), 'e')
      .replaceAll(RegExp(r'[ìíîï]'), 'i')
      .replaceAll(RegExp(r'[òóôõö]'), 'o')
      .replaceAll(RegExp(r'[ùúûü]'), 'u')
      .replaceAll(RegExp(r'[ýÿ]'), 'y')
      .replaceAll('ñ', 'n')
      .replaceAll('ç', 'c')
      .replaceAll('æ', 'ae')
      .replaceAll('œ', 'oe');

  // Mots vides français (ignorés pour la recherche par mots-clés)
  static const _stopWords = {
    'de', 'du', 'le', 'la', 'les', 'des', 'un', 'une',
    'a', 'au', 'aux', 'et', 'ou', 'en', 'sur', 'par',
    'avec', 'sans', 'pour', 'dans', 'sous',
  };

  // Extrait les mots-clés significatifs (hors mots vides, après normalisation)
  List<String> _motsCles(String queryN) => queryN
      .split(' ')
      .where((m) => m.isNotEmpty && !_stopWords.contains(m))
      .toList();

  // Clé de déduplication basée sur les valeurs nutritionnelles
  String _cle(Aliment a) => [
    a.nom.toLowerCase().trim(),
    a.calories.toStringAsFixed(1),
    a.proteines.toStringAsFixed(1),
    a.lipides.toStringAsFixed(1),
    a.glucides.toStringAsFixed(1),
  ].join("|");

  // Filtre, trie et déduplique les résultats LOCAUX (CIQUAL) par correspondance de nom
  List<Aliment> _trierEtDedupliquer(List<Aliment> aliments, String query) {
    final queryN = _normaliser(query);
    final motsCles = _motsCles(queryN);
    // Si la recherche contient des accents → matching précis (accent-sensible)
    // Si elle n'en a pas → matching large (accent-insensible, pour pallier le dead key)
    final avecAccents = _aDesAccents(query);

    final filtres = aliments.where((a) {
      if (a.calories <= 0) return false;
      final nomN = _normaliser(a.nom.toLowerCase().trim());
      // Niveau 1 : phrase exacte accent-insensible
      if (nomN.contains(queryN)) return true;
      // Niveau 2 : tous les mots-clés présents (hors mots vides)
      return motsCles.isNotEmpty && motsCles.every((m) => nomN.contains(m));
    }).toList();

    filtres.sort((a, b) {
      final nomA = _normaliser(a.nom.toLowerCase().trim());
      final nomB = _normaliser(b.nom.toLowerCase().trim());
      // 0. Si la recherche a des accents, priorité aux noms qui correspondent exactement (accent-sensible)
      if (avecAccents) {
        final rawA = a.nom.toLowerCase().trim().contains(query);
        final rawB = b.nom.toLowerCase().trim().contains(query);
        if (rawA && !rawB) return -1;
        if (!rawA && rawB) return 1;
      }
      // 1. Correspondance exacte (query complet)
      final aExact = nomA == queryN;
      final bExact = nomB == queryN;
      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;
      // 1b. Contient la phrase complète comme sous-chaîne
      final aPhrase = nomA.contains(queryN);
      final bPhrase = nomB.contains(queryN);
      if (aPhrase && !bPhrase) return -1;
      if (!aPhrase && bPhrase) return 1;
      // 2. Commence par le premier mot-clé de la recherche
      final premierMot = motsCles.isNotEmpty ? motsCles.first : queryN;
      if (nomA.startsWith(premierMot) && !nomB.startsWith(premierMot)) return -1;
      if (!nomA.startsWith(premierMot) && nomB.startsWith(premierMot)) return 1;
      // 3. Déjà ajoutés en premier
      if (a.dejaAjoute && !b.dejaAjoute) return -1;
      if (!a.dejaAjoute && b.dejaAjoute) return 1;
      // 4. Fibres non nulles en premier
      if (a.fibres > 0 && b.fibres <= 0) return -1;
      if (a.fibres <= 0 && b.fibres > 0) return 1;
      // 5. Avec portion en premier
      final aPortionNom = a.portions.isNotEmpty;
      final bPortionNom = b.portions.isNotEmpty;
      if (aPortionNom && !bPortionNom) return -1;
      if (!aPortionNom && bPortionNom) return 1;
      // 5. Protéines décroissantes
      if (a.proteines != b.proteines) return b.proteines.compareTo(a.proteines);
      // 6. Alphabétique
      return a.nom.compareTo(b.nom);
    });

    final Set<String> seen = {};
    final List<Aliment> uniques = [];
    for (final a in filtres) {
      final key = _cle(a);
      if (!seen.contains(key)) { seen.add(key); uniques.add(a); }
    }
    return uniques;
  }

  void _filtrer(String recherche) {
    final query = recherche.toLowerCase().trim();

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Champ vide → afficher les aliments récemment ajoutés
    if (query.isEmpty) {
      setState(() {
        _recherche = query;
        _alimentsFiltres = _recents;
        _isSearching = false;
      });
      return;
    }

    // ÉTAPE 1 : Résultats CIQUAL locaux immédiats (base en mémoire, 0 ms)
    final locaux = _trierEtDedupliquer(_aliments, query);
    setState(() {
      _recherche = query;
      _alimentsFiltres = locaux;
      _isSearching = true; // barre discrète pendant l'appel API
    });

    // ÉTAPE 2 : Compléter avec OpenFoodFacts après debounce (400 ms)
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final rechercheEnCours = query;

      List<Aliment> apiResultats;
      try {
        // Requête OFF : avec accents → recherche directe ; sans accents → mots-clés seuls (meilleur recall Meilisearch)
        final String queryOFF;
        if (_aDesAccents(query)) {
          queryOFF = query; // accents présents → Meilisearch les utilise directement
        } else {
          final kw = _motsCles(_normaliser(query)).join(' ');
          queryOFF = kw.isEmpty ? _normaliser(query) : kw; // "pate de noisette" → "pate noisette"
        }
        apiResultats = await OpenFoodFactsAPI.searchAliments(queryOFF);
      } catch (e) {
        if (mounted) setState(() => _isSearching = false);
        return;
      }

      // Ignorer si la recherche a changé pendant l'attente
      if (rechercheEnCours != _recherche || !mounted) return;

      final queryN = _normaliser(query);
      final motsCles = _motsCles(queryN);
      final avecAccents = _aDesAccents(query);

      // Filtre OFF : matching précis si la recherche a des accents, large sinon
      final seen = {for (final a in locaux) _cle(a)};
      final apiUniques = apiResultats
          .where((a) => a.calories > 0)
          .where((a) {
            final nomN = _normaliser(a.nom.toLowerCase().trim());
            final ok = nomN.contains(queryN) ||
                (motsCles.isNotEmpty && motsCles.every((m) => nomN.contains(m)));
            if (!ok) return false;
            final k = _cle(a);
            if (seen.contains(k)) return false;
            seen.add(k);
            return true;
          })
          .toList();

      // CIQUAL déjà triés par pertinence du nom → API en complément, ordre OpenFoodFacts préservé
      final combined = [...locaux, ...apiUniques];

      // Tri final sur l'ensemble (stable) :
      // 0. phrase exacte en tête
      // 1. commence par le premier mot-clé
      // 2. nom le plus court (plus précis) en premier
      // 3. fibre renseignée en priorité
      // 4. portion nommée en priorité
      final premierMot = motsCles.isNotEmpty ? motsCles.first : queryN;
      combined.sort((a, b) {
        final nomA = _normaliser(a.nom.toLowerCase().trim());
        final nomB = _normaliser(b.nom.toLowerCase().trim());
        // 0. Si la recherche a des accents, priorité aux noms qui correspondent exactement (accent-sensible)
        if (avecAccents) {
          final rawA = a.nom.toLowerCase().trim().contains(query);
          final rawB = b.nom.toLowerCase().trim().contains(query);
          if (rawA && !rawB) return -1;
          if (!rawA && rawB) return 1;
        }
        // 1. Contient la phrase complète comme sous-chaîne
        final aPhrase = nomA.contains(queryN);
        final bPhrase = nomB.contains(queryN);
        if (aPhrase && !bPhrase) return -1;
        if (!aPhrase && bPhrase) return 1;
        // 2. CIQUAL en priorité (données certifiées ANSES)
        if (a.isCiqual && !b.isCiqual) return -1;
        if (!a.isCiqual && b.isCiqual) return 1;
        final aStart = nomA.startsWith(premierMot);
        final bStart = nomB.startsWith(premierMot);
        if (aStart && !bStart) return -1;
        if (!aStart && bStart) return 1;
        // Fibres renseignées en priorité
        final aFibre = a.fibres > 0;
        final bFibre = b.fibres > 0;
        if (aFibre && !bFibre) return -1;
        if (!aFibre && bFibre) return 1;
        // Completeness décroissant (fiabilité des données nutritionnelles)
        if (a.completeness != b.completeness) return b.completeness.compareTo(a.completeness);
        // Portion nommée en priorité
        final aPortion = a.portions.isNotEmpty;
        final bPortion = b.portions.isNotEmpty;
        if (aPortion && !bPortion) return -1;
        if (!aPortion && bPortion) return 1;
        // Nom plus court = plus précis (critère de départage final)
        final wordsA = nomA.split(' ').length;
        final wordsB = nomB.split(' ').length;
        if (wordsA != wordsB) return wordsA.compareTo(wordsB);
        return 0;
      });
      setState(() {
        _alimentsFiltres = combined;
        _isSearching = false;
      });
    });
  }

  void _ajouterAuBuffer(Aliment aliment, double quantite, Portion portionChoisie) {
    setState(() { aliment.dejaAjoute = true; });
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _favoris.add(aliment.nom);
      LocalStorageService.saveFavoris(userId, _favoris);
      _recents = [
        aliment,
        ..._recents.where((a) => a.nom != aliment.nom),
      ].take(20).toList();
      LocalStorageService.saveRecents(userId, _recents);
      _recentsQuantites[aliment.nom] = {
        'quantite': quantite,
        'portionNom': portionChoisie.nom,
        'portionPoids': portionChoisie.poids,
      };
      LocalStorageService.saveRecentsQuantites(userId, _recentsQuantites);
    }
    setState(() {
      _alimentsEnAttente.add({
        'aliment': aliment,
        'quantite': quantite,
        'portionChoisie': portionChoisie,
        'repasChoisi': widget.repasPreselectionne,
      });
    });
    _searchController.clear();
    _filtrer('');
  }

  void _ajouterAliment(BuildContext context, Aliment aliment) async {
    final Map<String, dynamic>? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuantiteAliment(aliment: aliment),
      ),
    );
    if (result == null || !mounted) return;
    _ajouterAuBuffer(
      aliment,
      result['quantite']! as double,
      result['portionChoisie'] as Portion,
    );
  }

  // Valide tous les aliments en attente et retourne au dashboard
  void _confirmerAjouts() {
    final navigator = Navigator.of(context);
    for (final item in _alimentsEnAttente) {
      widget.onAlimentAjoute(
        item['aliment'] as Aliment,
        item['quantite'] as double,
        item['portionChoisie'] as Portion,
        item['repasChoisi'] as Repas?,
      );
    }
    navigator.pop();
  }

  // Retour arrière : demande confirmation si des aliments sont en attente
  void _handleBack() {
    if (_alimentsEnAttente.isEmpty) {
      Navigator.pop(context);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF393939),
        title: const Text('Abandonner les ajouts ?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          '${_alimentsEnAttente.length} aliment${_alimentsEnAttente.length > 1 ? 's' : ''} en attente ne seront pas enregistrés.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Rester', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Abandonner', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // Formatte la quantité pour l'affichage dans le buffer
  String _formatQuantite(double quantite, Portion portion) {
    final qty = quantite == quantite.roundToDouble()
        ? quantite.toInt().toString()
        : quantite.toStringAsFixed(1);
    if (portion.nom == 'g') return '$qty g';
    if (portion.nom.isEmpty) {
      return quantite == 1.0
          ? '${portion.poids.toStringAsFixed(0)} g'
          : '$qty × ${portion.poids.toStringAsFixed(0)} g';
    }
    if (quantite == 1.0) return '${portion.nom}\n(${portion.poids.round()} g)';
    return '$qty × ${portion.nom}\n(${portion.poids.round()} g)';
  }

  // Totaux caloriques et macros de tous les aliments en attente
  Map<String, double> _totauxEnAttente() {
    double kcal = 0, prot = 0, lip = 0, gluc = 0, fibres = 0;
    for (final item in _alimentsEnAttente) {
      final a = item['aliment'] as Aliment;
      final q = item['quantite'] as double;
      final p = item['portionChoisie'] as Portion;
      final f = p.nom == 'g' ? q / 100 : p.poids * q / 100;
      kcal += a.calories * f;
      prot += a.proteines * f;
      lip += a.lipides * f;
      gluc += a.glucides * f;
      fibres += a.fibres * f;
    }
    return {'kcal': kcal, 'prot': prot, 'lip': lip, 'gluc': gluc, 'fibres': fibres};
  }

  Widget _buildTotalBar() {
    final t = _totauxEnAttente();
    final kcal = t['kcal']!.round();
    final prot = t['prot']!.round();
    final lip = t['lip']!.round();
    final gluc = t['gluc']!.round();
    final fibres = t['fibres']!.round();
    const sep = TextSpan(
      text: '  ·  ',
      style: TextStyle(color: Colors.white38, fontSize: 13),
    );
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(
            text: '$kcal kcal',
            style: const TextStyle(
              color: Color(0xFF7FD4A0),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          sep,
          const TextSpan(
            text: 'P',
            style: TextStyle(color: Color.fromARGB(255, 255, 255, 255), fontSize: 13, fontWeight: FontWeight.w700),
          ),
          TextSpan(
            text: ' ${prot}g',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          sep,
          const TextSpan(
            text: 'L',
            style: TextStyle(color: Color(0xFFE8A838), fontSize: 13, fontWeight: FontWeight.w700),
          ),
          TextSpan(
            text: ' ${lip}g',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          sep,
          const TextSpan(
            text: 'G',
            style: TextStyle(color: Color(0xFF5B9BD5), fontSize: 13, fontWeight: FontWeight.w700),
          ),
          TextSpan(
            text: ' ${gluc}g',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          sep,
          const TextSpan(
            text: 'F',
            style: TextStyle(color: Color(0xFF9C8FD4), fontSize: 13, fontWeight: FontWeight.w700),
          ),
          TextSpan(
            text: ' ${fibres}g',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }
  // Ouvre QuantiteAliment pour modifier un item du buffer
  void _modifierAlimentEnAttente(int index) async {
    final item = _alimentsEnAttente[index];
    final aliment = item['aliment'] as Aliment;

    final Map<String, dynamic>? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QuantiteAliment(aliment: aliment)),
    );

    if (result == null || !mounted) return;

    setState(() {
      _alimentsEnAttente[index] = {
        'aliment': aliment,
        'quantite': result['quantite'] as double,
        'portionChoisie': result['portionChoisie'] as Portion,
        'repasChoisi': item['repasChoisi'],
      };
    });
  }

  // Change la quantité d'un item du buffer via un preset ou une portion nommée
  void _changerQuantiteEnAttente(int index, double quantite, Portion portionChoisie) {
    setState(() {
      _alimentsEnAttente[index] = {
        ..._alimentsEnAttente[index],
        'quantite': quantite,
        'portionChoisie': portionChoisie,
      };
    });
  }

  // Ancien picker repas (bottom sheet) — conservé en commentaire comme référence
  // Future<Repas?> _choisirRepas() {
  //   return showModalBottomSheet<Repas>(
  //     context: context,
  //     backgroundColor: const Color(0xFF393939),
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (ctx) => Padding(
  //       padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         crossAxisAlignment: CrossAxisAlignment.stretch,
  //         children: [
  //           const Text("Quel repas ?", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
  //           const SizedBox(height: 16),
  //           ...Repas.values.map((r) => _repasTile(ctx, r)),
  //           const SizedBox(height: 4),
  //           TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Passer", style: TextStyle(color: Colors.white54))),
  //         ],
  //       ),
  //     ),
  //   ).then((v) => v);
  // }
  // Widget _repasTile(BuildContext ctx, Repas repas) {
  //   return ListTile(
  //     contentPadding: EdgeInsets.zero,
  //     title: Text(repas.label, style: const TextStyle(color: Colors.white, fontSize: 15)),
  //     onTap: () => Navigator.pop(ctx, repas),
  //   );
  // }

static const double heightsearch = 35;

  // Carte d'aliment pour la liste de recherche et les récents.
  // useRecentsQty=true → badge et bouton "+" utilisent la dernière quantité enregistrée.
  Widget _buildAlimentCard(Aliment aliment, {bool useRecentsQty = false}) {
    final hasPortion = aliment.portions.isNotEmpty &&
        !(aliment.portions.length == 1 && aliment.portions.first.poids == 100);
    final portion = hasPortion ? aliment.portions.first : null;
    final ratio = hasPortion ? portion!.poids / 100 : 1.0;

    double addQuantite;
    Portion addPortion;
    String badgeLabel;

    final saved = useRecentsQty ? _recentsQuantites[aliment.nom] : null;
    if (saved != null) {
      addQuantite = (saved['quantite'] as num).toDouble();
      addPortion = Portion(
        nom: saved['portionNom'] as String,
        poids: (saved['portionPoids'] as num).toDouble(),
      );
      badgeLabel = _formatQuantite(addQuantite, addPortion);
    } else if (hasPortion) {
      addQuantite = 1.0;
      addPortion = portion!;
      badgeLabel = _formatQuantite(addQuantite, addPortion);
    } else {
      addQuantite = 100.0;
      addPortion = Portion(nom: 'g', poids: 100);
      badgeLabel = '100 g';
    }

    return Card(
      color: const Color(0x12FFFFFF),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // "+" → ajout direct avec la quantité de référence
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _ajouterAuBuffer(aliment, addQuantite, addPortion),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '+',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF393939),
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Corps de la carte → ouvre QuantiteAliment
            Expanded(
              child: InkWell(
                onTap: () => _ajouterAliment(context, aliment),
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            aliment.nom,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (aliment.isCiqual) ...[
                          const SizedBox(width: 5),
                          const Icon(Icons.verified, size: 14, color: Color(0xFF4DB6AC)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasPortion
                          ? '${(aliment.calories * ratio).toStringAsFixed(0)} kcal - '
                            'P${(aliment.proteines * ratio).toStringAsFixed(0)} | '
                            'L${(aliment.lipides * ratio).toStringAsFixed(0)} | '
                            'G${(aliment.glucides * ratio).toStringAsFixed(0)}'
                            '${aliment.fibres > 0 ? ' | F${(aliment.fibres * ratio).toStringAsFixed(0)}' : ''}'
                          : '${aliment.calories.toStringAsFixed(0)} kcal - '
                            'P${aliment.proteines.toStringAsFixed(0)} | '
                            'L${aliment.lipides.toStringAsFixed(0)} | '
                            'G${aliment.glucides.toStringAsFixed(0)}'
                            '${aliment.fibres > 0 ? ' | F${aliment.fibres.toStringAsFixed(0)}' : ''}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Badge → menu déroulant : portion par défaut (si dispo) + presets grammes
            PopupMenuButton<double>(
              color: const Color(0xFF4A4A4A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onSelected: (value) {
                if (value == double.infinity && hasPortion) {
                  _ajouterAuBuffer(aliment, 1.0, portion!);
                } else {
                  _ajouterAuBuffer(aliment, value, Portion(nom: 'g', poids: value));
                }
              },
              itemBuilder: (_) => [
                if (hasPortion) ...[
                  () {
                    final p = aliment.portions.first;
                    return PopupMenuItem<double>(
                      value: double.infinity,
                      child: Text(
                        _formatQuantite(1.0, p),
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }(),
                  const PopupMenuDivider(),
                ],
                ...[10, 20, 30, 50, 100, 150].map((g) => PopupMenuItem<double>(
                      value: g.toDouble(),
                      child: Text('$g g', style: const TextStyle(color: Colors.white)),
                    )),
              ],
              child: Container(
                margin: const EdgeInsets.only(left: 8, right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                constraints: const BoxConstraints(maxWidth: 120),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A4A4A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF357E50)),
                ),
                child: Text(
                  badgeLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Contenu défilant : buffer + récents (champ vide) ou résultats de recherche.
  // Buffer et récents sont dans le même ListView pour défiler ensemble.
  Widget _buildListContent() {
    if (_recherche.isNotEmpty) {
      if (_alimentsFiltres.isEmpty) {
        return const Center(
          child: Text('Aucun aliment trouvé', style: TextStyle(color: Colors.white)),
        );
      }
      final recentsNoms = {for (final a in _recents) a.nom};
      final recentsFiltres = _alimentsFiltres.where((a) => recentsNoms.contains(a.nom)).toList();
      final autresResultats = _alimentsFiltres.where((a) => !recentsNoms.contains(a.nom)).toList();

      if (recentsFiltres.isEmpty) {
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: _alimentsFiltres.length,
          itemBuilder: (context, index) => _buildAlimentCard(_alimentsFiltres[index]),
        );
      }

      return ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
            child: const Text(
              'Récemment ajoutés :',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          ...recentsFiltres.map((a) => _buildAlimentCard(a, useRecentsQty: true)),
          if (autresResultats.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
              child: const Text(
                'Résultats de recherche :',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            ...autresResultats.map((a) => _buildAlimentCard(a)),
          ],
        ],
      );
    }

    if (_alimentsFiltres.isEmpty && _alimentsEnAttente.isEmpty) {
      return const Center(
        child: Text('Aucun aliment trouvé', style: TextStyle(color: Colors.white)),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        // ── Buffer : aliments en attente de validation ──
        if (_alimentsEnAttente.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
            child: const Text(
              'Vous venez d\'ajouter :',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          ..._alimentsEnAttente.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final aliment = item['aliment'] as Aliment;
            final quantite = item['quantite'] as double;
            final portion = item['portionChoisie'] as Portion;
            return Card(
              color: const Color(0x12FFFFFF),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Pastille verte : tap = retirer du buffer
                    GestureDetector(
                      onTap: () => setState(() => _alimentsEnAttente.removeAt(index)),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Color(0xFF357E50),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Contenu : tap = modifier la quantité
                    Expanded(
                      child: InkWell(
                        onTap: () => _modifierAlimentEnAttente(index),
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    aliment.nom,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    () {
                                      final f = portion.nom == 'g'
                                          ? quantite / 100
                                          : portion.poids * quantite / 100;
                                      return '${(aliment.calories * f).toStringAsFixed(0)} kcal - '
                                          'P: ${(aliment.proteines * f).toStringAsFixed(0)} | '
                                          'L: ${(aliment.lipides * f).toStringAsFixed(0)} | '
                                          'G: ${(aliment.glucides * f).toStringAsFixed(0)}'
                                          '${aliment.fibres > 0 ? ' | F: ${(aliment.fibres * f).toStringAsFixed(0)}' : ''}';
                                    }(),
                                    // '${aliment.portions.isNotEmpty ? ' (Portion: ${aliment.portions.first.poids} g)' : ''}',
                                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            // Quantité — menu déroulant : portion par défaut (si dispo) + presets grammes
                            PopupMenuButton<double>(
                              color: const Color(0xFF4A4A4A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              onSelected: (value) {
                                if (value == double.infinity && aliment.portions.isNotEmpty) {
                                  _changerQuantiteEnAttente(index, 1.0, aliment.portions.first);
                                } else {
                                  _changerQuantiteEnAttente(index, value, Portion(nom: 'g', poids: value));
                                }
                              },
                              itemBuilder: (_) => [
                                if (aliment.portions.isNotEmpty) ...[
                                  () {
                                    final p = aliment.portions.first;
                                    return PopupMenuItem<double>(
                                      value: double.infinity,
                                      child: Text(
                                        p.nom.isNotEmpty
                                            ? '${p.nom} (${p.poids.toStringAsFixed(0)} g)'
                                            : '${p.poids.toStringAsFixed(0)} g',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    );
                                  }(),
                                  const PopupMenuDivider(),
                                ],
                                ...[10, 20, 30, 50, 100, 150].map((g) => PopupMenuItem<double>(
                                      value: g.toDouble(),
                                      child: Text('$g g', style: const TextStyle(color: Colors.white)),
                                    )),
                              ],
                              child: Container(
                                margin: const EdgeInsets.only(left: 8, right: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                constraints: const BoxConstraints(maxWidth: 120),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4A4A4A),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF357E50)),
                                ),
                                child: Text(
                                  _formatQuantite(quantite, portion),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
        // ── Récemment ajoutés ──
        if (_alimentsFiltres.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
            child: const Text(
              'Récemment ajoutés :',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          ..._alimentsFiltres.map((a) => _buildAlimentCard(a, useRecentsQty: true)),
        ],
      ],
    );
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Scaffold(
        backgroundColor: const Color(0xFF393939),

        // Bouton "Enregistrer" visible uniquement quand le buffer est non-vide
        bottomNavigationBar: _alimentsEnAttente.isNotEmpty
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTotalBar(),
                      const SizedBox(height: 15), //8
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _confirmerAjouts,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF357E50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            _alimentsEnAttente.length == 1
                                ? 'Enregistrer l\'ajout'
                                : 'Enregistrer les ${_alimentsEnAttente.length} ajouts',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,

        body: SafeArea(
          child: Column(
            children: [
              // ── Barre de recherche ──
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left,
                          color: Colors.white, size: 30),
                      onPressed: _handleBack,
                    ),
                    Expanded(
                      child: SizedBox(
                        height: heightsearch,
                        child: TextField(
                          focusNode: _searchFocusNode,
                          controller: _searchController,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 0, horizontal: 0),
                            labelText: 'Rechercher un aliment',
                            labelStyle: const TextStyle(
                                color: Color(0x4CFFFFFF)),
                            floatingLabelStyle: const TextStyle(
                                color: Colors.white),
                            prefixIcon: const Icon(Icons.search,
                                color: Color(0x33D9D9D9)),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(heightsearch),
                              borderSide: const BorderSide(
                                  color: Color(0x33D9D9D9), width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(heightsearch),
                              borderSide: const BorderSide(
                                  color: Color(0x33D9D9D9)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0x33D9D9D9), width: 2),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          onChanged: _filtrer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Icône SCAN CODE
                    IconButton(
                      icon: SvgPicture.asset(
                        'assets/images/icon_scan_6.svg',
                        height: heightsearch,
                        fit: BoxFit.contain,
                      ),
                      onPressed: () async {
                        final result = await Navigator.push<Map<String, dynamic>>(
                          context,
                          MaterialPageRoute(builder: (_) => const ScanPage()),
                        );
                        if (result == null || !mounted) return;
                        final aliment = result['aliment'] as Aliment;
                        final quantite = result['quantite'] as double;
                        final portion = result['portionChoisie'] as Portion? ??
                            Portion(nom: 'g', poids: quantite);
                        _ajouterAuBuffer(aliment, quantite, portion);
                      },
                    ),
                  ],
                ),
              ),

              // Barre de chargement discrète pendant l'appel API
              if (_isSearching)
                const LinearProgressIndicator(
                  minHeight: 2,
                  color: Color(0xFF357E50),
                  backgroundColor: Colors.transparent,
                ),

              // ── Contenu défilant : buffer + récents ou résultats de recherche ──
              Expanded(child: _buildListContent()),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
