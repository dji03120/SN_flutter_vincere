import 'dart:typed_data';

import 'package:flutter_web_bluetooth/js_web_bluetooth.dart';

final Map<String, String> ble_commands = {
  "mode1": "000B0900020000", //100hz
  "mode2 시작": "000B0900020001", //60hz
  "pause": "000B09000105",
  "continue": "000B09000106",
  "stop": "000B09000102",
  '': '',
  "강도 +": "000B09000103",
  "강도 -": "000B09000104",
  "펄스 +": "000B09000107",
  "펄스 -": "000B09000108",
  "info": "000B08010100",
  "battery": "000B08020100",
  // 1등급 - 15min 100hz 강도 1ma
  // 솔루션 통계 - 리포트 - 무료 운동시간
  //             유로 칼로리, 운동효과 구체적
  // 인터벌 pulse up down
  // log ma 확인
};

String setFrequency(int value) {
  // value = 10 -> 10hz
  if ((value > 1000) | (value < 0)) return 'none';
  String str_value = value.toString();
  String value_cmd = '00' * (4 - str_value.length);
  for (int i = 0; i < str_value.length; i++) {
    value_cmd += '0${str_value[i]}';
  }
  String cmd = "000B090408${value_cmd}00000000";
  return cmd;
}

String setVoltage(int value) {
  // value = 10 -> 1v
  if ((value > 100) | (value < 0)) return 'none';
  String str_value = value.toString();
  String value_cmd = '';
  for (int i = 0; i < str_value.length; i++) {
    value_cmd += '0${str_value[i]}';
  }
  String cmd = "000B09050A${value_cmd}0000000000000000";
  return cmd;
}

String setTemperature(int value) {
  int valueH = value + 2;
  int valueL = value - 2;
  if ((value > 48) | (value < 10)) return 'none';
  String value_cmd = '';
  for (int i = 0; i < 2; i++) value_cmd += '0${value.toString()[i]}';
  for (int i = 0; i < 2; i++) value_cmd += '0${valueH.toString()[i]}';
  for (int i = 0; i < 2; i++) value_cmd += '0${valueL.toString()[i]}';
  String cmd = "000B09060A${value_cmd}0000";
  return cmd;
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

Future<void> sendCommand(
  WebBluetoothRemoteGATTCharacteristic? _writeChar,
  String hexCommand,
) async {
  if (_writeChar == null) return;
  final commandBytes = buildCommand(hexCommand);
  _writeChar!.writeValueWithoutResponse(commandBytes);
  print("명령 전송: ${bytesToHex(commandBytes)}\n");
  await Future.delayed(const Duration(milliseconds: 150));
}
