import 'dart:typed_data';
import 'dart:js_util' as js_util;

import 'package:Vincere/utils/component/custom_widget.dart';
import 'package:Vincere/utils/component/header.dart';
import 'package:Vincere/utils/http/webReqFastapi.dart';
import 'package:Vincere/utils/page_ble_device/ble_utils.dart';
import 'package:Vincere/provider_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart';
import 'package:flutter_web_bluetooth/js_web_bluetooth.dart';
import 'package:provider/provider.dart';

final bluetooth = FlutterWebBluetooth.instance;

enum MeasureState {
  connecting,
  weightMeasuring,
  impedanceMeasuring,
  done,
}

class PageConnectFitrusWeight extends StatefulWidget {
  const PageConnectFitrusWeight({super.key});

  @override
  State<PageConnectFitrusWeight> createState() => _PageConnectFitrusWeightState();
}

class _PageConnectFitrusWeightState extends State<PageConnectFitrusWeight> with SingleTickerProviderStateMixin {
  BluetoothDevice? _device;
  WebBluetoothRemoteGATTCharacteristic? _writeChar;
  WebBluetoothRemoteGATTCharacteristic? _notifyChar;

  static const SERVICE_UUID = "0000ffb0-0000-1000-8000-00805f9b34fb";
  static const WRITE_UUID = "0000ffb1-0000-1000-8000-00805f9b34fb";
  static const NOTIFY_UUID = "0000ffb2-0000-1000-8000-00805f9b34fb";

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  MeasureState measureState = MeasureState.connecting;
  double weightResult = 0.0;
  double impedance = 0.0;
  double bfp = 0.0;

  bool _connectFailed = false;
  bool _saved = false;

