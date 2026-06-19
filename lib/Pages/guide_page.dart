import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Page hub ─────────────────────────────────────────────────────────────────

class GuidePage extends StatelessWidget {
  const GuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF393939),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                children: [
                  _NavButton(
                    icon: Icons.menu_book_rounded,
                    iconColor: const Color(0xFF357E50),
                    title: "Guide d'utilisation",
                    subtitle: "Philosophie & recommandations au quotidien",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GuideUtilisationPage()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _NavButton(
                    icon: Icons.calculate_rounded,
                    iconColor: const Color(0xFF5B9BD5),
                    title: "Méthodes de calcul",
                    subtitle: "D'où viennent les valeurs affichées",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MethodesCalculPage()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _NavButton(
                    icon: Icons.info_outline_rounded,
                    iconColor: const Color(0xFFE8A838),
                    title: "À propos",
                    subtitle: "Ce qu'est cette application et à qui elle s'adresse",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AProposPage()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 14),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Informations",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  "Guide, méthodes et à propos",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bouton de navigation ─────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF4A4A4A),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(18), width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Page 1 : Guide d'utilisation (ancien contenu) ────────────────────────────

class GuideUtilisationPage extends StatelessWidget {
  const GuideUtilisationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF393939),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                children: const [
                  _SectionCard(
                    icon: Icons.auto_awesome,
                    iconColor: Color(0xFF357E50),
                    title: "Principe",
                    content: _PrincipeContent(),
                  ),
                  SizedBox(height: 14),
                  _SectionCard(
                    icon: Icons.bar_chart_rounded,
                    iconColor: Color(0xFF5B9BD5),
                    title: "Utiliser les barres au quotidien",
                    content: _BarresContent(),
                  ),
                  SizedBox(height: 14),
                  _SectionCard(
                    icon: Icons.trending_down_rounded,
                    iconColor: Color(0xFFE8A838),
                    title: "Suivre votre évolution",
                    content: _EvolutionContent(),
                  ),
                  SizedBox(height: 14),
                  _SectionCard(
                    icon: Icons.loop_rounded,
                    iconColor: Color(0xFF9B59B6),
                    title: "La reverse diet",
                    content: _ReverseDietContent(),
                  ),
                  SizedBox(height: 14),
                  _SectionCard(
                    icon: Icons.warning_amber_rounded,
                    iconColor: Color(0xFFE05252),
                    title: "Avertissements",
                    content: _AvertissementsContent(),
                  ),
                  SizedBox(height: 14),
                  _ContactsCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 14),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Guide d'utilisation",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  "Philosophie & recommandations",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 2 : Méthodes de calcul ──────────────────────────────────────────────

class MethodesCalculPage extends StatelessWidget {
  const MethodesCalculPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF393939),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                children: const [
                  _SectionCard(
                    icon: Icons.monitor_weight_outlined,
                    iconColor: Color(0xFF5B9BD5),
                    title: "Poids de calcul (PDC)",
                    content: _PdcContent(),
                  ),
                  SizedBox(height: 14),
                  _SectionCard(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: Color(0xFFE8A838),
                    title: "Métabolisme de base (MB)",
                    content: _MbContent(),
                  ),
                  SizedBox(height: 14),
                  _SectionCard(
                    icon: Icons.directions_run_rounded,
                    iconColor: Color(0xFF357E50),
                    title: "Dépense totale (TDEE)",
                    content: _TdeeContent(),
                  ),
                  SizedBox(height: 14),
                  _SectionCard(
                    icon: Icons.track_changes_rounded,
                    iconColor: Color(0xFF9B59B6),
                    title: "Cibles caloriques",
                    content: _CiblesCaloriquesContent(),
                  ),
                  SizedBox(height: 14),
                  _SectionCard(
                    icon: Icons.egg_alt_outlined,
                    iconColor: Color(0xFFE05252),
                    title: "Protéines",
                    content: _ProteinesContent(),
                  ),
                  SizedBox(height: 14),
                  _SectionCard(
                    icon: Icons.water_drop_outlined,
                    iconColor: Color(0xFFE8A838),
                    title: "Lipides",
                    content: _LipidesContent(),
                  ),
                  SizedBox(height: 14),
                  _SectionCard(
                    icon: Icons.grain_rounded,
                    iconColor: Color(0xFF5B9BD5),
                    title: "Glucides & fibres",
                    content: _GlucidesContent(),
                  ),
                  SizedBox(height: 14),
                  _SectionCard(
                    icon: Icons.dataset_outlined,
                    iconColor: Color(0xFF357E50),
                    title: "Base de données nutritionnelles",
                    content: _BddContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 14),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Méthodes de calcul",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  "D'où viennent les valeurs affichées",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 3 : À propos ────────────────────────────────────────────────────────

class AProposPage extends StatelessWidget {
  const AProposPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF393939),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                children: const [
                  _SectionCard(
                    icon: Icons.lightbulb_outline_rounded,
                    iconColor: Color(0xFFE8A838),
                    title: "Qu'est-ce que cette application ?",
                    content: _AProposDefinitionContent(),
                  ),
                  SizedBox(height: 14),
                  _SectionCard(
                    icon: Icons.people_outline_rounded,
                    iconColor: Color(0xFF5B9BD5),
                    title: "À qui s'adresse-t-elle ?",
                    content: _AProposPublicContent(),
                  ),
                  SizedBox(height: 14),
                  _SectionCard(
                    icon: Icons.do_not_disturb_alt_rounded,
                    iconColor: Color(0xFFE05252),
                    title: "Ce que l'application n'est pas",
                    content: _AProposLimitesContent(),
                  ),
                  SizedBox(height: 14),
                  _SectionCard(
                    icon: Icons.favorite_outline_rounded,
                    iconColor: Color(0xFF357E50),
                    title: "Philosophie",
                    content: _AProposPhilosophieContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 14),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "À propos",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  "L'application et sa raison d'être",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section card générique ────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget content;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF4A4A4A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(18), width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 17),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          content,
        ],
      ),
    );
  }
}

