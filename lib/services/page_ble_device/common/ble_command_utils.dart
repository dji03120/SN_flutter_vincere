import 'dart:typed_data';

// Elexir 명령어 모음
final Map<String, String> elexirCommands = {
  "mode1": "000B0900020000",
  "mode2": "000B0900020001",
  "pause": "000B09000105",
  "continue": "000B09000106",
  "stop": "000B09000102",
  "intense_up": "000B09000103",
  "intense_dw": "000B09000104",
  "info": "000B08010100",
  "battery": "000B08020100",
};

// byte → hex 문자열
String bytesToHex(List<int> bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

// hex 문자열 → byte 배열
Uint8List hexStringToBytes(String hex) {
  final cleanHex = hex.replaceAll(' ', '');
  final result = Uint8List(cleanHex.length ~/ 2);

  for (var i = 0; i < result.length; i++) {
    result[i] = int.parse(cleanHex.substring(i * 2, i * 2 + 2), radix: 16);
  }

  return result;
}

// checksum 포함 BLE 전송 command 생성
Uint8List buildElexirCommand(String hex) {
  final bytes = hexStringToBytes(hex);

  int checksum = 0;
  for (final b in bytes) {
    checksum ^= b;
  }

  final result = Uint8List(bytes.length + 1);
  result.setAll(0, bytes);
  result[bytes.length] = checksum;

  return result;
}