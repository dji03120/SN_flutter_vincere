import 'package:Vincere/services/page_ble_device/ble_utils.dart';
import 'package:Vincere/services/page_ble_device/page_fitrus_weight.dart';
import 'package:Vincere/services/page_ble_device/web/page_blood_sugar.dart';
import 'package:Vincere/services/page_ble_device/page_inbody_hand_pressure.dart';
import 'package:Vincere/services/page_ble_device/page_select_measure_type_fitrus.dart';
import 'package:Vincere/services/page_ble_device/page_select_measure_type_bloodpress.dart';
import 'package:Vincere/services/page_health/screen_my_health_info_input.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:Vincere/utils/component/custom_drawer.dart';
import 'package:Vincere/utils/component/header.dart';

class SelectMeasureDevice extends StatefulWidget {
  const SelectMeasureDevice({super.key});

  @override
  State<SelectMeasureDevice> createState() => _SelectMeasureDeviceState();
}

class _SelectMeasureDeviceState extends State<SelectMeasureDevice> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    void initState() {
      super.initState();
      permissionCheck(context);
    }

    return Scaffold(
      appBar: const Header(),
      drawer: const CustomDrawer(
        isLogin: true,
      ),
      backgroundColor: const Color(0xFFF5F4F9),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "측정 장비를 선택해주세요",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.black87),
                ),
                const SizedBox(height: 40),

                // ---------------------- 카드 1 : 체중계 ----------------------
                _ModernCard(
                  icon: Icons.monitor_weight_outlined,
                  title: "스마트 체중계 측정",
                  subtitle: "체중계와 연동하여 자동 측정",
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PageConnectFitrusWeight()));
                  },
                ),

                const SizedBox(height: 20),

                // ---------------------- 카드 2 : 체지방 측정기 ----------------------
                _ModernCard(
                  icon: Icons.accessibility_new,
                  title: "체성분 및 스트레스 측정",
                  subtitle: "AI 기반 정밀 체성분 측정",
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PageSelectFitrusMeasureType()));
                  },
                ),

                const SizedBox(height: 20),

                // ---------------------- 카드 3 : 악력계 ----------------------
                _ModernCard(
                  icon: Icons.fitness_center,
                  title: "악력 측정",
                  subtitle: "악력계와 연동하여 자동 측정",
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PageInbodyHandPressure()));
                  },
                ),
                const SizedBox(height: 20),

                // ---------------------- 카드 4 : 혈압계 ----------------------
                _ModernCard(
                  icon: Icons.monitor_heart,
                  title: "혈압 측정",
                  subtitle: "혈압계와 연동하여 자동 측정",
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PageSelectBloodPressMeasureType()));
                  },
                ),
                const SizedBox(height: 20),

                // ---------------------- 카드 4 : 혈당계 ----------------------
                _ModernCard(
                  icon: Icons.bloodtype,
                  title: "혈당 측정",
                  subtitle: "혈당 측정기와 연동하여 자동 측정",
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PageBloodSugar()));
                  },
                ),

                const SizedBox(height: 20),
                // ---------------------- 카드 3 : 직접 입력 ----------------------
                _ModernCard(
                  icon: Icons.edit_note_outlined,
                  title: "직접 입력하기",
                  subtitle: "측정 없이 수동으로 입력",
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ScreenHealthInfoInput()));
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

//
//
//
//
class _ModernCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModernCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  @override
  State<_ModernCard> createState() => _ModernCardState();
}

class _ModernCardState extends State<_ModernCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
            border: Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(widget.icon, size: 32, color: Colors.blueAccent),
              ),
              const SizedBox(width: 20),

              // 텍스트
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(widget.title, maxLines: 1, minFontSize: 12, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    AutoSizeText(widget.subtitle, maxLines: 2, minFontSize: 12, style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.6))),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
