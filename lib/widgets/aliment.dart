class Aliment {
  final String nom;
  final double calories;
  final double proteines;
  final double lipides;
  final double glucides;

  const Aliment({
    required this.nom,
    required this.calories,
    required this.proteines,
    required this.lipides,
    required this.glucides,
  });

  // Méthode pour obtenir les macros pour une certaine quantité en grammes
  Map<String, double> getMacrosPourQuantite(double quantite) {
    return {
      'calories': (calories / 100) * quantite,
      'proteines': (proteines / 100) * quantite,
      'lipides': (lipides / 100) * quantite,
      'glucides': (glucides / 100) * quantite,
    };
  }

  Map<String, dynamic> toJson() => {
  'nom': nom,
  'calories': calories,
  'proteines': proteines,
  'lipides': lipides,
  'glucides': glucides,
};


    factory Aliment.fromJson(Map<String, dynamic> json) {
    return Aliment(
      nom: json['nom'],
      calories: (json['calories'] as num).toDouble(),
      proteines: (json['proteines'] as num).toDouble(),
      lipides: (json['lipides'] as num).toDouble(),
      glucides: (json['glucides'] as num).toDouble(),
    );
  }

  
  
  @override
  String toString() {
    return '$nom - $calories kcal, P: $proteines, G: $glucides, L: $lipides';
  
  }
}

class AlimentConsomme {
  final Aliment aliment;
  double quantite;

  AlimentConsomme(this.aliment, this.quantite);

  Map<String, dynamic> toJson() => {
  'aliment': aliment.toJson(),
  'quantite': quantite,
};

factory AlimentConsomme.fromJson(Map<String, dynamic> json) {
  return AlimentConsomme(
    Aliment.fromJson(json['aliment']),
    (json['quantite'] as num).toDouble(),
  );
}
}
