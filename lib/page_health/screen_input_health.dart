import 'package:Vincere/export/screens.dart';
import 'package:Vincere/http/webReqSpring.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Vincere/component/header.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InputInfoScreen extends StatefulWidget {
  const InputInfoScreen({super.key});

  @override
  _InputInfoScreenState createState() => _InputInfoScreenState();
}

class _InputInfoScreenState extends State<InputInfoScreen> {
  String? userId;
  List<Map<String, dynamic>> msmtPreInfo = [];
  Map<String, TextEditingController> controllers = {};
  Map<String, String?> originalValues = {}; // Store original values for comparison
  bool hasPreSavedData = false; // Track if pre-saved health data is available
  bool isDataSaved = false; // Track if new data has been saved successfully

  bool isHeightEntered = false;
  bool isWeightEntered = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');

    ApiService apiService = ApiService();
    Map<String, dynamic> result = await apiService.fetchMsmtPreInfo(userId.toString());

    if (result.containsKey('getMsmtPreInfo')) {
      setState(() {
        msmtPreInfo = List<Map<String, dynamic>>.from(result['getMsmtPreInfo']);

        // 데이터가 있는지 체크함 : 데이터가 있으면 N, 없으면 Y
        String msmtPreInfoNullYn = (result['getMsmtPreInfoNullYn'] ?? '').toString();
        if (msmtPreInfoNullYn == 'N') {
          hasPreSavedData = true;
        }
        controllers = {
          for (var item in msmtPreInfo)
            if (item['MSMT_ITEM_CD'] != null)
              item['MSMT_ITEM_CD']: TextEditingController(
                text: (item['MSMT_VALUE'] ?? '').toString(), // Handle null values
              )
        };

        originalValues = {for (var item in msmtPreInfo) item['MSMT_ITEM_CD']: item['MSMT_VALUE']?.toString()};
      });
    }
  }

  Future<void> _submitData() async {
    // Check for empty fields
    // ignore: unused_local_variable
    bool hasEmptyFields = false;

    for (var item in msmtPreInfo) {
      String? itemCd = item['MSMT_ITEM_CD'];
      if (itemCd != null && controllers.containsKey(itemCd) && (itemCd != 'MSMT_003' && itemCd != 'MSMT_004')) {
        String? currentValue = controllers[itemCd]?.text;

        if (currentValue == null || currentValue.isEmpty) {
          hasEmptyFields = true;
          break;
        }
      }
    }

    // if (hasEmptyFields) {
    //   _showAlertDialog('입력 오류', '모든 항목을 입력해 주세요.');
    //   return;
    // }

    // Check if no values have been modified
    bool allValuesUnmodified = true;

    for (var item in msmtPreInfo) {
      String? itemCd = item['MSMT_ITEM_CD'];
      if (itemCd != null && controllers.containsKey(itemCd)) {
        String? originalValue = originalValues[itemCd];
        String? currentValue = controllers[itemCd]?.text;

        if (originalValue != currentValue) {
          allValuesUnmodified = false;
          break;
        }
      }
    }

    if (allValuesUnmodified) {
      _showAlertDialog('변경 사항 없음', '이전 건강 정보와 모두 동일합니다.');
    } else {
      Map<String, dynamic> addInfo = {};

      for (var item in msmtPreInfo) {
        String? itemCd = item['MSMT_ITEM_CD'];
        if (itemCd != null && controllers.containsKey(itemCd)) {
          addInfo[itemCd] = controllers[itemCd]?.text;
        }
      }

      Map<String, dynamic> requestData = {
        'userId': userId,
        'addInfo': addInfo,
      };

      try {
        ApiService apiService = ApiService();
        await apiService.fetchUserAddInfo(requestData);
        _showAlertDialog('건강정보 저장', '건강 정보를 저장하였습니다.');
        setState(() {
          isDataSaved = true; // Mark new data as saved
        });
      } catch (e) {
        _showAlertDialog('처리에 실패했습니다.', e.toString());
        setState(() {
          isDataSaved = false; // Mark data as not saved
        });
      }
    }
  }

  // ignore: unused_element
  Future<void> _autoPscp() async {
    if (!hasPreSavedData && !isDataSaved) {
      _showAlertDialog('오류', '건강 정보를 먼저 저장하거나 조회된 건강 정보가 있어야 자동 처방을 신청할 수 있습니다.');
      return;
    }

    // Show confirmation dialog based on whether it's pre-saved or newly saved data
    bool proceed = await _showConfirmationDialog();

    if (!proceed) {
      return; // Do not proceed if the user selected "No"
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');

    try {
      ApiService apiService = ApiService();
      Map<String, dynamic> response = await apiService.fetchApplyAutoPscp(userId!);
      if (response["result"] == 0) {
        _showAlertDialog('자동 처방 신청', '자동 처방 신청을 실패했습니다. 관리자에게 문의해주세요.');
      } else {
        _showAlertToHome('자동 처방 신청', '자동 처방 신청을 완료했습니다.');
      }
    } catch (e) {
      _showAlertDialog('처리에 실패했습니다.', e.toString());
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('자동 처방 신청'),
          content: Text(
            hasPreSavedData && !isDataSaved ? '기존 건강 정보로 자동 처방을 진행하시겠습니까?' : '신규 건강 정보로 자동 처방을 진행하시겠습니까?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Return false if "No"
              },
              child: const Text('아니오'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Return true if "Yes"
              },
              child: const Text('네'),
            ),
          ],
        );
      },
    );
  }

  void _showAlertDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  void _showAlertToHome(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => MyHomePage(title: "vincere_App"))); // Close the dialog and navigate to home
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  // 여기에 _buildFormField 추가
  Widget _buildFormField(Map<String, dynamic> item) {
    String itemCode = item['MSMT_ITEM_CD'] ?? '';
    bool isCalculatedField = (item['MSMT_ITEM_NM']?.toString() ?? '').contains('신체질량지수') || (item['MSMT_ITEM_NM']?.toString() ?? '').contains('표준체중');

    if (isCalculatedField) {
      return Column(
        children: [
          TextFormField(
            controller: controllers[item['MSMT_ITEM_CD']],
            readOnly: true,
            enabled: false,
            textAlign: TextAlign.end,
            decoration: InputDecoration(
              labelText: item['MSMT_ITEM_NM'] ?? 'Unknown',
              suffixText: item['MSMT_UNIT'] ?? '',
              counterText: '',
              filled: true,
              fillColor: Colors.grey[200],
              disabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[400]!),
              ),
            ),
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 15.0,
            ),
          ),
          const SizedBox(height: 30.0),
        ],
      );
    }

    // 일반 입력 필드
    return Column(
      children: [
        TextFormField(
          controller: controllers[itemCode],
          autofocus: true,
          maxLength: 10,
          textAlign: TextAlign.end,
          onEditingComplete: () {
            // 키보드 닫기
            FocusScope.of(context).unfocus();
          },
          onChanged: (value) {
            setState(() {
              // 각 필드의 입력 상태 업데이트
              if ((itemCode == 'MSMT_001') || (itemCode == 'MSMT_002')) {
                isHeightEntered = value.isNotEmpty;
                isWeightEntered = value.isNotEmpty;
              }

              // 값이 비어있는 경우 계산된 필드 초기화
              if ((itemCode == 'MSMT_001' || itemCode == 'MSMT_002') && value.isEmpty) {
                if (controllers['MSMT_003'] != null) {
                  controllers['MSMT_003']!.text = '';
                }
                if (controllers['MSMT_004'] != null) {
                  controllers['MSMT_004']!.text = '';
                }
              }

              // 두 필드가 모두 입력되었는지 확인하고 계산 실행
              if (isHeightEntered && isWeightEntered) {
                _checkAndCalculate();
              }
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '숫자를 입력하세요.';
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: item['MSMT_ITEM_NM'] ?? 'Unknown',
            suffixText: item['MSMT_UNIT'] ?? '',
            counterText: '',
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')), // 숫자와 온점만 허용
            TextInputFormatter.withFunction((oldValue, newValue) {
              // 온점이 하나만 있도록 검사
              if (newValue.text.isEmpty) {
                return newValue;
              }
              if (newValue.text.contains('.')) {
                if (newValue.text.indexOf('.') != newValue.text.lastIndexOf('.')) {
                  return oldValue;
                }
              }
              return newValue;
            }),
          ],
        ),
        const SizedBox(height: 30.0),
      ],
    );
  }

  // 새로운 메서드 추가
  void _checkAndCalculate() {
    String? msmt001Value = controllers['MSMT_001']?.text; // 키
    String? msmt002Value = controllers['MSMT_002']?.text; // 몸무게

    // MSMT_001과 MSMT_002가 모두 입력되었는지 확인
    if (msmt001Value != null && msmt001Value.isNotEmpty && msmt002Value != null && msmt002Value.isNotEmpty) {
      _calculateValue(msmt001Value, msmt002Value).then((result) {
        setState(() {
          // BMI 값 설정
          if (controllers['MSMT_003'] != null && result['bmi'] != null) {
            controllers['MSMT_003']!.text = result['bmi'].toString();
          }

          // 표준체중 값 설정
          if (controllers['MSMT_004'] != null && result['stdWeight'] != null) {
            controllers['MSMT_004']!.text = result['stdWeight'].toString();
          }
        });
      });
    }
  }

  // 여기에 _calculateValue 메서드 추가
  Future<Map<String, dynamic>> _calculateValue(String height, String weight) async {
    try {
      ApiService apiService = ApiService();
      Map<String, dynamic> requestData = {'userId': userId, 'height': height, 'weight': weight};

      // API 호출하여 계산된 값 가져오기
      Map<String, dynamic> result = await apiService.fetchCalculatedValue(requestData);
      return {'bmi': result['bmi'], 'stdWeight': result['stdWeight']};
    } catch (e) {
      print('Error calculating value: $e');
      return {'bmi': '오류 발생', 'stdWeight': '오류 발생'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Header(),
      body: Column(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: 50,
            child: const Padding(
              padding: EdgeInsets.fromLTRB(20, 15, 0, 0),
              child: Text(
                '나의 건강 정보 입력',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
            ),
          ),
          Expanded(
            // Container를 Expanded로 변경
            child: SingleChildScrollView(
              // SingleChildScrollView 위치 변경
              child: Container(
                color: Colors.amber,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    width: double.infinity,
                    color: Colors.white,
                    child: Column(
                      children: [
                        Form(
                          child: Theme(
                            data: ThemeData(
                              primaryColor: Colors.grey,
                              inputDecorationTheme: const InputDecorationTheme(
                                labelStyle: TextStyle(color: Colors.black, fontSize: 15.0),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(40.0),
                              child: Builder(builder: (context) {
                                return Column(
                                  children: [
                                    Column(
                                      children: [
                                        for (var item in msmtPreInfo) _buildFormField(item), // 정의한 _buildFormField 메서드 사용
                                      ],
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
                        Padding(
                          // 버튼들의 패딩 추가
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: _submitData,
                                child: const Text('저장'),
                              ),
                              const SizedBox(width: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
