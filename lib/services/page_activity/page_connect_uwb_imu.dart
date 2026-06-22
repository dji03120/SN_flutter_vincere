// UWB와 IMU 결합 디바이스를 웹앱과 블루투스로 연결하기 위한 기능

import 'dart:js_util' as js_util;
import 'dart:typed_data';

import 'package:Vincere/provider_models.dart';
import 'package:Vincere/services/page_activity/page_uwb_imu_activity.dart';
import 'package:Vincere/services/page_ble_device/ble_utils.dart';
import 'package:Vincere/utils/component/custom_widget.dart';
import 'package:Vincere/utils/component/header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart';
import 'package:flutter_web_bluetooth/js_web_bluetooth.dart';
import 'package:provider/provider.dart';

// UWB/IMU 연결 요청에 사용할 BLE 인스턴스를 제공하기 위한 기능
final uwbImuBluetooth = FlutterWebBluetooth.instance;

// UWB/IMU 연결 화면의 상태를 관리하기 위한 기능
class PageConnectUwbImu extends StatefulWidget {
  const PageConnectUwbImu({super.key});

  @override
  State<PageConnectUwbImu> createState() => _PageConnectUwbImuState();
}

// UWB/IMU 디바이스 스캔과 재연결 안내를 처리하기 위한 기능
class _PageConnectUwbImuState extends State<PageConnectUwbImu>
    with SingleTickerProviderStateMixin {
  WebBluetoothRemoteGATTCharacteristic? _writeChar;
  WebBluetoothRemoteGATTCharacteristic? _notifyChar;

  // 26.06.22 모든 UUID 값은 시제품 펌웨어 개발후 수정 필요
  // 장치가 제공하는 BLE 서비스 묶음
  static const serviceUuid = '0000fe40-cc7a-482a-984a-7f2ed5b3e58f';
  // 웹앱이 장치로 명령을 보내는 통로
  static const writeUuid = '0000fe41-8e22-4541-9d4c-21edae82ed19';
  // 장치가 웹앱으로 센서값을 보내는 통로
  static const notifyUuid = '0000fe42-8e22-4541-9d4c-21edae82ed19';

  // 실제 UWB/IMU 장치 개발 전 테스트 진입을 허용하기 위한 기능
  static const bool useMockConnection = true;

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isConnecting = false;
  bool _connectFailed = false;

  // 연결 화면 진입 시 자동 스캔과 연결 애니메이션을 시작하기 위한 기능
  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.02)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    WidgetsBinding.instance.addPostFrameCallback((_) => _scanAndConnect());
  }

  // 연결 화면 종료 시 애니메이션 리소스를 정리하기 위한 기능
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // UWB/IMU 디바이스를 스캔하고 GATT characteristic을 저장하기 위한 기능
  Future<void> _scanAndConnect() async {
    if (_isConnecting) return;
    setState(() {
      _isConnecting = true;
      _connectFailed = false;
    });

    if (useMockConnection) {
      await _connectWithMockDevice();
      return;
    }

    try {
      final userModel = Provider.of<UserModel>(context, listen: false);
      final device = await uwbImuBluetooth.requestDevice(RequestOptionsBuilder(
        [
          RequestFilterBuilder(namePrefix: 'UWB_IMU'),
          RequestFilterBuilder(namePrefix: 'VINCERE'),
        ],
        optionalServices: [serviceUuid],
      ));

      for (int i = 0; i < 3; i++) {
        try {
          await device.gatt?.connect();
          final service = await device.gatt?.getPrimaryService(serviceUuid);
          _writeChar = await service?.getCharacteristic(writeUuid);
          _notifyChar = await service?.getCharacteristic(notifyUuid);

          if (_writeChar == null || _notifyChar == null) {
            throw Exception('UWB/IMU characteristic is not available.');
          }

          userModel.set_write_char(_writeChar!);
          userModel.set_notify_char(_notifyChar!);
          await _notifyChar!.startNotifications();
          _listenForConnectionPreview();

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('UWB·IMU 디바이스가 연결되었습니다.')));
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const UwbImuActivityPage()));
          return;
        } catch (e) {
          if (i == 2) rethrow;
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _connectFailed = true;
      });
      _showReconnectDialog();
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  // 실제 장치 없이 Activity 화면으로 진입하기 위한 테스트 연결 기능
  Future<void> _connectWithMockDevice() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('테스트 모드로 연결되었습니다.')));
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const UwbImuActivityPage()));

    if (mounted) {
      setState(() => _isConnecting = false);
    }
  }

  // 연결 직후 수신되는 센서 패킷을 콘솔에서 확인하기 위한 기능
  void _listenForConnectionPreview() {
    if (_notifyChar == null) return;
    js_util.callMethod(_notifyChar!, 'addEventListener', [
      'characteristicvaluechanged',
      js_util.allowInterop((event) {
        final target = js_util.getProperty(event, 'target');
        final value = js_util.getProperty(target, 'value');
        if (value == null) return;
        final buffer = js_util.getProperty(value, 'buffer');
        final bytes = Uint8List.view(buffer);
        print('UWB/IMU Notification: ${bytesToHex(bytes)}\n');
      }),
    ]);
  }

  // 연결 실패 시 재연결을 유도하는 팝업을 표시하기 위한 기능
  void _showReconnectDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 22,
                    offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                      color: const Color(0xFFE2FFF0),
                      borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.bluetooth_disabled_rounded,
                      color: Color(0xFF007130), size: 32),
                ),
                const SizedBox(height: 18),
                const Text('디바이스 연결 실패',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87)),
                const SizedBox(height: 8),
                Text(
                  'UWB·IMU 태그 전원과 브라우저 블루투스 권한을 확인한 뒤 다시 연결해주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Colors.black.withOpacity(0.62)),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          showConnectionGuide(context);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF007130),
                          side: const BorderSide(
                              color: Color(0xFF92D2B0), width: 1.4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('연결 안내',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _scanAndConnect();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007130),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('재연결 시도',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // UWB/IMU 연결 진행 상태를 기존 BLE 화면 톤으로 표시하기 위한 기능
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Header(),
      backgroundColor: const Color(0xFFF5F4F9),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Column(
          children: [
            const SizedBox(height: 36),
            Text(
              _connectFailed ? '연결 실패' : 'UWB·IMU 연결 중...',
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003366)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _connectFailed
                  ? '재연결 시도를 눌러 다시 검색해주세요.'
                  : '태그 전원을 켜고 앵커 설치 공간 안에서 가까이 두세요.',
              style: TextStyle(
                  fontSize: 16, color: Colors.black.withOpacity(0.65)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8))
                ],
              ),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: const _UwbImuConnectionVisual(),
              ),
            ),
            const SizedBox(height: 46),
            _connectFailed
                ? RoundButton(
                    text: '재연결 시도',
                    margin: const EdgeInsets.symmetric(horizontal: 60),
                    onPressed: _scanAndConnect)
                : Column(
                    children: [
                      Text('1. UWB 앵커와 착용 태그 전원을 켜주세요',
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.black.withOpacity(0.7))),
                      const SizedBox(height: 10),
                      Text('2. 블루투스 목록에서 UWB_IMU 또는 VINCERE 장치를 선택해주세요',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.black.withOpacity(0.7))),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

// UWB 앵커와 착용 태그 연결 대상을 시각적으로 보여주기 위한 기능
class _UwbImuConnectionVisual extends StatelessWidget {
  const _UwbImuConnectionVisual();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: Stack(
        children: [
          Positioned(top: 8, left: 8, child: _buildAnchor()),
          Positioned(top: 8, right: 8, child: _buildAnchor()),
          Positioned(bottom: 8, left: 8, child: _buildAnchor()),
          Positioned(bottom: 8, right: 8, child: _buildAnchor()),
          Center(
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4DC),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFFB84D), width: 2),
              ),
              child: const Icon(Icons.watch_rounded,
                  color: Color(0xFFFFB84D), size: 42),
            ),
          ),
        ],
      ),
    );
  }

  // 연결 시각화에서 UWB 앵커 아이콘을 그리기 위한 기능
  static Widget _buildAnchor() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFE2FFF0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF007130), width: 1.6),
      ),
      child: const Icon(Icons.settings_input_antenna_rounded,
          color: Color(0xFF007130), size: 27),
    );
  }
}
