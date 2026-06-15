// BLE 테스트용 화면
// 버튼 눌러서:
// - 연결
// - pause 전송
// - continue 전송
// - stop 전송
// 테스트 가능

import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'ble_mobile_test_service.dart';
import 'ble_mobile_test_utils.dart';

class BleMobileTestPage extends StatefulWidget {
  const BleMobileTestPage({super.key});

  @override
  State<BleMobileTestPage> createState() =>
      _BleMobileTestPageState();
}

class _BleMobileTestPageState
    extends State<BleMobileTestPage> {

  // BLE service 객체
  final BleMobileTestService bleService =
  BleMobileTestService();

  // 현재 상태 표시용
  String status = "대기 중";

  // 마지막 notify 데이터 표시용
  String lastNotify = "-";

  @override
  void dispose() {

    bleService.dispose();

    super.dispose();
  }

  // BLE 연결
  Future<void> connect() async {

    setState(() {
      status = "연결 중...";
    });

    try {

      await bleService.scanAndConnect();

      // notify 수신 listen
      bleService.notifyStream.listen((value) {

        setState(() {

          lastNotify = bytesToHex(
            Uint8List.fromList(value),
          );

        });
      });

      setState(() {
        status = "연결 완료";
      });

    } catch (e) {

      setState(() {
        status = "연결 실패";
      });

    }
  }

  // pause 명령 전송
  Future<void> sendPause() async {

    await bleService.writeHex(
      elexirCommands["pause"]!,
    );

  }

  // continue 명령 전송
  Future<void> sendContinue() async {

    await bleService.writeHex(
      elexirCommands["continue"]!,
    );

  }

  // stop 명령 전송
  Future<void> sendStop() async {

    await bleService.writeHex(
      elexirCommands["stop"]!,
    );

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("BLE TEST"),
      ),

      body: Padding(

        padding: const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [

            Text("상태: $status"),

            const SizedBox(height: 12),

            Text("Notify: $lastNotify"),

            const SizedBox(height: 20),

            // BLE 연결 버튼
            ElevatedButton(
              onPressed: connect,
              child: const Text("BLE 연결"),
            ),

            // pause 전송 버튼
            ElevatedButton(
              onPressed: sendPause,
              child: const Text("Pause"),
            ),

            // continue 전송 버튼
            ElevatedButton(
              onPressed: sendContinue,
              child: const Text("Continue"),
            ),

            // stop 전송 버튼
            ElevatedButton(
              onPressed: sendStop,
              child: const Text("Stop"),
            ),
          ],
        ),
      ),
    );
  }
}