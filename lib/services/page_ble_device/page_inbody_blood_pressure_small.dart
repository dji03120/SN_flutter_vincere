import 'dart:async';
import 'dart:typed_data';
import 'dart:js_util' as js_util;
import 'package:Vincere/services/page_ble_device/ble_utils.dart';
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
  measuringReady,
  measuring,
  done,
}

class PageInbodyBloodPressureSmall extends StatefulWidget {
  const PageInbodyBloodPressureSmall({super.key});

  @override
  State<PageInbodyBloodPressureSmall> createState() => _PageConnectFitrusWeightState();
}

class _PageConnectFitrusWeightState extends State<PageInbodyBloodPressureSmall> with SingleTickerProviderStateMixin {
  BluetoothDevice? _device;
  WebBluetoothRemoteGATTCharacteristic? _writeChar;
  WebBluetoothRemoteGATTCharacteristic? _notifyChar;

  static const SERVICE_UUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  static const WRITE_UUID = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";
  static const NOTIFY_UUID = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";
  static const device_name = "BP170B";

  late AnimationController _controller;

  MeasureState measureState = MeasureState.connecting;
  double weightResult = 0.0;
  bool _connectFailed = false;
  double _connectFailCount = 0;
  Timer? _statusTimer;
  double S = 0; // 최고혈압
  double D = 0; // 최저혈압
  double P = 0; // 맥박
  List<int> _resultBuffer = []; // 16+4 2번들어와서 병합필요

//
//
//
  /// Init
  @override
  void initState() {
    super.initState();
    _statusTimer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scanAndConnect());
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
                  child: SizedBox(width: double.infinity, height: 200, child: Image.asset('assets/images/bp170b.jpg', fit: BoxFit.contain)),
                ))),
        SizedBox(height: screenHeight * 0.03),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("1. 블루투스 목록에서 기기를 선택 후", style: TextStyle(fontSize: 18, color: Colors.black.withOpacity(0.7))),
          Text("   페어링을 눌러주세요", style: TextStyle(fontSize: 18, color: Colors.black.withOpacity(0.7))),
        ]),
        if (_connectFailed) RoundButton(margin: const EdgeInsets.fromLTRB(50, 36, 50, 0), text: "재연결", onPressed: _scanAndConnect)
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
                  child: SizedBox(width: double.infinity, height: 220, child: Image.asset('assets/images/bp170b_2.jpg', fit: BoxFit.contain)),
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 50),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            const SizedBox(height: 10),
            Text("측정중입니다...", style: TextStyle(fontSize: 22, color: Colors.black.withOpacity(0.7))),
            const SizedBox(height: 5),
            Text("잠시만 기다려주세요", style: TextStyle(fontSize: 20, color: Colors.black.withOpacity(0.7))),
            const SizedBox(height: 50),
            Text("ERR가 표시될 경우 장치 정지 후 ", style: TextStyle(fontSize: 16, color: Colors.black.withOpacity(0.7))),
            Text("재시작 버튼을 눌러 다시 시도해주세요", style: TextStyle(fontSize: 16, color: Colors.black.withOpacity(0.7))),
            RoundButton(
              margin: const EdgeInsets.fromLTRB(50, 16, 50, 0),
              text: "재시작",
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PageInbodyBloodPressureSmall()));
              },
            )
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
                const Text("다시 측정을 진행할까요?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PageInbodyBloodPressureSmall()));
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

  void _startStatusPolling() {
    // timer reset
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _sendCommand("status");
      // on notify -> setState
    });
  }