// ── Contenus page 1 (guide utilisation) ─────────────────────────────────────

class _PrincipeContent extends StatelessWidget {
  const _PrincipeContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BodyText(
          "Cette application n'est pas un régime. C'est un outil de conscience alimentaire.",
          bold: true,
        ),
        SizedBox(height: 10),
        _BodyText(
          "Vous renseignez vos données personnelles (poids, taille, âge, niveau d'activité, objectif) et l'application calcule une estimation de vos besoins énergétiques journaliers de départ.",
        ),
        SizedBox(height: 10),
        _BodyText(
          "Ce chiffre est un point de départ, pas une vérité absolue. Chaque corps réagit différemment — l'objectif est d'observer, d'ajuster, et d'apprendre à vous connaître.",
        ),
        SizedBox(height: 10),
        _InfoBox(
          "L'idée centrale : manger suffisamment de bons aliments, pas le moins possible.",
        ),
      ],
    );
  }
}

class _BarresContent extends StatelessWidget {
  const _BarresContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BodyText(
          "Chaque jour, l'objectif est de renseigner vos aliments consommés et de viser que chaque barre de macronutriments se situe entre ses deux bornes.",
        ),
        SizedBox(height: 10),
        _BulletPoint(
          label: "Calories",
          text: "la borne inférieure garantit un apport minimal pour votre organisme ; la borne supérieure évite les excès non souhaités.",
        ),
        SizedBox(height: 8),
        _BulletPoint(
          label: "Protéines",
          text: "essentielles à la masse musculaire et à la satiété. Rester dans la plage assure un apport adéquat sans excès.",
        ),
        SizedBox(height: 8),
        _BulletPoint(
          label: "Lipides",
          text: "indispensables aux hormones et à l'absorption des vitamines. Ne pas les négliger.",
        ),
        SizedBox(height: 8),
        _BulletPoint(
          label: "Glucides",
          text: "principale source d'énergie. La plage est large : choisissez des sources de qualité (légumineuses, céréales complètes, fruits).",
        ),
        SizedBox(height: 10),
        _InfoBox(
          "Les bornes servent à stabiliser votre total calorique ET à assurer un bon équilibre nutritionnel. Rester dans les bornes tous les jours, c'est l'essentiel.",
        ),
        SizedBox(height: 10),
        _BodyText(
          "Vous ne serez pas parfait chaque jour — et c'est normal. C'est la régularité sur plusieurs jours qui compte, pas la perfection quotidienne.",
        ),
      ],
    );
  }
}

