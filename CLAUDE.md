# CLAUDE.md — forkshot

## 0. Règles de build

**À chaque demande de génération d'une nouvelle version de l'application**, incrémenter le `versionCode` dans [pubspec.yaml](pubspec.yaml) avant de builder (ex: `1.0.0+3` → `1.0.0+4`). Le Play Store rejette tout build avec un code déjà utilisé.

---

## 1. Objectif de l'application

**forkshot** est une application mobile de suivi nutritionnel (calories + macronutriments) orientée performance et simplicité. Elle s'adresse à des personnes actives qui veulent suivre leurs apports sans peser chaque gramme au gramme près.

Philosophie centrale : afficher une **plage cible** (min–max) plutôt qu'un objectif ponctuel. L'utilisateur est dans la zone verte s'il se trouve entre le min et le max — pas besoin d'atteindre un chiffre exact.

Distribuée sur **App Store** (iOS) et **Google Play Store** (Android).

---

## 2. Architecture du projet

```
lib/
├── main.dart                    # Point d'entrée, init Firebase, orientation, edge-to-edge
├── firebase_options.dart        # Config Firebase auto-générée
│
├── Pages/                       # Écrans complets (un fichier = un écran)
│   ├── splashscreen.dart        # Écran de démarrage + routage auth
│   ├── splash_transition.dart   # Animation du curseur oscillant
│   ├── connexion_page.dart      # Login Firebase
│   ├── inscription_page.dart    # Création de compte + politique conf.
│   ├── donnees_utilisateur.dart # Saisie du profil nutritionnel
│   ├── tableaudebord.dart       # Dashboard principal (suivi du jour)
│   ├── liste_aliments_page.dart # Recherche + ajout d'aliments
│   ├── scancode_page.dart       # Scanner code-barre
│   ├── stats_page.dart          # Statistiques (jour / semaine / mois)
│   ├── historique_page.dart     # Historique des journées passées (codé, non accessible depuis la nav)
│   ├── guide_page.dart          # Hub d'aide + sous-pages éditoriales
│   ├── politique_confidentialite_page.dart  # Page RGPD
│   └── loading_screen.dart      # Écran de chargement (non utilisé en prod)
│
├── models/                      # Structures de données pures
│   ├── aliment.dart             # Aliment, AlimentConsomme, Portion, enum Repas
│   ├── user_data.dart           # UserModel (profil utilisateur)
│   └── local_data.dart          # (structure secondaire, peu utilisée)
│
├── services/                    # Logique métier et accès données
│   ├── formules_calories.dart   # CalculateurNutrition : MB, maintien, macros
│   ├── local_storage_service.dart # SharedPreferences : aliments/macros/favoris/recents
│   ├── basededonnees.dart       # Chargement et recherche dans le CSV CIQUAL
│   ├── csv_database.dart        # Parser CSV bas niveau
│   ├── openfoodfacts_api.dart   # Appels REST OpenFoodFacts (search + barcode)
│   ├── excel_service.dart       # Lecture Excel (obsolète, remplacé par le calcul dynamique)
│   └── test_csv.dart            # Script de dev pour tester le CSV (non utilisé en prod)
│
└── widgets/                     # Composants réutilisables
    ├── groupe_barre.dart        # Barre macro animée avec zones colorées
    ├── quantite_aliment.dart    # Sélecteur de quantité avec expressions math
    ├── calendrier_panel.dart    # Sélecteur de date avec indicateurs
    ├── slider.dart              # Slider custom (zones brown/green/red)
    ├── valeurcompteur.dart      # Affichage d'une valeur numérique avec unité
    ├── color_utils.dart         # Calcul de couleur HSL pour les barres macro
    ├── defilement_page.dart     # Transition de page avec défilement
    └── appbar.dart              # AppBar custom (peu utilisée)

assets/
├── data/ciqual4.csv             # Base ANSES-CIQUAL (~5 000 aliments certifiés)
├── images/                      # Illustrations
└── icons/                       # Icône de l'app
```

**Flux de navigation :**
`SplashScreen` → (profil existant OU nouveau) → `DonneesUtilisateur` → `TableauDeBord` ← → `ListeAlimentsPage` / `StatsPage` / `GuidePage` / `DonneesUtilisateur`

L'inscription Firebase est **optionnelle** (mode invité par défaut). Le `SplashScreen` redirige vers `TableauDeBord` si un profil local existe, vers `DonneesUtilisateur` sinon — sans vérifier l'état Firebase Auth.

---

## 3. Packages utilisés et pourquoi

