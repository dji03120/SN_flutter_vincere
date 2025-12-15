import 'package:Vincere/utils/component/header.dart';
import 'package:Vincere/utils/sample/ble_tester_web.dart';
import 'package:Vincere/utils/sample/gps_tester.dart';
import 'package:Vincere/utils/sample/gyro_tester.dart';
import 'package:flutter/material.dart';
import 'package:Vincere/utils/component/custom_widget.dart';

class PageSelectTest extends StatefulWidget {
  const PageSelectTest({super.key});

  @override
  State<PageSelectTest> createState() => _BLEPageState();
}

class _BLEPageState extends State<PageSelectTest> {
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
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const WebBleTest()));
                  },
                )),
            SizedBox(height: screenHeight * 0.04),
            SizedBox(
                height: 100,
                child: RoundButton(
                  text: 'TEST PAGE : GPS ',
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const TestGPS()));
                  },
                )),
            SizedBox(height: screenHeight * 0.04),
            SizedBox(
                height: 100,
                child: RoundButton(
                  text: 'TEST PAGE : GYRO ',
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const PedometerPage()));
                  },
                )),
          ],
        ),
      ),
    );
  }
}
