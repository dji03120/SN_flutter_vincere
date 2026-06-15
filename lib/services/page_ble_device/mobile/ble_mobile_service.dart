import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../common/ble_command_utils.dart';

class BleMobileService {
  BluetoothDevice? device;
  BluetoothCharacteristic? writeChar;
  BluetoothCharacteristic? notifyChar;

  final StreamController<List<int>> _notifyController =
  StreamController<List<int>>.broadcast();

  Stream<List<int>> get notifyStream => _notifyController.stream;

  // Elexir UUID
  static final Guid serviceUuid =
  Guid("0000fe40-cc7a-482a-984a-7f2ed5b3e58f");
  static final Guid writeUuid =
  Guid("0000fe41-8e22-4541-9d4c-21edae82ed19");
  static final Guid notifyUuid =
  Guid("0000fe42-8e22-4541-9d4c-21edae82ed19");

  // VINCERE 이름의 BLE 기기 검색 후 연결
  Future<void> scanAndConnectElexir() async {
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    await for (final results in FlutterBluePlus.scanResults) {
      for (final r in results) {
        final name = r.device.platformName;

        if (name.startsWith("VINCERE")) {
          await FlutterBluePlus.stopScan();

          device = r.device;
          await device!.connect(autoConnect: false);

          final services = await device!.discoverServices();

          for (final service in services) {
            if (service.uuid == serviceUuid) {
              for (final c in service.characteristics) {
                if (c.uuid == writeUuid) {
                  writeChar = c;
                }

                if (c.uuid == notifyUuid) {
                  notifyChar = c;
                  await c.setNotifyValue(true);

                  c.lastValueStream.listen((value) {
                    _notifyController.add(value);
                  });
                }
              }
            }
          }

          if (writeChar == null || notifyChar == null) {
            throw Exception("write/notify characteristic을 찾지 못했습니다.");
          }

          return;
        }
      }
    }

    throw Exception("VINCERE BLE 기기를 찾지 못했습니다.");
  }

  // hex 명령어 전송
  Future<void> writeElexirHex(String hexCommand) async {
    if (writeChar == null) {
      throw Exception("writeChar가 없습니다. 먼저 BLE 연결이 필요합니다.");
    }

    final bytes = buildElexirCommand(hexCommand);
    await writeChar!.write(bytes, withoutResponse: true);
    await Future.delayed(const Duration(milliseconds: 150));
  }

  Future<void> disconnect() async {
    await device?.disconnect();
  }

  void dispose() {
    _notifyController.close();
  }
}