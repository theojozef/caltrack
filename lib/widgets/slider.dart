import 'package:flutter/material.dart';

class SliderButton extends StatelessWidget {
  final double position;
  //final Function(double delta) onMove;

  const SliderButton({
    super.key,
    required this.position,
    // required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position - 3.5,
      top: (35 - 27) / 2,
      height: 27,
      // child: GestureDetector(
        // onHorizontalDragUpdate: (details) => onMove(details.delta.dx),
        child: Container(
          width: 7,
          height: 27,
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
