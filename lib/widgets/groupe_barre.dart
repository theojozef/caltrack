import 'package:flutter/material.dart';
import 'slider.dart';
import 'color_utils.dart';
import 'valeurcompteur.dart';

double getSliderValueFromCompteurCalories(
    double compteurCalories,
    double valeurMin,
    double valeurMax,
    double leftSoft,
    double rightSoft,
) {
  if (compteurCalories < valeurMin) {
    return (compteurCalories / valeurMin) * leftSoft;
  } else if (compteurCalories < valeurMax) {
    return leftSoft + ((compteurCalories - valeurMin) / (valeurMax - valeurMin) * (rightSoft - leftSoft));
  } else if (compteurCalories < (valeurMin + valeurMax)) {
    return rightSoft + ((compteurCalories - valeurMax) / (valeurMin) * (1 - rightSoft));
  } else {
    return 1.0;
  }
}

double _getValeurPosition(
    double compteurCalories,
    double valeurMin,
    double valeurMax,
    double width,
) {
  if (compteurCalories < valeurMin) {
    return width * (0.25 / 2) ;
  } else if (compteurCalories > valeurMax) {
    return width * ((1 + 0.75) / 2) ;
  } else {    
    return width * 0.5;
  }
}


class GroupeBarre extends StatefulWidget {  
  final double barWidth;
  final double barHeight;
  final double cornerRadius;
  final double borneHeight;
  final Color borneColor;
  final String titre;
  final double borneWidth;
  final double valeurMin;  // 👈 ajouté
  final double valeurMax;  // 👈 ajouté
  final double compteurCalories;

  const GroupeBarre({
    super.key,
    required this.titre,    
    this.barWidth = 322,
    this.barHeight = 35, // 35
    this.cornerRadius = 23,
    this.borneHeight = 21,
    this.borneWidth = 3,
    this.borneColor = const Color(0x0AFFFFFF),
    required this.valeurMin,   // 👈 ajouté
    required this.valeurMax,   // 👈 ajouté
    required this.compteurCalories,
  });

  @override
  State<GroupeBarre> createState() => _GroupeBarreState();
}

class _GroupeBarreState extends State<GroupeBarre> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sliderAnimation;
  double _currentSliderValue = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Initialisation de l'AnimationController
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

     final colorLimites = getColorLimites(widget.barWidth);
     _currentSliderValue = getSliderValueFromCompteurCalories(
      widget.compteurCalories,
      widget.valeurMin,
      widget.valeurMax,
      colorLimites['leftSoft']!,
      colorLimites['rightSoft']!,
    );

    // Création de l'animation de la position du slider
    _sliderAnimation = Tween<double>(begin: _currentSliderValue, end: _currentSliderValue).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant GroupeBarre oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Lorsque la valeur change, on démarre l'animation
    if (widget.compteurCalories != oldWidget.compteurCalories) {
      
      final colorLimites = getColorLimites(widget.barWidth);

      final sliderValue = getSliderValueFromCompteurCalories(
        widget.compteurCalories,
        widget.valeurMin,
        widget.valeurMax,
        colorLimites['leftSoft']!,
        colorLimites['rightSoft']!,
      );

      // Met à jour la fin de l'animation pour que la position finale soit correcte
      _sliderAnimation = Tween<double>(begin: _currentSliderValue, end: sliderValue).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );

      // Démarre l'animation
      _controller.forward(from: 0.0);
      
      // ✅ Met à jour la valeur actuelle pour la prochaine animation
      _currentSliderValue = sliderValue;
    }
  }



  @override  
  Widget build(BuildContext context) {
    
    // Calcul des limites de couleur avec la fonction getColorLimites
    //final colorLimites = getColorLimites(widget.barWidth);

    // Utilisation des variables globales
    /*final sliderValue = getSliderValueFromCompteurCalories(
      widget.compteurCalories,
      widget.valeurMin,
      widget.valeurMax,
      colorLimites['leftSoft']!,  // Utilisation des valeurs extraites du Map
      colorLimites['rightSoft']!,
    );*/
    
    //final color = getBarColor(sliderValue, widget.barWidth);
    final width = widget.barWidth;
    

    // final limites = getColorLimites(widget.barWidth);
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        /*Text( // titre de la barre
          widget.titre,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),*/
        _buildLimites(width),
        //_buildLimites(width, widget.valeurMax),
        const SizedBox(height: 2),
        
        SizedBox( // barre colorée
          width: width,
          height: widget.barHeight, // 35
          
          child: AnimatedBuilder(
          animation: _sliderAnimation,
          builder: (context, child) {
            final animatedSliderValue = _sliderAnimation.value;
            final color = getBarColor(animatedSliderValue, width);
            final sliderPosition = animatedSliderValue * (width - 30) + 15;
          return Stack(
            children: [
              _buildAnimatedBar(color),
              _buildBornes(width),
              //_buildLimites(width, widget.valeurMin),
              //_buildLimites(width, widget.valeurMax),
                            
              SliderButton( // bouton slider                
                position: sliderPosition // Value * (width - 30) + 15,
                /* onMove: (delta) {
                  setState(() {
                    sliderValue += delta / (width); // (width - 30)
                    sliderValue = sliderValue.clamp(0.0, 1.0);
                  });
                //},*/
              ),
              ValeurCompteur(
                position: _getValeurPosition(widget.compteurCalories, widget.valeurMin, widget.valeurMax, width), // width * 0.5,
                valeuraffichee: widget.compteurCalories.round().toDouble(),
              )
            ],
          );
          },
        ),
        ),
      ],
    );
  }
  

  Widget _buildAnimatedBar(Color color) {
      return Container(
        width: widget.barWidth,
        height: widget.barHeight,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(widget.cornerRadius),
        ),
      );
  }


  // BORNES
  Widget _buildBornes(double width) => Stack(
        children: [
          _borneAt(width * 0.25),
          _borneAt(width * 0.75),          
        ],
      );
  Widget _borneAt(double left) => Positioned(
        left: left - (widget.borneWidth /2),
        top: (widget.barHeight - widget.borneHeight) / 2,
        child: Container(
          width: widget.borneWidth,
          height: widget.borneHeight,
          decoration: BoxDecoration(
            color: widget.borneColor,
            borderRadius: BorderRadius.circular(widget.borneWidth /2),
          ) 
          
        ),
      );
  
  //TEXTE BORNES
  Widget _buildLimites(double width) => Stack(        
      children: [
      _borneTexte(width * 0.25, widget.valeurMin),
      _titreBarre(width),
      _borneTexte(width * 0.75, widget.valeurMax),
    ],
    );

  Widget _borneTexte(double left, double valeur) => Positioned(
    left: left - 20, // moitié de la largeur du container
    top: 0, //(widget.barHeight - 20) /2,    
    child: Container(
      width: 40, // largeur du container
      height: 20,
      color: Colors.transparent,
      alignment: Alignment.bottomCenter, // centrer le texte
      child: Text(      
        valeur.toStringAsFixed(0),
        style : const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 10,    
      ),  
      ),      
      ),
  );

  Widget _titreBarre(double width) => Container(
  width: width,
  height: 20,
  alignment: Alignment.bottomCenter,  
  child: Text(
    widget.titre,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 11,
      fontWeight: FontWeight.w500,
    ),
  ),
);  
}



