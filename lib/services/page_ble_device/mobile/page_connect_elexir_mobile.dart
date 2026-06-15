import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../common/ble_command_utils.dart';
import 'ble_mobile_service.dart';

class PageConnectElexirMobile extends StatefulWidget {
  const PageConnectElexirMobile({super.key});

  @override
  State<PageConnectElexirMobile> createState() =>
      _PageConnectElexirMobileState();
}

class _PageConnectElexirMobileState extends State<PageConnectElexirMobile> {
  final BleMobileService bleService = BleMobileService();

  String status = "디바이스 연결 대기 중";
  String lastNotify = "-";

  @override
  void dispose() {
    bleService.dispose();
    super.dispose();
  }

  Future<void> connect() async {
    setState(() => status = "VINCERE 기기 검색 및 연결 중...");

    try {
      await bleService.scanAndConnectElexir();

      bleService.notifyStream.listen((value) {
        setState(() {
          lastNotify = bytesToHex(Uint8List.fromList(value));
        });
      });

      await bleService.writeElexirHex("000C0E050100");
      await bleService.writeElexirHex(elexirCommands["pause"]!);

      setState(() => status = "연결 완료");
    } catch (e) {
      setState(() => status = "연결 실패: $e");
    }
  }

  Future<void> sendPause() async {
    await bleService.writeElexirHex(elexirCommands["pause"]!);
  }

  Future<void> sendContinue() async {
    await bleService.writeElexirHex(elexirCommands["continue"]!);
  }

  Future<void> sendStop() async {
    await bleService.writeElexirHex(elexirCommands["stop"]!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Elexir Mobile BLE"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("상태: $status"),
            const SizedBox(height: 12),
            Text("최근 Notify: $lastNotify"),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: connect,
              child: const Text("BLE 연결"),
            ),
            ElevatedButton(
              onPressed: sendPause,
              child: const Text("Pause 전송"),
            ),
            ElevatedButton(
              onPressed: sendContinue,
              child: const Text("Continue 전송"),
            ),
            ElevatedButton(
              onPressed: sendStop,
              child: const Text("Stop 전송"),
            ),
          ],
        ),
      ),
    );
  }
}