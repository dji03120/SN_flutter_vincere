import 'package:Vincere/component/custom_widget.dart';
import 'package:Vincere/component/header.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class TestGPS extends StatefulWidget {
  const TestGPS({super.key});

  @override
  State<TestGPS> createState() => _LocationWidgetState();
}

class _LocationWidgetState extends State<TestGPS> {
  String _locationMessage = '버튼을 눌러 현재위치를 요청하세요';

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 위치 서비스 확인
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationMessage = '위치 서비스를 켜주세요.';
      });
      return;
    }

    // 권한 확인
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationMessage = '위치 권한이 거부되었습니다.';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationMessage = '앱에서 위치 권한을 영구적으로 거부했습니다.';
      });
      return;
    }

    // 위치 가져오기
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _locationMessage = '위도: ${position.latitude}, 경도: ${position.longitude}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Header(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextCustom(
              text: _locationMessage,
              fontSize: 20,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _getCurrentLocation,
              child: const Text('위치 가져오기'),
            ),
          ],
        ),
      ),
    );
  }
}
