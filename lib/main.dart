// import 'package:Vincere/services/page_ble_device/web/page_blood_sugar.dart';
import 'package:Vincere/services/page_ble_device/page_inbody_blood_pressure_large.dart';
import 'package:Vincere/services/page_ble_device/page_inbody_blood_pressure_small.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:provider/provider.dart';
import 'package:Vincere/provider_models.dart';
import 'package:Vincere/utils/export/screens.dart';

void main() {
  runApp(AppRoot(key: appRootKey));
}

final GlobalKey<_AppRootState> appRootKey = GlobalKey<_AppRootState>();

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  Key _providerKey = UniqueKey();

  void resetProviders() {
    setState(() {
      _providerKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
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
      home: LoginScreen(),
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