class _EvolutionContent extends StatelessWidget {
  const _EvolutionContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BodyText(
          "Ne jugez pas vos résultats sur 1 ou 2 jours. Le poids fluctue naturellement selon l'hydratation, le cycle hormonal, la digestion...",
        ),
        SizedBox(height: 12),
        _StepBox(
          number: "1",
          title: "Pesez-vous régulièrement",
          text: "Le même moment de la journée (idéalement le matin à jeun), et calculez une moyenne sur 5 à 7 jours consécutifs.",
        ),
        SizedBox(height: 8),
        _StepBox(
          number: "2",
          title: "Comparez les moyennes",
          text: "Si votre poids moyen diminue comme prévu → conservez les besoins actuels. S'il stagne ou augmente → passez à l'étape suivante.",
        ),
        SizedBox(height: 8),
        _StepBox(
          number: "3",
          title: "Ajustez progressivement",
          text: "Appuyez sur \"Ajuster les besoins\" et appuyez 2 fois sur la flèche ↓ (soit −200 kcal). Validez et testez ce nouveau total pendant 1 semaine complète.",
        ),
        SizedBox(height: 8),
        _StepBox(
          number: "4",
          title: "Réitérez si nécessaire",
          text: "Attendez toujours une semaine complète avant d'ajuster à nouveau. Les changements métaboliques sont lents — la patience est une stratégie.",
        ),
        SizedBox(height: 10),
        _InfoBox(
          "Ne descendez pas en dessous de 1 200 kcal pour les femmes et 1 500 kcal pour les hommes sans suivi médical. En dessous, les risques de carences et de perte musculaire augmentent fortement.",
        ),
      ],
    );
  }
}

class _ReverseDietContent extends StatelessWidget {
  const _ReverseDietContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BodyText(
          "La reverse diet (ou montée progressive des calories) est une stratégie à connaître pour ne pas tomber dans le piège de la restriction excessive.",
        ),
        SizedBox(height: 10),
        _BodyText(
          "Si vous avez diminué vos apports plusieurs fois et que vous vous retrouvez à manger très peu, votre métabolisme s'est probablement adapté à la baisse. Résultat : les résultats stagnent malgré une restriction importante.",
        ),
        SizedBox(height: 10),
        _BodyText(
          "La reverse diet consiste à remonter progressivement les calories (200 kcal par semaine) pour permettre au métabolisme de récupérer, tout en limitant la reprise de masse grasse.",
        ),
        SizedBox(height: 12),
        _InfoBox(
          "Si vous avez l'impression de ne plus pouvoir manger moins sans que ça marche, remonter les calories peut être la bonne décision à long terme. Ce n'est pas un échec — c'est de la stratégie.",
        ),
        SizedBox(height: 10),
        _BodyText(
          "Dans ce cas, utilisez la flèche ↑ dans \"Ajuster les besoins\" pour augmenter progressivement vos cibles, et observez votre évolution sur 2 à 4 semaines.",
        ),
      ],
    );
  }
}

class _AvertissementsContent extends StatelessWidget {
  const _AvertissementsContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BodyText(
          "Cette application est un outil de suivi, pas un dispositif médical. Elle ne remplace pas l'avis d'un professionnel de santé.",
          bold: true,
        ),
        SizedBox(height: 12),
        _BulletPoint(
          label: "Flexibilité avant tout",
          text: "Dépasser légèrement les bornes un jour n'a aucun impact significatif. La flexibilité est essentielle à une relation saine avec la nourriture.",
        ),
        SizedBox(height: 8),
        _BulletPoint(
          label: "Pas d'obsession",
          text: "Si le suivi vous génère du stress ou de l'anxiété, c'est un signal à prendre au sérieux. Faites une pause si nécessaire.",
        ),
        SizedBox(height: 8),
        _BulletPoint(
          label: "Profils particuliers",
          text: "Femmes enceintes ou allaitantes, adolescents, personnes souffrant ou ayant souffert de troubles alimentaires : consultez un professionnel avant d'utiliser cet outil.",
        ),
        SizedBox(height: 8),
        _BulletPoint(
          label: "Conditions médicales",
          text: "Diabète, insuffisance rénale, troubles cardiaques, ou toute pathologie chronique nécessitent un accompagnement diététique spécialisé.",
        ),
        SizedBox(height: 10),
        _BodyText(
          "Les estimations caloriques sont calculées à partir de formules de référence. Elles sont indicatives et peuvent varier de ±15 % selon les individus.",
          italic: true,
        ),
      ],
    );
  }
}

