// 실제 모바일 BLE 연결 처리 파일
// flutter_blue_plus 사용
// - BLE 스캔
// - BLE 연결
// - characteristic 찾기
// - notify 수신
// - 데이터 write

import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'ble_mobile_test_utils.dart';

class BleMobileTestService {

  // BLE 기기 객체
  BluetoothDevice? device;

  // write characteristic
  BluetoothCharacteristic? writeChar;

  // notify characteristic
  BluetoothCharacteristic? notifyChar;

  // notify 데이터 stream
  final StreamController<List<int>> _notifyController =
  StreamController<List<int>>.broadcast();

  Stream<List<int>> get notifyStream => _notifyController.stream;

  // UUID 정의
  static final Guid serviceUuid =
  Guid("0000fe40-cc7a-482a-984a-7f2ed5b3e58f");

  static final Guid writeUuid =
  Guid("0000fe41-8e22-4541-9d4c-21edae82ed19");

  static final Guid notifyUuid =
  Guid("0000fe42-8e22-4541-9d4c-21edae82ed19");

  // BLE 스캔 + 연결
  Future<void> scanAndConnect() async {

    // BLE 검색 시작
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 5),
    );

    // 검색 결과 listen
    await for (final results in FlutterBluePlus.scanResults) {

      for (final r in results) {

        final name = r.device.platformName;

        // VINCERE 기기 찾기
        if (name.startsWith("VINCERE")) {

          await FlutterBluePlus.stopScan();

          device = r.device;

          // 기기 연결
          await device!.connect(autoConnect: false);

          // 서비스 검색
          final services = await device!.discoverServices();

          for (final service in services) {

            // 서비스 UUID 확인
            if (service.uuid == serviceUuid) {

              for (final c in service.characteristics) {

                // write characteristic 저장
                if (c.uuid == writeUuid) {
                  writeChar = c;
                }

                // notify characteristic 저장
                if (c.uuid == notifyUuid) {

                  notifyChar = c;

                  // notify 활성화
                  await c.setNotifyValue(true);

                  // notify 수신 listen
                  c.lastValueStream.listen((value) {

                    _notifyController.add(value);

                  });
                }
              }
            }
          }

          return;
        }
      }
    }

    throw Exception("VINCERE 기기를 찾지 못했습니다.");
  }

  // hex command BLE write
  Future<void> writeHex(String hexCommand) async {

    if (writeChar == null) {
      throw Exception("BLE 연결 필요");
    }

    // checksum 포함 command 생성
    final bytes = buildElexirCommand(hexCommand);

    // BLE write
    await writeChar!.write(
      bytes,
      withoutResponse: true,
    );
  }

  // BLE 연결 해제
  Future<void> disconnect() async {
    await device?.disconnect();
  }

  // stream 종료
  void dispose() {
    _notifyController.close();
  }
}