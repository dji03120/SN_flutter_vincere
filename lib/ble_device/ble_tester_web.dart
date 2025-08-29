import 'dart:typed_data';
import 'dart:js_util' as js_util;

import 'package:flutter/material.dart';
import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart';
import 'package:flutter_web_bluetooth/js_web_bluetooth.dart';

final bluetooth = FlutterWebBluetooth.instance;

class PageConnectBLE extends StatefulWidget {
  const PageConnectBLE({super.key});

  @override
  State<PageConnectBLE> createState() => _BLEPageState();
}

class _BLEPageState extends State<PageConnectBLE> {
  BluetoothDevice? _device;
  WebBluetoothRemoteGATTCharacteristic? _writeChar;
  WebBluetoothRemoteGATTCharacteristic? _notifyChar;
  String _log = "";
  final TextEditingController _hexController = TextEditingController();

  static const SERVICE_UUID = "0000fe40-cc7a-482a-984a-7f2ed5b3e58f";
  static const WRITE_UUID = "0000fe41-8e22-4541-9d4c-21edae82ed19";
  static const NOTIFY_UUID = "0000fe42-8e22-4541-9d4c-21edae82ed19";

  @override
  void initState() {
    super.initState();
    _scanAndConnect();
  }

  Future<void> _scanAndConnect() async {
    try {
      final device = await bluetooth.requestDevice(
        RequestOptionsBuilder.acceptAllDevices(
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
        print('Notifications started: $_notifyChar');
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

      setState(() => _log += "연결 성공!\n");
    } catch (e) {
      setState(() => _log += "연결 실패: $e\n");
    }
  }

  Future<void> _sendCommand(String hexCommand) async {
    if (_writeChar == null) return;

    final commandBytes = buildCommand(hexCommand);

    await _writeChar!.writeValueWithoutResponse(commandBytes);

    setState(() {
      _log += "명령 전송: ${bytesToHex(commandBytes)}\n";
    });
  }

  Uint8List buildCommand(String hex) {
    final bytes = hexStringToBytes(hex);
    int checksum = 0;
    for (var b in bytes) {
      checksum ^= b;
    }
    final result = Uint8List(bytes.length + 1);
    result.setAll(0, bytes);
    result[bytes.length] = checksum;
    return result;
  }

  Uint8List hexStringToBytes(String hex) {
    final cleanHex = hex.replaceAll(' ', '');
    final length = cleanHex.length ~/ 2;
    final result = Uint8List(length);
    for (var i = 0; i < length; i++) {
      result[i] = int.parse(cleanHex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }

  String bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
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
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                final hex = _hexController.text.trim();
                if (hex.isNotEmpty) {
                  _sendCommand(hex);
                }
              },
              child: const Text("명령 전송"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_log, style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
