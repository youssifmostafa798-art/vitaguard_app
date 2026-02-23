import 'package:flutter/material.dart';

class VitaGuardLogo extends StatelessWidget {
  final double size;

  const VitaGuardLogo({super.key, this.size = 160});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [Image.asset('assets/Logo/Vita Guard 2.png', width: 300)],
    );
  }
}
