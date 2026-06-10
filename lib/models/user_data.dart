class UserModel {
  String sexe;  
  double poids;
  double taille;
  int age;
  String nActivite;
  String typeSport;
  String objectif;

  UserModel({
    required this.sexe,    
    required this.poids,
    required this.taille,
    required this.age,
    required this.nActivite,
    required this.typeSport,
    required this.objectif,    
  });

  Map<String, dynamic> toJson() => {
    'sexe': sexe,    
    'poids': poids,
    'taille': taille,
    'age': age,
    'nActivite': nActivite,
    'typeSport': typeSport,
    'objectif': objectif,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Clés minuscules = cache local (toJson), clés majuscules = Firestore
    return UserModel(
      sexe: json['sexe'] ?? json['Sexe'] ?? 'homme',
      poids: ((json['poids'] ?? json['Poids'] ?? 72) as num).toDouble(),
      taille: ((json['taille'] ?? json['Taille'] ?? 180) as num).toDouble(),
      age: (json['age'] ?? json['Âge'] ?? 25) as int,
      nActivite: json['nActivite'] ?? json['Niveau d\'activité physique'] ?? 'actif',
      typeSport: json['typeSport'] ?? json['Type d\'activité physique'] ?? 'endurance',
      objectif: json['objectif'] ?? json['Objectif'] ?? 'maintien',
    );
  }
}
