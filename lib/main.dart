import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:provider/provider.dart';
import 'package:Vincere/provider_models.dart';
import 'package:Vincere/export/screens.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WorkoutModel()),
        ChangeNotifierProvider(create: (_) => UserModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vincere App',
      theme: ThemeData(fontFamily: 'NotoSansKR'),
      home: LoginScreen(), // const LoginScreen(),
      locale: const Locale('ko', 'KR'), // 기본 로케일을 한국어로
      supportedLocales: const [
        Locale('ko', 'KR'), // 한국어
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
