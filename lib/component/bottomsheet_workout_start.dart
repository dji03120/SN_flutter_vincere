import 'package:flutter/material.dart';
import 'package:Vincere/custom_widget/custom_button.dart';
import 'package:Vincere/custom_widget/custom_text.dart';
import 'package:Vincere/page_workout/page_workout_content.dart';

class BottomsheetWorkoutStart extends StatelessWidget {
  const BottomsheetWorkoutStart({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height - 50;

    return SafeArea(
      child: Container(
        width: double.infinity,
        height: screenHeight * 0.3,
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 111, 163, 27),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          // 내부 내용 스크롤 가능하게
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextLarge(text: '남은 운동 개수 : n ', color: Colors.white),
                TextLarge(text: '남은 운동 시간 : n Min', color: Colors.white),
                SizedBox(height: screenHeight * 0.04),
                RoundButton(
                  text: "운동시작",
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => WorkoutContent()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