//
//
//
  Uint8List buildCommand(int cmd0, int cmd1, Uint8List data) {
    final bodyLen = data.length + 2;

    final body0 = ((bodyLen & 0x3F) + 0x0A) & 0xFF;
    final body1 = (((bodyLen >> 6) & 0x3F) + 0x0A) & 0xFF;
    final bytes = <int>[0x02, 0x42, body0, body1, cmd0, cmd1, ...data];

    // checksum = sum(cmd[1:]) & 0x3F + 0x0A
    final checksum = ((bytes.sublist(1).reduce((a, b) => a + b)) & 0x3F) + 0x0A;
    bytes.add(checksum & 0xFF);
    bytes.add(0x03); // ETX
    return Uint8List.fromList(bytes);
  }

  Uint8List buildDateTimeBytes(int year, int month, int day, int hour, int minute) {
    final y = (year - 2000) & 0xFF;
    return Uint8List.fromList([
      (y + 0x0A) & 0xFF,
      (month + 0x0A) & 0xFF,
      (day + 0x0A) & 0xFF,
      (hour + 0x0A) & 0xFF,
      (minute + 0x0A) & 0xFF,
    ]);
  }

  /// 선택한 명령어를 BLE 장치로 전송
  Future<void> _sendCommand(
    String cmd,
  ) async {
    final empty = Uint8List(0);
    final now = DateTime.now();

    final timeBytes = buildDateTimeBytes(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );

    final commands = <String, Uint8List>{
      "time_sync": buildCommand(0xB1, 0xB0, timeBytes),
      "status": buildCommand(0xC0, 0x00, empty),
      "log": buildCommand(0xCA, 0x00, empty),
    };

    if (!commands.containsKey(cmd)) {
      print('❌ unknown cmd');
      return;
    }

    await _writeChar?.writeValueWithoutResponse(commands[cmd]!);
    await Future.delayed(Duration(milliseconds: 100));
    safeSetState(() {});
  }

//
//
//
  /// BLE 연결
  Future<void> _scanAndConnect() async {
    setState(() => _connectFailed = false);
    if (_connectFailCount >= 3) {
      // 3회 실패시 안내화면
      showConnectionGuide(context);
    }

    try {
      final device = await bluetooth.requestDevice(
        RequestOptionsBuilder([RequestFilterBuilder(namePrefix: device_name)], optionalServices: [SERVICE_UUID]),
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
          _startStatusPolling();
          safeSetState(() {
            measureState = MeasureState.measuringReady;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("디바이스 연결됨")),
          );
          _connectFailed = false;
          break;
        } catch (e) {
          if (i == 2) safeSetState(() => _connectFailed = true);
        }
        if (_connectFailed == true) {
          //연결 실패
          _connectFailCount += 1;
        }
      }
    } catch (e) {
      safeSetState(() => _connectFailed = true);
      _connectFailCount += 1;
    }
  }

//
//
//
  Map<String, dynamic> parseBpResultFrameMap(Uint8List frame) {
    if (frame.length < 12) {
      throw Exception("BP Frame too short: ${frame.length}");
    }
    int d(int i) => frame[i] - 0x0A;
    return {
      "S": (d(11) << 8) | d(12),
      "D": d(13),
      "P": d(14),
    };
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

      if (bytes.length >= 9 && bytes[4] == 0xB0) {
        final statusByte = bytes[6];
        switch (statusByte) {
          case 0x13: // ready 02 42 0D 0A B0 00 13 26 03
            safeSetState(() => measureState = MeasureState.measuringReady);
            break;
          case 0x0E: // running 02 42 0D 0A B0 00 0E 21 03
            safeSetState(() => measureState = MeasureState.measuring);
            break;
          case 0x0F: // end 02 42 0D 0A B0 00 0F 22 03
            safeSetState(() => measureState = MeasureState.done);
            _statusTimer?.cancel();
            await _sendCommand("log");
            break;
        }
      }

      //notify end result : 02 42 18 0A BA 00 23 0C 16 17 32 0A 95 5E 6C 0A,  00 00 29 03
      // 1️⃣ 앞 프레임 버퍼 추가 (16 bytes)
      if (bytes.length == 16 && bytes[4] == 0xBA) {
        _resultBuffer.clear();
        _resultBuffer.addAll(bytes);
        return;
      }

      // 2️⃣ 뒤 프레임 (4 bytes, ETX)
      if (bytes.length == 4 && bytes.last == 0x03 && _resultBuffer.isNotEmpty) {
        _resultBuffer.addAll(bytes);
        final fullFrame = Uint8List.fromList(_resultBuffer);
        _resultBuffer.clear();
        print(fullFrame);
        Map result = parseBpResultFrameMap(fullFrame);
        print(result);
        S = double.tryParse(result['S'].toString() ?? '0') ?? 0;
        D = double.tryParse(result['D'].toString() ?? '0') ?? 0;
        P = double.tryParse(result['P'].toString() ?? '0') ?? 0;

        final userModel = Provider.of<UserModel>(context, listen: false);
        userModel.userHealthData?['혈압(고)'][0] = S;
        userModel.userHealthData?['혈압(저)'][0] = D;
        userModel.userHealthData?['심박수'][0] = P;
        await saveMeasureResult(context);
        _statusTimer?.cancel();
      }
      safeSetState(() {});
    } catch (e) {
      print("Notify 처리 오류: $e");
    }
  }
}
