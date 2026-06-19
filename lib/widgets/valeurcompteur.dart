import 'package:flutter/material.dart';

class ValeurCompteur extends StatelessWidget {
  final double position;
  final double valeuraffichee;
  final double barHeight;
  final double fontSize;
  final FontWeight fontWeight;

  const ValeurCompteur({
    super.key,
    required this.position,
    required this.valeuraffichee,
    required this.barHeight,
    this.fontSize = 10,
    this.fontWeight = FontWeight.normal,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
    left: position - 20, // moitié de la largeur du container
    top: 0,
    child: Container(
      width: 40, // largeur du container
      height: barHeight,
      color: Colors.transparent,
      alignment: Alignment.center, // centrer le texte
      child: Text(
        valeuraffichee.toStringAsFixed(0),
        style : TextStyle(
          color: const Color(0x80FFFFFF),
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: 1.0,
      ),
      ),
      ),
  );  
    
  }
}
