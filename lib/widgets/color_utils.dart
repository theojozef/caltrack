import 'package:flutter/material.dart';

Map<String, double> getColorLimites(double width) {
  double nouveauQuart = (1 - (width * 0.5) / (width - 30)) / 2;

  double leftSoft = double.parse((nouveauQuart).toStringAsFixed(3));
  double rightSoft = double.parse((nouveauQuart + ((width * 0.5) / (width - 30))).toStringAsFixed(3));  
  
  double leftHard = leftSoft - 0.04;
  double rightHard = rightSoft + 0.04;

  // Retourne un Map avec les valeurs des bornes
  return {
    'leftHard': leftHard,
    'leftSoft': leftSoft,
    'rightSoft': rightSoft,
    'rightHard': rightHard,
  };
}

Color getBarColor(double sliderValue, double width) {
  final limites = getColorLimites(width);  // Récupère les bornes calculées

  double leftSoft = limites['leftSoft']!;
  double rightSoft = limites['rightSoft']!;
  double leftHard = limites['leftHard']!;
  double rightHard = limites['rightHard']!;

  // const double leftHard = 0.22;
  // const double leftSoft = 0.25;
  // const double rightSoft = 0.78;
  // const double rightHard = 0.80;

  /*double nouveauQuart = (1 - (width * 0.5) / (width - 30)) / 2;
  
  double leftSoft = double.parse((nouveauQuart).toStringAsFixed(3));
  double rightSoft = double.parse((nouveauQuart + ((width * 0.5) / (width - 30))).toStringAsFixed(3));  
 
  double leftHard = leftSoft - 0.04;
  double rightHard = rightSoft + 0.04; */

  const colorLeft = Color(0x3ABC8C56); // marron
  const colorMiddle = Color(0x3A0BE754); // vert
  const colorRight = Color(0x3ABC5A56); // rouge

  if (sliderValue < leftHard) {
    return colorLeft;
  } else if (sliderValue < leftSoft) {
    final t = (sliderValue - leftHard) / (leftSoft - leftHard);
    return Color.lerp(colorLeft, colorMiddle, t)!;
  } else if (sliderValue <= rightSoft) {
    return colorMiddle;
  } else if (sliderValue <= rightHard) {
    final t = (sliderValue - rightSoft) / (rightHard - rightSoft);
    return Color.lerp(colorMiddle, colorRight, t)!;
  } else {
    return colorRight;
  }  
}