import 'dart:html';
import 'dart:math';
import 'package:flutter/material.dart';

class PedometerPage extends StatefulWidget {
  const PedometerPage({super.key});

  @override
  State<PedometerPage> createState() => _PedometerPageState();
}

class _PedometerPageState extends State<PedometerPage> {
  int steps = 0;
  double lastX = 0, lastY = 0, lastZ = 0;
  double threshold = 12; // 흔들림 감도 (실험 필요)

  @override
  void initState() {
    super.initState();
    startPedometer();
  }

  void startPedometer() {
    window.onDeviceMotion.listen((event) {
      final acc = event.accelerationIncludingGravity;
      if (acc != null) {
        double deltaX = acc.x! - lastX;
        double deltaY = acc.y! - lastY;
        double deltaZ = acc.z! - lastZ;

        double speed = sqrt(deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ);

        if (speed > threshold) {
          setState(() {
            steps += 1;
          });
        }

        lastX = acc.x!.toDouble();
        lastY = acc.y!.toDouble();
        lastZ = acc.z!.toDouble();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Flutter Web 만보계")),
      body: Center(
        child: Text(
          "걸음 수: $steps",
          style: const TextStyle(fontSize: 32),
        ),
      ),
    );
  }
}
