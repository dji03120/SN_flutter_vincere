import 'dart:math';
import 'dart:math' as Math;
import 'dart:typed_data';
import 'dart:js_util' as js_util;

import 'package:Vincere/services/page_ble_device/page_select_measure_type_fitrus.dart';
import 'package:Vincere/services/page_health/screen_my_health_info.dart';
import 'package:Vincere/utils/component/custom_widget.dart';
import 'package:Vincere/utils/component/header.dart';
import 'package:Vincere/services/page_ble_device/ble_utils.dart';
import 'package:Vincere/provider_models.dart';
import 'package:Vincere/utils/http/webReqFastapi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart';
import 'package:flutter_web_bluetooth/js_web_bluetooth.dart';
import 'package:provider/provider.dart';

final bluetooth = FlutterWebBluetooth.instance;

enum MeasureState {
  connecting,
  measuring,
  done,
}

class GlucoseRecord {
  final DateTime time;
  final double valueKgL;

  GlucoseRecord({
    required this.time,
    required this.valueKgL,
  });

  double get mgdl => valueKgL * 100000; // kg/L → mg/dL 변환
}

class PageBloodSugar extends StatefulWidget {
  const PageBloodSugar({super.key});

  @override
  State<PageBloodSugar> createState() => _PageBloodSugarState();
}

class _PageBloodSugarState extends State<PageBloodSugar> with SingleTickerProviderStateMixin {
  BluetoothDevice? _device;
  WebBluetoothRemoteGATTCharacteristic? _measureChar;
  WebBluetoothRemoteGATTCharacteristic? _contextChar;
  WebBluetoothRemoteGATTCharacteristic? _racpChar;
  String device_name = "Auto-Chek";

  static const SERVICE_UUID = "00001808-0000-1000-8000-00805f9b34fb";
  static const MEASURE_UUID = "00002a18-0000-1000-8000-00805f9b34fb";
  static const CONTEXT_UUID = "00002a34-0000-1000-8000-00805f9b34fb";
  static const RACP_UUID = "00002a52-0000-1000-8000-00805f9b34fb";

  late AnimationController _controller;

  MeasureState measureState = MeasureState.connecting;
  double weightResult = 0.0;
  bool _connectFailed = false;
  double _connectFailCount = 0;

  List<String> _notifyLogs = []; // Notify 로그
  List<GlucoseRecord> _records = [];
  bool _collecting = false;

//
//
//
  /// Init
  @override
  void initState() {
    super.initState();
    //WidgetsBinding.instance.addPostFrameCallback((_) => _scanAndConnect());
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

//
//
//
  /// UI
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: const Header(),
      body: Container(
        color: const Color(0xFFf5f4f9),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // 기본값이 min이어서 공간이 남음
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: screenHeight * 0.02),
                Center(child: _buildCurrentUI(screenHeight)),
                SizedBox(height: 200),
              ],
            ),
          ),
        ),
      ),
    );
  }

//
//
//
  /// 현재 상태에 맞는 UI 선택
  Widget _buildCurrentUI(double screenHeight) {
    switch (measureState) {
      case MeasureState.connecting:
        return _buildConnectingUI(screenHeight);
      case MeasureState.measuring:
        return _buildMeasureing();
      case MeasureState.done:
        return _buildDoneUI();
    }
  }

//
//
//
  Widget _buildConnectingUI(double screenHeight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 50),
        SizedBox(
            height: 300,
            child: Card(
                elevation: 4,
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(width: double.infinity, height: 200, child: Image.asset('assets/images/autochek.jpg', fit: BoxFit.contain)),
                ))),
        SizedBox(height: screenHeight * 0.03),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("1. 장치의 'S' 와 '▶' 버튼을 동시에 눌러주세요", style: TextStyle(fontSize: 16, color: Colors.black.withOpacity(0.7))),
          const SizedBox(height: 10),
          Text("2. 장치에 'BT' 문자가 나타난다면 'S' 버튼을 눌러주세요", style: TextStyle(fontSize: 16, color: Colors.black.withOpacity(0.7))),
          const SizedBox(height: 10),
          Text("3. 어플 화면에 연결 버튼을 눌러주세요", style: TextStyle(fontSize: 16, color: Colors.black.withOpacity(0.7))),
        ]),
        RoundButton(
          margin: const EdgeInsets.fromLTRB(50, 36, 50, 0),
          text: "연결",
          onPressed: _scanAndConnect,
        )
      ],
    );
  }

