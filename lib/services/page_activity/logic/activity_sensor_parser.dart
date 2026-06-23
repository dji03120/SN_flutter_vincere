// UWB/IMU 센서 패킷을 움직임 점수와 지도 좌표로 변환하기 위한 기능

import 'dart:typed_data';

import 'package:flutter/material.dart';

// 센서 패킷 변화량과 태그 위치 계산을 담당하기 위한 기능
class ActivitySensorParser {
  // 센서 패킷 간 변화량을 계산하기 위한 기능
  static int calculateMovementScore(
      Uint8List bytes, Uint8List? previousPacket) {
    if (previousPacket == null || previousPacket.length != bytes.length) {
      return 99;
    }

    int score = 0;
    for (int i = 0; i < bytes.length; i++) {
      score += (bytes[i] - previousPacket[i]).abs();
    }
    return score;
  }

  // 센서 패킷에서 실내 태그 위치 표시 좌표를 추정하기 위한 기능
  static Offset deriveTagPosition(Uint8List bytes, Offset fallbackPosition) {
    if (bytes.length < 4) return fallbackPosition;
    final x = (bytes[0] + bytes[1]) / 510;
    final y = (bytes[2] + bytes[3]) / 510;
    return Offset(
        x.clamp(0.08, 0.92).toDouble(), y.clamp(0.12, 0.88).toDouble());
  }
}
