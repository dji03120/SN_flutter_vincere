import 'package:Vincere/utils/component/custom_drawer.dart';
import 'package:Vincere/utils/component/header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Vincere/provider_models.dart';
import 'package:Vincere/services/page_workout/page_select_muscle.dart';

class SelectMode extends StatefulWidget {
  const SelectMode({super.key});

  @override
  State<SelectMode> createState() => SelectModeState();
}

class SelectModeState extends State<SelectMode> {
  @override
  Widget build(BuildContext context) {
    final workoutModel = Provider.of<WorkoutModel>(context);
    final userModel = Provider.of<UserModel>(context);

    return Scaffold(
      appBar: const Header(),
      drawer: CustomDrawer(isLogin: true),
      backgroundColor: const Color(0xFFF5F4F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Title
              const Text(
                "운동 모드를\n선택해주세요.",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 60),

              // Passive Mode Card
              _modeCard(
                icon: Icons.self_improvement,
                title: "Passive Mode",
                subtitle: "기본 운동 모드",
                onTap: () async {
                  await workoutModel.get_workout_info(userModel.userId);
                  workoutModel.set_workout_level(userModel.gradeAvg);
                  workoutModel.set_workout_mode("passive");
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SelectMuscle()),
                  );
                },
              ),

              const SizedBox(height: 35),

              // Active Mode Card / Paid 체크
              (userModel.userInfo?['authCd'] ?? '').contains('PAID')
                  ? _modeCard(
                      icon: Icons.flash_on,
                      title: "Active Mode",
                      subtitle: "강화된 개인 맞춤 모드",
                      onTap: () async {
                        await workoutModel.get_workout_info(userModel.userId);
                        workoutModel.set_workout_level(userModel.gradeAvg);
                        workoutModel.set_workout_mode("active");
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SelectMuscle()),
                        );
                      },
                    )
                  : _disabledCard(
                      icon: Icons.lock,
                      title: "Active Mode",
                      subtitle: "유료 사용자 전용 기능",
                      context: context,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------
  // ↓ ACTIVE / PASSIVE 카드
  // ----------------------
  Widget _modeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Function onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => onTap(),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF003366),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),

            const SizedBox(width: 22),

            // Text
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003366),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------
  // ↓ ACTIVE MODE – 비활성 카드
  // ----------------------------
  Widget _disabledCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required BuildContext context,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("해당 서비스는 유료입니다.\n관리자에게 요청해주세요."),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 22),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "유료 사용자 전용 기능",
                  style: TextStyle(fontSize: 15, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
