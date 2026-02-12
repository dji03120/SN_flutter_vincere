import 'dart:async';
import 'dart:typed_data';
import 'dart:js_util' as js_util;

import 'package:Vincere/services/page_health/screen_my_health_info.dart';
import 'package:Vincere/utils/component/custom_widget.dart';
import 'package:Vincere/utils/component/header.dart';
import 'package:Vincere/utils/http/webReqFastapi.dart';
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

class PageInbodyHandPressure extends StatefulWidget {
  const PageInbodyHandPressure({super.key});

  @override
  State<PageInbodyHandPressure> createState() => _PageConnectFitrusWeightState();
}

class _PageConnectFitrusWeightState extends State<PageInbodyHandPressure> with SingleTickerProviderStateMixin {
  BluetoothDevice? _device;
  WebBluetoothRemoteGATTCharacteristic? _writeChar;
  WebBluetoothRemoteGATTCharacteristic? _notifyChar;

  static const SERVICE_UUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  static const WRITE_UUID = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";
  static const NOTIFY_UUID = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";

  MeasureState measureState = MeasureState.connecting;
  double pressureResult = 0; //kg
  bool _connectFailed = false;
  Timer? _measureTimer;
  Timer? _stopTimer;

  List<String> _notifyLogs = []; // Notify 로그

//
//
//
  /// Init
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scanAndConnect());
  }

  @override
  void dispose() {
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
        SizedBox(height: 50),
        SizedBox(
            height: 300,
            child: Card(
                elevation: 4,
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(width: double.infinity, height: 200, child: Image.asset('assets/images/hand_press.png', fit: BoxFit.contain)),
                ))),
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

//
//
//
  Widget _buildMeasureing() {
    final userModel = Provider.of<UserModel>(context, listen: false);
    List<dynamic> grade_range = userModel.userHealthData?['악력'][6] ?? [10, 20, 30, 40];
    final screenWidth = MediaQuery.of(context).size.width;
    double progress = (pressureResult / grade_range[0] * 0.8).clamp(0.0, 1.0);
    String label;
    Color gaugeColor;
    if (pressureResult > grade_range[0]) {
      label = "매우높음";
      gaugeColor = Colors.blue;
    } else if (pressureResult > grade_range[1]) {
      label = "높음";
      gaugeColor = Colors.green;
    } else if (pressureResult > grade_range[2]) {
      label = "보통";
      gaugeColor = Colors.green;
    } else if (pressureResult > grade_range[3]) {
      label = "낮음";
      gaugeColor = Colors.yellow;
    } else if (pressureResult > 5) {
      label = "매우낮음";
      gaugeColor = Colors.red;
    } else {
      label = "--";
      gaugeColor = Colors.green;
    }

    return Column(
      children: [
        SizedBox(height: 50),
        SizedBox(
          width: screenWidth * 0.62,
          height: screenWidth * 0.62,
          child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, _) {
                return Stack(alignment: Alignment.center, children: [
                  // 배경 도넛
                  SizedBox(
                    width: screenWidth * 0.62,
                    height: screenWidth * 0.62,
                    child: CircularProgressIndicator(value: 1, strokeWidth: 24, valueColor: AlwaysStoppedAnimation(Colors.grey[300]!)),
                  ),

                  // 진행 도넛
                  SizedBox(
                      width: screenWidth * 0.62,
                      height: screenWidth * 0.62,
                      child: CircularProgressIndicator(
                        value: animatedValue,
                        strokeWidth: 24,
                        valueColor: AlwaysStoppedAnimation(gaugeColor),
                        backgroundColor: Colors.transparent,
                      )),

                  // 가운데 숫자
                  Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text("${pressureResult.toStringAsFixed(1)} kg", style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text("Pressure ${pressureResult.toStringAsFixed(1)}kg", style: TextStyle(fontSize: 20, color: Colors.grey[600])),
                    const SizedBox(height: 6),
                    Text(label, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: gaugeColor)),
                  ])
                ]);
              }),
        ),
        SizedBox(height: 50),
        Text("측정중입니다.", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text("잠시만 기다려주세요...", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 40),
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

              _buildResultRow("측정결과", "${pressureResult.toStringAsFixed(1)} kg"),
              //_buildResultRow("등급", pressureResult > 0 ? pressureResult.toStringAsFixed(1) : "-"),

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
                const Text("다시 악력 측정을 진행할까요?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text("다시 악력을 측정하거나\n측정을 종료할 수 있습니다.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[900])),
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
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ScreenHealthInfo()));
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
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PageInbodyHandPressure()));
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
  /// 안전한 setState
  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(fn);
    });
  }

  void timerSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