//
//
//
  Widget _buildMeasureing() {
    return Column(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text("혈당 기록 수집 중...", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 12), Text("기기에서 데이터를 수신하는 중입니다. 잠시만 기다려주세요.", style: TextStyle(fontSize: 16, color: Colors.black.withOpacity(0.7))), Text(_notifyLogs.toString()), RoundButton(margin: const EdgeInsets.fromLTRB(50, 36, 50, 0), text: "연결", onPressed: requestAllRecords)],
        ),
      ],
    );
  }

//
//
  GlucoseRecord? _selectedRecord;
  Widget _buildDoneUI() {
    const Color kGreenMain = Color(0xFF2E7D32);
    const Color kGreenAccent = Color(0xFF4CAF50);
    const Color kGreenSoft = Color(0x332E7D32);

    return Center(
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// 상단 아이콘
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: kGreenSoft),
                child: const Icon(Icons.check, color: kGreenMain, size: 48),
              ),
              const SizedBox(height: 20),
              const Text("혈당 기록 수집 완료", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),

              /// 기록 없을 때
              if (_records.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text("저장된 기록이 없습니다.", style: TextStyle(color: Colors.grey)),
                )
              else
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: _records.length >= 5 ? 5 : _records.length,
                    itemBuilder: (context, index) {
                      final recentRecords = _records.length > 5 ? _records.sublist(_records.length - 5) : _records;
                      final record = recentRecords.reversed.toList()[index];
                      return _buildRecordCard(record);
                    },
                  ),
                ),
              const SizedBox(height: 20),

              /// 닫기 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedRecord != null ? kGreenAccent : Colors.grey.shade400,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _selectedRecord == null
                      ? null
                      : () async {
                          //save
                          final userModel = Provider.of<UserModel>(context, listen: false);
                          userModel.userHealthData?['혈당'][0] = _selectedRecord!.mgdl.toInt();
                          await saveMeasureResult(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ScreenHealthInfo()));
                        },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "저장하기",
                      style: TextStyle(fontSize: 18, color: _selectedRecord != null ? Colors.white : Colors.black),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordCard(GlucoseRecord record) {
    final bool isSelected = _selectedRecord == record;

    return GestureDetector(
      onTap: () {
        safeSetState(() {
          if (_selectedRecord == record) {
            _selectedRecord = null;
          } else {
            _selectedRecord = record;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0x332E7D32) // 선택 시 연한 초록
              : const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${record.time.year}.${record.time.month.toString().padLeft(2, '0')}.${record.time.day.toString().padLeft(2, '0')}",
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Text(
                  "${record.time.hour.toString().padLeft(2, '0')}:${record.time.minute.toString().padLeft(2, '0')}:${record.time.second.toString().padLeft(2, '0')}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${record.mgdl.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const Text(
                  "mg/dL",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(fn);
    });
  }

  void timerSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  /// BLE 연결
  Future<void> _scanAndConnect() async {
    setState(() => _connectFailed = false);
    if (_connectFailCount >= 3) {
      // 3회 실패시 안내화면
      showConnectionGuide(context);
    }

    try {
      final device = await bluetooth.requestDevice(
        RequestOptionsBuilder(
          [RequestFilterBuilder(namePrefix: device_name)],
          optionalServices: [SERVICE_UUID],
        ),
      );
      setState(() => _device = device);

      for (int i = 0; i < 3; i++) {
        try {
          await device.gatt?.connect();
          final service = await device.gatt?.getPrimaryService(SERVICE_UUID);

          _measureChar = await service?.getCharacteristic(MEASURE_UUID);
          _contextChar = await service?.getCharacteristic(CONTEXT_UUID);
          _racpChar = await service?.getCharacteristic(RACP_UUID);

          await _measureChar?.startNotifications();
          await _contextChar?.startNotifications();
          await _racpChar?.startNotifications();
          js_util.callMethod(_measureChar!, 'addEventListener', ['characteristicvaluechanged', js_util.allowInterop(_onMeasureNotify)]);
          js_util.callMethod(_contextChar!, 'addEventListener', ['characteristicvaluechanged', js_util.allowInterop(_onContextNotify)]);
          js_util.callMethod(_racpChar!, 'addEventListener', ['characteristicvaluechanged', js_util.allowInterop(_onRacpNotify)]);
          safeSetState(() {
            measureState = MeasureState.measuring;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("디바이스 연결됨")),
          );
          _connectFailed = false;
          requestAllRecords();
          break;
        } catch (e) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (i == 2) safeSetState(() => _connectFailed = true);
        }
        if (_connectFailed == true) {
          _connectFailCount += 1;
        }
      }
    } catch (e) {
      await Future.delayed(const Duration(milliseconds: 500));
      safeSetState(() => _connectFailed = true);
      _connectFailCount += 1;
    }
  }

//
//
//
  /// BLE Notify 처리
  num _parseSFloat(int raw) {
    int mantissa = raw & 0x0FFF;
    int exponent = raw >> 12;

    // 2의 보수 처리
    if (mantissa >= 0x0800) mantissa = mantissa - 0x1000;
    if (exponent >= 0x0008) exponent = exponent - 0x0010;

    return mantissa * pow(10, exponent);
  }

  void _onMeasureNotify(event) {
    final value = js_util.getProperty(event.target, 'value');
    final buffer = js_util.getProperty(value, 'buffer');
    final bytes = Uint8List.view(buffer);

    if (!_collecting) return;

    int index = 0;
    final flags = bytes[index++];

    final seq = bytes[index++] | (bytes[index++] << 8);
    final year = bytes[index++] | (bytes[index++] << 8);
    final month = bytes[index++];
    final day = bytes[index++];
    final hour = bytes[index++];
    final minute = bytes[index++];
    final second = bytes[index++];

    final timeOffset = bytes[index++] | (bytes[index++] << 8);
    final rawGlucose = bytes[index++] | (bytes[index++] << 8);
    final glucose = _parseSFloat(rawGlucose);

    final record = GlucoseRecord(
      time: DateTime(year, month, day, hour, minute, second),
      valueKgL: glucose.toDouble(),
    );
    _records.add(record);
    safeSetState(() {});
  }

  void _onContextNotify(event) {
    final value = js_util.getProperty(event.target, 'value');
    final buffer = js_util.getProperty(value, 'buffer');
    final bytes = Uint8List.view(buffer);
    safeSetState(() {
      _notifyLogs.add("📘 Context: $bytes");
    });
  }

  void _onRacpNotify(event) {
    final value = js_util.getProperty(event.target, 'value');
    final buffer = js_util.getProperty(value, 'buffer');
    final bytes = Uint8List.view(buffer);
    safeSetState(() {
      _notifyLogs.add("📗 RACP: $bytes");
    });

    // 완료 신호 체크
    if (bytes.length >= 4 && bytes[0] == 0x06 && bytes[2] == 0x01 && bytes[3] == 0x01) {
      _collecting = false;

      safeSetState(() {
        _notifyLogs.add("✅ 모든 기록 수집 완료 (${_records.length}개)");
      });
      measureState = MeasureState.done;
    }
  }

  Future<void> requestAllRecords() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_racpChar == null) return;
    _records.clear();
    _collecting = true;
    await _racpChar!.writeValueWithResponse(Uint8List.fromList([0x01, 0x01]));
    await Future.delayed(const Duration(milliseconds: 1000));
    safeSetState(() {
      _notifyLogs.insert(0, "📤 Request All Records");
    });
  }
}
