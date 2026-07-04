import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cal_track_v1/models/user_data.dart';
import 'package:cal_track_v1/models/aliment.dart';

class LocalStorageService {

  // Retourne l'uid Firebase si connecté, sinon crée/récupère un UUID guest local
  static Future<String> getCurrentUserId() async {
    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    if (firebaseUid != null) return firebaseUid;

    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('guest_id');
    if (existing != null) return existing;

    final uuid = _generateUUID();
    await prefs.setString('guest_id', uuid);
    return uuid;
  }

  static String _generateUUID() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String h(int v) => v.toRadixString(16).padLeft(2, '0');
    return '${h(bytes[0])}${h(bytes[1])}${h(bytes[2])}${h(bytes[3])}-'
        '${h(bytes[4])}${h(bytes[5])}-'
        '${h(bytes[6])}${h(bytes[7])}-'
        '${h(bytes[8])}${h(bytes[9])}-'
        '${h(bytes[10])}${h(bytes[11])}${h(bytes[12])}${h(bytes[13])}${h(bytes[14])}${h(bytes[15])}';
  }

  static Future<void> saveUserData(String userId, UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    //final jsonString = json.encode(user.toJson());
    await prefs.setString('userData_$userId', jsonEncode(user.toJson()));
  }

  static Future<UserModel?> loadUserData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('userData_$userId');

    if (jsonString == null) return null; 
      
      final jsonData = json.decode(jsonString);
      return UserModel.fromJson(jsonData);
    
    
  }

  static Future<void> clearUserData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData_$userId');
  }

  // Formate une date en "yyyy-MM-dd" pour les clés SharedPreferences
  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static Future<void> saveAlimentsDuJour(String userId, List<AlimentConsomme> aliments, String date) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = aliments.map((a) => a.toJson()).toList();
    await prefs.setString('alimentsDuJour_${userId}_$date', jsonEncode(jsonList));
  }

  static Future<List<AlimentConsomme>> loadAlimentsDuJour(String userId, String date) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('alimentsDuJour_${userId}_$date');

    if (jsonString == null) return [];

    final List<dynamic> decodedList = jsonDecode(jsonString);

    return decodedList
    .map((item) => AlimentConsomme.fromJson(item))
    .toList();
  }

  // Retourne la liste des dates (yyyy-MM-dd) pour lesquelles un journal existe,
  // triées de la plus récente à la plus ancienne
  static Future<void> saveFavoris(String userId, Set<String> noms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favoris_$userId', noms.toList());
  }

  static Future<Set<String>> loadFavoris(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('favoris_$userId') ?? []).toSet();
  }

  static Future<List<String>> getJoursAvecDonnees(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = 'alimentsDuJour_${userId}_';
    final dates = prefs
        .getKeys()
        .where((k) => k.startsWith(prefix))
        .map((k) => k.replaceFirst(prefix, ''))
        .toList();
    dates.sort((a, b) => b.compareTo(a)); // plus récent en premier
    return dates;
  }


  // ── Aliments épinglés (persistance quotidienne) ──────────────────────────

  static Future<List<AlimentConsomme>> loadPinnedItems(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('pins_$userId');
    if (jsonString == null) return [];
    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded.map((item) => AlimentConsomme.fromJson(item as Map<String, dynamic>)).toList();
  }

  static Future<void> savePinnedItems(String userId, List<AlimentConsomme> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = items.map((a) => a.toJson()).toList();
    await prefs.setString('pins_$userId', jsonEncode(jsonList));
  }

  // Ajoute ou retire l'aliment du store de pins selon s'il est déjà présent.
  static Future<void> togglePin(String userId, AlimentConsomme item) async {
    final pins = await loadPinnedItems(userId);
    final idx = pins.indexWhere(
      (p) => p.aliment.nom == item.aliment.nom && p.repas == item.repas,
    );
    if (idx >= 0) {
      pins.removeAt(idx);
    } else {
      pins.add(AlimentConsomme(item.aliment, item.quantite, repas: item.repas, estEpingle: true));
    }
    await savePinnedItems(userId, pins);
  }

  // Retire définitivement l'aliment du store de pins (utilisé lors d'une suppression définitive).
  static Future<void> removePin(String userId, AlimentConsomme item) async {
    final pins = await loadPinnedItems(userId);
    pins.removeWhere((p) => p.aliment.nom == item.aliment.nom && p.repas == item.repas);
    await savePinnedItems(userId, pins);
  }

  // Nettoie le pin sur toutes les dates depuis aujourd'hui, sauf [exclureDate]
  // (le jour en cours d'édition, déjà géré par la vue).
  // - Aujourd'hui : retire estEpingle sans supprimer l'item.
  // - Jours futurs : supprime l'item entièrement.
  static Future<void> nettoyerPinGlobal(String userId, AlimentConsomme item, String exclureDate) async {
    final today = formatDate(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final prefix = 'alimentsDuJour_${userId}_';
    final dates = prefs
        .getKeys()
        .where((k) => k.startsWith(prefix))
        .map((k) => k.replaceFirst(prefix, ''))
        .where((d) => d.compareTo(today) >= 0 && d != exclureDate)
        .toList();

    for (final date in dates) {
      final aliments = await loadAlimentsDuJour(userId, date);
      bool modified = false;
      if (date == today) {
        for (final a in aliments) {
          if (a.aliment.nom == item.aliment.nom && a.repas == item.repas && a.estEpingle) {
            a.estEpingle = false;
            modified = true;
          }
        }
      } else {
        final avant = aliments.length;
        aliments.removeWhere((a) => a.aliment.nom == item.aliment.nom && a.repas == item.repas);
        modified = aliments.length != avant;
      }
      if (modified) await saveAlimentsDuJour(userId, aliments, date);
    }
  }

  // Met à jour la quantité d'un pin existant (propagée aux jours futurs).
  static Future<void> updatePinQuantite(String userId, AlimentConsomme item) async {
    final pins = await loadPinnedItems(userId);
    final idx = pins.indexWhere(
      (p) => p.aliment.nom == item.aliment.nom && p.repas == item.repas,
    );
    if (idx >= 0) {
      pins[idx] = AlimentConsomme(item.aliment, item.quantite, repas: item.repas, estEpingle: true);
      await savePinnedItems(userId, pins);
    }
  }

  static Future<void> saveRecents(String userId, List<Aliment> recents) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = recents.map((a) => a.toJson()).toList();
    await prefs.setString('recents_$userId', jsonEncode(jsonList));
  }

  static Future<List<Aliment>> loadRecents(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('recents_$userId');
    if (jsonString == null) return [];
    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded
        .map((item) => Aliment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveRecentsQuantites(String userId, Map<String, Map<String, dynamic>> quantites) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('recentsQuantites_$userId', jsonEncode(quantites));
  }

  static Future<Map<String, Map<String, dynamic>>> loadRecentsQuantites(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('recentsQuantites_$userId');
    if (jsonString == null) return {};
    final Map<String, dynamic> decoded = jsonDecode(jsonString);
    return decoded.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)));
  }

  static Future<void> saveSliderValue(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('slider_value', value);
  }

  static Future<double> loadSliderValue() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('slider_value') ?? 0.0; // valeur par défaut
  }


  static Future<void> saveMacros(String userId, Map<String, int> macros) async {
  final prefs = await SharedPreferences.getInstance();
  // setDouble pour correspondre à loadMacros qui utilise getDouble()
  // (SharedPreferences distingue strictement setInt et setDouble)
  macros.forEach((key, value) {
    prefs.setDouble('macros_${userId}_$key', value.toDouble());
  });
}