// ── Contenus page 2 (méthodes de calcul) ─────────────────────────────────────

class _PdcContent extends StatelessWidget {
  const _PdcContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BodyText(
          "Le PDC (Poids de Calcul Corrigé) est le poids utilisé dans les formules de macronutriments à la place du poids réel. Il vise à éviter de sur- ou sous-estimer les besoins chez les personnes très minces ou en surpoids.",
        ),
        SizedBox(height: 12),
        _FormulaBox(
          "IMC = poids ÷ taille²  (taille en mètres)\n\n"
          "Si IMC < 18.5  →  PDC = 18.5 × taille²\n"
          "Si IMC > 24.9  →  PDC = 24.9 × taille²\n"
          "Sinon          →  PDC = poids réel",
        ),
        SizedBox(height: 12),
        _BodyText(
          "En pratique, le PDC ramène le poids à l'intérieur de la fourchette de corpulence normale (IMC 18.5–24.9). Cela évite, par exemple, de calculer des besoins protéiques disproportionnés chez quelqu'un en forte surcharge pondérale.",
        ),
      ],
    );
  }
}

class _MbContent extends StatelessWidget {
  const _MbContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BodyText(
          "Le Métabolisme de Base (MB) est la quantité d'énergie dépensée au repos complet — ce dont le corps a besoin juste pour maintenir ses fonctions vitales (respiration, circulation, température, etc.).",
        ),
        SizedBox(height: 12),
        _FormulaBox(
          "Homme :\nMB = 46.68 + (11.70 × poids) + (5.52 × taille) − (5.34 × âge)\n\n"
          "Femme :\nMB = 143.30 + (9.62 × poids) + (4.67 × taille) − (4.67 × âge)\n\n"
          "poids en kg · taille en cm · résultat en kcal/jour",
        ),
        SizedBox(height: 12),
        _BodyText(
          "Cette formule est une régression linéaire basée sur le poids, la taille et l'âge. Elle est dans la lignée des formules de référence Harris-Benedict et Mifflin-St Jeor, dont elle partage la structure mathématique.",
        ),
        SizedBox(height: 10),
        _InfoBox(
          "Le MB seul ne suffit pas : il représente uniquement le besoin au repos. La dépense réelle dépend de votre niveau d'activité (voir TDEE ci-dessous).",
        ),
      ],
    );
  }
}

class _TdeeContent extends StatelessWidget {
  const _TdeeContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BodyText(
          "Le TDEE (Total Daily Energy Expenditure) est la dépense calorique réelle estimée sur une journée. Il s'obtient en multipliant le MB par un coefficient d'activité (PAL).",
        ),
        SizedBox(height: 12),
        _FormulaBox("TDEE = MB × Coefficient d'activité"),
        SizedBox(height: 14),
        _BodyText("Coefficients d'activité disponibles :", bold: true),
        SizedBox(height: 10),
        _BulletPoint(label: "Sédentaire", text: "× 1.20 — travail de bureau, peu ou pas de sport (environ 3 500 pas/jour)"),
        SizedBox(height: 6),
        _BulletPoint(label: "Modéré", text: "× 1.375 — activité légère 1 à 3 jours par semaine (environ 7 500 pas/jour)"),
        SizedBox(height: 6),
        _BulletPoint(label: "Actif", text: "× 1.55 — activité modérée 3 à 5 jours par semaine (environ 10 000 pas/jour)"),
        SizedBox(height: 6),
        _BulletPoint(label: "Très actif", text: "× 1.725 — activité intense 6 à 7 jours par semaine (environ 14 000 pas/jour)"),
        SizedBox(height: 6),
        _BulletPoint(label: "Extrêmement actif", text: "× 1.90 — travail physique intense + sport quotidien (environ 20 000 pas/jour)"),
        SizedBox(height: 10),
        _InfoBox(
          "Ces coefficients sont issus des références FAO/OMS et Harris-Benedict. Ils tiennent compte de l'ensemble de la dépense journalière, pas uniquement des séances de sport.",
        ),
      ],
    );
  }
}