| Package | Version | Rôle |
|---|---|---|
| `firebase_core` + `firebase_auth` + `cloud_firestore` | ^3/5/5 | Auth utilisateur + sync cloud des données |
| `shared_preferences` | ^2.2.2 | Persistance locale (aliments du jour, macros, recents, favoris) |
| `http` | ^1.3.0 | Appels REST vers l'API OpenFoodFacts |
| `csv` | ^6.0.0 | Parsing du fichier CIQUAL (`ciqual4.csv`) |
| `mobile_scanner` | ^6.0.0 | Scanner code-barre via caméra |
| `permission_handler` | ^11.0.0 | Demande de permissions caméra (Android/iOS) |
| `flutter_svg` | ^2.1.0 | Affichage d'icônes SVG dans la liste aliments |
| `math_expressions` | ^2.4.0 | Évaluation d'expressions dans le champ quantité (ex: `100+50`) |
| `flutter_screenutil` | ^5.9.0 | Adaptation responsive — design size référence : 375×667 (iPhone SE) |
| `excel` | ^4.0.6 | Lecture Excel (vestige de l'ancien système de macros, non utilisé en prod) |
| `flutter_lints` | dev | Linting Dart standard |
| `flutter_launcher_icons` | dev | Génération des icônes d'application |

---

## 4. Fonctionnalités déjà implémentées

### Authentification
- Login email/mot de passe (Firebase Auth)
- Création de compte avec validation (prénom, email, mot de passe ≥ 6 chars)
- Réinitialisation de mot de passe par email
- Acceptation de la politique de confidentialité obligatoire à l'inscription
- Auto-complétion email depuis les sessions précédentes
- Splash screen avec animation + routage automatique selon l'état auth

### Profil utilisateur
- Saisie : sexe, poids, taille, âge, niveau d'activité, type de sport, objectif
- Validations : poids 30–300 kg, taille 100–250 cm, âge 10–100 ans
- Alerte santé si IMC < 18,5 et objectif = déficit (liens ANAB, FFAB, MangerBouger)
- Sauvegarde locale (SharedPreferences) + sync Firestore
- `UserModel.fromJson` gère deux formats de clés : local (camelCase) et Firestore (capitalisé)

### Dashboard — suivi du jour
- Barre de calories animée avec trois zones : brun (sous le min), vert (dans la plage), rouge (au-delà du max)
- 4 barres macro : Protéines, Lipides, Glucides, Fibres — toutes avec min/max calculés
- Navigation jour par jour (±7 jours depuis aujourd'hui) via flèches et sélecteur de date
- Consultation des jours passés avec leurs macros figées (snapshot)
- Bouton d'ajustement manuel des calories (±100 kcal, déverrouillé à la demande)
- Bouton "Calcul automatique" pour revenir aux valeurs de la formule
- Sections repas accordéon : Petit-déjeuner, Déjeuner, Dîner, Collation
- Swipe gauche pour supprimer un aliment
- Modification rapide de quantité via menu déroulant (5g à 150g)
- Tap sur le nom → sélecteur de quantité précis
- AppBar collant avec fond flouté (BackdropFilter)
- Barre de navigation basse collante avec fond flouté

### Recherche et ajout d'aliments
- Dual source : CIQUAL local (prioritaire) + OpenFoodFacts API (secondaire, débounce 400ms)
- Recherche insensible aux accents
- Ranking des résultats : correspondance exacte > CIQUAL > avec portions > score de complétude OFF
- Affichage des aliments récents quand la recherche est vide (20 derniers, quantités mémorisées)
- Favoris persistants (marqués d'une coche)
- Buffer multi-aliments : ajouter plusieurs aliments avant de confirmer
- Scanner code-barre (mobile_scanner) avec torch et dialogue "produit non trouvé"

### Sélecteur de quantité
- Affichage en temps réel des macros recalculées
- Expressions mathématiques supportées (`+`, `−`, `×`, `÷`)
- Sélecteur de portion nommée (ex: "1 biscuit") avec fallback en grammes

### Statistiques
- Onglets : Aujourd'hui / Semaine (7j) / Mois (30j)
- Barres visuelles pour calories, protéines, lipides, glucides, fibres
- Moyennes calculées sur les jours avec données uniquement

### Historique
- Page `HistoriquePage` codée et fonctionnelle (liste des journées passées avec totaux)
- Non accessible depuis la navigation principale (le bouton "Journal" est inactif)

### Guide
- Hub avec 4 sous-pages : Guide d'utilisation, Méthodes de calcul, À propos, Codes couleur
- Politique de confidentialité RGPD complète

### Persistance
- Données locales par clé `userId_date` dans SharedPreferences
- Snapshot des macros figées à chaque changement de journée
- Fallback cascade pour les macros d'un jour passé : snapshot exact → snapshot antérieur le plus proche → macros courantes

---

## 5. Fonctionnalités en cours / manquantes

- **Mode invité (guest-first)** : à implémenter — l'app doit fonctionner sans compte Firebase ; un UUID local (`guest_id` dans SharedPreferences) remplace le `uid` Firebase pour les clés de données ; l'inscription reste proposée comme option de sauvegarde cloud dans les paramètres du profil
- **Journal (HistoriquePage)** : codé mais non branché dans la nav bar (bouton "Journal" inactif)
- **Suivi du poids** : aucune fonctionnalité de saisie ou courbe de poids dans le temps
- **Notifications** : aucun rappel ou notification push
- **Export des données** : `ExcelService` existe mais n'est pas utilisé en production
- **Synchronisation Firestore des aliments** : les aliments du jour sont uniquement en local (SharedPreferences), Firestore ne stocke que le profil utilisateur
- **Mode hors-ligne explicite** : pas de feedback visuel si la recherche OFF échoue
- **Images produits** : pas d'affichage des photos des aliments OpenFoodFacts

---

## 6. Conventions de code

- **Langue** : code en français (variables, méthodes, commentaires, labels UI)
- **Fichiers** : snake_case — ex: `liste_aliments_page.dart`, `local_storage_service.dart`
- **Classes** : PascalCase — ex: `TableauDeBord`, `AlimentConsomme`
- **Variables/méthodes** : camelCase — ex: `_alimentsDuJour`, `_chargerAliments()`
- **Constantes de layout** : `const` au niveau fichier en majuscules partielles — ex: `const double _espacementAliments = 8`
- **Privé** : préfixe `_` pour tout ce qui est privé à la classe ou au fichier
- **Widgets** : un fichier par page complète dans `Pages/`, composants réutilisables dans `widgets/`
- **Commentaires** : les blocs `// import ...` commentés en tête de fichier sont des imports alternatifs conservés intentionnellement (ne pas supprimer)
- **Imports** : chemin absolu `package:cal_track_v1/...` pour les imports internes
- **Async** : `async/await` partout, pas de `.then()` chaîné
- **Null safety** : `late` pour les variables initialisées dans `initState()`, `?` pour les optionnels réels

---

## 7. Décisions techniques importantes

### Guest-first : pas de compte requis
L'app fonctionne intégralement sans compte Firebase. À la première ouverture, un UUID est généré et stocké dans SharedPreferences sous la clé `guest_id` — il sert de `userId` pour toutes les clés de données locales. Si l'utilisateur crée ensuite un compte Firebase, son `uid` remplace le `guest_id` et les données locales migrent sous la nouvelle clé. L'inscription est proposée dans les paramètres comme "Sauvegarder mes données sur le cloud".

### Local-first, cloud en backup
Les aliments du jour et le profil sont sauvegardés en local (SharedPreferences) avant tout. Firestore est utilisé uniquement pour le profil utilisateur connecté, pas pour les journaux alimentaires. Cela assure un fonctionnement offline complet y compris en mode invité.

### Plage cible plutôt qu'objectif fixe
Toutes les macros s'affichent en min/max, jamais en valeur unique. Le calcul utilise Mifflin-St Jeor avec poids de calcul corrigé (PDC) : si l'IMC est hors norme, on calcule les protéines sur le poids idéal plutôt que le poids réel.

### Snapshot des macros par journée
À chaque changement de journée, les macros courantes sont figées dans un snapshot daté. Consulter un jour passé charge le snapshot de ce jour — ce qui permet à l'utilisateur de voir les objectifs qui étaient les siens ce jour-là, même s'il a modifié son profil depuis.

### Deux sources d'aliments avec ranking
CIQUAL (CSV local, ~5 000 aliments ANSES certifiés) est chargé au démarrage et interrogé en synchrone. OpenFoodFacts (REST) est appelé en parallèle avec debounce 400ms. Les résultats sont fusionnés avec CIQUAL prioritaire, puis triés par pertinence (correspondance exacte > présence de portions > score de complétude).

### flutter_screenutil avec design size iPhone SE (375×667)
Toutes les tailles de texte et d'espacement utilisent `.sp` et `.w`/`.h` de screenutil. La taille de référence est 375×667. Ne pas mélanger pixels absolus et valeurs screenutil dans un même widget.

### Mode immersif edge-to-edge
`SystemUiMode.edgeToEdge` est activé dans `main.dart`. Les barres système (status bar + nav bar Android) sont transparentes. L'AppBar et la bottom nav bar utilisent `BackdropFilter` + `SafeArea` pour ne pas se superposer au contenu système.

### Orientation portrait bloquée
`SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])` est appelé au démarrage. Toute l'UI est conçue portrait uniquement.

### Expressions mathématiques dans la saisie de quantité
Le package `math_expressions` est utilisé pour évaluer les expressions saisies dans le champ quantité. Les opérateurs `+`, `−`, `×`, `÷` sont remplacés avant parsing. Cela permet à l'utilisateur d'écrire `100+50` ou `3×30` directement.

### `UserModel.fromJson` double format de clés
Firestore stocke les données avec des clés lisibles en français capitalisé (ex: `"Poids"`, `"Niveau d'activité physique"`). Le cache local utilise des clés camelCase (ex: `"poids"`, `"nActivite"`). `fromJson` gère les deux avec un fallback (`json['poids'] ?? json['Poids']`). Ne pas changer ce comportement sans migrer les données Firestore.
