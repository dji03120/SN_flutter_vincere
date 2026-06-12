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

//
//
//
//
// 심박수 데이터 수집
List<int> parseRawData(Uint8List bytes) {
  const chunkSize = 3; //
  if (bytes.length != 18) throw Exception('Expected 18 bytes, got ${bytes.length}');

  // 3bytes * 6 = 18bytes(raw) -> 0~1 정규화
  List<int> values = List.generate(bytes.length ~/ chunkSize, (i) {
    final raw1 = bytes[i * chunkSize + 0].toInt();
    final raw2 = bytes[i * chunkSize + 1].toInt();
    final raw3 = bytes[i * chunkSize + 2].toInt();
    final value = (raw1 << 16) | (raw2 << 8) | raw3;
    return value; // 0~1 정규화
  }); // green, ir, green, ir, green, ir

  return values;
}

//
//
//
// 연결 안내 팝업 함수
void showConnectionGuide(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return const ConnectionGuideDialog();
    },
  );
}

class ConnectionGuideDialog extends StatefulWidget {
  const ConnectionGuideDialog({super.key});
  @override
  State<ConnectionGuideDialog> createState() => _ConnectionGuideDialogState();
}

String getDeviceOS() {
  final userAgent = html.window.navigator.userAgent.toLowerCase();
  if (userAgent.contains("iphone") || userAgent.contains("ipad")) return "apple";
  if (userAgent.contains("android")) return "android";
  return "other";
}

class _ConnectionGuideDialogState extends State<ConnectionGuideDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late List<Map<String, String>> _guideData;
  late String os;

  @override
  void initState() {
    super.initState();
    _setupGuide();
  }

  void _setupGuide() {
    os = getDeviceOS();
    _guideData = [
      if (os == "apple") {"title": "아이폰(iOS) 사용자", "desc": "Web Bluetooth를 지원하는\n'Bluefy' 브라우저를 설치해 주세요.", "icon": "🍎", "image": "assets/images/bluefy-icon-app.jpg"},
      // 안드로이드이거나 기타 기기일 때 보여줄 설정 4단계
      {"title": "환경설정 1", "desc": "설정에 들어가서\n'애플리케이션'을 선택해주세요.", "icon": "⚙️", "image": "assets/images/ble_guide1.png"},
      {"title": "환경설정 2", "desc": "사용하시는 브라우저\n(삼성 인터넷 등)를 선택해주세요.", "icon": "🌐", "image": "assets/images/ble_guide2.png"},
      {"title": "환경설정 3", "desc": "'권한' 항목을\n클릭하여주세요.", "icon": "🔒", "image": "assets/images/ble_guide3.png"},
      {"title": "환경설정 4", "desc": "'근처 기기' 권한이\n허용되어 있는지 확인하세요.", "icon": "📡", "image": "assets/images/ble_guide4.png"},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent, // 외부 여백 투명하게
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400), // 모바일 웹 대응
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // 내용만큼만 높이 차지
          children: [
            // 1. 가이드 콘텐츠 영역
            SizedBox(height: 10),
            SizedBox(
              height: screenHeight * 0.55, // 콘텐츠 높이 고정
              width: screenWidth * 0.9, // 콘텐츠 높이 고정
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _guideData.length,
                itemBuilder: (context, index) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 이미지 영역 (이미지가 있을 때만 노출)
                      if (_guideData[index].containsKey("image"))
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                _guideData[index]["image"]!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        )
                      else
                        // 이미지가 없을 때 아이콘 크게 표시
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: Text(_guideData[index]["icon"]!, style: const TextStyle(fontSize: 64)),
                        ),

                      // 제목 및 설명
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_guideData[index]["icon"]!, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            _guideData[index]["title"]!,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _guideData[index]["desc"]!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          height: 1.5,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // 2. 인디케이터 (점)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _guideData.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 20 : 8, // 선택된 점은 길게
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentPage == index ? Colors.blue.shade600 : Colors.grey.shade300,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 3. 닫기 버튼 (너비 80%)
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.7, // 팝업 내 가용 너비의 약 80%
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("닫기"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> permissionCheck(BuildContext context) async {
  try {
    // 브라우저 권한 상태 확인
    final permissionStatus = await js_util.promiseToFuture(
      js_util.callMethod(js_util.getProperty(html.window, 'navigator').permissions, 'query', [
        js_util.jsify({"name": "bluetooth"})
      ]),
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
}
