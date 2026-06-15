// BLE 명령어 관련 공통 유틸 파일
// - hex 문자열 ↔ byte 변환
// - checksum 생성
// - Elexir 명령어 저장

import 'dart:typed_data';

// Elexir 기기에 보내는 명령어 목록
final Map<String, String> elexirCommands = {
  "pause": "000B09000105",
  "continue": "000B09000106",
  "stop": "000B09000102",
};

// byte 배열 → hex 문자열 변환
String bytesToHex(List<int> bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

// hex 문자열 → byte 배열 변환
Uint8List hexStringToBytes(String hex) {
  final cleanHex = hex.replaceAll(' ', '');
  final result = Uint8List(cleanHex.length ~/ 2);

  for (var i = 0; i < result.length; i++) {
    result[i] = int.parse(cleanHex.substring(i * 2, i * 2 + 2), radix: 16);
  }

  return result;
}

// BLE 전송용 checksum 포함 command 생성
Uint8List buildElexirCommand(String hex) {
  final bytes = hexStringToBytes(hex);

  int checksum = 0;

  for (final b in bytes) {
    checksum ^= b;
  }

  final result = Uint8List(bytes.length + 1);

  result.setAll(0, bytes);

  // 마지막 byte에 checksum 추가
  result[bytes.length] = checksum;

  return result;
}