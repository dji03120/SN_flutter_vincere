import 'package:Vincere/http/webReq.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Vincere/export/screens.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyNutriCheck extends StatefulWidget {
  const MyNutriCheck({super.key});

  @override
  _MyNutriCheckScreenState createState() => _MyNutriCheckScreenState();
}

class _MyNutriCheckScreenState extends State<MyNutriCheck> {
  String? userId;
  String? password;
  bool _isLogIn = false;
  Map<String, dynamic>? _myNutriData;

  @override
  void initState() {
    super.initState();
    _loadSessionData().then((_) {
      if (_isLogIn) {
        _getMyNutriCheck();
      }
    });
  }

  // 세션에서 userId와 password 불러오기
  Future<void> _loadSessionData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
      password = prefs.getString('password');
      if (userId != null && password != null) {
        _isLogIn = true;
      }
    });
  }

  Future<void> _getMyNutriCheck() async {
    try {
      ApiService apiService = ApiService();

      Map<String, dynamic> result = await apiService.fetchGetMyNutriCheck(userId.toString());
      print('Received data: $result');

      if (result.containsKey('myNutri')) {
        setState(() {
          _myNutriData = Map<String, dynamic>.from(result['myNutri']);
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  final TextEditingController _textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Header(),
      drawer: CustomDrawer(isLogin: _isLogIn),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 50,
              child: const Padding(
                padding: EdgeInsets.fromLTRB(20, 15, 0, 0),
                child: Text(
                  '나의 필요 영양소 확인',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              color: Colors.green,
              padding: const EdgeInsets.all(20.0),
              child: _myNutriData != null
                  ? Text('${_myNutriData?["content"] ?? "데이터가 없습니다."}',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                ),
              )
                  : Text('아직 영양상태 평가 및 추천받은 식단이 없습니다.',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
