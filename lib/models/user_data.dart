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
  
  return UserModel(
    sexe: json['Sexe'] ?? 'homme', // ?? 'homme',
    poids: (json['Poids'] ?? 72 ).toDouble(), // ?? 72
    taille: (json['Taille'] ?? 180).toDouble(), // ?? 180
    age: json['Âge'] ?? 25, // ?? 25,
    nActivite: json['Niveau d\'activité physique'] ?? 'actif', // ?? 'actif',
    typeSport: json['Type d\'activité physique'] ?? 'loisir', // ?? 'force',
    objectif: json['Objectif'] ?? 'maintien', // ?? 'pdm',
  );
  }
}
