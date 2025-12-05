import 'package:Vincere/component/custom_drawer.dart';
import 'package:Vincere/component/header.dart';
import 'package:flutter/material.dart';

class ScreenSurvey extends StatefulWidget {
  const ScreenSurvey({super.key});

  @override
  State<ScreenSurvey> createState() => _ScreenSurveyState();
}

class _ScreenSurveyState extends State<ScreenSurvey> {
  int selectedIndex = -1;
  Map<String, bool> selected = {};
  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;

    final String question = "Q : 현재 가지고 계신 질병이 있다면 선택해 주세요.";
    final List<String> options = ["A. 매우 그렇다", "B. 조금 그렇다", "C. 가끔 그렇다", "D. 아니다"];
    final List<String> options2 = ["고혈압", "당뇨", "고지혈증", "심장질환", "뇌혈관질환", "골다공증", "관절염", "천식", "간질환", "신장질환", "암", "비만"];

    for (var option in options2) {
      selected.putIfAbsent(option, () => false);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: const Header(),
      drawer: const CustomDrawer(isLogin: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            questionBox(question),
            //selectorForm(options),
            //editorForm(),
            chipForm(options2),
            pagination(),
          ],
        ),
      ),
    );
  }

  Widget questionBox(String question) {
    final double height = MediaQuery.of(context).size.height;
    return Container(
      height: height * 0.25,
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Text(
        question,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black87),
      ),
    );
  }

  //
  //
  //
  Widget pagination() {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;
    return SizedBox(
      height: height * 0.2,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(width: 10),
          SizedBox(
            width: width * 0.35,
            height: 60,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
                "이전",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
          SizedBox(
            width: width * 0.35,
            height: 60,
            child: ElevatedButton(
              onPressed: selectedIndex == -1 ? null : () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                disabledBackgroundColor: Colors.blue.shade200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
                "다음",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
    );
  }

  //
  //
  //
  Widget editorForm() {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    return Container(
      height: height * 0.4,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const TextField(
              maxLines: null, // 여러 줄 입력 가능
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(fontSize: 20, color: Colors.black87),
              decoration: const InputDecoration(
                hintText: "내용을 입력하세요...",
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          ),
          SizedBox(height: 50),
        ],
      ),
    );
  }

  //
  //
  //
  Widget chipForm(List<String> options) {
    final double height = MediaQuery.of(context).size.height;

    return Container(
      height: height * 0.4,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Wrap(
          spacing: 8, // 가로 간격
          runSpacing: 8, // 줄 간격
          alignment: WrapAlignment.center,
          children: List.generate(options.length, (i) {
            return ChoiceChip(
              label: Text(
                options[i],
                style: const TextStyle(fontSize: 16),
              ),
              selected: false,
              onSelected: (val) {
                setState(() {
                  selected[options[i]] = !(selected[options[i]] ?? false);
                  print(selected);
                });
              },
              backgroundColor: selected[options[i]]! ? Colors.blue.shade200 : Colors.grey.shade200,
              selectedColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        ),
      ),
    );
  }

  //
  //
  //
  Widget selectorForm(List<String> options) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;
    return SizedBox(
      height: height * 0.4,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          for (int i = 0; i < options.length; i++) ...[
            GestureDetector(
              onTap: () {
                setState(() => selectedIndex = i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: selectedIndex == i ? Colors.blue.shade100 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selectedIndex == i ? Colors.blue : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Text(
                  options[i],
                  style: TextStyle(
                    fontSize: 18,
                    color: selectedIndex == i ? Colors.blue.shade900 : Colors.black87,
                    fontWeight: selectedIndex == i ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
