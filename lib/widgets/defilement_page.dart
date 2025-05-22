import 'package:flutter/material.dart';

class ScrollablePage extends StatelessWidget {
  final Widget child; // Contenu spécifique de chaque page

  const ScrollablePage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Votre page')), // Change le titre selon la page
      body: SingleChildScrollView( // Rendre la page défilable
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: child, // Le contenu spécifique de la page
        ),
      ),
    );
  }
}
