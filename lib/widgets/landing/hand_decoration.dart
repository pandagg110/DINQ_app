import 'package:flutter/material.dart';
import '../../utils/asset_path.dart';

class HandDecoration extends StatelessWidget {
  const HandDecoration({super.key, this.size = 160});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath('images/landing/4-hand.png'),
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

