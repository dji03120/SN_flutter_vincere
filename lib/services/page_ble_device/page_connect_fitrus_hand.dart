import 'dart:math';
import 'dart:typed_data';
import 'dart:js_util' as js_util;

import 'package:Vincere/utils/component/custom_widget.dart';
import 'package:Vincere/utils/component/header.dart';
import 'package:Vincere/utils/http/webReqFastapi.dart';
import 'package:Vincere/services/page_ble_device/ble_utils.dart';
import 'package:Vincere/services/page_health/screen_my_health_info.dart';
import 'package:Vincere/provider_models.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart';
import 'package:flutter_web_bluetooth/js_web_bluetooth.dart';
import 'package:provider/provider.dart';

enum MeasureState {
  connecting,
  waitUserReady,
  impedanceMeasuring,
  requestAiAnalysis,
  done,
}

enum MeasureType {
  bfp,
  spo2,
  stress,
  temp,
}

final bluetooth = FlutterWebBluetooth.instance;

class PageConnectFitrusHand extends StatefulWidget {
  final MeasureType measureType;
  const PageConnectFitrusHand({
    super.key,
    required this.measureType,
  });

  @override
  State<PageConnectFitrusHand> createState() => _PageConnectFitrusHandState();
}

class _PageConnectFitrusHandState extends State<PageConnectFitrusHand> with SingleTickerProviderStateMixin {
  BluetoothDevice? _device;
  WebBluetoothRemoteGATTCharacteristic? _writeChar;
  WebBluetoothRemoteGATTCharacteristic? _notifyChar;

  static const SERVICE_UUID = "00000001-0000-1100-8000-00805f9b34fb";
  static const WRITE_UUID = "00000002-0000-1100-8000-00805f9b34fb";
  static const NOTIFY_UUID = "00000003-0000-1100-8000-00805f9b34fb";

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  Map OSDResult = {};
  bool _connectFailed = false;
  MeasureState measureState = MeasureState.connecting;
  int progress = 0;

  double stress = 0.0;
  double impedance = 0.0;
  List<double> ppgGrAc = List.generate(100, (index) => 0.0); //green
  List<double> ppgIrAc = List.generate(100, (index) => 0.0);
  double ppgGrIir = 0.5;
  double ppgIrIir = 0.5;
  double bpm = 0.0;
  String _notifyStr = '';

