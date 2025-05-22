//import 'package:cal_track_v1/services/formules_calories.dart';
// const calories = 2500;
import 'package:cal_track_v1/models/user_data.dart';
//import 'package:cal_track_v1/Pages/donnees_utilisateur.dart';
//import 'package:cal_track_v1/Pages/tableaudebord.dart';

class CalculateurNutrition {
  final UserModel user;    

  late double pdc; // poids de calcul corrigé
  late final double coefSport;
  late final double coefActivite;

  CalculateurNutrition(this.user) {
    pdc = _calculPdc();
    coefSport = getCoefSport(user.typeSport);
    coefActivite = getCoefActivite(user.nActivite);
  }

  double _calculIMC() {
    double tailleMetres = user.taille / 100;
    return user.poids / (tailleMetres * tailleMetres);
  }

  double _calculPdc() {
    double imc = _calculIMC();
    if (imc < 18.5) {
      return 18.5 * (user.taille / 100) * (user.taille / 100);
    } else if (imc > 24.9) {
      return 24.9 * (user.taille / 100) * (user.taille / 100);
    } else {
      return user.poids;
    }
  }

  double _calculMB() {
    if (user.sexe == 'homme') {
      return 46.681 + (11.6985 * user.poids) + (5.5245 * user.taille) - (5.3385 * user.age);
    } else {
      return 143.2965 + (9.6235 * user.poids) + (4.674 * user.taille) - (4.665 * user.age);
    }
  }

  double _calculMaintien() {
    return _calculMB() * coefActivite;
  }

  Map<String, int> calculCalories() {
    double maintien = _calculMaintien();
    double caloriesMin;
    double caloriesMax;

    if (user.objectif == 'déficit') {
      caloriesMin = (maintien * 0.9) - 100;
      caloriesMax = caloriesMin + 200;
    } else if (user.objectif == 'pdm') {
      caloriesMin = (maintien * 1.1) - 100;
      caloriesMax = caloriesMin + 200;
    } else { // maintien
      caloriesMin = maintien - 100;
      caloriesMax = maintien + 100;
    }

    return {
      'calories_min': _arrondir100(caloriesMin),
      'calories_max': _arrondir100(caloriesMax),
    };
  }

  int _arrondir100(double valeur) {
    return (valeur / 100).round() * 100;
  }

  Map<String, int> getMacros() {
  final calories = calculCalories();
  final caloriesMin = calories['calories_min']!;
  final caloriesMax = calories['calories_max']!;

  final protMin1 = user.poids * coefSport;
  final protMin2 = (caloriesMin * 0.15) / 4;
  final protMin = (protMin1 > protMin2 ? protMin1 : protMin2).round();

  final protMax1 = pdc * 1.9;
  final protMax2 = (caloriesMax * 0.2) / 4;
  final protMax = (protMax1 > protMax2 ? protMax1 : protMax2).round();

  final lipidesMin1 = ((user.taille - 150) * 0.5) + 30;
  final lipidesMin2 = (caloriesMin * 0.2) / 9;
  final lipidesMin = (lipidesMin1 > lipidesMin2 ? lipidesMin1 : lipidesMin2).round();
  final lipidesMax = ((caloriesMax * 0.3) / 9).round();

  final glucidesMin = ((caloriesMin - (4 * protMax) - (9 * lipidesMax)) / 4).round();
  final glucidesMax = ((caloriesMax - (4 * protMin) - (9 * lipidesMin)) / 4).round();

  return {
    'calories_min': caloriesMin,
    'calories_max': caloriesMax,
    'prot_min': protMin,
    'prot_max': protMax,
    'lipides_min': lipidesMin,
    'lipides_max': lipidesMax,
    'glucides_min': glucidesMin,
    'glucides_max': glucidesMax,
  };
}

double getCoefActivite(String nActivite) {
  switch (nActivite.toLowerCase()) {
    case 'sédentaire':
      return 1.2;
    case 'modéré':
      return 1.375;
    case 'actif':
      return 1.55;
    case 'très actif':
      return 1.725;
    case 'extrêmement actif':
      return 1.9;
    default:
      return 1.2; // valeur par défaut
  }
}

double getCoefSport(String typeSport) {
  switch (typeSport.toLowerCase()) {
    case 'loisir':
      return 1.0;
    case 'endurance':
      return 1.3;
    case 'force':
      return 1.6;
    default:
      return 1.0;
  }
}

}