import 'package:Vincere/page_survey/screen_survey.dart';
import 'package:flutter/material.dart';

void showSurveyModal(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return Dialog(
        insetPadding: EdgeInsets.fromLTRB(10, 20, 10, 20),
        backgroundColor: Color(0xFFf4f4f4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: 330,
          height: 400,
          child: Stack(
            children: [
              // 모달 내용
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20), // 상단 X버튼 공간 확보
                    const Text(
                      "안녕하세요.",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      "{user_name}님",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "고객님의 건강 성향에 맞춘 서비스를 제공하기 위해, 간단한 설문조사를 준비했습니다.",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "테스트를 진행하시겠습니까?",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ScreenSurvey()),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(200, 50), // 버튼 크기 (너비 x 높이)
                        backgroundColor: Colors.blue, // 배경색
                        foregroundColor: Colors.white, // 글자색
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // 모서리 둥글게
                        ),
                        elevation: 6, // 그림자 높이
                        shadowColor: Colors.black54, // 그림자 색상
                        textStyle: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text("시작"),
                    )
                  ],
                ),
              ),

              // 우측 상단 X 버튼
              Positioned(
                right: 10,
                top: 10,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  iconSize: 28, // 아이콘 크기 조절
                  padding: EdgeInsets.all(4), // 버튼 안쪽 여백
                  constraints: const BoxConstraints(), // 기본 최소 크기 제거
                  onPressed: () => Navigator.of(context).pop(),
                ),
              )
            ],
          ),
        ),
      );
    },
  );
}
