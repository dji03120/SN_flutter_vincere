import 'dart:typed_data';
import 'dart:js_util' as js_util;

import 'package:Vincere/component/custom_button.dart';
import 'package:Vincere/component/custom_text.dart';
import 'package:Vincere/component/header.dart';
import 'package:Vincere/page_workout/page_select_muscle.dart';
import 'package:Vincere/page_ble_device/ble_utils.dart';
import 'package:Vincere/provider_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart';
import 'package:flutter_web_bluetooth/js_web_bluetooth.dart';
import 'package:provider/provider.dart';

final bluetooth = FlutterWebBluetooth.instance;

class PageConnectBle extends StatefulWidget {
  const PageConnectBle({super.key});

  @override
  State<PageConnectBle> createState() => _BLEPageState();
}

class _BLEPageState extends State<PageConnectBle> with SingleTickerProviderStateMixin {
  BluetoothDevice? _device;
  WebBluetoothRemoteGATTCharacteristic? _writeChar;
  WebBluetoothRemoteGATTCharacteristic? _notifyChar;
  static const SERVICE_UUID = "0000fe40-cc7a-482a-984a-7f2ed5b3e58f";
  static const WRITE_UUID = "0000fe41-8e22-4541-9d4c-21edae82ed19";
  static const NOTIFY_UUID = "0000fe42-8e22-4541-9d4c-21edae82ed19";

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  bool _isConnecting = false;
  bool _connectFailed = false;

  Future<void> _scanAndConnect(WorkoutModel workoutModel) async {
    setState(() {
      _isConnecting = true;
      _connectFailed = false;
    });

    try {
      final device = await bluetooth.requestDevice(
        RequestOptionsBuilder(
          [RequestFilterBuilder(namePrefix: "VINCERE")],
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
          workoutModel.set_write_char(_writeChar!);
          workoutModel.set_notify_char(_notifyChar!);

          if (workoutModel.notifyChar != null) {
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
                    setState(() {
                      print("Notification: ${bytesToHex(bytes)}\n");
                    });
                  }
                } catch (e) {
                  setState(() {
                    print("Notification parsing error: $e\n");
                  });
                }
              }),
            ]);
          }
          // get calendar device setting command
          await sendCommand(workoutModel.writeChar, "000C0E050100");
          print("connect complete");
          setState(() => _isConnecting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('디바이스가 연결되었습니다.')),
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SelectMuscle()),
          );
          break;
        } catch (e) {
          print("connect fail.. retrying connect ");
          if (i == 2) {
            setState(() {
              _connectFailed = true;
              _isConnecting = false;
            });
          }
        }
      }
    } catch (e) {
      print("connect fail");
      setState(() {
        _connectFailed = true;
        _isConnecting = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workoutModel = Provider.of<WorkoutModel>(context, listen: false); // 상태 접근
      // 모델 초기화나 데이터 세팅
      _scanAndConnect(workoutModel);
    });

    // 애니메이션 컨트롤러 초기화
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true); // 반복 + 뒤로 되돌리기

    _scaleAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: const Header(),
      body: Container(
        color: Color(0xFFf5f4f9),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.08),
              Card(
                elevation: 4,
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                color: const Color(0xFFFFFFFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/images/image_ble_2.png',
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      ScaleTransition(
                          scale: _scaleAnimation,
                          child: Image.asset(
                            'assets/images/image_ble_1.png',
                            fit: BoxFit.contain,
                          )),
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.08),
              if (_connectFailed == true)
                RoundButton(
                  margin: EdgeInsets.fromLTRB(50, 36, 50, 0),
                  text: "재연결 시도",
                  onPressed: () {
                    final workoutModel = Provider.of<WorkoutModel>(context, listen: false);
                    _scanAndConnect(workoutModel);
                  },
                ),
              if (_connectFailed == false)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextLarge(text: "1. 장치의 전원을 켜주세요"),
                    SizedBox(height: screenHeight * 0.02),
                    TextLarge(text: "2. 블루투스를 선택 하신 후에"),
                    TextLarge(text: "     페어링을 눌러주세요"),
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }
}
