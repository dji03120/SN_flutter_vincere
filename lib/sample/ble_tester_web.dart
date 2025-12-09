import 'dart:typed_data';
import 'dart:js_util' as js_util;

import 'package:Vincere/component/custom_widget.dart';
import 'package:Vincere/page_ble_device/ble_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart';
import 'package:flutter_web_bluetooth/js_web_bluetooth.dart';

final bluetooth = FlutterWebBluetooth.instance;

class WebBleTest extends StatefulWidget {
  const WebBleTest({super.key});

  @override
  State<WebBleTest> createState() => _BLEPageState();
}

class _BLEPageState extends State<WebBleTest> {
  // ignore: unused_field
  BluetoothDevice? _device;
  WebBluetoothRemoteGATTCharacteristic? _writeChar;
  WebBluetoothRemoteGATTCharacteristic? _notifyChar;
  String _log = "";
  final TextEditingController _hexController = TextEditingController();

  static const SERVICE_UUID = "0000fe40-cc7a-482a-984a-7f2ed5b3e58f";
  static const WRITE_UUID = "0000fe41-8e22-4541-9d4c-21edae82ed19";
  static const NOTIFY_UUID = "0000fe42-8e22-4541-9d4c-21edae82ed19";

  // 드롭다운 항목 정의
  final Map<String, String> _commands = {
    "mode1 시작": "000B0900020000", //100hz
    "mode2 시작": "000B0900020001", //60hz
    "일시정지": "000B09000105",
    "다시시작": "000B09000106",
    "종료": "000B09000102",
    '': '',
    "강도 +": "000B09000103",
    "강도 -": "000B09000104",
    "펄스 +": "000B09000107",
    "펄스 -": "000B09000108",
    "info": "000B08010100",
    "battery": "000B08020100",
  };

  double _voltage = 50; // 0~10 V
  double _frequency = 50; // 0~10000 Hz
  double _temperature = 30; // 10~48

  String? _selectedCommand;

  @override
  void initState() {
    super.initState();
    _scanAndConnect();
  }

  Future<void> _scanAndConnect() async {
    try {
      final device = await bluetooth.requestDevice(
        RequestOptionsBuilder(
          [RequestFilterBuilder(namePrefix: "VINCERE")],
          optionalServices: [SERVICE_UUID],
        ),
      );
      setState(() => _device = device);
      await device.gatt?.connect();

      final service = await device.gatt?.getPrimaryService(SERVICE_UUID);
      _writeChar = await service?.getCharacteristic(WRITE_UUID);
      _notifyChar = await service?.getCharacteristic(NOTIFY_UUID);

      if (_notifyChar != null) {
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
                  _log += "Notification: ${bytesToHex(bytes)}\n";
                });
              }
            } catch (e) {
              setState(() => _log += "Notification parsing error: $e\n");
            }
          }),
        ]);
      }
      sendCommandElexir(_writeChar, "000C0E050100"); // 초기화 인증
      setState(() => _log += "연결 성공!\n");
    } catch (e) {
      setState(() => _log += "연결 실패: $e\n");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BLE Command Test")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _hexController,
              decoration: const InputDecoration(
                labelText: "Hex 명령어 입력",
                hintText: "예: 000B08010100",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            RoundButton(
                text: "전송",
                onPressed: () {
                  sendCommandElexir(_writeChar, _hexController.text);
                }),
            SizedBox(height: 10),
            DropdownButton<String>(
              hint: const Text("명령 선택"),
              value: _selectedCommand,
              isExpanded: true,
              items: _commands.keys.map((label) {
                return DropdownMenuItem(value: label, child: Text(label));
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCommand = value);
                if (value != null) {
                  sendCommandElexir(_writeChar, _commands[value]!);
                }
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_log, style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
