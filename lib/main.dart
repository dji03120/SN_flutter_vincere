// 앱 시작 시 로그인 상태 확인과 초기 화면 분기를 위한 기능

import 'package:Vincere/page_home/splash_page.dart';
import 'package:Vincere/utils/http/webReqSpring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:provider/provider.dart';
import 'package:Vincere/provider_models.dart';
import 'package:Vincere/utils/export/screens.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(AppRoot(key: appRootKey));
}

// 로그아웃 시 앱 Provider 상태를 초기화하기 위한 기능
final GlobalKey<AppRootState> appRootKey = GlobalKey<AppRootState>();

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => AppRootState();
}

class AppRootState extends State<AppRoot> {
  // Provider 트리를 새로 생성하기 위한 기능
  Key _providerKey = UniqueKey();

  // 로그아웃 후 Provider 상태를 초기화하기 위한 기능
  void resetProviders() {
    setState(() {
      _providerKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 앱 전역 상태 모델을 주입하기 위한 기능
    return MultiProvider(
      key: _providerKey,
      providers: [
        ChangeNotifierProvider(create: (_) => UserModel()),
        ChangeNotifierProvider(create: (_) => WorkoutModel()),
      ],
      child: const MyApp(),
    );
  }
}

// clustering :

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vincere App',
      theme: ThemeData(fontFamily: 'NotoSansKR'),
      // 저장된 로그인 상태 확인 후 첫 화면을 결정하기 위한 기능
      home: const AuthGate(),
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

// 저장된 로그인 세션에 따라 최초 화면을 분기하기 위한 기능
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // 최초 화면 결정 비동기 작업을 한 번만 실행하기 위한 기능
  late final Future<Widget> _initialScreenFuture;

  @override
  void initState() {
    super.initState();
    _initialScreenFuture = _getInitialScreen();
  }

  Future<Widget> _getInitialScreen() async {
    // 로그인 상태를 전역 사용자 모델에 반영하기 위한 기능
    final userModel = context.read<UserModel>();

    // 브라우저에 저장된 로그인 정보를 불러오기 위한 기능
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final password = prefs.getString('password') ?? '';

    // 저장된 로그인 정보가 없을 때 로그인 화면으로 이동하기 위한 기능
    if (userId.isEmpty || password.isEmpty) {
      return const LoginScreen();
    }

    // 저장된 로그인 정보가 서버에서 유효한지 확인하기 위한 기능
    final result = await ApiService().fetchUserLogin(userId, password);
    if (result['result'] == true) {
      // 자동 로그인 성공 시 사용자 모델과 스플래시 화면을 준비하기 위한 기능
      await userModel.set_login_data();
      return const SplashPage();
    }

    // 유효하지 않은 저장 로그인 정보를 삭제하기 위한 기능
    await prefs.remove('userId');
    await prefs.remove('password');
    return const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _initialScreenFuture,
      builder: (context, snapshot) {
        // 로그인 상태 확인이 끝난 후 결정된 화면을 표시하기 위한 기능
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return snapshot.data!;
        }

        // 로그인 상태 확인 중 로그인 화면 깜빡임을 방지하기 위한 기능
        return const Scaffold(
          backgroundColor: Colors.white,
          body: SizedBox.expand(),
        );
      },
    );
  }
}
