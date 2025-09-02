import 'package:Vincere/component/header.dart';
import 'package:Vincere/test/gps_tester.dart';
import 'package:Vincere/test/gyro_tester.dart';
import 'package:flutter/material.dart';
import 'package:Vincere/component/custom_button.dart';
import 'package:Vincere/page_workout/page_select_mode.dart';

class PageConnectBLE extends StatefulWidget {
  const PageConnectBLE({super.key});

  @override
  State<PageConnectBLE> createState() => _BLEPageState();
}

class _BLEPageState extends State<PageConnectBLE> {
  static const SERVICE_UUID = "0000fe40-cc7a-482a-984a-7f2ed5b3e58f";
  static const WRITE_UUID = "0000fe41-8e22-4541-9d4c-21edae82ed19";
  static const NOTIFY_UUID = "0000fe42-8e22-4541-9d4c-21edae82ed19";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: const Header(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 100),
            SizedBox(
              height: 100,
              child: RoundButton(
                text: 'TEST PAGE : BLE ',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SelectMode()),
                  );
                },
              ),
            ),
            SizedBox(height: screenHeight * 0.04),
            SizedBox(
              height: 100,
              child: RoundButton(
                text: 'TEST PAGE : GPS ',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TestGPS()),
                  );
                },
              ),
            ),
            SizedBox(height: screenHeight * 0.04),
            SizedBox(
              height: 100,
              child: RoundButton(
                text: 'TEST PAGE : GYRO ',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PedometerPage()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
