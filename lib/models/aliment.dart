enum Repas { petitDejeuner, dejeuner, diner, collation }

extension RepasLabel on Repas {
  String get label {
    switch (this) {
      case Repas.petitDejeuner: return 'Petit-déjeuner';
      case Repas.dejeuner:      return 'Déjeuner';
      case Repas.diner:         return 'Dîner';
      case Repas.collation:     return 'Collation';
    }
  }
}

class Aliment {
  final String nom;
  final double calories;
  final double proteines;
  final double lipides;
  final double glucides;
  final double fibres;
  final double sucresLibres;
  final List<Portion> portions;
  final double completeness; // 0.0–1.0, issu de OFF (0.0 pour CIQUAL)
  final bool isCiqual; // true = données issues de la base ANSES-CIQUAL (certifiées)

  bool dejaAjoute; // true si l'utilisateur l'a déjà ajouté

  Aliment({
    required this.nom,
    required this.calories,
    required this.proteines,
    required this.lipides,
    required this.glucides,
    required this.fibres,
    required this.sucresLibres,
    this.portions = const [],
    this.completeness = 0.0,
    this.isCiqual = false,
    this.dejaAjoute = false,
  });

  // Méthode pour obtenir les macros pour une certaine quantité en grammes
  Map<String, double> getMacrosPourQuantite(double quantite) {
    return {
      'calories': (calories / 100) * quantite,
      'proteines': (proteines / 100) * quantite,
      'lipides': (lipides / 100) * quantite,
      'glucides': (glucides / 100) * quantite,
      'fibres': (fibres / 100) * quantite,
      'sucres_libres': (sucresLibres / 100) * quantite,
    };
  }

  Map<String, dynamic> toJson() => {
  'nom': nom,
  'calories': calories,
  'proteines': proteines,
  'lipides': lipides,
  'glucides': glucides,
  'fibres': fibres,
  'sucres_libres': sucresLibres,
  'portions': portions.map((p) => {'nom': p.nom, 'poids': p.poids}).toList(),

};

// Fonction utilitaire pour retirer le poids d'une chaîne
static String _nettoyerNomPortion(String nom) {
  final regexPoids = RegExp(
    r'[\s,]*\(?.*?(\d+(?:[.,]\d+)?)\s*(g|grammes|ml|millilitres?|oz|ounces?)\)?[\s,]*',
      caseSensitive: false);
  
  // Supprime la portion de texte correspondant au poids et unités + ponctuation et espaces autour
  String nettoye = nom.replaceAll(regexPoids, '');

  // Supprimer virgules ou parenthèses résiduelles au début ou fin de chaîne
  nettoye = nettoye.replaceAll(RegExp(r'^[,\(\)\s]+|[,\(\)\s]+$'), '');

  return nettoye.trim();
}


  factory Aliment.fromJson(Map<String, dynamic> json) {
    
  // Extraction de la portion
  List<Portion> portions = [];

  // Nom brut éventuel fourni par OpenFoodFacts
  String? portionNomBrut = json['serving_name'] ??
                           json['serving_name_fr'];

  // 1. Extraction améliorée avec fallback
  if (json['serving_quantity'] != null) {
    final poids = (json['serving_quantity'] as num).toDouble();

    // Si pas de nom brut, on essaie d'en extraire un depuis serving_size
    if (portionNomBrut == null && json['serving_size'] != null) {
      portionNomBrut = json['serving_size'].toString().trim();
      // On découpe si format "20 g, un biscuit"
    }

    // Nom par défaut si rien trouvé
    portionNomBrut ??= 'Portion';
    portionNomBrut = _nettoyerNomPortion(portionNomBrut);

    portions.add(Portion(nom: portionNomBrut, poids: poids));
  }
  
  else if (json['serving_size'] != null) {  
  // 2. Tentative d'extraction du poids à partir d'une string comme "1 bar (50g)"
    final servingSize = json['serving_size'].toString();
    
    final regex = RegExp(r'(\d+(?:[.,]\d+)?)\s*(g|grammes|ml|millilitres?|oz|ounces?)', caseSensitive: false);
    
    final match = regex.firstMatch(servingSize);

    String portionNom = servingSize; // par défaut on garde tout
    
    if (match != null) {
      final poids = double.tryParse(match.group(1)!.replaceAll(',', '.'));
      if (poids != null) {
        // Retirer la partie du poids de la string
        portionNom = servingSize.replaceFirst(match.group(0)!, '').trim();
        portionNom = _nettoyerNomPortion(portionNom);
        portions.add(Portion(nom: portionNom, poids: poids));
      }
    }
  }
    
    return Aliment(
      nom: json['nom'],
      calories: (json['calories'] as num).toDouble(),
      proteines: (json['proteines'] as num).toDouble(),
      lipides: (json['lipides'] as num).toDouble(),
      glucides: (json['glucides'] as num).toDouble(),
      fibres: (json['fibres'] != null) 
        ? (json['fibres'] as num).toDouble() 
        : 0.0, // 👈 fallback
      sucresLibres: (json['sucres_libres'] != null) 
        ? (json['sucres_libres'] as num).toDouble() 
        : 0.0, // 👈 fallback
      portions: portions,
    );
  }

  
  
  @override
  String toString() {
    return '$nom - $calories kcal, P: $proteines, G: $glucides, L: $lipides, F: $fibres, Sucres libres: $sucresLibres';
  
  }
}

class AlimentConsomme {
  final Aliment aliment;
  double quantite;
  Repas? repas; // nullable pour compatibilité avec données existantes
  bool estEpingle;

  AlimentConsomme(this.aliment, this.quantite, {this.repas, this.estEpingle = false});

  Map<String, dynamic> toJson() => {
    'aliment': aliment.toJson(),
    'quantite': quantite,
    if (repas != null) 'repas': repas!.name,
    if (estEpingle) 'estEpingle': true,
  };

  factory AlimentConsomme.fromJson(Map<String, dynamic> json) {
    Repas? repas;
    final repasStr = json['repas'] as String?;
    if (repasStr != null) {
      // firstWhere avec orElse pour ne pas crasher sur une valeur inconnue
      repas = Repas.values.firstWhere(
        (r) => r.name == repasStr,
        orElse: () => Repas.dejeuner,
      );
    }
    return AlimentConsomme(
      Aliment.fromJson(json['aliment']),
      (json['quantite'] as num).toDouble(),
      repas: repas,
      estEpingle: json['estEpingle'] as bool? ?? false,
    );
  }
}

class Portion {
  final String nom; // ex : "1 cookie", "1 tasse", "1 pot"
  double poids; // en grammes

  Portion({
    required this.nom,
    required this.poids,
  });

  @override
  String toString() => "$nom ($poids g)";
}

