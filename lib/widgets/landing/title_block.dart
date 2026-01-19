import 'package:flutter/material.dart';

class TitleBlock extends StatelessWidget {
  const TitleBlock({super.key, required this.title, this.textAlign = TextAlign.center, this.style});

  final String title;
  final TextAlign textAlign;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: textAlign,
      style: style ?? const TextStyle(
        fontFamily: 'Editor Note',
        fontSize: 42,
        fontWeight: FontWeight.w600,
        height: 1.1,
        color: Color(0xFF171717),
      ),
    );
  }
}

