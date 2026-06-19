import 'package:flutter/material.dart';

class SliderButton extends StatelessWidget {
  final double position;
  final double barHeight;

  //final Function(double delta) onMove;

  const SliderButton({
    super.key,
    required this.position,
    required this.barHeight,
    // required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    final double sliderHeight = barHeight * (27 / 35);
    final double sliderWidth  = barHeight * (7 / 35);

    return Positioned(
      left: position - (sliderWidth / 2),
      top: (barHeight - sliderHeight) / 2,
      height: sliderHeight,
      // child: GestureDetector(
        // onHorizontalDragUpdate: (details) => onMove(details.delta.dx),
        child: Container(
          width: sliderWidth,
          height: sliderHeight,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: Color(0x32D9D9D9),
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
