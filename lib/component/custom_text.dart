import 'package:flutter/material.dart';

class TextMedium extends StatelessWidget {
  final String text; // 버튼에 표시할 텍스트
  final Color color;
  const TextMedium({super.key, required this.text, this.color = Colors.black});
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
    );
  }
}

class TextLarge extends StatelessWidget {
  final String text; // 버튼에 표시할 텍스트
  final Color color;
  const TextLarge({super.key, required this.text, this.color = Colors.black});
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
    );
  }
}

class TextCustom extends StatelessWidget {
  final String text; // 버튼에 표시할 텍스트
  final Color color;
  final double fontSize;

  const TextCustom({
    super.key,
    required this.text,
    this.color = Colors.black,
    this.fontSize = 22,
  });
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }
}
