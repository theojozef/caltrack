import 'package:flutter/material.dart';

class PolitiqueConfidentialitePage extends StatelessWidget {
  const PolitiqueConfidentialitePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF393939),
      appBar: AppBar(
        backgroundColor: const Color(0xFF393939),
        foregroundColor: Colors.white,
        title: const Text('Politique de confidentialité', style: TextStyle(fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: _PolicyContent(),
      ),
    );
  }
}

class _PolicyContent extends StatelessWidget {
  const _PolicyContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _Section(
          title: 'Responsable du traitement',
          body:
              'Théo MARTIN\n'
              'Contact : martin.to@orange.fr',
        ),
        _Section(
          title: 'Données collectées',
          body:
              '• Identité : prénom, nom\n'
              '• Coordonnées : adresse e-mail\n'
              '• Données de santé : informations nutritionnelles et caloriques saisies dans l\'application',
        ),
        _Section(
          title: 'Finalité du traitement',
          body:
              'Ces données sont collectées uniquement pour :\n'
              '• Créer et gérer votre compte utilisateur\n'
              '• Assurer le fonctionnement du suivi nutritionnel\n'
              '\nElles ne sont ni vendues, ni louées, ni partagées avec des tiers à des fins commerciales.',
        ),
        _Section(
          title: 'Durée de conservation',
          body:
              'Vos données sont conservées pendant toute la durée d\'activité de votre compte. '
              'En cas de suppression du compte, elles sont effacées dans un délai de 30 jours.',
        ),
        _Section(
          title: 'Hébergement',
          body:
              'Les données sont hébergées par Google Firebase (Google LLC), '
              'dans le cadre de serveurs conformes aux exigences du RGPD. '
              'Un accord de traitement des données (DPA) est en place avec Google.',
        ),
        _Section(
          title: 'Vos droits',
          body:
              'Conformément au RGPD (Règlement UE 2016/679), vous disposez des droits suivants :\n'
              '• Droit d\'accès à vos données\n'
              '• Droit de rectification\n'
              '• Droit à l\'effacement (« droit à l\'oubli »)\n'
              '• Droit à la portabilité\n'
              '• Droit d\'opposition au traitement\n'
              '\nPour exercer ces droits, contactez : martin.to@orange.fr\n'
              'Vous disposez également du droit d\'introduire une réclamation auprès de la CNIL (www.cnil.fr).',
        ),
        _Section(
          title: 'Sécurité',
          body:
              'L\'accès à votre compte est protégé par un mot de passe. '
              'Nous mettons en œuvre des mesures techniques adaptées pour protéger vos données contre tout accès non autorisé.',
        ),
        _Section(
          title: 'Mise à jour',
          body: 'Dernière mise à jour : juin 2026.',
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF357E50),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }
}
