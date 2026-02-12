import 'dart:typed_data';
import 'dart:js_util' as js_util;

import 'package:Vincere/services/page_ble_device/page_fitrus_hand.dart';
import 'package:Vincere/services/page_ble_device/page_select_measure_type_fitrus.dart';
import 'package:Vincere/utils/component/custom_widget.dart';
import 'package:Vincere/utils/component/header.dart';
import 'package:Vincere/utils/http/webReqFastapi.dart';
import 'package:Vincere/services/page_ble_device/ble_utils.dart';
import 'package:Vincere/provider_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart';
import 'package:flutter_web_bluetooth/js_web_bluetooth.dart';
import 'package:provider/provider.dart';

final bluetooth = FlutterWebBluetooth.instance;

enum MeasureState {
  connecting,
  measuring,
  done,
}

class PageInbodyBloodPressureLarge extends StatefulWidget {
  const PageInbodyBloodPressureLarge({super.key});

  @override
  State<PageInbodyBloodPressureLarge> createState() => _PageConnectFitrusWeightState();
}

class _PageConnectFitrusWeightState extends State<PageInbodyBloodPressureLarge> with SingleTickerProviderStateMixin {
  BluetoothDevice? _device;
  WebBluetoothRemoteGATTCharacteristic? _writeChar;
  WebBluetoothRemoteGATTCharacteristic? _notifyChar;

  static const SERVICE_UUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  static const WRITE_UUID = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";
  static const NOTIFY_UUID = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";
  static const device_name = "BPBIO320";

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  MeasureState measureState = MeasureState.connecting;
  double weightResult = 0.0;
  bool _connectFailed = false;
  bool _saved = false;

  String _selectedCmd = "start"; // 드롭다운 선택
  List<String> _notifyLogs = []; // Notify 로그

//
//
//
  /// Init
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scanAndConnect());
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

//
//
//
  /// UI
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: const Header(),
      body: Container(
        color: const Color(0xFFf5f4f9),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // 기본값이 min이어서 공간이 남음
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: screenHeight * 0.02),
                Center(child: _buildCurrentUI(screenHeight)),
                SizedBox(height: 200), // 하단 여백 (선택)
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
  /// 현재 상태에 맞는 UI 선택
  Widget _buildCurrentUI(double screenHeight) {
    switch (measureState) {
      case MeasureState.connecting:
        return _buildConnectingUI(screenHeight);
      case MeasureState.measuring:
        return _buildMeasureing();
      case MeasureState.done:
        return _buildDoneUI();
    }
  }

//
//
//
  Widget _buildConnectingUI(double screenHeight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Card(
          elevation: 4,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                // 🔵 외곽 파동 애니메이션
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ScaleTransition(scale: _scaleAnimation, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green.withOpacity(0.15)))),
                      ScaleTransition(scale: Tween(begin: 0.7, end: 1.0).animate(_scaleAnimation), child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green.withOpacity(0.25)))),
                      Container(
                        width: 110,
                        height: 110,
                        child: Center(child: Icon(Icons.monitor_weight, color: Colors.green, size: 90)),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: Offset(0, 4))],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
        SizedBox(height: screenHeight * 0.03),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("1. 장치의 전원버튼을 눌러주세요", style: TextStyle(fontSize: 18, color: Colors.black.withOpacity(0.7))),
          const SizedBox(height: 10),
          Text("2. 블루투스 목록에서 기기를 선택 후", style: TextStyle(fontSize: 18, color: Colors.black.withOpacity(0.7))),
          Text("   페어링을 눌러주세요", style: TextStyle(fontSize: 18, color: Colors.black.withOpacity(0.7))),
        ]),
        if (_connectFailed) RoundButton(margin: const EdgeInsets.fromLTRB(50, 36, 50, 0), text: "재연결", onPressed: _scanAndConnect)
      ],
    );
  }

  Future<void> sendCommandInbodyPressure(
    WebBluetoothRemoteGATTCharacteristic? _writeChar,
    String hexCommand,
  ) async {
    if (_writeChar == null) return;
    final commandBytes = buildElexirCommand(hexCommand);
    _writeChar.writeValueWithoutResponse(commandBytes);
    print("명령 전송: ${bytesToHex(commandBytes)}\n");
    await Future.delayed(const Duration(milliseconds: 150));
  }

  /// 선택한 명령어를 BLE 장치로 전송
  Future<void> _sendCommand(String cmd) async {
    if (_writeChar == null) {
      safeSetState(() => _notifyLogs.add("❌ write characteristic이 없습니다."));
      return;
    }

    try {
      // 명령어 맵
      final Map<String, Uint8List> commands = {
        "start": Uint8List.fromList([0x16, 0x16, 0x01, 0x30, 0x30, 0x02, 0x52, 0x43, 0x03, 0x11]),
        "log": Uint8List.fromList([0x16, 0x16, 0x01, 0x30, 0x30, 0x02, 0x52, 0x42, 0x03, 0x10]),
        "result": Uint8List.fromList([0x02, 0x62, 0x03])
      };

      if (!commands.containsKey(cmd)) {
        safeSetState(() => _notifyLogs.add("❌ 알 수 없는 명령어: $cmd"));
        return;
      }

      // BLE 전송
      await _writeChar?.writeValueWithoutResponse(commands[cmd]!);
      await Future.delayed(Duration(milliseconds: 100));

      safeSetState(() => _notifyLogs.insert(0, "✅ Sent command: $cmd"));
    } catch (e) {
      safeSetState(() => _notifyLogs.insert(0, "❌ 명령 전송 오류: $cmd, 에러: $e"));
    }
  }

