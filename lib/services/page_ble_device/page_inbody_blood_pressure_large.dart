import 'dart:typed_data';
import 'dart:js_util' as js_util;

import 'package:Vincere/services/page_ble_device/page_fitrus_hand.dart';
import 'package:Vincere/services/page_ble_device/page_select_measure_type_fitrus.dart';
import 'package:Vincere/services/page_health/screen_my_health_info.dart';
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
  measuringReady,
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
  double S = 0; // 최고혈압
  double D = 0; // 최저혈압
  double P = 0; // 맥박

  MeasureState measureState = MeasureState.connecting;
  String result = "";
  bool _connectFailed = false;
  double _connectFailCount = 0;

//
//
//
  /// Init
  @override
  void initState() {
    super.initState();
    //WidgetsBinding.instance.addPostFrameCallback((_) => _scanAndConnect());
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
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
                SizedBox(height: 100), // 하단 여백 (선택)
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
      case MeasureState.measuringReady:
        return _buildMeasureingReady(screenHeight);
      case MeasureState.measuring:
        return _buildMeasureing(screenHeight);
      case MeasureState.done:
        return _buildDoneUI();
    }
  }

//
//
//
  Widget _buildConnectingUI(double screenHeight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
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
                  child: SizedBox(width: double.infinity, height: 200, child: Image.asset('assets/images/bpbio320.jpg', fit: BoxFit.contain)),
                ))),
        SizedBox(height: screenHeight * 0.03),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 10),
          Text("1. 블루투스 목록에서 기기를 선택 후", style: TextStyle(fontSize: 18, color: Colors.black.withOpacity(0.7))),
          Text("   페어링을 눌러주세요", style: TextStyle(fontSize: 18, color: Colors.black.withOpacity(0.7))),
        ]),
        RoundButton(
          margin: const EdgeInsets.fromLTRB(50, 36, 50, 0),
          text: "연결",
          onPressed: _scanAndConnect,
        )
      ],
    );
  }

//
//
//
  Widget _buildMeasureingReady(double screenHeight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 30),
        SizedBox(
            height: 300,
            child: Card(
                elevation: 4,
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(width: double.infinity, height: 220, child: Image.asset('assets/images/bpbio320_2.png', fit: BoxFit.contain)),
                ))),
        SizedBox(height: screenHeight * 0.03),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 10),
            Text("1. 그림과 같이 장치에 팔을 넣어주세요", style: TextStyle(fontSize: 18, color: Colors.black.withOpacity(0.7))),
            Text("2. 장치의 시작버튼을 눌러주신 후 ", style: TextStyle(fontSize: 18, color: Colors.black.withOpacity(0.7))),
            Text("   잠시 기다려주세요", style: TextStyle(fontSize: 18, color: Colors.black.withOpacity(0.7))),
          ]),
        ),
      ],
    );
  }

//
//
//
  Widget _buildMeasureing(double screenHeight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 50),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 10),
            Text("측정중입니다...", style: TextStyle(fontSize: 22, color: Colors.black.withOpacity(0.7))),
            const SizedBox(height: 5),
            Text("잠시만 기다려주세요", style: TextStyle(fontSize: 18, color: Colors.black.withOpacity(0.7))),
          ]),
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

              _buildResultRow("최고혈압", "$S mmHg"),
              _buildResultRow("최저혈압", "$D mmHg"),
              _buildResultRow("맥박수", "$P bpm"),

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
                const Text("측정 완료", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text("다시 혈압을 측정하거나\n측정을 종료할 수 있습니다.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[900])),
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
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PageInbodyBloodPressureLarge()));
                      },
                      child: const Text("다시 측정", style: TextStyle(fontSize: 16, color: Colors.black)),
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

  /// 선택한 명령어를 BLE 장치로 전송
  Future<void> _sendCommand(String cmd) async {
    if (_writeChar == null) {
      safeSetState(() {});
      return;
    }

    try {
      // 명령어 맵
      final Map<String, Uint8List> commands = {
        //"start": Uint8List.fromList([0x16, 0x16, 0x01, 0x30, 0x30, 0x02, 0x52, 0x43, 0x03, 0x11]),
        "log": Uint8List.fromList([0x16, 0x16, 0x01, 0x30, 0x30, 0x02, 0x52, 0x42, 0x03, 0x10]),
      };

      if (!commands.containsKey(cmd)) {
        safeSetState(() {});
        return;
      }

      // BLE 전송
      await _writeChar?.writeValueWithoutResponse(commands[cmd]!);
      await Future.delayed(Duration(milliseconds: 100));

      safeSetState(() {});
    } catch (e) {
      safeSetState(() {});
    }
  }

  /// BLE 연결
  Future<void> _scanAndConnect() async {
    setState(() => _connectFailed = false);
    if (_connectFailCount >= 3) {
      // 3회 실패시 안내화면
      showConnectionGuide(context);
    }

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
            measureState = MeasureState.measuringReady;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("디바이스 연결됨")),
          );
          _connectFailed = false;
          break;
        } catch (e) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (i == 2) safeSetState(() => _connectFailed = true);
        }
        if (_connectFailed == true) {
          _connectFailCount += 1;
        }
      }
    } catch (e) {
      await Future.delayed(const Duration(milliseconds: 500));
      safeSetState(() => _connectFailed = true);
      _connectFailCount += 1;
    }
  }

//
//
//
  Map<String, String> parseSDP(List<int> frame) {
    final result = <String, String>{};

    for (int i = 0; i < frame.length - 4; i++) {
      if (frame[i] == 0x1E) {
        final id = frame[i + 1];
        if (id == 'S'.codeUnitAt(0) || id == 'D'.codeUnitAt(0) || id == 'P'.codeUnitAt(0)) {
          final values = frame.sublist(i + 2, i + 5);
          final parsed = values.map((e) => e == 0 ? '0' : String.fromCharCode(e)).join();
          result[String.fromCharCode(id)] = parsed;
        }
      }
    }
    return result;
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
      if (measureState == MeasureState.measuringReady) {
        measureState = MeasureState.measuring;
      } else if (measureState == MeasureState.measuring) {
        Map<String, String> sdp = parseSDP(bytes);
        S = double.tryParse(sdp['S'] ?? '0') ?? 0; // 최고혈압
        D = double.tryParse(sdp['D'] ?? '0') ?? 0; // 최저혈압
        P = double.tryParse(sdp['P'] ?? '0') ?? 0; // 맥박

        final userModel = Provider.of<UserModel>(context, listen: false);
        userModel.userHealthData?['혈압(고)'][0] = S;
        userModel.userHealthData?['혈압(저)'][0] = D;
        userModel.userHealthData?['심박수'][0] = P;
        await saveMeasureResult(context);

        measureState = MeasureState.done;
      }
      safeSetState(() {});
    } catch (e) {
      print("Notify 처리 오류: $e");
    }
  }
}
