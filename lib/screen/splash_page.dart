import 'package:Vincere/screen/screen_home.dart';
import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _opacityAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 75), //밝아짐
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 25), //어두워짐
    ]).animate(_controller);

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 3000), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MyHomePage(title: "vincere_App")));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _opacityAnimation,
        builder: (context, child) {
          // 밝기 값 (0~1). 반대로 어두운 오버레이 계산
          double darkOpacity = (1 - _opacityAnimation.value) * 0.8;

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset("assets/images/splash.jpg", fit: BoxFit.cover),
              Container(color: Colors.black.withOpacity(darkOpacity)), // 어두운 오버레이

              // 텍스트
              Center(
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Personalized",
                        style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Bio Health",
                        style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
                      ),
                      SizedBox(height: 18),
                      Text(
                        "개인 건강정보 기반한 영양평가 및 식품추천",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