//
//
//
  Widget _buildMeasureing() {
    return Column(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedCmd,
                    items: [
                      "start",
                      "log",
                      "result",
                    ].map((cmd) => DropdownMenuItem(value: cmd, child: Text(cmd))).toList(),
                    onChanged: (val) {
                      if (val != null) safeSetState(() => _selectedCmd = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: () => _sendCommand(_selectedCmd), child: const Text("Send")),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                reverse: true,
                child: Text(_notifyLogs.join("\n"), style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
              ),
            ),
          ],
        ),
      ],
    );
  }

//
//
//
  Widget _buildDoneUI() {
    const Color kGreenMain = Color(0xFF2E7D32); // 딥 그린 (신뢰감)
    const Color kGreenAccent = Color(0xFF4CAF50); // 버튼 / 포인트
    const Color kGreenSoft = Color(0x332E7D32); // 연한 배경
    final userModel = Provider.of<UserModel>(context, listen: false);

    double heightM = (userModel.userHealthData?['키'][0] ?? 0.0) / 100;
    double bmi = heightM > 0 ? weightResult / (heightM * heightM) : 0;

    return Center(
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 완료 아이콘
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: kGreenSoft),
                child: const Icon(Icons.check_rounded, color: kGreenMain, size: 56),
              ),

              const SizedBox(height: 24),
              const Text("측정이 완료되었습니다", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),

              _buildResultRow("체중", "${weightResult.toStringAsFixed(1)} kg"),
              _buildResultRow("BMI", bmi > 0 ? bmi.toStringAsFixed(1) : "-"),

              const SizedBox(height: 36),

              // 다음 단계 버튼
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGreenAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _showNextMeasureDialog,
                    child: const Text("다음 단계로", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
                  )),
            ],
          ),
        ),
      ),
    );
  }

//
//
//
  Widget _buildResultRow(String label, String value) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ]));
  }

//
//
//
  void _showNextMeasureDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.help_outline, size: 48, color: Colors.green),
                const SizedBox(height: 16),
                const Text("다음 측정을 진행할까요?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text("다시 체중을 측정하거나\n측정을 종료할 수 있습니다.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[900])),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                        child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context); // 페이지 종료 or 홈 이동
                      },
                      child: const Text("종료", style: TextStyle(fontSize: 16, color: Colors.black)),
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PageSelectFitrusMeasureType()));
                      },
                      child: const Text("예", style: TextStyle(fontSize: 16, color: Colors.black)),
                    )),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

//
//
//
//
//
//
//
//
//
//
//
//
  /// 안전한 setState
  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(fn);
    });
  }

  /// BLE 연결
  Future<void> _scanAndConnect() async {
    setState(() => _connectFailed = false);

    try {
      final device = await bluetooth.requestDevice(
        RequestOptionsBuilder(
          [RequestFilterBuilder(namePrefix: device_name)],
          optionalServices: [SERVICE_UUID],
        ),
      );

      setState(() => _device = device);

      for (int i = 0; i < 3; i++) {
        try {
          await device.gatt?.connect();
          final service = await device.gatt?.getPrimaryService(SERVICE_UUID);
          _writeChar = await service?.getCharacteristic(WRITE_UUID);
          _notifyChar = await service?.getCharacteristic(NOTIFY_UUID);

          await _notifyChar!.startNotifications();
          js_util.callMethod(_notifyChar!, 'addEventListener', [
            'characteristicvaluechanged',
            js_util.allowInterop(_onNotify), // notify function
          ]);

          safeSetState(() {
            measureState = MeasureState.measuring;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("디바이스 연결됨")),
          );
          break;
        } catch (e) {
          if (i == 2) safeSetState(() => _connectFailed = true);
        }
      }
    } catch (e) {
      safeSetState(() => _connectFailed = true);
    }
  }

//
//
//
  /// BLE Notify 처리
  void _onNotify(event) async {
    try {
      final target = js_util.getProperty(event, 'target');
      final value = js_util.getProperty(target!, 'value');

      if (value == null) return;

      final buffer = js_util.getProperty(value, 'buffer');
      final bytes = Uint8List.view(buffer);
      safeSetState(() {
        safeSetState(() => _notifyLogs.add("response${bytes}"));
      });
    } catch (e) {
      print("Notify 처리 오류: $e");
    }
  }
}
