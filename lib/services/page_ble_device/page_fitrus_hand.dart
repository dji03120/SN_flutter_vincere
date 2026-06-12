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
  List<int> ppgList = []; //green
  double bpm = 0.0;
  String _notifyStr = '';
  DateTime lastUpdate = DateTime.now();
  double _connectFailCount = 0;

  //
  //
  //
  //
  // notify setState 동기화
  void safeSetState(VoidCallback fn, {int ms = 50}) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // throttle
      if (DateTime.now().difference(lastUpdate).inMilliseconds > ms) {
        if (mounted) setState(fn);
      }
    });
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
          ble_disconnect();
          safeSetState(() => measureState = MeasureState.requestAiAnalysis);
        }
      }

      //
      //
      if (widget.measureType == MeasureType.spo2) {
        List<int> ppgData = parseRawData(bytes);
        ppgList.addAll(ppgData);

        if (ppgList.length % (6 * 100) == 0) {
          progress = (ppgList.length / 18000 * 100).toInt();
          safeSetState(() {});
          if (ppgList.length >= 6000) {
            // 10초 이후부터는 1초마다 api 요청
            _requestOSDPPG(ppgList);
          }
        }
        if (ppgList.length > (6 * 3000)) {
          sendCommandFitrus(_writeChar, fitrus_hand_commands['spo2_stop'] ?? '');
          ble_disconnect();
          safeSetState(() => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ScreenHealthInfo())));
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // 기본값이 min이어서 공간이 남음
              children: [
                SizedBox(height: screenHeight * 0.04),

                // Expanded 제거
                Center(
                  child: _buildCurrentUI(screenHeight),
                ),

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
                    if (widget.measureType == MeasureType.bfp) Image.asset('assets/images/fitrus_bfp_grip.png'),
                    if (widget.measureType == MeasureType.spo2) Image.asset('assets/images/fitrus_ppg_grip.png'),
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
              SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: progress / 100,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  )),
              Text(
                "$progress%",
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
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
      future: _requestOSDBFP(),
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ScreenHealthInfo()));
            }
          });
          return Text("AI 서버 분석 오류 : 관리자에게 문의하여 주세요.");
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
  /// BLE 연결
  Future<void> _scanAndConnect() async {
    final userModel = Provider.of<UserModel>(context, listen: false);
    safeSetState(() {
      _connectFailed = false;
      measureState = MeasureState.connecting;
    });

    if (_connectFailCount >= 3) {
      showConnectionGuide(context);
    }

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
          await device.gatt?.connect();
          final service = await device.gatt?.getPrimaryService(SERVICE_UUID);
          _writeChar = await service?.getCharacteristic(WRITE_UUID);
          _notifyChar = await service?.getCharacteristic(NOTIFY_UUID);
          userModel.set_notify_char(_notifyChar!);
          userModel.set_write_char(_writeChar!);

          await _notifyChar!.startNotifications();
          js_util.callMethod(_notifyChar!, 'addEventListener', ['characteristicvaluechanged', js_util.allowInterop(_onNotify)]);
          _connectFailCount = 0;
          safeSetState(() => measureState = MeasureState.waitUserReady);
          break;
        } catch (e) {
          if (i == 2) safeSetState(() => _connectFailed = true);
        }
      }
      if (measureState != MeasureState.waitUserReady) {
        _connectFailCount += 1;
        await Future.delayed(const Duration(milliseconds: 500));
        safeSetState(() => _connectFailed = true);
      }
    } catch (e) {
      _connectFailCount += 1;
      await Future.delayed(const Duration(milliseconds: 500));
      safeSetState(() => _connectFailed = true);
    }
  }

  Future<void> ble_disconnect() async {
    if (_device != null) {
      try {
        _device!.gatt?.disconnect();
      } catch (e) {
        print('BLE disconnect failed: $e');
      } finally {
        safeSetState(() {
          _device = null;
          _writeChar = null;
          _notifyChar = null;
        });
      }
    }
  }

  //
  //
  //
  //
  Future<Map<String, dynamic>> _requestOSDBFP() async {
    ApiServiceFast apiService = ApiServiceFast();
    UserModel userModel = Provider.of<UserModel>(context, listen: false);
    Map<String, dynamic> response = await apiService.requestOSDBFP(userModel, impedance);

    try {
      userModel.userHealthData?['체지방률'][0] = response['result']['bfp'];
      userModel.userHealthData?['체지방량'][0] = response['result']['bfm'];
      userModel.userHealthData?['기초대사량'][0] = response['result']['bmr'];
      userModel.userHealthData?['근육'][0] = response['result']['smm'];
      userModel.userHealthData?['세포내 수분(ICW)'][0] = response['result']['icw'];
      userModel.userHealthData?['세포외 수분(ECW)'][0] = response['result']['ecw'];
      userModel.userHealthData?['단백질량'][0] = response['result']['protein'];
      userModel.userHealthData?['무기질량'][0] = response['result']['mineral'];
      await saveMeasureResult(context);
    } catch (_) {}

    return response;
  }

  //
  //
  //
  //
  Future<void> _requestOSDPPG(List<int> ppgList) async {
    ApiServiceFast apiService = ApiServiceFast();
    UserModel userModel = Provider.of<UserModel>(context, listen: false);
    Map<String, dynamic> response = await apiService.requestOSDPPG(userModel, ppgList);
    userModel.userHealthData?['산소포화도'][0] = response['result']['spo2'];
    userModel.userHealthData?['스트레스지수'][0] = response['result']['value'];
    userModel.userHealthData?['심박수'][0] = response['result']['hr'];
    userModel.userHealthData?['심박변이도'][0] = response['result']['hrv'];
    safeSetState(() => _notifyStr = response.toString());
    await saveMeasureResult(context);
  }

  void _onAiAnalyzeFinished(Map result) {
    if (measureState == MeasureState.done) return;
    OSDResult = result;
    measureState = MeasureState.done;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ScreenHealthInfo()));
      }
    });
  }
}
