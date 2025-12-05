import 'dart:typed_data';
import 'dart:js_util' as js_util;

import 'package:Vincere/component/custom_widget.dart';
import 'package:Vincere/component/header.dart';
import 'package:Vincere/http/webReqFastapi.dart';
import 'package:Vincere/page_ble_device/ble_utils.dart';
import 'package:Vincere/provider_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart';
import 'package:flutter_web_bluetooth/js_web_bluetooth.dart';
import 'package:provider/provider.dart';
import 'dart:html' as html;

import 'package:shared_preferences/shared_preferences.dart';

final bluetooth = FlutterWebBluetooth.instance;

//
//
//
enum MeasureState {
  connecting,
  weightMeasuring,
  impedanceMeasuring,
  done,
}

//
//
//
class PageConnectFitrusWeight extends StatefulWidget {
  const PageConnectFitrusWeight({super.key});

  @override
  State<PageConnectFitrusWeight> createState() => _PageConnectFitrusWeightState();
}

//
//
//
class _PageConnectFitrusWeightState extends State<PageConnectFitrusWeight> with SingleTickerProviderStateMixin {
  // ignore: unused_field
  BluetoothDevice? _device;
  WebBluetoothRemoteGATTCharacteristic? _writeChar;
  WebBluetoothRemoteGATTCharacteristic? _notifyChar;

  static const SERVICE_UUID = "0000ffb0-0000-1000-8000-00805f9b34fb";
  static const WRITE_UUID = "0000ffb1-0000-1000-8000-00805f9b34fb";
  static const NOTIFY_UUID = "0000ffb2-0000-1000-8000-00805f9b34fb";

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _connectFailed = false;
  bool _isConnected = false;

  MeasureState measureState = MeasureState.connecting;
  double weightResult = 0.0;
  double impedance = 0.0;
  double bfp = 0.0;

  //
  //
  //
  Future<void> _scanAndConnect() async {
    setState(() {
      _connectFailed = false;
    });

    try {
      final device = await bluetooth.requestDevice(RequestOptionsBuilder(
        [RequestFilterBuilder(namePrefix: "F_Scale_A")],
        optionalServices: [SERVICE_UUID],
      ));
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
            js_util.allowInterop((event) {
              try {
                final target = js_util.getProperty(event, 'target');
                final value = js_util.getProperty(target!, 'value');
                if (value != null) {
                  final buffer = js_util.getProperty(value, 'buffer');
                  final bytes = Uint8List.view(buffer);
                  print("Notification: ${bytesToHex(bytes)}\n");

                  double tmpWeight = parseWeightFromBytes(bytes);
                  if (tmpWeight >= 0 && tmpWeight < 220) {
                    measureState = MeasureState.weightMeasuring;
                    weightResult = tmpWeight;
                  }
                  if (bytes[2] == 0xFD) {
                    measureState = MeasureState.impedanceMeasuring;
                    impedance = parseImpedanceToMap(bytes);
                  }
                  if (bytes[2] == 0xFE) {
                    measureState = MeasureState.done;
                    bfp = calculateBfpKushner(weightResult, 168, 28, 'male', impedance);
                  }
                  setState(() {});
                }
              } catch (e) {
                print("Notification parsing error: $e\n");
              }
            }),
          ]);
          print("connect complete");
          _isConnected = true;
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('디바이스가 연결되었습니다.')),
          );
          break;
        } catch (e) {
          print("${e} connect fail.. retrying connect ");
          if (i == 2) {
            setState(() {
              _connectFailed = true;
            });
          }
        }
      }
    } catch (e) {
      print(e);
      print("connect fail");
      setState(() {
        _connectFailed = true;
      });
    }
  }

  //
  //
  //
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scanAndConnect();
    });

    // 커지고 작아지는 이미지
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
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.04),

              // ---------- 화면 분기 ----------
              if (measureState == MeasureState.connecting) _buildConnectingUI(screenHeight),

              if (measureState == MeasureState.weightMeasuring) _buildWeightUI(),

              if (measureState == MeasureState.impedanceMeasuring) _buildImpedanceUI(),

              if (measureState == MeasureState.done) _buildDoneUI(),
            ],
          ),
        ),
      ),
    );
  }

//
//
//
//
//
//
  Widget _buildConnectingUI(double screenHeight) {
    return Column(
      children: [
        Card(
          elevation: 4,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        SizedBox(height: screenHeight * 0.03),
        TextCustom(text: "체중계와 연결중입니다...", fontSize: 20),
        if (_connectFailed)
          RoundButton(
            margin: const EdgeInsets.fromLTRB(50, 36, 50, 0),
            text: "재연결",
            onPressed: _scanAndConnect,
          )
      ],
    );
  }

//
//
//
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

//
//
//
  Widget _buildImpedanceUI() {
    return Column(
      children: const [
        Text("체지방 분석중입니다...", style: TextStyle(fontSize: 22)),
        SizedBox(height: 20),
        CircularProgressIndicator(),
      ],
    );
  }

//
//
//
  Widget _buildDoneUI() {
    return Column(
      children: [
        TextCustom(text: "측정 완료!", fontSize: 26),
        SizedBox(height: 20),
        Text("체중: ${weightResult.toStringAsFixed(1)} kg", style: TextStyle(fontSize: 22)),
        Text("임피던스: ${impedance}", style: TextStyle(fontSize: 22)),
        Text("체지방률: ${bfp.toStringAsFixed(1)}%", style: TextStyle(fontSize: 22)),
        SizedBox(height: 30),
        RoundButton(
          margin: const EdgeInsets.fromLTRB(50, 36, 50, 0),
          text: "다시 측정",
          onPressed: _scanAndConnect,
        )
      ],
    );
  }
}
