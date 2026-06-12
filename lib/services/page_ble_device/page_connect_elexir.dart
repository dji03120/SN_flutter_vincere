import 'dart:typed_data';
import 'dart:js_util' as js_util;

import 'package:Vincere/utils/component/custom_widget.dart';
import 'package:Vincere/utils/component/header.dart';
import 'package:Vincere/services/page_workout/page_select_mode.dart';
import 'package:Vincere/services/page_ble_device/ble_utils.dart';
import 'package:Vincere/provider_models.dart';

import 'package:flutter/material.dart';
import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart';
import 'package:flutter_web_bluetooth/js_web_bluetooth.dart';
import 'package:provider/provider.dart';
import 'dart:html' as html;

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

  bool _connectFailed = false;

  //
  // BLE Connect
  //
  Future<void> _scanAndConnect() async {
    setState(() => _connectFailed = false);

    try {
      final userModel = Provider.of<UserModel>(context, listen: false);
      final device = await bluetooth.requestDevice(RequestOptionsBuilder(
        [RequestFilterBuilder(namePrefix: "VINCERE")],
        optionalServices: [SERVICE_UUID],
      ));
      setState(() => _device = device);

      for (int i = 0; i < 3; i++) {
        try {
          await device.gatt?.connect();

          final service = await device.gatt?.getPrimaryService(SERVICE_UUID);
          _writeChar = await service?.getCharacteristic(WRITE_UUID);
          _notifyChar = await service?.getCharacteristic(NOTIFY_UUID);

          userModel.set_write_char(_writeChar!);
          userModel.set_notify_char(_notifyChar!);

          if (userModel.notifyChar != null) {
            await _notifyChar!.startNotifications();
            js_util.callMethod(_notifyChar!, 'addEventListener', [
              'characteristicvaluechanged',
              js_util.allowInterop((event) {
                final target = js_util.getProperty(event, 'target');
                final value = js_util.getProperty(target, 'value');
                if (value != null) {
                  final buffer = js_util.getProperty(value, 'buffer');
                  final bytes = Uint8List.view(buffer);
                  print("Notification: ${bytesToHex(bytes)}\n");
                }
              }),
            ]);
          }

          await sendCommandElexir(userModel.writeChar, "000C0E050100");
          await sendCommandElexir(userModel.writeChar, elexir_commands['pause']!);

          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('디바이스가 연결되었습니다.')));

          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SelectMode()),
          );
          break;
        } catch (e) {
          if (i == 2) setState(() => _connectFailed = true);
        }
      }
    } catch (e) {
      setState(() => _connectFailed = true);
    }
  }

  //
  // init
  //
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scanAndConnect();
    });
    // breathing animation
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  //
  // UI
  //
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: const Header(),
      backgroundColor: const Color(0xFFF5F4F9),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Column(
          children: [
            const SizedBox(height: 36),

            /// Title
            Text(
              _connectFailed ? "연결 실패" : "디바이스 연결 중...",
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),
            Text(
              _connectFailed ? "다시 시도해주세요." : "장치 전원을 켜고 가까이 두세요.",
              style: TextStyle(fontSize: 16, color: Colors.black.withOpacity(0.65)),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            /// 카드 (BLE 애니메이션)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  Image.asset('assets/images/image_ble_2.png', height: 40),
                  const SizedBox(height: 10),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Image.asset('assets/images/image_ble_1.png', height: 250),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 50),

            /// 메시지 or 버튼
            _connectFailed
                ? RoundButton(
                    text: "재연결 시도",
                    margin: const EdgeInsets.symmetric(horizontal: 60),
                    onPressed: () {
                      _scanAndConnect();
                    },
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text("1. 장치 전원을 켜주세요", style: TextStyle(fontSize: 18, color: Colors.black.withOpacity(0.7))),
                      const SizedBox(height: 10),
                      Text("2. 블루투스 목록에서 기기를 선택 후", style: TextStyle(fontSize: 18, color: Colors.black.withOpacity(0.7))),
                      Text("   페어링을 눌러주세요", style: TextStyle(fontSize: 18, color: Colors.black.withOpacity(0.7))),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