class _CiblesCaloriquesContent extends StatelessWidget {
  const _CiblesCaloriquesContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BodyText(
          "À partir du TDEE, l'application calcule une fourchette calorique [min – max] selon votre objectif. La fourchette de 200 kcal offre une marge de flexibilité quotidienne.",
        ),
        SizedBox(height: 12),
        _FormulaBox(
          "Maintien :\n  Min = TDEE − 100  /  Max = TDEE + 100\n\n"
          "Perte de poids (déficit −10 %) :\n  Min = (TDEE × 0.9) − 100  /  Max = (TDEE × 0.9) + 100\n\n"
          "Prise de masse (+10 %) :\n  Min = (TDEE × 1.1) − 100  /  Max = (TDEE × 1.1) + 100\n\n"
          "→ Valeurs arrondies aux 100 kcal les plus proches",
        ),
        SizedBox(height: 12),
        _BodyText(
          "Le déficit de −10 % est volontairement modéré. Un déficit trop agressif (−30 % ou plus) entraîne une perte musculaire importante et un ralentissement métabolique. La lenteur est une stratégie.",
        ),
        SizedBox(height: 10),
        _InfoBox(
          "Ces cibles sont un point de départ. Si après 2 semaines votre poids n'évolue pas dans la direction souhaitée, ajustez manuellement via le bouton \"Ajuster les besoins\", par paliers de 200 kcal.",
        ),
      ],
    );
  }
}

class _ProteinesContent extends StatelessWidget {
  const _ProteinesContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BodyText(
          "Les protéines sont calculées à partir de deux critères : le poids de calcul (PDC) pondéré par le type de sport, et un pourcentage minimal des calories. La valeur retenue est le maximum des deux — pour garantir un apport suffisant quelle que soit la situation.",
        ),
        SizedBox(height: 12),
        _FormulaBox(
          "Protéines min = max(PDC × coefSport, CalMin × 15% ÷ 4)\n"
          "Protéines max = max(PDC × 1.9,      CalMax × 20% ÷ 4)\n\n"
          "Coefficients sport :\n"
          "  Pas / Loisir  → 1.0 g par kg PDC\n"
          "  Endurance     → 1.3 g par kg PDC\n"
          "  Force         → 1.6 g par kg PDC",
        ),
        SizedBox(height: 12),
        _BodyText(
          "Le plafond de 1.9 g/kg PDC correspond au haut de la fourchette recommandée dans la littérature sportive pour les athlètes de force en phase de restriction calorique. Pour un usage sédentaire, le calcul revient au minimum calorique (15 %).",
        ),
        SizedBox(height: 10),
        _InfoBox(
          "1 gramme de protéines = 4 kcal. Les apports recommandés par l'ANSES pour l'adulte sédentaire sont de 0.83 g/kg/jour ; ce seuil est systématiquement respecté par le calcul.",
        ),
      ],
    );
  }
}

class _LipidesContent extends StatelessWidget {
  const _LipidesContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BodyText(
          "Les lipides sont également calculés avec une double contrainte : une valeur plancher liée à la taille (proxy de la masse maigre), et un minimum calorique. Le maximum est plafonné à 30 % des calories totales.",
        ),
        SizedBox(height: 12),
        _FormulaBox(
          "Lipides min = max((taille − 150) × 0.5 + 30,  CalMin × 20% ÷ 9)\n"
          "Lipides max = CalMax × 30% ÷ 9\n\n"
          "1 g de lipides = 9 kcal",
        ),
        SizedBox(height: 12),
        _BodyText(
          "La formule taille-dépendante (taille − 150) × 0.5 + 30 est une approximation simple qui reflète le besoin en acides gras essentiels proportionnel à la taille corporelle. Elle assure un minimum de 30 g/j pour une personne de 150 cm, montant linéairement avec la taille.",
        ),
        SizedBox(height: 8),
        _BodyText(
          "Si l'écart entre lipMax et lipMin est inférieur à 20 g — ce qui peut arriver en contexte très hypocalorique — lipMax est automatiquement relevé pour maintenir une plage minimale affichable.",
          italic: true,
        ),
        SizedBox(height: 10),
        _InfoBox(
          "Les lipides sont souvent réduits à tort en période de restriction. En dessous de 20 % des calories, la synthèse hormonale (testostérone, œstrogènes) et l'absorption des vitamines A, D, E, K sont compromises.",
        ),
      ],
    );
  }
}

