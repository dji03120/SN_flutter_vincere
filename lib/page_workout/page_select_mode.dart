import 'package:Vincere/component/header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Vincere/provider_models.dart';
import 'package:Vincere/component/custom_button.dart';
import 'package:Vincere/component/custom_text.dart';
import 'package:Vincere/page_workout/page_select_muscle.dart';

class SelectMode extends StatefulWidget {
  const SelectMode({super.key});

  @override
  State<SelectMode> createState() => SelectModeState();
}

class SelectModeState extends State<SelectMode> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workoutModel = Provider.of<WorkoutModel>(context); // 상태 접근
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: const Header(),
      body: Container(
        width: double.infinity,
        child: Container(
          color: Color(0xFFf5f4f9),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.1),
              TextLarge(text: '운동 모드를 선택해주세요.'),
              SizedBox(height: screenHeight * 0.1),
              SizedBox(
                height: 100,
                child: RoundButton(
                  text: 'Passive Mode',
                  margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
                  onPressed: () {
                    workoutModel.set_current_workout(0);
                    workoutModel.set_workouts([
                      '상완근 10min',
                      '이두근 10min',
                      '삼각근 10min',
                      '대흉근 10min',
                      '대퇴근 10min',
                    ]);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SelectMuscle()),
                    );
                  },
                ),
              ),
              SizedBox(height: screenHeight * 0.04),
              SizedBox(
                height: 100,
                child: RoundButton(
                  text: 'Active Mode',
                  margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
                  onPressed: () {
                    workoutModel.set_current_workout(0);
                    workoutModel.set_workouts([
                      '상완근 10min',
                      '이두근 10min',
                      '삼각근 10min',
                      '대흉근 10min',
                      '대퇴근 10min',
                    ]);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SelectMuscle()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
