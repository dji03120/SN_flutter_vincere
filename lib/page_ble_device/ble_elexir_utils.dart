import 'dart:typed_data';
import 'package:flutter_web_bluetooth/js_web_bluetooth.dart';

final Map<String, String> ble_commands = {
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

//
//
//
Uint8List hexStringToBytes(String hex) {
  final cleanHex = hex.replaceAll(' ', '');
  final length = cleanHex.length ~/ 2;
  final result = Uint8List(length);
  for (var i = 0; i < length; i++) {
    result[i] = int.parse(cleanHex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return result;
}

//
//
//
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

//
//
//
String bytesToHex(Uint8List bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

//
//
//
Future<void> sendCommand(
  WebBluetoothRemoteGATTCharacteristic? _writeChar,
  String hexCommand,
) async {
  if (_writeChar == null) return;
  final commandBytes = buildCommand(hexCommand);
  _writeChar.writeValueWithoutResponse(commandBytes);
  print("명령 전송: ${bytesToHex(commandBytes)}\n");
  await Future.delayed(const Duration(milliseconds: 150));
}