class _GlucidesContent extends StatelessWidget {
  const _GlucidesContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BodyText(
          "Les glucides occupent les calories restantes, une fois protéines et lipides alloués. Ils sont calculés \"par différence\" — c'est pourquoi leur plage est la plus large et la plus variable selon les profils.",
        ),
        SizedBox(height: 12),
        _FormulaBox(
          "Glucides min = (CalMin − 4×ProtMax − 9×LipMax) ÷ 4\n"
          "Glucides max = (CalMax − 4×ProtMin − 9×LipMin) ÷ 4\n\n"
          "1 g de glucides = 4 kcal",
        ),
        SizedBox(height: 8),
        _BodyText(
          "Si le résultat de glucMin est négatif (les protéines et lipides occupent déjà toutes les calories disponibles), il est ramené à 0. glucMax reste au minimum à 20 g pour qu'une plage soit toujours affichée.",
          italic: true,
        ),
        SizedBox(height: 14),
        _BodyText("Fibres :", bold: true),
        SizedBox(height: 8),
        _FormulaBox(
          "Fibres min = CalMin × 12.5 ÷ 1000  (12.5 g pour 1 000 kcal)\n"
          "Fibres max = CalMax × 15 ÷ 1000    (15 g pour 1 000 kcal)",
        ),
        SizedBox(height: 12),
        _BodyText(
          "Cette plage correspond aux recommandations de l'ANSES : 25 g/j minimum à 30 g/j pour un adulte à 2 000 kcal, soit 12.5 à 15 g pour 1 000 kcal. Les fibres ne sont pas comptabilisées dans les macros principales car leur contribution calorique nette est marginale.",
        ),
        SizedBox(height: 10),
        _InfoBox(
          "Les glucides étant calculés par différence, leur plage peut sembler large ou inhabituelle selon votre profil (fort en protéines, faible en calories…). C'est normal : ils s'adaptent à l'espace calorique disponible.",
        ),
      ],
    );
  }
}

class _BddContent extends StatelessWidget {
  const _BddContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BodyText(
          "Les valeurs nutritionnelles proviennent de deux sources complémentaires, utilisées selon le contexte de recherche.",
        ),
        SizedBox(height: 14),
        _BodyText("CIQUAL (intégrée hors-ligne)", bold: true),
        SizedBox(height: 8),
        _BulletPoint(
          label: "Éditeur",
          text: "ANSES — Agence nationale de sécurité sanitaire de l'alimentation, de l'environnement et du travail (France)",
        ),
        SizedBox(height: 6),
        _BulletPoint(
          label: "Couverture",
          text: "Plus de 3 500 aliments bruts et transformés couvrant l'alimentation française courante : viandes, poissons, légumes, fruits, céréales, produits laitiers…",
        ),
        SizedBox(height: 6),
        _BulletPoint(
          label: "Disponibilité",
          text: "Chargée directement dans l'application — utilisable sans connexion internet. C'est la source par défaut pour la recherche d'aliments.",
        ),
        SizedBox(height: 14),
        _BodyText("Open Food Facts (recherche en ligne)", bold: true),
        SizedBox(height: 8),
        _BulletPoint(
          label: "Éditeur",
          text: "Base de données collaborative et open source, alimentée par des contributeurs du monde entier.",
        ),
        SizedBox(height: 6),
        _BulletPoint(
          label: "Couverture",
          text: "Plusieurs millions de produits alimentaires industriels avec code-barres : marques, références de grande distribution, produits étrangers.",
        ),
        SizedBox(height: 6),
        _BulletPoint(
          label: "Utilisation",
          text: "Interrogée en complément de CIQUAL pour les produits transformés, les marques et les références non présentes dans la base française.",
        ),
        SizedBox(height: 12),
        _InfoBox(
          "Les valeurs CIQUAL sont mesurées en laboratoire par l'ANSES — c'est la source la plus fiable pour les aliments bruts. Les données Open Food Facts sont issues de la déclaration nutritionnelle des emballages et peuvent varier selon les lots.",
        ),
        SizedBox(height: 10),
        _BodyText(
          "Dans les deux cas, toutes les valeurs sont exprimées pour 100 g et recalculées automatiquement selon la quantité renseignée.",
          italic: true,
        ),
      ],
    );
  }
}

