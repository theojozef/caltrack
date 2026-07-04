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
    double width, {
    bool showMaxBorne = true,
}) {
  if (compteurCalories < valeurMin) {
    return width * (0.25 / 2);
  } else if (showMaxBorne && compteurCalories > valeurMax) {
    return width * ((1 + 0.75) / 2);
  } else {
    return width * 0.5;
  }
}


class GroupeBarre extends StatefulWidget {
  final double barWidth;
  final Color borneColor;
  final String titre;
  final double valeurMin;  // 👈 ajouté
  final double valeurMax;  // 👈 ajouté
  final double compteurCalories;
  final double compteurFontSize;
  final FontWeight compteurFontWeight;
  final double borneFontSize;
  final bool showMaxBorne;

  const GroupeBarre({
    super.key,
    required this.titre,
    required this.barWidth, // = 250, //322
    this.borneColor = const Color(0x0AFFFFFF),
    required this.valeurMin,   // 👈 ajouté
    required this.valeurMax,   // 👈 ajouté
    required this.compteurCalories,
    this.compteurFontSize = 14, //10
    this.compteurFontWeight = FontWeight.normal,
    this.borneFontSize = 12, //10
    this.showMaxBorne = true,
  });

  @override
  State<GroupeBarre> createState() => _GroupeBarreState();
}

class _GroupeBarreState extends State<GroupeBarre> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sliderAnimation;
  double currentSliderValue = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Initialisation de l'AnimationController
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200), //700
      vsync: this,
    );

     final colorLimites = getColorLimites(widget.barWidth);
     
     double currentSliderValue = getSliderValueFromCompteurCalories(
      widget.compteurCalories,
      widget.valeurMin,
      widget.valeurMax,
      colorLimites['leftSoft']!,
      colorLimites['rightSoft']!,
    );

    // Création de l'animation de la position du slider (Initialisation)
    _sliderAnimation = Tween<double>(begin: 0.0, end: currentSliderValue).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // 🔹 Ajout du listener juste après la création de l'animation
    _controller.addListener(() {
      setState(() {
      // À chaque frame d'animation, on rebuild pour mettre à jour la position
    });
    
    // Lancer l’animation dès l’ouverture
    

  });
  _controller.forward();

  }

  @override
  void didUpdateWidget(covariant GroupeBarre oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Lorsque la valeur change, on démarre l'animation
    if (widget.compteurCalories != oldWidget.compteurCalories ||
      widget.valeurMin != oldWidget.valeurMin ||
      widget.valeurMax != oldWidget.valeurMax) {   
      
      final colorLimites = getColorLimites(widget.barWidth);

      final sliderValue = getSliderValueFromCompteurCalories(
        widget.compteurCalories,
        widget.valeurMin,
        widget.valeurMax,
        colorLimites['leftSoft']!,
        colorLimites['rightSoft']!,
      );

      // Met à jour la fin de l'animation pour que la position finale soit correcte
      _sliderAnimation = Tween<double>(begin: currentSliderValue, end: sliderValue).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );

      

      // Démarre l'animation
      //_controller.reset();
      _controller.forward(from: 0.0);
      
      // ✅ Met à jour la valeur actuelle pour la prochaine animation
      currentSliderValue = sliderValue;
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
    final double barHeight   = width * (35 / 320);
    final double cornerRadius = barHeight * (23 / 35);
    final double borneHeight  = barHeight * (21 / 35);
    final double borneWidth   = width * (3 / 320);
    final double marge        = width * (15 / 320);

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
          height: barHeight,
          
          child: AnimatedBuilder(
          animation: _sliderAnimation,
          builder: (context, child) {
            //final animatedSliderValue = _sliderAnimation.value;
            final colorLimites = getColorLimites(width);
            final effectiveSlider = widget.showMaxBorne
              ? _sliderAnimation.value
              : _sliderAnimation.value.clamp(0.0, colorLimites['rightSoft']!);
            final color = getBarColor(effectiveSlider, width);
            //final sliderPosition = animatedSliderValue * (width - 30) + 15;
          return Stack(
            children: [
              _buildAnimatedBar(color, barHeight, cornerRadius),
              _buildBornes(width, barHeight, borneHeight, borneWidth),
              //_buildLimites(width, widget.valeurMin),
              //_buildLimites(width, widget.valeurMax),

              // CURSEUR
              SliderButton(
                position: _sliderAnimation.value * (width - 2 * marge) + marge,
                barHeight: barHeight,
                /* onMove: (delta) {
                  setState(() {
                    sliderValue += delta / (width); // (width - 30)
                    sliderValue = sliderValue.clamp(0.0, 1.0);
                  });
                //},*/



              ),

              ValeurCompteur(
                position: _getValeurPosition(widget.compteurCalories, widget.valeurMin, widget.valeurMax, width, showMaxBorne: widget.showMaxBorne),
                valeuraffichee: widget.compteurCalories.round().toDouble(),
                barHeight: barHeight,
                fontSize: widget.compteurFontSize,
                fontWeight: widget.compteurFontWeight,
              )
            ],
          );
          },
        ),
        ),
      ],
    );
  }
  

  Widget _buildAnimatedBar(Color color, double barHeight, double cornerRadius) {
      return Container(
        width: widget.barWidth,
        height: barHeight,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(cornerRadius),
        ),
      );
  }


  // BORNES
  Widget _buildBornes(double width, double barHeight, double borneHeight, double borneWidth) => Stack(
        children: [
          _borneAt(width * 0.25, barHeight, borneHeight, borneWidth),
          if (widget.showMaxBorne) _borneAt(width * 0.75, barHeight, borneHeight, borneWidth),
        ],
      );
  Widget _borneAt(double left, double barHeight, double borneHeight, double borneWidth) => Positioned(
        left: left - (borneWidth / 2),
        top: (barHeight - borneHeight) / 2,
        child: Container(
          width: borneWidth,
          height: borneHeight,
          decoration: BoxDecoration(
            color: widget.borneColor,
            borderRadius: BorderRadius.circular(borneWidth / 2),
          )
        ),
      );
  
  //TEXTE BORNES
  Widget _buildLimites(double width) => Stack(
      children: [
      _borneTexte(width * 0.25, widget.valeurMin),
      _titreBarre(width),
      if (widget.showMaxBorne) _borneTexte(width * 0.75, widget.valeurMax),
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
        style: TextStyle(
          color: const Color(0xFFFFFFFF),
          fontSize: widget.borneFontSize,
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
      fontSize: 14, //11
      fontWeight: FontWeight.w500,
    ),
  ),
);  
}