import 'package:Vincere/utils/http/webReqFastapi.dart';
import 'package:Vincere/utils/component/header.dart';
import 'package:Vincere/provider_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class ScreenHealthInfoInput extends StatefulWidget {
  const ScreenHealthInfoInput({Key? key}) : super(key: key);

  @override
  _ScreenHealthInfoState createState() => _ScreenHealthInfoState();
}

class _ScreenHealthInfoState extends State<ScreenHealthInfoInput> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {}; // 포커스 관리를 위한 노드
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      updateControllers();
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    // 메모리 누수 방지
    for (var controller in _controllers.values) controller.dispose();
    for (var node in _focusNodes.values) node.dispose();
    super.dispose();
  }

  // 데이터 타입 변환 유틸리티
  double toDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      if (value.isEmpty || value == ".") return defaultValue;
      return double.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  // 컨트롤러 초기화 및 값 동기화
  void updateControllers() {
    final userModel = Provider.of<UserModel>(context, listen: false);

    userModel.userHealthData?.forEach((key, value) {
      if (value is List) {
        // 컨트롤러와 포커스노드가 없으면 생성
        _controllers.putIfAbsent(key, () => TextEditingController());
        _focusNodes.putIfAbsent(key, () => FocusNode());

        String currentStr = value[0]?.toString() ?? "";

        // 사용자가 입력 중인 필드가 아닐 때만 값을 갱신 (소수점 입력 보호)
        if (!_focusNodes[key]!.hasFocus) {
          if (_controllers[key]!.text != currentStr) {
            _controllers[key]!.text = currentStr;
          }
        }
      }
    });
  }

  // 저장 버튼 클릭 시 수행할 계산 로직
  void calculateOnSave() {
    final userModel = Provider.of<UserModel>(context, listen: false);

    double height = toDouble(userModel.userHealthData?['키'][0]);
    double weight = toDouble(userModel.userHealthData?['몸무게'][0]);
    double fatPercentage = toDouble(userModel.userHealthData?['체지방률'][0]);

    if (height > 0 && weight > 0) {
      double heightInMeters = height / 100;
      double bmi = weight / (heightInMeters * heightInMeters);
      userModel.userHealthData?['신체질량지수(BMI)'][0] = bmi.toStringAsFixed(2);
    }

    if (weight > 0 && fatPercentage > 0) {
      double fatMass = weight * fatPercentage / 100;
      userModel.userHealthData?['체지방량'][0] = fatMass.toStringAsFixed(2);
    }
  }

  InputDecoration getInputDecoration(String hint, String? unit) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8F9FB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(color: Color(0xFFEDEDED), width: 1.0),
      ),
      suffix: unit != null && unit.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(unit, style: const TextStyle(color: Color(0xFF8D8D8D), fontSize: 16)),
            )
          : null,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0), borderSide: const BorderSide(color: Color(0xFFEDEDED), width: 1.0)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0), borderSide: const BorderSide(color: Color(0xFF007130), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    );
  }

  Widget editForm(UserModel userModel, String keyword) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(keyword, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _controllers[keyword],
            focusNode: _focusNodes[keyword], // 포커스노드 연결 필수
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')), // 숫자와 점만 허용
            ],
            decoration: getInputDecoration('', userModel.userHealthData?[keyword][3] ?? ''),
            onChanged: (value) {
              // 입력 중에는 동적 계산이나 포맷팅을 수행하지 않고 데이터만 보관
              userModel.userHealthData?[keyword][0] = value;
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    UserModel userModel = Provider.of<UserModel>(context);

    return Scaffold(
      appBar: const Header(),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 30),
                child: Text('My 건강정보 입력하기', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
              ),
              Row(children: [
                editForm(userModel, '키'),
                const SizedBox(width: 10),
                editForm(userModel, '몸무게'),
              ]),
              const SizedBox(height: 20),
              Row(children: [
                editForm(userModel, '근육'),
                const SizedBox(width: 10),
                editForm(userModel, '체지방률'),
              ]),
              const SizedBox(height: 20),
              Row(children: [editForm(userModel, '신체질량지수(BMI)')]),
              const SizedBox(height: 60),
              Row(children: [editForm(userModel, '악력')]),
              const SizedBox(height: 20),
              Row(children: [editForm(userModel, '앉았다 일어서기')]),
              const SizedBox(height: 20),
              Row(children: [editForm(userModel, '걷기')]),
              const SizedBox(height: 60),
              Row(children: [
                editForm(userModel, '혈압(고)'),
                const SizedBox(width: 10),
                editForm(userModel, '혈압(저)'),
              ]),
              const SizedBox(height: 20),
              Row(children: [editForm(userModel, '혈당')]),
              const SizedBox(height: 20),
              Row(children: [editForm(userModel, '간수치 ALP')]),
              const SizedBox(height: 20),
              Row(children: [editForm(userModel, '간수치 ASP')]),
              const SizedBox(height: 20),
              Row(children: [editForm(userModel, '간수치 ALT')]),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () async {
              calculateOnSave();
              await saveMeasureResult(context);
              updateControllers();
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007130),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
            ),
            child: const Text('저장하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}