// ── Contenus page 3 (à propos) ───────────────────────────────────────────────

class _AProposDefinitionContent extends StatelessWidget {
  const _AProposDefinitionContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BodyText(
          "Cette application est un outil de suivi nutritionnel quotidien. Elle permet de :",
        ),
        SizedBox(height: 10),
        _BulletPoint(
          label: "Estimer vos besoins",
          text: "à partir de vos données personnelles (poids, taille, âge, activité, objectif).",
        ),
        SizedBox(height: 8),
        _BulletPoint(
          label: "Enregistrer vos repas",
          text: "en recherchant des aliments parmi plusieurs milliers de références.",
        ),
        SizedBox(height: 8),
        _BulletPoint(
          label: "Visualiser vos apports",
          text: "sous forme de barres de progression pour les calories et chaque macronutriment.",
        ),
        SizedBox(height: 8),
        _BulletPoint(
          label: "Suivre l'évolution",
          text: "de vos habitudes alimentaires sur plusieurs jours via l'historique.",
        ),
        SizedBox(height: 10),
        _InfoBox(
          "Le suivi est un moyen, pas une fin. L'objectif à terme est de développer une conscience alimentaire suffisante pour ne plus en avoir besoin au quotidien.",
        ),
      ],
    );
  }
}

class _AProposPublicContent extends StatelessWidget {
  const _AProposPublicContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BodyText(
          "Cette application s'adresse avant tout aux personnes souhaitant reprendre contact avec leur alimentation de manière autonome et sans dogmatisme.",
        ),
        SizedBox(height: 12),
        _BulletPoint(
          label: "Personnes en gestion de poids",
          text: "qui souhaitent perdre, stabiliser ou prendre du poids progressivement, sans régime restrictif.",
        ),
        SizedBox(height: 8),
        _BulletPoint(
          label: "Sportifs",
          text: "cherchant à adapter leurs apports protéiques et caloriques à leurs entraînements.",
        ),
        SizedBox(height: 8),
        _BulletPoint(
          label: "Curieux de nutrition",
          text: "qui veulent simplement comprendre ce qu'ils mangent et remettre de la conscience dans leurs habitudes.",
        ),
        SizedBox(height: 8),
        _BulletPoint(
          label: "Personnes sédentaires",
          text: "qui débutent et souhaitent un point de départ simple, sans s'imposer un suivi rigide.",
        ),
        SizedBox(height: 10),
        _InfoBox(
          "Elle n'est pas adaptée aux personnes ayant des besoins nutritionnels médicalisés, aux femmes enceintes ou allaitantes, ni aux adolescents en phase de croissance — ces profils doivent consulter un diététicien.",
        ),
      ],
    );
  }
}

class _AProposLimitesContent extends StatelessWidget {
  const _AProposLimitesContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BulletPoint(
          label: "Pas un dispositif médical",
          text: "elle ne diagnostique rien et ne remplace aucun suivi médical ou diététique professionnel.",
        ),
        SizedBox(height: 8),
        _BulletPoint(
          label: "Pas un régime",
          text: "il n'y a pas de liste d'aliments interdits, de phases ou de protocoles imposés.",
        ),
        SizedBox(height: 8),
        _BulletPoint(
          label: "Pas un coach personnel",
          text: "les recommandations sont génériques. Elles ne tiennent pas compte de votre historique médical, de vos préférences alimentaires ou de votre contexte de vie.",
        ),
        SizedBox(height: 8),
        _BulletPoint(
          label: "Pas infaillible",
          text: "les formules de calcul sont des estimations avec une marge d'erreur de ±10 à 15 %. Votre corps reste la meilleure source de feedback.",
        ),
        SizedBox(height: 10),
        _BodyText(
          "Si vos résultats divergent fortement des estimations après 3 à 4 semaines de suivi régulier, il peut être utile de consulter un professionnel pour affiner les paramètres.",
          italic: true,
        ),
      ],
    );
  }
}

