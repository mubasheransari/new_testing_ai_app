import 'package:flutter/material.dart';

class ShaderMaskText extends StatelessWidget {
  String text;
  double textxfontsize;
  ShaderMaskText({super.key, required this.text, required this.textxfontsize});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          colors: [Colors.cyan, Colors.purpleAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds);
      },
      child: Text(
        text,
        style: TextStyle(
          fontSize: textxfontsize,
          fontWeight: FontWeight.bold,
          color: Colors.white, // Needed to apply ShaderMask
        ),
      ),
    );
  }
}
