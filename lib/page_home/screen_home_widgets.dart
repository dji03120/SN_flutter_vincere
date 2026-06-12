import 'package:Vincere/utils/component/metric_chart_dialog.dart';
import 'package:Vincere/services/page_health/screen_my_health_info.dart';
import 'package:Vincere/page_home/utils.dart';
import 'package:Vincere/services/page_nutrition/screen_my_nutri.dart';
import 'package:Vincere/services/page_workout/page_workout_home.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/rendering.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:Vincere/provider_models.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';

//
//
//
//
//
class ProfileCard extends StatelessWidget {
  final UserModel userModel;

  const ProfileCard({
    Key? key,
    required this.userModel,
  }) : super(key: key);

  // --- 건강 정보 위젯 ---
  Widget _buildHealthMetric(String label, double value, String unit) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInCubic,
      builder: (context, animatedValue, child) {
        return Column(
          children: [
            Text(label, style: TextStyle(fontSize: 14, color: Color(0xFFFFFF).withOpacity(0.8))),
            SizedBox(height: 2),
            AutoSizeText(
              animatedValue.toStringAsFixed(1),
              maxLines: 1,
              minFontSize: 14,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            SizedBox(height: 2),
            Text(unit, style: TextStyle(fontSize: 14, color: Color(0xFFFFFF).withOpacity(0.8))),
          ],
        );
      },
    );
  }

  // --- 프로필 이미지 ---
  Widget _buildProfileImage(String? imageUrl) {
    Widget defaultAvatar = CircleAvatar(radius: 58, backgroundColor: Colors.grey[300], child: Icon(Icons.person, size: 35, color: Colors.grey[600]));
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
      child: imageUrl != null
          ? ClipOval(
              child: Image.network(imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => defaultAvatar,
                  loadingBuilder: (_, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                        child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
                    ));
                  }))
          : defaultAvatar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel>(context);
    return Card(
      color: Colors.black87,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(4.0),
        child: Column(
          children: [
            SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  margin: EdgeInsets.fromLTRB(32, 32, 16, 24),
                  //decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle),
                  child: Center(child: _buildProfileImage(userModel.profileImageUrl)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(width: 10),
                        Text(userModel.userInfo?["userNm"] ?? '', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(width: 25),
                        Text('만 ${calculateAge(userModel.userInfo?["bym"] ?? "정보없음").toString()}세', style: TextStyle(fontSize: 18, color: Colors.white)),
                      ],
                    ),
                    SizedBox(height: 20),
                    Container(
                      margin: EdgeInsets.only(left: 6),
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ScreenHealthInfo()));
                        },
                        style: TextButton.styleFrom(
                          fixedSize: Size(186, 40),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF92D2B0), width: 2)),
                        ),
                        child: const Text('내 건강정보 자세히보기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF92D2B0))),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 5),
            Container(width: 312, child: Divider(color: Colors.white.withOpacity(0.15), thickness: 1, height: 10)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: Container(
                  margin: const EdgeInsets.fromLTRB(18.0, 24.0, 0, 24.0),
                  child: _buildHealthMetric('키', userModel.userHealthData?['키'][0] ?? 0, 'cm'),
                )),
                Container(height: 74, child: VerticalDivider(color: Colors.white.withOpacity(0.15), thickness: 1)),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(0.0),
                    child: _buildHealthMetric('체중', userModel.userHealthData?['몸무게'][0] ?? 0, userModel.userHealthData?['몸무게'][3] ?? 'kg'),
                  ),
                ),
                Container(height: 74, child: VerticalDivider(color: Colors.white.withOpacity(0.15), thickness: 1)),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(0.0),
                    child: _buildHealthMetric('체지방량', userModel.userHealthData?['체지방량'][0] ?? 0, userModel.userHealthData?['체지방량'][3] ?? 'kg'),
                  ),
                ),
                Container(height: 74, child: VerticalDivider(color: Colors.white.withOpacity(0.15), thickness: 1)),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 24.0, 18.0, 24.0),
                    child: _buildHealthMetric('근육량', userModel.userHealthData?['근육량'][0] ?? 0, userModel.userHealthData?['근육량'][3] ?? 'kg'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBox(String name, double value, String unit) {
    return Column(
      children: [
        Text(name, style: TextStyle(fontSize: 15, color: Colors.grey[600])),
        SizedBox(height: 4),
        Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
        SizedBox(height: 2),
        Text(unit, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
      ],
    );
  }
}

//
//
//
//
//
//

class ProfileMuscleCard extends StatelessWidget {
  final UserModel userModel;

  const ProfileMuscleCard({
    super.key,
    required this.userModel,
  });

  @override
  Widget build(BuildContext context) {
    final muscleData = userModel.userHealthData;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 왼쪽: 근육 나이 텍스트
              Container(
                  alignment: Alignment.centerLeft,
                  width: MediaQuery.of(context).size.width * 0.6,
                  margin: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.06),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(height: 10),
                    const Text('내 근육 나이', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    RichText(
                        text: TextSpan(children: [
                      TextSpan(
                        text: userModel.userHealthData?['muscleAge']?.toString() ?? '--',
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Color(0xFF007130)),
                      ),
                      const TextSpan(text: ' 세', style: TextStyle(fontSize: 22, color: Color(0xFF000000))),
                    ]))
                  ])),

              // 오른쪽: 이미지
              Container(width: 60, height: 60, margin: EdgeInsets.only(right: MediaQuery.of(context).size.width * 0.06), child: Image.asset('images/body.png', fit: BoxFit.contain)),
            ],
          ),

          // ====== 메트릭 리스트 ======
          const SizedBox(height: 16),
          buildDivider(context, isBold: true),
          _buildMetricRow(context, '신체조성', '신체질량지수(BMI)'),
          buildDashedDivider(context),
          _buildMetricRow(context, '', '체지방률'),
          buildDashedDivider(context),
          _buildMetricRow(context, '', '근육'), // ASM/체중*100%
          buildDivider(context),
          _buildMetricRow(context, '신체기능', '악력'),
          buildDashedDivider(context),
          _buildMetricRow(context, '', '걷기'),
          buildDashedDivider(context),
          _buildMetricRow(context, '', '앉았다 일어서기'),
          buildDivider(context, isBold: true),
          const SizedBox(height: 26),
        ],
      ),
    );
  }

  // 기존에 작성된 _buildMetricRow 함수 및 buildDivider, buildDashedDivider 함수는 여기에 위치해야 합니다.

  // --- Metric Row ---
  Widget _buildMetricRow(BuildContext context, String category, String title) {
    double grade = userModel.userHealthData?[title][4] ?? 5;
    String code = userModel.userHealthData?[title][1]; // msmt 코드
    String unit = userModel.userHealthData?[title][3]; // 단위
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2, horizontal: MediaQuery.of(context).size.width * 0.06),
      child: Row(
        children: [
          // category
          SizedBox(width: 70, child: category.isNotEmpty ? Text(category, style: const TextStyle(color: Color(0xFF000000), fontSize: 13, fontWeight: FontWeight.w500)) : const SizedBox()),
          Expanded(child: Text("$title ($unit)", style: const TextStyle(color: Color(0xFF555555), fontSize: 13, fontWeight: FontWeight.w400))),
          if (grade == 1)
            Container(
              width: 40,
              height: 22,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF00914B), width: 2)),
              child: const Center(child: Text('BEST', style: TextStyle(color: Color(0xFF007130), fontSize: 11, fontWeight: FontWeight.bold))),
            ),
          const SizedBox(width: 10),
          Text('$grade등급', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: grade == 1 ? const Color(0xFF00914B) : (grade == 2 ? const Color(0xFF9D895B) : const Color(0xFF8D8D8D)))),
          IconButton(
            icon: const Icon(Icons.bar_chart, size: 24, color: Color(0xFF00914B)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return MetricChartDialog(title: title, code: code, userId: userModel.userId);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

//
//
//
//
//
//
Widget contentsCardActive(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;

  return Container(
    width: screenWidth,
    padding: const EdgeInsets.all(4),
    child: InkWell(
      borderRadius: BorderRadius.circular(32),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MyWorkoutPage()));
      },
      child: Card(
        elevation: 6,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              // 🌊 Wave Background
              SizedBox(
                height: 400,
                width: double.infinity,
                child: WaveWidget(
                  config: CustomConfig(
                    gradients: [
                      [const Color(0xFFE2FFF0), const Color(0xFFC8FFE2)],
                      [const Color(0xFFB2FBD2), const Color(0xFFA0F9C5)],
                    ],
                    durations: [17500, 9720],
                    heightPercentages: [0.50, 0.56],
                  ),
                  backgroundColor: Colors.white,
                  waveAmplitude: 0,
                  size: const Size(double.infinity, double.infinity),
                ),
              ),

              // 콘텐츠
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    SizedBox(width: screenWidth * 0.5, height: 150, child: Image.asset("assets/images/HealthyActive.png")),
                    const SizedBox(height: 12),
                    const AutoSizeText(
                      "일상 속에서 근력을 늘릴 수 있는",
                      maxLines: 1,
                      minFontSize: 12,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF00914B)),
                    ),
                    const AutoSizeText(
                      "맞춤형 운동 미션을 확인하세요",
                      maxLines: 1,
                      minFontSize: 12,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(width: screenWidth, height: 90, child: Image.asset("assets/images/HealthyActive2.png")),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

//
//
//
//
//
//
Widget contentsCardPlate(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;

  return Container(
    width: screenWidth,
    padding: const EdgeInsets.all(4),

    // ⭐ InkWell로 Card 전체 클릭 가능
    child: InkWell(
      borderRadius: BorderRadius.circular(32),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MyNutriPage()));
      },
      child: Card(
        elevation: 6,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              // 🌊 Wave Background
              SizedBox(
                height: 400,
                width: double.infinity,
                child: WaveWidget(
                  config: CustomConfig(
                    gradients: [
                      [const Color(0xFFE2FFF0), const Color(0xFFC8FFE2)],
                      [const Color(0xFFB2FBD2), const Color(0xFFA0F9C5)],
                    ],
                    durations: [17500, 9720],
                    heightPercentages: [0.50, 0.56],
                  ),
                  backgroundColor: Colors.white,
                  waveAmplitude: 0,
                  size: const Size(double.infinity, double.infinity),
                ),
              ),

              // 콘텐츠
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 8),
                    SizedBox(width: screenWidth * 0.45, height: 150, child: Image.asset("assets/images/HealthyPlate.png")),
                    SizedBox(height: 12),
                    AutoSizeText(
                      "좋은 음식을 바르게 섭취할 수 있도록",
                      maxLines: 1, // → 두 줄 이상 못 넘어가게
                      minFontSize: 12, // → 최소 폰트 크기
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF00914B),
                      ),
                    ),
                    AutoSizeText(
                      "식사습관 맞춤 영양식을 확인해보세요",
                      maxLines: 1,
                      minFontSize: 12,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: screenWidth,
                      height: 90,
                      child: Image.asset("assets/images/HealthyPlate2.png"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