  /// 안전한 setState
  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(fn);
    });
  }

  /// 데이터 저장
  Future<void> saveMeasureResult() async {
    final userModel = Provider.of<UserModel>(context, listen: false);

    try {
      ApiServiceFast apiService = ApiServiceFast();
      Map<String, dynamic> result = await apiService.insertUserHealth(
        userModel.userId,
        userModel.userHealthData ?? {},
      );

      if (result.containsKey("result")) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('건강정보가 업데이트되었습니다.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장 중 오류가 발생했습니다.')),
      );
    }
  }

  /// BLE 연결
  Future<void> _scanAndConnect() async {
    setState(() => _connectFailed = false);

    try {
      final device = await bluetooth.requestDevice(
        RequestOptionsBuilder(
          [RequestFilterBuilder(namePrefix: "F_Scale_A")],
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

          // Notify 이벤트 등록
          js_util.callMethod(_notifyChar!, 'addEventListener', [
            'characteristicvaluechanged',
            js_util.allowInterop(_onNotify),
          ]);

          safeSetState(() {});
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

  /// BLE Notify 처리
  void _onNotify(event) async {
    try {
      final target = js_util.getProperty(event, 'target');
      final value = js_util.getProperty(target!, 'value');

      if (value == null) return;

      final buffer = js_util.getProperty(value, 'buffer');
      final bytes = Uint8List.view(buffer);

      double tmpWeight = parseWeightFromBytes(bytes);

      // 체중 측정
      if (tmpWeight >= 0 && tmpWeight < 220) {
        _saved = false;
        weightResult = tmpWeight;

        safeSetState(() {
          measureState = MeasureState.weightMeasuring;
        });
      }

      // 임피던스 측정
      if (bytes.length > 2 && bytes[2] == 0xFD) {
        impedance = parseImpedanceToMap(bytes);

        safeSetState(() {
          measureState = MeasureState.impedanceMeasuring;
        });
      }

      // 측정 완료
      if (bytes.length > 2 && bytes[2] == 0xFE) {
        final userModel = Provider.of<UserModel>(context, listen: false);

        bfp = calculateBfpKushner(
          weightResult,
          userModel.userHealthData?['키'][0] ?? 0.0,
          userModel.userInfo?['age'],
          userModel.userInfo?['sex'],
          impedance,
        );

        if (weightResult > 30) {
          userModel.userHealthData?["몸무게"][0] = weightResult;
          double height = userModel.userHealthData?["키"][0] ?? 0.0 / 100;
          userModel.userHealthData?["신체질량지수(BMI)"][0] = weightResult / (height * height);
        }
        if (bfp > 0) {
          userModel.userHealthData?["체지방률"][0] = bfp;
        }

        if (!_saved) {
          await saveMeasureResult();
          _saved = true;
        }

        safeSetState(() {
          measureState = MeasureState.done;
        });
      }
    } catch (e) {
      print("Notify 처리 오류: $e");
    }
  }

  /// Init
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scanAndConnect();
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

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

  /// UI
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: const Header(),
      body: Container(
        color: const Color(0xFFf5f4f9),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.04),
              Expanded(
                child: Center(child: _buildCurrentUI(screenHeight)),
              ),
            ],
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
      case MeasureState.weightMeasuring:
        return _buildWeightGauge();
      case MeasureState.impedanceMeasuring:
        return _buildImpedanceUI();
      case MeasureState.done:
        return _buildDoneUI();
    }
  }

  Widget _buildConnectingUI(double screenHeight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Card(
          elevation: 4,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
                      // 외부 파동
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green.withOpacity(0.15)),
                        ),
                      ),

                      // 중간 파동
                      ScaleTransition(
                        scale: Tween(begin: 0.7, end: 1.0).animate(_scaleAnimation),
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green.withOpacity(0.25)),
                        ),
                      ),

                      // 아이콘(체중계)
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: Offset(0, 4))],
                        ),
                        child: Center(child: Icon(Icons.monitor_weight, color: Colors.green, size: 90)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        const Text("체중계와 연결중입니다...", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 20),
        const Text("양말을 벗고 체중계 위에 오르신 후", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const Text("페어링을 눌러주세요", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        if (_connectFailed)
          RoundButton(
            margin: const EdgeInsets.fromLTRB(50, 36, 50, 0),
            text: "재연결",
            onPressed: _scanAndConnect,
          )
      ],
    );
  }

  Widget _buildWeightGauge() {
    final userModel = Provider.of<UserModel>(context, listen: false);
    double heightM = (userModel.userHealthData?['키'][0] ?? 0.0) / 100;
    double bmi = weightResult / (heightM * heightM);
    final screenWidth = MediaQuery.of(context).size.width;

    // 도넛 진행률 (BMI 5~35 범위)
    double progress = ((bmi - 5) / 30).clamp(0.0, 1.0);

    // BMI 단계별 색상
    String bmiLabel;
    Color gaugeColor;
    if (bmi < 18.5) {
      bmiLabel = "저체중";
      gaugeColor = Colors.blue;
    } else if (bmi < 23) {
      bmiLabel = "정상";
      gaugeColor = Colors.green;
    } else if (bmi < 25) {
      bmiLabel = "과체중";
      gaugeColor = Colors.orange;
    } else {
      bmiLabel = "비만";
      gaugeColor = Colors.deepOrange;
    }
    if (heightM == 0) {
      bmiLabel = "신장 정보가 없습니다";
      gaugeColor = Colors.green;
      bmi = 0;
      progress = 0;
    }

    return Column(
      children: [
        SizedBox(height: 100),
        SizedBox(
          width: screenWidth * 0.62,
          height: screenWidth * 0.62,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: progress),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // 배경 도넛
                  SizedBox(
                    width: screenWidth * 0.62,
                    height: screenWidth * 0.62,
                    child: CircularProgressIndicator(
                      value: 1,
                      strokeWidth: 24,
                      valueColor: AlwaysStoppedAnimation(Colors.grey[300]!),
                    ),
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
                    ),
                  ),

                  // 가운데 숫자
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("${weightResult.toStringAsFixed(1)} kg", style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text("BMI ${bmi.toStringAsFixed(1)}", style: TextStyle(fontSize: 20, color: Colors.grey[600])),
                      const SizedBox(height: 6),
                      Text(bmiLabel, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: gaugeColor)),
                    ],
                  )
                ],
              );
            },
          ),
        ),
        SizedBox(height: 100),
        Text("측정중입니다.", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text("잠시만 기다려주세요...", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 40),
        Column(children: [const Text("예시 : 건강에 대한 팁....", style: TextStyle(fontSize: 20))])
      ],
    );
  }

  Widget _buildImpedanceUI() {
    return Column(
      children: const [
        Text("체지방 분석중입니다...", style: TextStyle(fontSize: 22)),
        SizedBox(height: 20),
        CircularProgressIndicator(),
      ],
    );
  }

  Widget _buildDoneUI() {
    return Column(
      children: [
        const Text("측정 완료!", style: TextStyle(fontSize: 26)),
        const SizedBox(height: 20),
        Text("체중: ${weightResult.toStringAsFixed(1)} kg", style: const TextStyle(fontSize: 22)),
        Text("임피던스: $impedance", style: const TextStyle(fontSize: 22)),
        Text("체지방률: ${bfp.toStringAsFixed(1)}%", style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 30),
        RoundButton(
          margin: const EdgeInsets.fromLTRB(50, 36, 50, 0),
          text: "다시 측정",
          onPressed: _scanAndConnect,
        )
      ],
    );
  }
}
