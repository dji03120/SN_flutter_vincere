import 'dart:typed_data';
import 'dart:js_util' as js_util;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart';
import 'package:flutter_web_bluetooth/js_web_bluetooth.dart';
import 'package:http/http.dart' as http;

final bluetooth = FlutterWebBluetooth.instance;

String bytesToHex(Uint8List bytes) => bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

class PageConnectFitrus extends StatefulWidget {
  const PageConnectFitrus({super.key});
  @override
  State<PageConnectFitrus> createState() => _PageConnectFitrus();
}

class _PageConnectFitrus extends State<PageConnectFitrus> {
  BluetoothDevice? _device;
  WebBluetoothRemoteGATTCharacteristic? _writeChar;
  WebBluetoothRemoteGATTCharacteristic? _notifyChar;

  String _log = "";
  String? _selectedCommand;

  // Device 서비스 및 특성 UUID
  static const SERVICE_UUID = "00000001-0000-1100-8000-00805f9b34fb";
  static const WRITE_UUID = "00000002-0000-1100-8000-00805f9b34fb";
  static const NOTIFY_UUID = "00000003-0000-1100-8000-00805f9b34fb";

//
//
//
  final Map<String, String> _commands = {
    "bfp_start": "*BFP:Start#\r\n",
    "bfp_stop": "*BFP:Stop#\r\n",
    "cal_start": "*Calmode:Start#\r\n", //bfp 캘리브레이션 무엇을?
    "cal_stop": "*Calmode:Stop#\r\n",
    "spo2_start": "*SpO2:Start#\r\n",
    "spo2_stop": "*SpO2:Stop#\r\n",
    "stress_start": "*Stress:Start#\r\n",
    "stress_stop": "*Stress:Stop#\r\n",
    "temp_start": "*Temp:Start#\r\n",
    "temp_body_start": "*Temp.Body:Start#\r\n",
    "info": "*Dev.Info:Read#\r\n",
    "battery": "*Dev.Info:Batt.Read#\r\n",
  };

//
//
//
  @override
  void initState() {
    super.initState();
    scanAndConnect();
  }

  List<int> trimRightZeros(List<int> bytes) {
    int i = bytes.length - 1;
    while (i >= 0 && bytes[i] == 0) {
      i--;
    }
    return bytes.sublist(0, i + 1);
  }

  String bytesToUtf8String(Uint8List bytes) {
    final trimBytes = trimRightZeros(bytes);
    return utf8.decode(trimBytes, allowMalformed: true);
  }

  static Future<List<dynamic>> requestOSDResult(String voltage) async {
    const apiKey = "zPkSTulXlcw4UKXo9YQS1n7lus1sOEnXVkG727sY2ck9wZ8YPQxehyPAf2pg9FhdITGSZx7aW8tTl2jqLcNivvSuPOW2xW8r5KnTsRMfxqgy0emq0SSdzNtGQ6hIVi3w";
    final Map<String, dynamic> param = {
      "age": "30",
      "gender": "male",
      "height": "170",
      "voltage": voltage,
      "weight": "70",
    };
    final res = await http.post(
      Uri.parse("https://api.thefitrus.com/fitrus-ml/measure/bodyfat"),
      headers: {"Content-Type": "application/json", "x-api-key": apiKey},
      body: jsonEncode(param),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("requestOSDResult error: ${res.statusCode} / ${res.body}");
    }
  }

//
//
//
  Future<void> scanAndConnect() async {
    try {
      // 1️⃣ 디바이스 선택
      final device = await bluetooth.requestDevice(
        RequestOptionsBuilder.acceptAllDevices(
          optionalServices: [SERVICE_UUID],
        ),
      );
      setState(() => _device = device);

      // 2️⃣ 연결
      await device.gatt?.connect();

      // 3️⃣ 서비스 & 특성 가져오기
      final service = await device.gatt?.getPrimaryService(SERVICE_UUID);
      _writeChar = await service?.getCharacteristic(WRITE_UUID);
      _notifyChar = await service?.getCharacteristic(NOTIFY_UUID);

      // 4️⃣ Notify 처리
      if (_notifyChar != null) {
        await _notifyChar!.startNotifications();
        js_util.callMethod(_notifyChar!, 'addEventListener', [
          'characteristicvaluechanged',
          js_util.allowInterop((event) {
            final target = js_util.getProperty(event, 'target');
            final value = js_util.getProperty(target!, 'value');
            if (value != null) {
              final buffer = js_util.getProperty(value, 'buffer');
              final bytes = Uint8List.view(buffer);
              setState(() {
                String notifyMsg = bytesToUtf8String(bytes);
                _log += "Notification: ${notifyMsg}\n\n";
              });
            }
          }),
        ]);
      }
      setState(() => _log += "연결 성공!\n");

      // 5️⃣ 서비스 & 특성 출력
      await printServicesAndCharacteristics();
    } catch (e) {
      setState(() => _log += "연결 실패: $e\n");
    }
  }

//
//
//
  Future<void> printServicesAndCharacteristics() async {
    if (_device == null) return;
    try {
      final services = await _device!.gatt?.getPrimaryServices();
      if (services == null || services.isEmpty) return;

      setState(() => _log += "📌 서비스 및 특성 목록:\n");
      for (var service in services) {
        setState(() => _log += "🔧 Service: ${service.uuid}\n");

        final characteristics = await service.getCharacteristics();
        for (var char in characteristics) {
          setState(() => _log += "   📎 Characteristic: ${char.uuid}\n");
          final props = <String>[];
          if (char.properties.read) props.add("read");
          if (char.properties.write) props.add("write");
          if (char.properties.notify) props.add("notify");
          if (char.properties.indicate) props.add("indicate");
          setState(() => _log += "      🔸 Properties: ${props.join(', ')}\n");
        }
      }
    } catch (e) {
      setState(() => _log += "서비스 조회 실패: $e\n");
    }
  }

//
//
//
  Future<void> sendCommandFitrus(String command) async {
    if (_writeChar == null) return;
    final commandBytes = Uint8List.fromList(utf8.encode(command));
    await _writeChar!.writeValueWithoutResponse(commandBytes);
    setState(() {
      _log += "명령 전송: ${bytesToHex(commandBytes)}\n";
    });
  }

//
//
//
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("FitrusPlus3 Web BLE Test")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: scanAndConnect,
              child: const Text("연결 시도"),
            ),
            DropdownButton<String>(
              hint: const Text("명령 선택"),
              value: _selectedCommand,
              isExpanded: true,
              items: _commands.keys.map((label) {
                return DropdownMenuItem(value: label, child: Text(label));
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCommand = value);
                if (value != null) sendCommandFitrus(_commands[value]!);
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_log, style: const TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