static Future<Map<String, double>?> loadMacros(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  final keys = [
    'calories_min', 'calories_max',
    'prot_min', 'prot_max',
    'lipides_min', 'lipides_max',
    'glucides_min', 'glucides_max',
    'fibres_min', 'fibres_max',
  ];

  final result = <String, double>{};
  for (var key in keys) {
    final value = prefs.getDouble('macros_${userId}_$key');
    if (value == null) return null; // Si une valeur est manquante, retourne null
    result[key] = value;
  }
  return result;
}

// Sauvegarde un snapshot figé des macros pour un jour passé (déclenchée au changement de journée)
static Future<void> saveMacrosSnapshot(String userId, String date, Map<String, int> macros) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('macros_snapshot_${userId}_$date', jsonEncode(macros));
}

// Charge les macros applicables à une date donnée :
// 1. Snapshot exact du jour → 2. Snapshot le plus récent avant ce jour → 3. Macros courantes
static Future<Map<String, double>?> loadMacrosForDate(String userId, String date) async {
  final prefs = await SharedPreferences.getInstance();

  final snapshotStr = prefs.getString('macros_snapshot_${userId}_$date');
  if (snapshotStr != null) {
    final Map<String, dynamic> decoded = jsonDecode(snapshotStr);
    return decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  // Fallback : chercher le snapshot le plus récent avant cette date
  final prefix = 'macros_snapshot_${userId}_';
  final datesAvant = prefs
      .getKeys()
      .where((k) => k.startsWith(prefix))
      .map((k) => k.replaceFirst(prefix, ''))
      .where((d) => d.compareTo(date) < 0)
      .toList()
    ..sort((a, b) => b.compareTo(a)); // plus récent en premier

  if (datesAvant.isNotEmpty) {
    final closestStr = prefs.getString('$prefix${datesAvant.first}');
    if (closestStr != null) {
      final Map<String, dynamic> decoded = jsonDecode(closestStr);
      return decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
    }
  }

  // Aucun snapshot disponible : le caller décidera quoi afficher
  return null;
}



}
