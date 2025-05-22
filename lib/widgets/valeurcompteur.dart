import 'package:flutter/material.dart';

class ValeurCompteur extends StatelessWidget {
  final double position;
  final double valeuraffichee;

  const ValeurCompteur({
    super.key,
    required this.position,
    required this.valeuraffichee,    
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
    left: position - 20, // moitié de la largeur du container
    top: (35 - 20) / 2, //(widget.barHeight - 20) /2,    
    child: Container(
      width: 40, // largeur du container
      height: 20,
      color: Colors.transparent,
      alignment: Alignment.center, // centrer le texte
      child: Text(      
        '$valeuraffichee',
        style : const TextStyle(
          color: Color(0x80FFFFFF),
          fontSize: 10,    
      ),  
      ),      
      ),
  );  
    
  }
}
