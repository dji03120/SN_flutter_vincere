import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'BLE Demo', home: BLEHomePage());
  }
}

class BLEHomePage extends StatefulWidget {
  const BLEHomePage({super.key});

  @override
  _BLEHomePageState createState() => _BLEHomePageState();
}

class _BLEHomePageState extends State<BLEHomePage> {
  List<ScanResult> scanResults = [];
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? writeChar;
  BluetoothCharacteristic? notifyChar;

  bool isScanning = false;
  String notifyText = "";

  // 선택된 명령
  String selectedCommandKey = 'info';

  // 명령 dictionary
  final Map<String, String> messageDict = {
    // info
    'info': '000B08010100',
    'battery': '000B08020100',
    'rtc_battery': '000B08030100',
    'mac_address': '000B08040100',

    // control
    'mode1': '000B0900020000',
    'mode2': '000B0900020001',
    'run': '000B09010100',
    'stop': '000B09020100',
    'intense_up': '000C09030100',
    'intense_dw': '000C09040100',
    'pause': '000C09050100',
    'continue': '000C09060100',
    'duration_up': '000C09070100',
    'duration_dw': '000C09080100',

    // notification
    'noti_health': '000B0CF70100',
  };

  /// BLE 장치 스캔
  void startScan() async {
    setState(() {
      scanResults.clear();
      isScanning = true;
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scanResults = results;
      });
    }).onDone(() {
      setState(() => isScanning = false);
    });
  }

  /// 장치 연결
  Future<void> connectToDevice(BluetoothDevice device) async {
    await device.connect(autoConnect: false);
    connectedDevice = device;

    try {
      await device.createBond();
      device.bondState.listen((bondState) {
        print("🔗 Bond state: $bondState");
      });
    } catch (e) {
      print("⚠️ Bonding 오류: $e");
    }

    await discoverServicesAndSetup();
    setState(() {});
  }

  /// 서비스 탐색
  Future<void> discoverServicesAndSetup() async {
    if (connectedDevice == null) return;

    List<BluetoothService> services = await connectedDevice!.discoverServices();

    writeChar = services
        .firstWhere(
          (s) => s.uuid.toString() == "0000fe40-cc7a-482a-984a-7f2ed5b3e58f",
        )
        .characteristics
        .firstWhere(
          (c) => c.uuid.toString() == "0000fe41-8e22-4541-9d4c-21edae82ed19",
        );

    notifyChar = services
        .firstWhere(
          (s) => s.uuid.toString() == "0000fe40-cc7a-482a-984a-7f2ed5b3e58f",
        )
        .characteristics
        .firstWhere(
          (c) => c.uuid.toString() == "0000fe42-8e22-4541-9d4c-21edae82ed19",
        );
    String bytesToHex(List<int> bytes) {
      return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
    }

    // Notify 구독
    await notifyChar!.setNotifyValue(true);
    notifyChar!.lastValueStream.listen((value) {
      final hexString = bytesToHex(value);
      print("🔔 Notify: $hexString");
      setState(() {
        notifyText = hexString;
      });
    });
  }

  /// 명령 전송
  Future<void> sendCommand(String key) async {
    if (writeChar == null) return;
    final hexString = messageDict[key]!;
    final List<int> bytes = [
      for (int i = 0; i < hexString.length; i += 2) int.parse(hexString.substring(i, i + 2), radix: 16),
    ];
    await writeChar!.write(bytes, withoutResponse: true);
    print("📤 Sent command: $key -> $bytes");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BLE Demo')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: isScanning ? null : startScan,
            child: Text(isScanning ? "Scanning..." : "Start Scan"),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: scanResults.length,
              itemBuilder: (context, index) {
                final r = scanResults[index];
                return ListTile(
                  title: Text(
                    r.device.platformName.isNotEmpty ? r.device.platformName : "Unknown",
                  ),
                  subtitle: Text(r.device.remoteId.toString()),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      await FlutterBluePlus.stopScan();
                      await connectToDevice(r.device);
                    },
                    child: const Text("Connect"),
                  ),
                );
              },
            ),
          ),
          if (connectedDevice != null) ...[
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("✅ Connected: ${connectedDevice!.platformName}"),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DropdownButton<String>(
                      value: selectedCommandKey,
                      items: messageDict.keys
                          .map(
                            (key) => DropdownMenuItem(value: key, child: Text(key)),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCommandKey = value!;
                        });
                      },
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => sendCommand(selectedCommandKey),
                      child: const Text("Send Command"),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("🔔 Notify Data: $notifyText"),
                ),
                SizedBox(height: 100),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
