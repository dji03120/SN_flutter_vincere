import 'package:Vincere/component/header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Vincere/provider_models.dart';
import 'package:Vincere/component/custom_button.dart';
import 'package:Vincere/component/custom_text.dart';
import 'package:Vincere/page_workout/page_workout_plan.dart';

class SelectMuscle extends StatefulWidget {
  const SelectMuscle({super.key});

  @override
  State<SelectMuscle> createState() => Component3State();
}

class Component3State extends State<SelectMuscle> {
  // 체크된 항목을 저장할 리스트
  List<String> selectedWorkouts = [];

  // 체크박스 항목 목록
  final List<dynamic> workouts = [
    {'name': '상완근', 'service_type': '무료'},
    {'name': '삼각근', 'service_type': '무료'},
    {'name': '대퇴근', 'service_type': '무료'},
    {'name': '척추기립근', 'service_type': '유료'},
    {'name': '대퇴이두근', 'service_type': '유료'},
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final workoutModel = Provider.of<WorkoutModel>(context); // 상태 접근
    final userModel = Provider.of<UserModel>(context); // 상태 접근

    return Scaffold(
      appBar: const Header(),
      //drawer: CustomDrawer(isLogin: true),
      body: Container(
        width: screenWidth,
        height: screenHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F4F9), Color(0xFFE0E0F0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Container(
          color: Color(0xFFf5f4f9),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.06),
              Chip(
                label: TextCustom(text: workoutModel.workoutMode == "active" ? "Active Mode" : "Passive Mode", color: Colors.white, fontSize: 16),
                backgroundColor: workoutModel.workoutMode == "active" ? Colors.deepOrangeAccent : Colors.lightBlue,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              SizedBox(height: screenHeight * 0.015),
              TextCustom(text: '운동 부위를 선택해주세요', fontSize: 20),

              // 체크 버튼들
              SizedBox(height: screenHeight * 0.05),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: workouts.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    var workout = workouts[index];
                    bool isDisabled = workout['service_type'] == '유료';
                    if (userModel.userInfo['authCd'].contains('PAID')) isDisabled = false;
                    final isSelected = selectedWorkouts.contains(workout['name']);

                    return GestureDetector(
                      onTap: () {
                        if (isDisabled) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('해당 서비스는 유료입니다.\n관리자에게 요청해주세요.')),
                          );
                        } else {
                          setState(() {
                            if (isSelected == true) selectedWorkouts.remove(workout['name']);
                            if (isSelected == false) selectedWorkouts.add(workout['name']!);
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        decoration: BoxDecoration(
                          color: isDisabled
                              ? Colors.grey.shade300
                              : isSelected
                                  ? Colors.lightGreen[100]
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(workout['name']!,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: isDisabled ? Colors.white : Colors.black87,
                                )),
                            Chip(
                              label: Text(workout['service_type']!,
                                  style: TextStyle(
                                    color: isDisabled ? Colors.white : Colors.white,
                                    fontWeight: FontWeight.bold,
                                  )),
                              backgroundColor: workout['service_type'] == '유료' ? Colors.orangeAccent : Color(0xFF4CAF50),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: screenHeight * 0.03),
              SizedBox(
                width: screenWidth / 4 * 3,
                child: RoundButton(
                  text: '운동시작',
                  onPressed: () {
                    // 선택된 항목 확인 가능
                    workoutModel.set_workout_plan(selectedWorkouts);
                    workoutModel.set_current_workout(0);
                    if (selectedWorkouts.length != 0) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WorkoutPlan(explainText: '운동 계획이 설정되었습니다.'),
                          ));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('운동을 한 개 이상 선택해주세요')),
                      );
                    }
                  },
                  borderRadius: 10,
                ),
              ),
              SizedBox(height: screenHeight * 0.05),
            ],
          ),
        ),
      ),
    );
  }
}