class _AProposPhilosophieContent extends StatelessWidget {
  const _AProposPhilosophieContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BodyText(
          "La plupart des applications de nutrition affichent une valeur cible unique et fixe pour chaque macro et pour les calories.",
        ),
        SizedBox(height: 10),
        _BodyText(
          "Ce format rigide génère inévitablement des questions sans réponse claire :",
        ),
        SizedBox(height: 10),
        _BulletPoint(
          label: "Si je dépasse",
          text: "est-ce grave ? De combien puis-je dépasser sans que ça compromette mes résultats ?",
        ),
        SizedBox(height: 8),
        _BulletPoint(
          label: "Si je dois atteindre exactement la valeur",
          text: "la marge est quasi nulle sur 4 indicateurs simultanés — calories, protéines, lipides, glucides. Le suivi devient une contrainte épuisante.",
        ),
        SizedBox(height: 14),
        _BodyText(
          "Le principe central de cette application est différent : chaque indicateur a une borne basse et une borne haute. L'objectif est d'être dans la plage — pas d'atteindre un chiffre précis.",
          bold: true,
        ),
        SizedBox(height: 12),
        _InfoBox(
          "La FLEXIBILITÉ est la clé. Une journée à 1 850 kcal quand la cible est 1 800–2 000 est une bonne journée. Une journée à 2 100 kcal n'est pas un échec. C'est la régularité sur plusieurs jours qui compte, pas la perfection à chaque repas.",
        ),
        SizedBox(height: 10),
        _BodyText(
          "Une alimentation durable est une alimentation que vous aimez, pas une que vous subissez. Le meilleur suivi est celui que vous pouvez tenir sans effort dans 5 ans.",
        ),
      ],
    );
  }
}

// ── Widgets contact (inchangés) ───────────────────────────────────────────────

class _ContactsCard extends StatelessWidget {
  const _ContactsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3D2B2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE05252).withAlpha(60), width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.favorite_rounded, color: Color(0xFFE05252), size: 18),
              SizedBox(width: 10),
              Text(
                "Besoin d'aide ?",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _BodyText(
            "Si vous pensez souffrir d'un trouble du comportement alimentaire (TCA) ou si votre rapport à la nourriture vous préoccupe, des professionnels peuvent vous aider.",
          ),
          const SizedBox(height: 14),
          _ContactItem(
            label: "Anorexie boulimie info",
            detail: "09 69 325 900",
            note: "Lun–ven · 9h–18h · prix d'un appel local",
          ),
          const SizedBox(height: 10),
          _ContactItem(
            label: "Numéro national de prévention du suicide",
            detail: "3114",
            note: "24h/24 · 7j/7 · gratuit",
          ),
          const SizedBox(height: 10),
          _ContactItem(
            label: "AFDAS-TCA (ressources & spécialistes)",
            detail: "afdas-tca.com",
          ),
          const SizedBox(height: 10),
          _ContactItem(
            label: "NCA – Aide & soutien TCA",
            detail: "ncatroublealimentaire.com",
          ),
          const SizedBox(height: 12),
          const _BodyText(
            "Appuyez et maintenez sur un numéro ou une adresse pour le copier.",
            italic: true,
          ),
        ],
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  final String label;
  final String detail;
  final String? note;

  const _ContactItem({required this.label, required this.detail, this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(40),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: detail));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copié : $detail'),
                  backgroundColor: const Color(0xFF357E50),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              detail,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 2),
            Text(
              note!,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Petits widgets de mise en forme ──────────────────────────────────────────

class _BodyText extends StatelessWidget {
  final String text;
  final bool bold;
  final bool italic;

  const _BodyText(this.text, {this.bold = false, this.italic = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white70,
        fontSize: 13.5,
        height: 1.55,
        fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;

  const _InfoBox(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF357E50).withAlpha(30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF357E50).withAlpha(80), width: 1),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF7FD4A0),
          fontSize: 13,
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _FormulaBox extends StatelessWidget {
  final String text;

  const _FormulaBox(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(60),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withAlpha(20), width: 1),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFB0C8E8),
          fontSize: 12.5,
          height: 1.7,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String label;
  final String text;

  const _BulletPoint({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 5),
          child: CircleAvatar(
            radius: 3,
            backgroundColor: Color(0xFF357E50),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label : ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
                TextSpan(
                  text: text,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StepBox extends StatelessWidget {
  final String number;
  final String title;
  final String text;

  const _StepBox({required this.number, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFFE8A838).withAlpha(40),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE8A838).withAlpha(120), width: 1),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xFFE8A838),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
