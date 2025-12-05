import 'package:Vincere/page_ble_device/page_connect_fitrux_hand.dart';
import 'package:Vincere/page_ble_device/page_connect_fitrux_weight.dart';
import 'package:Vincere/page_health/screen_my_health_info_raw.dart';
import 'package:flutter/material.dart';
import 'package:Vincere/component/custom_drawer.dart';
import 'package:Vincere/component/header.dart';
import 'package:Vincere/page_elexir_workout/page_select_muscle.dart';

class SelectMeasureDevice extends StatefulWidget {
  const SelectMeasureDevice({super.key});

  @override
  State<SelectMeasureDevice> createState() => _SelectMeasureDeviceState();
}

class _SelectMeasureDeviceState extends State<SelectMeasureDevice> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: const Header(),
      drawer: const CustomDrawer(isLogin: true),
      backgroundColor: const Color(0xFFF5F4F9),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "측정 장비를 선택해주세요",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 40),

              // ---------------------- 카드 1 : 체중계 ----------------------
              _ModernCard(
                icon: Icons.monitor_weight_outlined,
                title: "스마트 체중계 측정",
                subtitle: "BLE 체중계 연동하여 자동 측정",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PageConnectFitrusWeight()),
                  );
                },
              ),

              const SizedBox(height: 20),

              // ---------------------- 카드 2 : 체지방 측정기 ----------------------
              _ModernCard(
                icon: Icons.bolt_outlined,
                title: "체지방 측정기",
                subtitle: "AI 기반 정밀 체성분 측정",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PageConnectFitrusHand()),
                  );
                },
              ),

              const SizedBox(height: 20),

              // ---------------------- 카드 3 : 직접 입력 ----------------------
              _ModernCard(
                icon: Icons.edit_note_outlined,
                title: "직접 입력하기",
                subtitle: "측정 없이 수동으로 입력",
                onTap: () {
                  /*Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScreenHealthInfoInput()),
                  );*/
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 현대적인 유리모피즘 스타일 카드
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, size: 32, color: Colors.blueAccent),
              ),
              const SizedBox(width: 20),

              // 텍스트
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.6)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
