import 'package:Vincere/http/webReq.dart';
import 'package:Vincere/component/header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Vincere/screen/screen_home.dart';

class ScreenHealthInfo extends StatefulWidget {
  final List<Map<String, dynamic>> healthData;
  final List<Map<String, dynamic>> msmtItemData; // final 변수 선언
  final Future healthInfoItemsFuture; // 추가
  final String? userId; // 추가
  final Function initializeData; // 추가

  const ScreenHealthInfo({
    Key? key,
    List<Map<String, dynamic>>? healthData, // optional로 변경
    List<Map<String, dynamic>>? msmtItemData, // optional 파라미터 추가
    required this.healthInfoItemsFuture,
    required this.userId,
    required this.initializeData,
  })  : this.healthData = healthData ?? const [], // 기본값 빈 리스트 설정
        this.msmtItemData = msmtItemData ?? const [], // 기본값 빈 리스트로 초기화
        super(key: key);

  @override
  _ScreenHealthInfoState createState() => _ScreenHealthInfoState();
}

class _ScreenHealthInfoState extends State<ScreenHealthInfo> {
  late List<Map<String, dynamic>> _editedHealthData;
  late List<Map<String, dynamic>> _editMsmtItemData;
  List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    // _editedHealthData = List<Map<String, dynamic>>.from(widget.healthData);
    getDefaultHealthData();
    // _editedHealthData = widget.healthData.isEmpty
    //     ? getDefaultHealthData()
    //     : List<Map<String, dynamic>>.from(widget.healthData);
    _editedHealthData = getDefaultHealthData();
    print("widget.healthData 확인 : ${widget.healthData}");
    print("_editedHealthData:$_editedHealthData");
    // 각 필드별로 기존 값을 가진 컨트롤러 생성
    _controllers = List.generate(
        _editedHealthData.length,
        (index) => TextEditingController(text: _editedHealthData[index]['MSMT_VALUE']?.toString() ?? '' // 기존 값을 초기값으로 설정
            ));
  }

  @override
  void dispose() {
    // 메모리 누수 방지를 위한 컨트롤러 dispose
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<Map<String, dynamic>> getDefaultHealthData() {
    print("widget.msmtItemData : ${widget.msmtItemData}");
    print("widget.healthData : ${widget.healthData}");

    _editMsmtItemData = widget.msmtItemData
        .where((item) => item['USE_YN'] == 'Y') // USE_YN이 Y인 항목만 필터링
        .map((item) => {'MSMT_ITEM_CD': item['MSMT_ITEM_CD'], 'MSMT_ITEM_NM': item['MSMT_ITEM_NM'], 'MSMT_VALUE': item['MSMT_VALUE'] ?? '', 'MSMT_UNIT': item['MSMT_UNIT'] ?? ''})
        .toList();

    // widget.healthData 값이 null이면 _editMsmtItemData 초기값 반환,
    // null이 아닌 경우, widget.healthData 데이터 갯수만큼 반복문 돌려서
    // _editMsmtItemData에 값 세팅

    // widget.healthData가 null이 아니고 비어있지 않은 경우
    // ignore: unnecessary_null_comparison
    if (widget.healthData != null && widget.healthData.isNotEmpty) {
      // _editMsmtItemData를 순회하면서 healthData의 값으로 업데이트
      for (var item in _editMsmtItemData) {
        // healthData에서 matching되는 항목 찾기
        final healthItem = widget.healthData.firstWhere(
          (healthItem) => healthItem['MSMT_ITEM_CD'] == item['MSMT_ITEM_CD'],
          orElse: () => <String, dynamic>{}, // 빈 Map 반환
        );

        // healthItem이 비어있지 않고 MSMT_VALUE가 있는 경우에만 업데이트
        if (healthItem.isNotEmpty && healthItem['MSMT_VALUE'] != null) {
          item['MSMT_VALUE'] = healthItem['MSMT_VALUE'].toString();
        }
      }
    }

    return _editMsmtItemData;
  }

  double? getValueByCode(List<Map<String, dynamic>> healthData, String code) {
    final value = healthData.firstWhere(
      (item) => item['MSMT_ITEM_CD'] == code,
      orElse: () => {'MSMT_VALUE': null},
    )['MSMT_VALUE'];

    // value가 String일 경우 double로 변환 시도
    if (value is String) {
      return double.tryParse(value);
    } else if (value is double) {
      return value;
    }

    return null; // value가 null이거나 변환에 실패한 경우
  }

  void updateCalculatedValues(List<Map<String, dynamic>> healthData) {
    double? height = getValueByCode(healthData, 'MSMT_001');
    double? weight = getValueByCode(healthData, 'MSMT_002');
    double? fatPercentage = getValueByCode(healthData, 'MSMT_008');

    if (height != null && weight != null) {
      double heightInMeters = height / 100;
      double bmi = weight / (heightInMeters * heightInMeters);
      double stdWeight = (height - 100) * 0.9;

      // BMI와 표준 체중 값을 업데이트
      updateValueByCode(healthData, 'MSMT_003', bmi.toStringAsFixed(1));
      updateValueByCode(healthData, 'MSMT_004', stdWeight.toStringAsFixed(1));
    }

    if (weight != null && fatPercentage != null) {
      double fatMass = weight * fatPercentage / 100;
      double muscleMass = weight - fatMass;

      // 근육량 값을 업데이트
      updateValueByCode(healthData, 'MSMT_010', muscleMass.toStringAsFixed(1));
    }
  }

  void updateValueByCode(List<Map<String, dynamic>> healthData, String code, String value) {
    final index = healthData.indexWhere((item) => item['MSMT_ITEM_CD'] == code);
    if (index != -1) {
      setState(() {
        healthData[index]['MSMT_VALUE'] = value; // _editedHealthData 업데이트
        _controllers[index].text = value; // 컨트롤러 동기화
      });
    }
  }

  InputDecoration getInputDecoration(String hint, bool isReadOnly, String? unit) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8F9FB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(
          color: Color(0xFFEDEDED),
          width: 1.0,
        ),
      ),
      suffix: unit != null
          ? Padding(
              padding: const EdgeInsets.only(right: 0),
              child: Text(
                unit,
                style: const TextStyle(
                  color: Color(0xFF8D8D8D),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            )
          : null,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(
          color: Color(0xFFEDEDED),
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(
          color: Color(0xFFEDEDED),
          width: 1.0,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(
          color: Color(0xFFEDEDED),
          width: 1.0,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      hintStyle: const TextStyle(
        color: Color(0xFF8D8D8D),
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    int index = 0;

    TextStyle textStyleFont16w500 = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
    );

    children.add(
      const Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: Text('My 건강정보 입력하기',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ))),
    );
    while (index < _editedHealthData.length) {
      if (index < _editedHealthData.length && _editedHealthData[index]['MSMT_ITEM_CD'] == 'MSMT_001' && index + 1 < _editedHealthData.length && _editedHealthData[index + 1]['MSMT_ITEM_CD'] == 'MSMT_002') {
        // 키와 몸무게를 Row로 배치
        int areaidx = index;
        int areaidx2 = index + 1;
        children.add(
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_editedHealthData[index]['MSMT_ITEM_NM'] ?? '항목명 없음', style: textStyleFont16w500),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _controllers[index], // controller 사용
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                      ],
                      decoration: getInputDecoration(
                        '',
                        false,
                        _editedHealthData[index]['MSMT_UNIT'],
                      ),
                      onChanged: (value) {
                        setState(() {
                          print("value:$value");
                          print("areaidx:$areaidx");
                          _editedHealthData[areaidx]['MSMT_VALUE'] = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_editedHealthData[index + 1]['MSMT_ITEM_NM'] ?? '항목명 없음', style: textStyleFont16w500),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _controllers[index + 1],
                      //initialValue: _editedHealthData[index+1]['MSMT_VALUE']?.toString() ?? '',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')), // 숫자와 소수점만 허용
                      ],
                      decoration: getInputDecoration(
                        '',
                        false,
                        _editedHealthData[index + 1]['MSMT_UNIT'],
                      ),
                      onChanged: (value) {
                        setState(() {
                          print("value:$value");
                          print("index:$index");
                          _editedHealthData[areaidx2]['MSMT_VALUE'] = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        children.add(const SizedBox(height: 0)); // 간격 수정
        index += 2; // 두 항목을 처리했으므로 2 증가
      } else if (_editedHealthData[index]['MSMT_ITEM_CD'] == 'MSMT_005' && index + 2 < _editedHealthData.length && _editedHealthData[index + 1]['MSMT_ITEM_CD'] == 'MSMT_006' && _editedHealthData[index + 2]['MSMT_ITEM_CD'] == 'MSMT_007') {
        print("index:$index");
        int areaidx = index;
        // 간수치 ALT, AST, ALP를 Row로 배치
        children.add(const SizedBox(height: 30)); // 간격 수정
        children.add(
          Row(
            children: [
              for (int i = 0; i < 3; i++) ...[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_editedHealthData[index + i]['MSMT_ITEM_NM'] ?? '항목명 없음', style: textStyleFont16w500),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _controllers[index + i],
                        //initialValue: _editedHealthData[index + i]['MSMT_VALUE']?.toString() ?? '', // index + i로 변경
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')), // 숫자와 소수점만 허용
                        ],
                        decoration: getInputDecoration(
                          '',
                          false,
                          _editedHealthData[index + i]['MSMT_UNIT'],
                        ),
                        onChanged: (value) {
                          setState(() {
                            print("value:$value");
                            print("index:$index");
                            _editedHealthData[areaidx + i]['MSMT_VALUE'] = value; // index + i로 변경
                          });
                        },
                      ),
                    ],
                  ),
                ),
                if (i < 2) const SizedBox(width: 8), // 두 필드 사이 여백
              ],
            ],
          ),
        );
        children.add(const SizedBox(height: 0)); // 간격 수정
        index += 3; // 세 항목을 처리했으므로 index를 3 증가
      } else if (_editedHealthData[index]['MSMT_ITEM_CD'] == 'MSMT_010' && index + 1 < _editedHealthData.length && _editedHealthData[index + 1]['MSMT_ITEM_CD'] == 'MSMT_011') {
        int areaidx = index;
        int areaidx2 = index + 1;
        children.add(const SizedBox(height: 30)); // 간격 추가
        // 근육량과 악력을 Row로 배치
        children.add(
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_editedHealthData[index]['MSMT_ITEM_NM'] ?? '항목명 없음', style: textStyleFont16w500),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _controllers[index],
                      //initialValue: _editedHealthData[index]['MSMT_VALUE']?.toString() ?? '',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')), // 숫자와 소수점만 허용
                      ],
                      enabled: _editedHealthData[index]['MSMT_ITEM_CD'] != 'MSMT_010',
                      decoration: getInputDecoration(
                        '',
                        false,
                        _editedHealthData[index]['MSMT_UNIT'],
                      ),
                      onChanged: (value) {
                        setState(() {
                          _editedHealthData[areaidx]['MSMT_VALUE'] = value; // 정확히 index 데이터 참조
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8), // 두 필드 사이 여백
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_editedHealthData[index + 1]['MSMT_ITEM_NM'] ?? '항목명 없음', style: textStyleFont16w500),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _controllers[index + 1],
                      //initialValue: _editedHealthData[index + 1]['MSMT_VALUE']?.toString() ?? '',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')), // 숫자와 소수점만 허용
                      ],
                      decoration: getInputDecoration(
                        '',
                        false,
                        _editedHealthData[index + 1]['MSMT_UNIT'],
                      ),
                      onChanged: (value) {
                        setState(() {
                          _editedHealthData[areaidx2]['MSMT_VALUE'] = value; // 정확히 index + 1 데이터 참조
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        children.add(const SizedBox(height: 30)); // Row 밑 간격 추가
        index += 2; // 두 항목을 처리했으므로 index를 2 증가
      } else if (_editedHealthData[index]['MSMT_ITEM_CD'] == 'MSMT_012' && index + 1 < _editedHealthData.length && _editedHealthData[index + 1]['MSMT_ITEM_CD'] == 'MSMT_013') {
        int areaidx = index;
        int areaidx2 = index + 1;
        // 근육량과 악력을 Row로 배치
        children.add(
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_editedHealthData[index]['MSMT_ITEM_NM'] ?? '항목명 없음', style: textStyleFont16w500),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _controllers[index],
                      //initialValue: _editedHealthData[index]['MSMT_VALUE']?.toString() ?? '', // index만 참조
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')), // 숫자와 소수점만 허용
                      ],
                      decoration: getInputDecoration(
                        '',
                        false,
                        _editedHealthData[index]['MSMT_UNIT'],
                      ),
                      onChanged: (value) {
                        setState(() {
                          _editedHealthData[areaidx]['MSMT_VALUE'] = value; // index만 참조
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8), // 두 필드 사이 여백
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_editedHealthData[index + 1]['MSMT_ITEM_NM'] ?? '항목명 없음', style: textStyleFont16w500),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _controllers[index + 1],
                      //initialValue: _editedHealthData[index + 1]['MSMT_VALUE']?.toString() ?? '', // index + 1로 변경
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')), // 숫자와 소수점만 허용
                      ],
                      decoration: getInputDecoration(
                        '',
                        false,
                        _editedHealthData[index + 1]['MSMT_UNIT'],
                      ),
                      onChanged: (value) {
                        setState(() {
                          _editedHealthData[areaidx2]['MSMT_VALUE'] = value; // index + 1로 변경
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        children.add(const SizedBox(height: 30)); // Row 밑 간격 추가
        index += 2; // 두 항목을 처리했으므로 index를 2 증가
      } else if (_editedHealthData[index]['MSMT_ITEM_CD'] == 'MSMT_014' && index + 1 < _editedHealthData.length && _editedHealthData[index + 1]['MSMT_ITEM_CD'] == 'MSMT_015') {
        int areaidx = index;
        int areaidx2 = index + 1;
        // 혈당과 혈압을 Row로 배치
        children.add(
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_editedHealthData[index]['MSMT_ITEM_NM'] ?? '항목명 없음', style: textStyleFont16w500),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _controllers[index],
                      //initialValue: _editedHealthData[index]['MSMT_VALUE']?.toString() ?? '',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')), // 숫자와 소수점만 허용
                      ],
                      decoration: getInputDecoration(
                        '',
                        false,
                        _editedHealthData[index]['MSMT_UNIT'],
                      ),
                      onChanged: (value) {
                        setState(() {
                          _editedHealthData[areaidx]['MSMT_VALUE'] = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8), // 두 필드 사이 여백
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_editedHealthData[index + 1]['MSMT_ITEM_NM'] ?? '항목명 없음', style: textStyleFont16w500),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _controllers[index + 1],
                      //initialValue: _editedHealthData[index + 1]['MSMT_VALUE']?.toString() ?? '',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d{0,3}(\/\d{0,3})?$'), // 숫자 최대 3자리 + 슬래시 + 숫자 최대 3자리 허용
                        ),
                      ],
                      decoration: getInputDecoration(
                        '',
                        false,
                        _editedHealthData[index + 1]['MSMT_UNIT'],
                      ),
                      onChanged: (value) {
                        setState(() {
                          _editedHealthData[areaidx2]['MSMT_VALUE'] = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        children.add(const SizedBox(height: 0)); // Row 밑 간격 추가
        index += 2; // 두 항목을 처리했으므로 2 증가
      } else {
        int areaidx = index;
        int areaidx2 = index + 1;
        // 일반적인 항목 처리
        children.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30), // 간격 수정
              Text(_editedHealthData[index]['MSMT_ITEM_NM'] ?? '항목명 없음', style: textStyleFont16w500),
              const SizedBox(height: 8),
              TextFormField(
                controller: _controllers[index],
                //initialValue: _editedHealthData[index]['MSMT_VALUE']?.toString() ?? '',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')), // 숫자와 소수점만 허용
                ],
                enabled: _editedHealthData[index]['MSMT_ITEM_CD'] != 'MSMT_003' && _editedHealthData[index]['MSMT_ITEM_CD'] != 'MSMT_004' && _editedHealthData[index]['MSMT_ITEM_CD'] != 'MSMT_010',
                decoration: getInputDecoration(
                  '',
                  false,
                  _editedHealthData[index]['MSMT_UNIT'],
                ),
                onChanged: (value) {
                  setState(() {
                    _editedHealthData[areaidx]['MSMT_VALUE'] = value;
                  });
                },
              ),
            ],
          ),
        );
        index++; // 일반 항목은 1 증가
      }
    }

    return Scaffold(
      appBar: const Header(),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Form(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
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
                updateCalculatedValues(_editedHealthData);
                final List<Map<String, dynamic>> updateData = _editedHealthData
                    .map((item) => {
                          'MSMT_ITEM_CD': item['MSMT_ITEM_CD'],
                          'MSMT_VALUE': item['MSMT_VALUE'], // 수정된 값만 포함
                        })
                    .toList();
                print("API로 전달할 데이터: $updateData");

                // API 호출
                ApiService apiService = ApiService();
                Map<String, dynamic> result = await apiService.updateUserHealthData(
                  widget.userId!,
                  updateData,
                );

                // 결과 처리
                if (result["result"] > 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('건강정보가 성공적으로 업데이트되었습니다.'),
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.green,
                    ),
                  );

                  widget.initializeData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('업데이트 중 오류가 발생했습니다.'),
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                print("저장 중 오류 발생: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('알 수 없는 오류가 발생했습니다.'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007130),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
            ),
            child: const Text(
              '저장하기',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
