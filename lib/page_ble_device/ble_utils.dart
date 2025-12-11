import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_web_bluetooth/js_web_bluetooth.dart';

import 'dart:js_util' as js_util;
import 'dart:html' as html;
import 'package:flutter/material.dart';

//
//
//
//
//
//
final Map<String, String> elexir_commands = {
  "mode1": "000B0900020000", //100hz
  "mode2": "000B0900020001", //60hz
  "pause": "000B09000105",
  "continue": "000B09000106",
  "stop": "000B09000102",
  "intense_up": "000B09000103",
  "intense_dw": "000B09000104",
  "info": "000B08010100",
  "battery": "000B08020100",
};

String bytesToHex(Uint8List bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
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

Uint8List buildElexirCommand(String hex) {
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

Future<void> sendCommandElexir(
  WebBluetoothRemoteGATTCharacteristic? _writeChar,
  String hexCommand,
) async {
  if (_writeChar == null) return;
  final commandBytes = buildElexirCommand(hexCommand);
  _writeChar.writeValueWithoutResponse(commandBytes);
  print("명령 전송: ${bytesToHex(commandBytes)}\n");
  await Future.delayed(const Duration(milliseconds: 150));
}

//
//
//
//
//
//
final Map<String, String> fitrus_hand_commands = {
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

Future<void> sendCommandFitrus(
  WebBluetoothRemoteGATTCharacteristic? _writeChar,
  String command,
) async {
  if (_writeChar == null) return;
  final commandBytes = Uint8List.fromList(utf8.encode(command));
  await _writeChar.writeValueWithoutResponse(commandBytes);
  print("명령 전송: ${bytesToHex(commandBytes)}\n");
}

//
//
//
// weight calculate
double parseWeightFromBytes(Uint8List data) {
  if (data.length < 8) return 0.0;
  if (data[0] != 0xAC || data[1] != 0x02) return 0.0;
  // 3,4 byte = 체중
  int high = data[2];
  int low = data[3];
  int raw = (high << 8) | low;
  return raw / 10.0;
}

double parseImpedanceToMap(Uint8List data) {
  if (data.length < 8) return 0.0;
  if (data[0] != 0xAC || data[1] != 0x02) return 0.0;
  int imp = (data[4] << 8) | data[5];
  return imp.toDouble();
}

double calculateBfpKushner(
  double weight, // kg
  double height, // cm
  int age,
  String sex, // "male" 또는 "female"
  double impedance, // Ω
) {
  int sexValue = sex.toLowerCase() == "male" ? 1 : 0;

  // FFM 계산
  double impAdj = impedance / 1000 * 1.54;
  double ffm = 0.00085 * (height * height / impAdj) + 0.14 * weight + 0.25 * age + 2.2 * sexValue;

  // 체지방률 계산
  double bfp = weight - ffm;
  return double.parse(bfp.toStringAsFixed(3));
}



/*
  Future<void> _permissionCheck() async {
    try {
      // 브라우저 권한 상태 확인
      final permissionStatus = await js_util.promiseToFuture(
        js_util.callMethod(
          js_util.getProperty(html.window, 'navigator').permissions,
          'query',
          [
            js_util.jsify({"name": "bluetooth"})
          ],
        ),
      );
      final state = js_util.getProperty(permissionStatus, 'state');
      print("BLE 권한 상태: $state");

      if (state == 'denied') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("브라우저에서 블루투스 권한을 허용해야 연결할 수 있습니다.")),
        );
        return;
      }
    } catch (e) {
      print("권한 확인 실패: $e");
    }
  }*/