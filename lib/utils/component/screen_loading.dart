import 'package:flutter/material.dart';
import 'package:Vincere/utils/export/screens.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _mockLoading();
  }

  Future<void> _mockLoading() async {
    // 3초 동안 로딩 화면을 보여줍니다.
    await Future.delayed(const Duration(seconds: 3));
    // 로딩이 끝나면 홈 화면으로 이동합니다.
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => const MyHomePage(
                title: 'Vincere_App',
              )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            child: Image.asset('images/Vincere.png'),
          ),
          Container(
            child: const Text(
              'For Your Health',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 20,
              ),
            ),
          )
        ]),
      ),
    );
  }
}
