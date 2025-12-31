import 'package:Vincere/utils/http/webReqFastapi.dart';
import 'package:Vincere/utils/http/webReqSpring.dart';
import 'package:Vincere/utils/component/header.dart';
import 'package:Vincere/provider_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class ScreenHealthInfoInput extends StatefulWidget {
  const ScreenHealthInfoInput({
    Key? key,
  });

  @override
  _ScreenHealthInfoState createState() => _ScreenHealthInfoState();
}

class _ScreenHealthInfoState extends State<ScreenHealthInfoInput> {
  Map<String, TextEditingController> _controllers = {};
  bool _isInitialized = false; // ← 초기화 여부 체크

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      updateControllers();
      updateCalculatedValues();
      _isInitialized = true; // 다시 실행되지 않음
    }
  }

  double? parseDouble(String input) {
    if (input.isEmpty || input.endsWith(".")) return null;
    return double.tryParse(input);
  }

  double toDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return parseDouble(value) ?? defaultValue;
    }
    return defaultValue;
  }

  void updateCalculatedValues() {
    final userModel = Provider.of<UserModel>(context, listen: false);
    double height = toDouble(userModel.userHealthData?['키'][0]);
    double weight = toDouble(userModel.userHealthData?['몸무게'][0]);
    double fatPercentage = toDouble(userModel.userHealthData?['체지방률'][0]);

    if (height != null && weight != null) {
      double heightInMeters = height / 100;
      double bmi = weight / (heightInMeters * heightInMeters);
      userModel.userHealthData?['신체질량지수(BMI)'][0] = bmi;
    }

    if (weight != null && fatPercentage != null) {
      double fatMass = weight * fatPercentage / 100;
      double muscleMass = weight - fatMass;
    }
  }

  void updateControllers() {
    final userModel = Provider.of<UserModel>(context, listen: false);
    updateCalculatedValues();

    userModel.userHealthData?.forEach((key, value) {
      if (value is List) {
        double tmp = toDouble(value[0]) ?? 0.0;
        print("$value $tmp");
        if ((value[2] == "몸무게") && (tmp == 0.0)) {
          return;
        }
        String newText = (tmp % 1 == 0 ? tmp.toStringAsFixed(0) : tmp.toStringAsFixed(2));

        if (_controllers.containsKey(key)) {
          // 컨트롤러 내용만 업데이트
          if (_controllers[key]!.text != newText) {
            _controllers[key]!.text = newText;
          }
        } else {
          // 컨트롤러가 없을 때만 생성
          _controllers[key] = TextEditingController(text: newText);
        }
      }
    });
  }

  @override
  void dispose() {
    // 메모리 누수 방지를 위한 컨트롤러 dispose
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  InputDecoration getInputDecoration(String hint, bool isReadOnly, String? unit) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8F9FB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(color: Color(0xFFEDEDED), width: 1.0),
      ),
      suffix: unit != null
          ? Padding(
              padding: const EdgeInsets.only(right: 0),
              child: Text(unit, style: const TextStyle(color: Color(0xFF8D8D8D), fontSize: 16, fontWeight: FontWeight.w400)),
            )
          : null,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0), borderSide: const BorderSide(color: Color(0xFFEDEDED), width: 1.0)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0), borderSide: const BorderSide(color: Color(0xFFEDEDED), width: 1.0)),
      disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0), borderSide: const BorderSide(color: Color(0xFFEDEDED), width: 1.0)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      hintStyle: const TextStyle(color: Color(0xFF8D8D8D), fontSize: 16, fontWeight: FontWeight.w400),
    );
  }

  Widget editForm(UserModel userModel, String keyword) {
    return Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(keyword, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      TextFormField(
        controller: _controllers[keyword],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        decoration: getInputDecoration('', false, userModel.userHealthData?[keyword][3] ?? ''),
        onChanged: (value) {
          userModel.userHealthData?[keyword][0] = value;
          updateControllers();
          setState(() {});
        },
      )
    ]));
  }

  @override
  Widget build(BuildContext context) {
    UserModel userModel = Provider.of<UserModel>(context); // 상태 접근
    final screenWidth = MediaQuery.of(context).size.width;

    List<Widget> children = [];
    children.add(const Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Text('My 건강정보 입력하기', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black)),
    ));

    children.add(
      Column(
        children: [
          Row(
            children: [
              editForm(userModel, '키'),
              SizedBox(width: 10),
              editForm(userModel, '몸무게'),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              editForm(userModel, '근육'),
              SizedBox(width: 10),
              editForm(userModel, '체지방률'),
            ],
          ),
          SizedBox(height: 20),
          Row(children: [editForm(userModel, '신체질량지수(BMI)')]),
          SizedBox(height: 60),
          Row(children: [editForm(userModel, '악력')]),
          SizedBox(height: 20),
          Row(children: [editForm(userModel, '앉았다 일어서기')]),
          SizedBox(height: 20),
          Row(children: [editForm(userModel, '걷기')]),
          SizedBox(height: 60),
          Row(
            children: [
              editForm(userModel, '혈압(고)'),
              SizedBox(width: 10),
              editForm(userModel, '혈압(저)'),
            ],
          ),
          SizedBox(height: 20),
          Row(children: [editForm(userModel, '혈당')]),
          SizedBox(height: 20),
          Row(children: [editForm(userModel, '간수치 ALP')]),
          SizedBox(height: 20),
          Row(children: [editForm(userModel, '간수치 ASP')]),
          SizedBox(height: 20),
          Row(children: [editForm(userModel, '간수치 ALT')]),
        ],
      ),
    );

    return Scaffold(
      appBar: const Header(),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Form(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 60),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () async {
              try {
                // API 호출
                ApiServiceFast apiService = ApiServiceFast();
                Map<String, dynamic> result = await apiService.insertUserHealth(userModel.userId, userModel.userHealthData ?? {});
                updateCalculatedValues();
                // 결과 처리
                if (result.containsKey("result")) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('건강정보가 성공적으로 업데이트되었습니다.'), duration: Duration(seconds: 2), backgroundColor: Colors.green),
                  );
                }
                if (result.containsKey("error")) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('업데이트 중 오류가 발생했습니다.'), duration: Duration(seconds: 2), backgroundColor: Colors.red),
                  );
                }
                userModel.set_user_info();
              } catch (e) {
                print("저장 중 오류 발생: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('알 수 없는 오류가 발생했습니다.'), duration: Duration(seconds: 2), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007130),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
            ),
            child: const Text(
              '저장하기',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}