//
//
//
  void _startMeasurementLoop() {
    // timer reset
    _measureTimer?.cancel();
    _stopTimer?.cancel();
    _measureTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _sendCommand("result");
      timerSetState(() {});
      // on notify -> setState
    });

    _stopTimer = Timer(const Duration(seconds: 10), () async {
      timerSetState(() {
        measureState = MeasureState.done;
        _measureTimer?.cancel();
      });

      // save data
      final userModel = Provider.of<UserModel>(context, listen: false);
      userModel.userHealthData?['악력'][0] = pressureResult;
      await saveMeasureResult(context);

      try {
        await _notifyChar?.stopNotifications();
      } catch (_) {}
      _notifyLogs.insert(0, "⏹️ 측정 종료 (5초)");
    });
  }

//
//
//
  Future<void> _sendCommand(String cmd) async {
    if (_writeChar == null) {
      safeSetState(() => _notifyLogs.add("❌ write characteristic이 없습니다."));
      return;
    }
    try {
      // 설정: kg 단위, buzzer on
      int unit = 0x30; // kg -> 0x30, lb -> 0x31
      int buzzer = 0x31; // true -> 0x31, false -> 0x30

      // 명령어 맵
      final Map<String, Uint8List> commands = {
        "status": Uint8List.fromList([0x02, 0x60, 0x03]),
        "setup": Uint8List.fromList([0x02, 0x61, unit, 0x1B, buzzer, 0x1B, 0x03]),
        "result": Uint8List.fromList([0x02, 0x62, 0x03]),
        "reset": Uint8List.fromList([0x02, 0x63, 0x03]),
        "poweroff": Uint8List.fromList([0x02, 0x70, 0x03]),
      };
      if (!commands.containsKey(cmd)) {
        safeSetState(() => _notifyLogs.add("❌ 알 수 없는 명령어: $cmd"));
        return;
      }
      await _writeChar?.writeValueWithoutResponse(commands[cmd]!);
      safeSetState(() => _notifyLogs.insert(0, "✅ Sent command: $cmd"));
    } catch (e) {
      safeSetState(() => _notifyLogs.insert(0, "❌ 명령 전송 오류: $cmd, 에러: $e"));
    }
  }

//
//
//
  /// BLE 연결
  Future<void> _scanAndConnect() async {
    setState(() => _connectFailed = false);

    try {
      final device = await bluetooth.requestDevice(
        RequestOptionsBuilder(
          [RequestFilterBuilder(namePrefix: "InBodyHGS")],
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
          await _sendCommand("reset");
          _startMeasurementLoop();
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
      final escIndices = <int>[];
      for (int i = 0; i < bytes.length; i++) {
        if (bytes[i] == 0x1B) escIndices.add(i);
      }
      if (escIndices.length < 2) return;
      final gripBytes = bytes.sublist(
        escIndices[0] + 1,
        escIndices[1],
      );

      final gripStr = String.fromCharCodes(gripBytes); // "348"
      final gripValue = double.parse(gripStr) / 10.0;
      pressureResult = gripValue;
      safeSetState(() {});
    } catch (e) {
      print("Notify 처리 오류: $e");
    }
  }
}
