import 'package:flutter/material.dart';

class RoundButton extends StatelessWidget {
  final String text; // 버튼에 표시할 텍스트
  final VoidCallback onPressed; // 클릭 시 실행할 함수
  final double borderRadius; // 둥근 정도 조절
  final Color color; // 둥근 정도 조절
  final double textSize;
  final EdgeInsets margin;

  const RoundButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = const Color(0xFFFFFFFF),
    this.borderRadius = 30, // 기본값 30
    this.textSize = 20,
    this.margin = const EdgeInsets.fromLTRB(10, 0, 10, 5),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: SizedBox(
        width: double.infinity, // 가로 꽉 채우기
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 6, // ✅ 그림자 높이
            shadowColor: Colors.black.withOpacity(1),
            backgroundColor: color, // 배경 흰색
            foregroundColor: Colors.black, // 글자 검정
            padding: EdgeInsets.symmetric(vertical: textSize * 0.7),
            textStyle: TextStyle(
              fontSize: textSize,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius), // round 수치
            ),
          ),
          child: Text(text),
        ),
      ),
    );
  }
}

class RoundCheckButton extends StatefulWidget {
  final String text;
  final ValueChanged<bool>? onChanged;
  final EdgeInsets margin;
  final double textSize;
  const RoundCheckButton({
    super.key,
    required this.text,
    this.onChanged,
    this.textSize = 20,
    this.margin = const EdgeInsets.fromLTRB(10, 0, 10, 5),
  });
  @override
  State<RoundCheckButton> createState() => _RoundCheckButtonState();
}

class _RoundCheckButtonState extends State<RoundCheckButton> {
  bool _isSelected = false;
  void _toggle() {
    setState(() {
      _isSelected = !_isSelected;
    });
    if (widget.onChanged != null) {
      widget.onChanged!(_isSelected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _toggle,
          icon: Icon(
            _isSelected ? Icons.check_circle : Icons.circle_outlined,
            color: _isSelected ? Colors.green : Colors.grey,
          ),
          label: Text(widget.text),
          style: ElevatedButton.styleFrom(
            elevation: 3, // ✅ 그림자 높이
            shadowColor: Colors.black.withOpacity(1),
            backgroundColor: _isSelected ? Colors.lightBlue[100] : Colors.white,
            foregroundColor: Colors.black,
            padding: EdgeInsets.symmetric(vertical: widget.textSize / 1.2),
            textStyle: TextStyle(
              fontSize: widget.textSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
