import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Vincere/provider_models.dart';
import 'package:Vincere/custom_widget/custom_text.dart';
import 'package:Vincere/page_workout/page_statistics.dart';
import 'package:Vincere/page_workout/page_workout_plan.dart';

class CounterButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final double width;
  final double fontSize;

  const CounterButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.width = 100,
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: EdgeInsets.symmetric(horizontal: fontSize),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 6,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: EdgeInsets.symmetric(vertical: fontSize),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: fontSize.toDouble(),
          ),
        ),
      ),
    );
  }
}

class BottomsheetWorkoutContent extends StatefulWidget {
  final int value;
  final bool isWorkoutDone;

  const BottomsheetWorkoutContent({
    super.key,
    required this.value,
    this.isWorkoutDone = false,
  });

  @override
  State<BottomsheetWorkoutContent> createState() => _BottomsheetWorkoutContentState();
}

class _BottomsheetWorkoutContentState extends State<BottomsheetWorkoutContent> {
  late int inner_value;

  @override
  void initState() {
    super.initState();
    inner_value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height - 50;
    final screenWidth = MediaQuery.of(context).size.width;

    final workoutModel = Provider.of<WorkoutModel>(context); // 상태 접근
    return Container(
      width: double.infinity,
      height: screenHeight * 0.3,
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 111, 163, 27),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.all(30),
      child: widget.isWorkoutDone == false
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextLarge(text: '전기자극 강도', color: Colors.white),
                SizedBox(height: screenHeight * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CounterButton(
                      width: screenWidth * 0.25,
                      label: '-',
                      onPressed: () {
                        setState(() {
                          inner_value = (inner_value - 1).clamp(0, 5);
                        });
                      },
                    ),
                    TextTitle(text: '$inner_value/5'),
                    CounterButton(
                      width: screenWidth * 0.25,
                      label: '+',
                      onPressed: () {
                        setState(() {
                          inner_value = (inner_value + 1).clamp(0, 5);
                        });
                      },
                    ),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextLarge(text: '운동이 종료되었습니다', color: Colors.white),
                SizedBox(height: screenHeight * 0.04),
                CounterButton(
                  width: screenWidth * 0.75,
                  label: '다음운동',
                  onPressed: () {
                    int next_workout_idx = workoutModel.currentWorkout + 1;
                    if (next_workout_idx >= workoutModel.workouts.length) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StatisticsPage(),
                        ),
                      );
                    } else {
                      workoutModel.set_current_workout(next_workout_idx);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkoutPlan(
                            explainText: '다음 운동을 진행하시려면\n 시작버튼을 눌러주세요',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
    );
  }
}
