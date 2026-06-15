import 'package:flutter/material.dart';

import 'page_connect_elexir_mobile.dart';

class SelectMeasureDeviceMobile extends StatelessWidget {
  const SelectMeasureDeviceMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("모바일 측정 장비 선택"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PageConnectElexirMobile(),
                ),
              );
            },
            child: const Text("Elexir 모바일 BLE 연결 테스트"),
          ),
          const SizedBox(height: 12),
          const Text(
            "나머지 체중계/혈당/혈압/악력 BLE는 이후 UUID 확인 후 모바일용으로 추가 구현 필요",
          ),
        ],
      ),
    );
  }
}