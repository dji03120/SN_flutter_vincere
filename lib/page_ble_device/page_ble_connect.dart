import 'package:Vincere/component/header.dart';
import 'package:flutter/material.dart';
import 'package:Vincere/custom_widget/custom_button.dart';
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
    return Scaffold(
      appBar: const Header(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            RoundButton(
              text: 'goto workout',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SelectMode()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
