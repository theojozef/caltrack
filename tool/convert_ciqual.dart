// ignore_for_file: avoid_print
// Convertit les fichiers XML CIQUAL 2025 (dossier assets/data/ciqual-2025_11_03/)
// en assets/data/ciqual4.csv prêt pour l'app Flutter.
//
// Utilisation (depuis la racine du projet) :
//   dart run tool/convert_ciqual.dart
//
// Fichiers sources :
//   alim_*.xml   → noms des aliments (alim_code + alim_nom_fr)
//   compo_*.xml  → valeurs nutritionnelles (alim_code + const_code + teneur)
//
// const_codes utilisés :
//   328   → Energie EU kcal/100g     (prioritaire)
//   333   → Energie N×Jones kcal/100g (fallback)
//   25000 → Protéines N×Jones         (prioritaire)
//   25003 → Protéines N×6.25          (fallback)
//   31000 → Glucides
//   34100 → Fibres alimentaires
//   40000 → Lipides

import 'dart:io';
import 'dart:convert';
import 'package:xml/xml.dart';

// ── Chemin du dossier source (relatif à la racine du projet) ──
const _srcDir = 'assets/data/ciqual-2025_11_03';
const _dst    = 'assets/data/ciqual4.csv';

// ── Codes nutriments ──
const _cKcalEu    = '328';
const _cKcalJones = '333';
const _cProt      = '25000';
const _cProt625   = '25003';
const _cGluc      = '31000';
const _cFibres    = '34100';
const _cLip       = '40000';

/// Convertit un texte CIQUAL en double (0.0 si absent ou tiret).
double _parse(String s) {
  s = s.trim();
  if (s.isEmpty || s == '-') { return 0.0; }
  return double.tryParse(s.replaceAll(',', '.')) ?? 0.0;
}

/// Formate un double : 2 décimales max, sans zéros inutiles.
String _fmt(double v) {
  if (v == 0.0) { return '0'; }
  var s = v.toStringAsFixed(2);
  s = s.replaceAll(RegExp(r'0+$'), '');
  if (s.endsWith('.')) { s = s.substring(0, s.length - 1); }
  return s;
}

/// Trouve le premier fichier XML du dossier dont le nom commence par [prefix].
File _xmlFile(String prefix) {
  final dir = Directory(_srcDir);
  final match = dir.listSync().whereType<File>().firstWhere(
    (f) => f.uri.pathSegments.last.startsWith(prefix),
    orElse: () => throw FileSystemException('Fichier "$prefix*.xml" introuvable dans $_srcDir'),
  );
  return match;
}

void main() {
  // ── 1. Noms des aliments ──────────────────────────────────────────────────
  print('Lecture des aliments...');
  final alimXml = XmlDocument.parse(_xmlFile('alim_').readAsStringSync());
  final Map<String, String> noms = {};
  for (final node in alimXml.findAllElements('ALIM')) {
    final code = node.getElement('alim_code')?.innerText.trim() ?? '';
    final nom  = node.getElement('alim_nom_fr')?.innerText.trim() ?? '';
    if (code.isNotEmpty && nom.isNotEmpty) { noms[code] = nom; }
  }
  print('  → ${noms.length} aliments trouvés');

  // ── 2. Valeurs nutritionnelles ────────────────────────────────────────────
  print('Lecture des compositions (peut prendre quelques secondes)...');
  final compoXml = XmlDocument.parse(_xmlFile('compo_').readAsStringSync());

  // compo[alim_code][const_code] = teneur
  final Map<String, Map<String, double>> compo = {};
  for (final node in compoXml.findAllElements('COMPO')) {
    final alimCode  = node.getElement('alim_code')?.innerText.trim()  ?? '';
    final constCode = node.getElement('const_code')?.innerText.trim() ?? '';
    final teneur    = node.getElement('teneur')?.innerText             ?? '-';

    if (alimCode.isEmpty || constCode.isEmpty) { continue; }
    // On ne garde que les const_codes utiles
    if (!{_cKcalEu, _cKcalJones, _cProt, _cProt625, _cGluc, _cFibres, _cLip}
        .contains(constCode)) { continue; }

    compo.putIfAbsent(alimCode, () => <String, double>{})[constCode] = _parse(teneur);
  }
  print('  → ${compo.length} aliments avec données nutritionnelles');

  // ── 3. Génération du CSV ──────────────────────────────────────────────────
  print('Génération de $_dst...');
  final out = StringBuffer()
    ..writeln('alim_nom_fr;Energie (kcal/100 g);Protéines (g/100 g);Glucides (g/100 g);Lipides (g/100 g);Fibres (g/100 g)');

  int ok = 0, skip = 0;

  for (final entry in noms.entries) {
    final code = entry.key;
    final nom  = entry.value;
    final vals = compo[code] ?? {};

    final prot   = (vals[_cProt]  ?? 0) > 0 ? vals[_cProt]!  : (vals[_cProt625] ?? 0);
    final gluc   = vals[_cGluc]   ?? 0;
    final lip    = vals[_cLip]    ?? 0;
    final fibres = vals[_cFibres] ?? 0;

    // Énergie : EU kcal → N×Jones kcal → calcul depuis macros
    double kcal = vals[_cKcalEu] ?? 0;
    if (kcal <= 0) { kcal = vals[_cKcalJones] ?? 0; }
    if (kcal <= 0) { kcal = prot * 4 + gluc * 4 + lip * 9 + fibres * 2; }
    if (kcal <= 0) { skip++; continue; }

    out.writeln('$nom;${_fmt(kcal)};${_fmt(prot)};${_fmt(gluc)};${_fmt(lip)};${_fmt(fibres)}');
    ok++;
  }

  File(_dst).writeAsStringSync(out.toString(), encoding: utf8);
  print('✓  $ok aliments écrits dans $_dst  ($skip ignorés)');
}
