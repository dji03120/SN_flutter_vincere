import 'dart:typed_data';
import 'dart:js_util' as js_util;

import 'package:Vincere/component/custom_widget.dart';
import 'package:Vincere/component/header.dart';
import 'package:Vincere/http/webReqFastapi.dart';
import 'package:Vincere/page_ble_device/ble_utils.dart';
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

        bfp = calculateBfpKushner(weightResult, 168, 28, "male", impedance);

        userModel.userHealthData?["몸무게"][0] = weightResult;
        userModel.userHealthData?["체지방률"][0] = bfp;

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
        return _buildWeightUI();
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
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Image.asset('assets/images/image_ble_2.png'),
                const SizedBox(height: 16),
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Image.asset('assets/images/image_ble_1.png'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        const Text("체중계와 연결중입니다...", style: TextStyle(fontSize: 20)),
      ],
    );
  }

  Widget _buildWeightUI() {
    return Column(
      children: [
        const Text("체중 측정중...", style: TextStyle(fontSize: 22)),
        const SizedBox(height: 20),
        Text(
          "${weightResult.toStringAsFixed(1)} kg",
          style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
        ),
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
