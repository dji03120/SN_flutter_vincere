import 'dart:typed_data';
import 'dart:js_util' as js_util;

import 'package:Vincere/component/custom_widget.dart';
import 'package:Vincere/component/header.dart';
import 'package:Vincere/page_ble_device/ble_utils.dart';
import 'package:Vincere/provider_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart';
import 'package:flutter_web_bluetooth/js_web_bluetooth.dart';
import 'package:provider/provider.dart';
import 'dart:html' as html;

final bluetooth = FlutterWebBluetooth.instance;

class PageConnectFitrusHand extends StatefulWidget {
  const PageConnectFitrusHand({super.key});

  @override
  State<PageConnectFitrusHand> createState() => _PageConnectFitrusHandState();
}

class _PageConnectFitrusHandState extends State<PageConnectFitrusHand> with SingleTickerProviderStateMixin {
  // ignore: unused_field
  BluetoothDevice? _device;
  WebBluetoothRemoteGATTCharacteristic? _writeChar;
  WebBluetoothRemoteGATTCharacteristic? _notifyChar;

  static const SERVICE_UUID = "00000001-0000-1100-8000-00805f9b34fb";
  static const WRITE_UUID = "00000002-0000-1100-8000-00805f9b34fb";
  static const NOTIFY_UUID = "00000003-0000-1100-8000-00805f9b34fb";

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _connectFailed = false;

  //
  //
  //

  //
  //
  //
  Future<void> _scanAndConnect(WorkoutModel workoutModel) async {
    setState(() {
      _connectFailed = false;
    });

    try {
      final device = await bluetooth.requestDevice(RequestOptionsBuilder(
        [RequestFilterBuilder(namePrefix: "FitrusPlus3")],
        optionalServices: [SERVICE_UUID],
      ));
      setState(() => _device = device);

      // 연결 3회 시도 -> 재시도 버튼
      for (int i = 0; i < 3; i++) {
        try {
          // ignore: invalid_use_of_visible_for_testing_member
          await device.gatt?.connect();

          // ignore: invalid_use_of_visible_for_testing_member
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
          print("connect complete");
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('디바이스가 연결되었습니다.')),
          );
          break;
        } catch (e) {
          print("connect fail.. retrying connect ");
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
      final workoutModel = Provider.of<WorkoutModel>(context, listen: false); //
      _scanAndConnect(workoutModel);
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
        color: Color(0xFFf5f4f9),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.04),
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
                      Image.asset('assets/images/image_ble_2.png', fit: BoxFit.contain),
                      const SizedBox(height: 16),
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Image.asset('assets/images/image_ble_1.png', fit: BoxFit.contain),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.04),
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
                    TextCustom(text: "1. 장치의 전원을 켜주세요", fontSize: 20),
                    SizedBox(height: screenHeight * 0.02),
                    TextCustom(text: "2. 블루투스를 선택 하신 후에", fontSize: 20),
                    TextCustom(text: "    페어링을 눌러주세요", fontSize: 20),
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }
}
