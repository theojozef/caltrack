import 'package:flutter/material.dart';

class SliderButton extends StatelessWidget {
  final double position;
  
  //final Function(double delta) onMove;

  const SliderButton({
    super.key,
    required this.position,
    // required this.onMove,
  });

  static double sliderWidth = 7;
  static double sliderHeight = sliderWidth * 3.85;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position - (sliderWidth/2), //position - 3.5
      top: (35 - sliderHeight) / 2, //(35 - 27) / 2
      height: sliderHeight, //27
      // child: GestureDetector(
        // onHorizontalDragUpdate: (details) => onMove(details.delta.dx),
        child: Container(
          width: sliderWidth, //7
          height: sliderHeight, //27
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color:  Color(0x32D9D9D9),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
        ),
      );
    //);
  }
}
