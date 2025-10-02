import 'package:Vincere/component/custom_drawer.dart';
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
    final userModel = Provider.of<UserModel>(context); // 상태 접근
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: const Header(),
      drawer: const CustomDrawer(isLogin: true),
      body: SizedBox(
        width: double.infinity,
        child: Container(
          color: const Color(0xFFf5f4f9),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.1),
              const TextCustom(text: '운동 모드를 선택해주세요.', fontSize: 20),
              SizedBox(height: screenHeight * 0.1),
              _modeSelectButton(context, workoutModel, userModel, "Passive Mode", "passive"),
              const SizedBox(height: 30),
              if (userModel.userInfo['authCd'].contains('PAID')) _modeSelectButton(context, workoutModel, userModel, "Active Mode", "active"),
              if (userModel.userInfo['authCd'].contains('PAID') == false)
                SizedBox(
                    height: 100,
                    child: RoundButton(
                        text: 'Active Mode',
                        color: Colors.grey,
                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        onPressed: () async {
                          await workoutModel.get_workout_info(userModel.userId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('해당 서비스는 유료입니다.\n관리자에게 요청해주세요.'),
                            ),
                          );
                        })),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeSelectButton(BuildContext context, WorkoutModel workoutModel, UserModel userModel, String text, String mode) {
    return SizedBox(
        height: 100,
        child: RoundButton(
            text: text,
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            onPressed: () async {
              await workoutModel.get_workout_info(userModel.userId);
              workoutModel.set_workout_level(userModel.gradeAvg);
              workoutModel.set_workout_mode(mode);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SelectMuscle()),
              );
            }));
  }
}
