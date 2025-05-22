import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cal_track_v1/models/user_data.dart';
import 'package:cal_track_v1/widgets/aliment.dart';

class LocalStorageService {
  static const String _userKey = 'user_data';

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

  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

    static Future<void> saveAlimentsDuJour(String userId, List<AlimentConsomme> aliments) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = aliments.map((a) => a.toJson()).toList();
    await prefs.setString('alimentsDuJour_$userId', jsonEncode(jsonList));
  }

  static Future<List<AlimentConsomme>> loadAlimentsDuJour(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('alimentsDuJour_$userId');
    
    if (jsonString == null) return [];

    final List<dynamic> decodedList = jsonDecode(jsonString);
    
    return decodedList
    .map((item) => AlimentConsomme.fromJson(item))
    .toList();
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
  macros.forEach((key, value) {
    prefs.setInt('macros_${userId}_$key', value);
  });
}

static Future<Map<String, double>?> loadMacros(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  final keys = [
    'calories_min', 'calories_max',
    'prot_min', 'prot_max',
    'lipides_min', 'lipides_max',
    'glucides_min', 'glucides_max',
  ];
  
  final result = <String, double>{};
  for (var key in keys) {
    final value = prefs.getDouble('macros_${userId}_$key');
    if (value == null) return null; // Si une valeur est manquante, retourne null
    result[key] = value;
  }
  return result;
}



}
