import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Vincere/component/custom_button.dart';
import 'package:Vincere/component/custom_text.dart';
import 'package:Vincere/page_workout/page_workout_content.dart';
import 'package:Vincere/provider_models.dart';
import 'package:Vincere/page_ble_device/ble_utils.dart';

class BottomsheetWorkoutStart extends StatelessWidget {
  const BottomsheetWorkoutStart({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height - 50;
    final screenWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Container(
        width: screenWidth,
        height: screenHeight * 0.3,
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 111, 163, 27),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
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
                  onPressed: () async {
                    final workoutModel = Provider.of<WorkoutModel>(context, listen: false);
                    if (workoutModel.writeChar != null) {
                      await sendCommand(workoutModel.writeChar, ble_commands["pause"]!);
                      await sendCommand(workoutModel.writeChar, ble_commands["continue"]!); // 다시시작
                    } else {
                      print("writeChar is null, BLE not connected");
                    }
                    // 운동 페이지로 이동
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const WorkoutContent()));
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