  //
  //
  //
  //
  // notify setState 동기화
  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(fn);
    });
  }

  //
  //
  //
  //
  /// BLE 연결
  Future<void> _scanAndConnect() async {
    safeSetState(() {
      _connectFailed = false;
      measureState = MeasureState.connecting;
    });

    try {
      final device = await bluetooth.requestDevice(
        RequestOptionsBuilder(
          [RequestFilterBuilder(namePrefix: "FitrusPlus3")],
          optionalServices: [SERVICE_UUID],
        ),
      );
      safeSetState(() => _device = device);

      for (int i = 0; i < 3; i++) {
        try {
          await Future.delayed(const Duration(milliseconds: 1));
          await device.gatt?.connect();

          final service = await device.gatt?.getPrimaryService(SERVICE_UUID);
          _writeChar = await service?.getCharacteristic(WRITE_UUID);
          _notifyChar = await service?.getCharacteristic(NOTIFY_UUID);

          await _notifyChar!.startNotifications();
          js_util.callMethod(_notifyChar!, 'addEventListener', ['characteristicvaluechanged', js_util.allowInterop(_onNotify)]);
          safeSetState(() => measureState = MeasureState.waitUserReady);
          break;
        } catch (e) {
          if (i == 2) safeSetState(() => _connectFailed = true);
        }
      }
      if (measureState != MeasureState.waitUserReady) {
        safeSetState(() => _connectFailed = true);
      }
    } catch (e) {
      safeSetState(() => _connectFailed = true);
    }
  }

  //
  //
  //
  //
  /// BLE Notify 이벤트 처리
  void _onNotify(event) {
    try {
      final target = js_util.getProperty(event, 'target');
      final value = js_util.getProperty(target!, 'value');
      if (value == null) return;

      final buffer = js_util.getProperty(value, 'buffer');
      final bytes = Uint8List.view(buffer);
      String notifyMsg = bytesToUtf8String(bytes).replaceAll('\r', '').replaceAll('\n', '').trim();

      if (widget.measureType == MeasureType.bfp) {
        final progMatch = RegExp(r'BFP:Prog=(\d+)').firstMatch(notifyMsg);
        if (progMatch != null) {
          progress = int.parse(progMatch.group(1)!);
          safeSetState(() {});
        }
        final endRawMatch = RegExp(r'BFP:End\.Raw=([0-9.]+)').firstMatch(notifyMsg);
        if (endRawMatch != null) {
          sendCommandFitrus(_writeChar, fitrus_hand_commands['bfp_stop'] ?? '');
          impedance = double.parse(endRawMatch.group(1)!);
          safeSetState(() => measureState = MeasureState.requestAiAnalysis);
        }
      }

      if (widget.measureType == MeasureType.spo2) {
        //bpm 측정
        final ppgData = parseRawData(bytes);
        double gr = (ppgData[0] + ppgData[2] + ppgData[4]) / 3; // green 3 channal
        double ir = (ppgData[1] + ppgData[3] + ppgData[5]) / 3; // ir 3 channal
        final dGr = gr - ppgGrIir;
        final dIr = ir - ppgIrIir;
        ppgGrIir = ppgGrIir * 0.99 + gr * 0.01;
        ppgIrIir = ppgIrIir * 0.99 + ir * 0.01;
        ppgGrAc.add(dGr); // dGr
        ppgIrAc.add(dIr); // dIr

        // 100hz로 가정함
        int peakCount = 0;
        double threshold = 0.2; // 신호 세기에 맞춰 조정
        int minInterval = 20; // 최대 bpm 300 (bpm limit and noise peak filter)
        int lastPeak = -minInterval;
        int bpm = peakCount * 60; // 1sec * 60

        if (ppgGrAc.length > 100) {
          // min/max 계산
          final recent = ppgGrAc.sublist(ppgGrAc.length - 100);
          double minV = 0, maxV = 0, alpha = 0.03;
          for (var v in recent) {
            minV = minV * (1 - alpha) + min(v.abs(), minV) * alpha;
            maxV = maxV * (1 - alpha) + max(v.abs(), maxV) * alpha;
          }

          for (int i = minInterval; i < recent.length - minInterval; i++) {
            final v1 = (recent[i - minInterval].abs() - minV) / (maxV - minV);
            final v2 = (recent[i + 0].abs() - minV) / (maxV - minV);
            final v3 = (recent[i + minInterval].abs() - minV) / (maxV - minV);

            if (v2 > v1 && v2 > v3 && v2 > threshold && i > lastPeak + minInterval) {
              bpm = ((100 / (i - lastPeak)) * 60 / 2).toInt(); // 1sec * 60
              peakCount += 1;
              lastPeak = i;
              safeSetState(() => _notifyStr = "${dGr}_\n${v2}_\n${bpm}_\n${ppgGrAc.length}");
            }
          }
          safeSetState(() => _notifyStr = "${dGr}_\n${bpm}_\n${ppgGrAc.length}");
        } else {
          safeSetState(() => _notifyStr = "${dGr}_\n${dIr}_\n${bpm}_\n${ppgData}_\n${ppgGrAc.length}");
        }
        if (ppgGrAc.length > 3000) {
          sendCommandFitrus(_writeChar, fitrus_hand_commands['spo2_stop'] ?? '');
          safeSetState(() => measureState = MeasureState.done);
        }
      }
    } catch (e) {
      print("Notify parsing error: $e");
    }
  }

  //
  //
  //
  //
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scanAndConnect());

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  //
  //
  //
  //
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  //
  //
  //
  //
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
        appBar: const Header(),
        body: Container(
            color: const Color(0xFFf5f4f9),
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(children: [
                  SizedBox(height: screenHeight * 0.04),
                  Expanded(child: Center(child: _buildCurrentUI(screenHeight))),
                ]))));
  }

  //
  //
  //
  //
  Widget _buildCurrentUI(double screenHeight) {
    switch (measureState) {
      case MeasureState.connecting:
        return _buildConnectingUI(screenHeight);
      case MeasureState.waitUserReady:
        return _buildUserReadyUI();
      case MeasureState.impedanceMeasuring:
        return _buildImpedanceUI();
      case MeasureState.requestAiAnalysis:
        return _buildRequestAIAnalysis();
      case MeasureState.done:
        return const SizedBox();
    }
  }

  //
  //
  //
  //
  Widget _buildConnectingUI(double screenHeight) {
    return Column(
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
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Image.asset('assets/images/fitrus_start.png'),
                  ])),
            )),
        SizedBox(height: screenHeight * 0.03),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("1. 장치 전원을 켜주세요", style: TextStyle(fontSize: 18, color: Colors.black.withOpacity(0.7))),
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
  //
  // --------------------------------------------------------
  Widget _buildUserReadyUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 300,
            child: Card(
                elevation: 4,
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Image.asset('assets/images/grip_fitrus.png'),
                  ]),
                )),
          ),
          const SizedBox(height: 20),
          Text("1. 그림과 같이 장치를 잡아주세요.", style: TextStyle(fontSize: 18, color: Colors.black.withOpacity(0.7))),
          const SizedBox(height: 10),
          Text("2. 준비가 되셨으면, 아래 버튼을 눌러", style: TextStyle(fontSize: 18, color: Colors.black.withOpacity(0.7))),
          Text("   측정을 시작해주세요", style: TextStyle(fontSize: 18, color: Colors.black.withOpacity(0.7))),
          const SizedBox(height: 40),
          RoundButton(
            text: "측정 시작",
            margin: const EdgeInsets.fromLTRB(50, 0, 50, 0),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("3초 후 측정이 시작됩니다.")));
              await Future.delayed(const Duration(seconds: 3));
              if (widget.measureType == MeasureType.bfp) await sendCommandFitrus(_writeChar, fitrus_hand_commands['bfp_start'] ?? '');
              if (widget.measureType == MeasureType.spo2) await sendCommandFitrus(_writeChar, fitrus_hand_commands['spo2_start'] ?? '');
              if (widget.measureType == MeasureType.stress) await sendCommandFitrus(_writeChar, fitrus_hand_commands['stress_start'] ?? '');

              setState(() {
                measureState = MeasureState.impedanceMeasuring;
              });
            },
          ),
        ],
      ),
    );
  }

  //
  //
  //
  //
  // --------------------------------------------------------
  Widget _buildImpedanceUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          Text("측정중입니다.", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text("잠시만 기다려주세요...", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          Stack(
            alignment: Alignment.center,
            children: [
              if (widget.measureType == MeasureType.bfp) ...[
                SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: progress / 100,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                    )),
              ],
              if (widget.measureType == MeasureType.spo2) ...[
                Container(
                  height: 200,
                  width: 220,
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(100, (i) => FlSpot(i.toDouble(), ppgGrAc[ppgGrAc.length - 100 + i])),
                          isCurved: true,
                          color: Colors.green,
                        )
                      ],
                      titlesData: FlTitlesData(show: false),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ],
              Text(
                "$progress%",
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              )
            ],
          ),
          const SizedBox(height: 30),
          Column(children: [
            Text("예시 : 건강에 대한 팁", style: TextStyle(fontSize: 20)),
            Text("$_notifyStr", style: TextStyle(fontSize: 20)),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  //
  //
  //
  //
  Widget _buildRequestAIAnalysis() {
    return FutureBuilder<Map>(
      future: _requestAi(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("AI 분석중입니다...", style: TextStyle(fontSize: 22)),
              SizedBox(height: 20),
              CircularProgressIndicator(),
            ],
          );
        }

        if (snapshot.hasError) {
          return Text("AI 분석 실패: ${snapshot.error}");
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _onAiAnalyzeFinished(snapshot.data!);
        });

        return const SizedBox();
      },
    );
  }

  //
  //
  //
  //
  Future<Map<String, dynamic>> _requestAi() async {
    ApiServiceFast apiService = ApiServiceFast();
    UserModel userModel = Provider.of<UserModel>(context, listen: false);
    Map<String, dynamic> response = await apiService.requestOSDResult(userModel, impedance);

    try {
      userModel.userHealthData?['체지방률'][0] = response['result']['bfp'];
      userModel.userHealthData?['체지방량'][0] = response['result']['bfm'];
      userModel.userHealthData?['기초대사량'][0] = response['result']['bmr'];
      userModel.userHealthData?['근육'][0] = response['result']['smm'];
      userModel.userHealthData?['세포내 수분(ICW)'][0] = response['result']['icw'];
      userModel.userHealthData?['세포외 수분(ECW)'][0] = response['result']['ecw'];
      userModel.userHealthData?['단백질량'][0] = response['result']['protein'];
      userModel.userHealthData?['무기질량'][0] = response['result']['mineral'];
      await saveMeasureResult();
    } catch (_) {}

    return response;
  }

  void _onAiAnalyzeFinished(Map result) {
    if (measureState == MeasureState.done) return;
    OSDResult = result;
    measureState = MeasureState.done;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ScreenHealthInfo()));
      }
    });
  }

  //
  //
  //
  //
  Future<void> saveMeasureResult() async {
    final userModel = Provider.of<UserModel>(context, listen: false);
    try {
      // API 호출
      ApiServiceFast apiService = ApiServiceFast();
      Map<String, dynamic> result = await apiService.insertUserHealth(userModel.userId, userModel.userHealthData ?? {});
      // 결과 처리
      if (result.containsKey("result")) {
        await userModel.set_user_info();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('건강정보가 성공적으로 업데이트되었습니다.'), duration: Duration(seconds: 2), backgroundColor: Colors.green),
        );
      }
      if (result.containsKey("error")) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('업데이트 중 오류가 발생했습니다.'), duration: Duration(seconds: 2), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print("저장 중 오류 발생: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알 수 없는 오류가 발생했습니다.'), duration: Duration(seconds: 2), backgroundColor: Colors.red),
      );
    }
  }
}
