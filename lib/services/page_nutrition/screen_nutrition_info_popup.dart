// nutrition_info_popup.dart
import 'package:flutter/material.dart';

class NutritionInfoPopup extends StatelessWidget {
  final String foodName;
  final Map<String, dynamic> result;

  const NutritionInfoPopup({
    Key? key,
    required this.foodName,
    required this.result,
  }) : super(key: key);

  // 영양소 정보를 매핑하는 메서드
  List<Map<String, String>> _getNutritionInfo() {
    // result의 nutritionInfoList를 가져옴
    List<dynamic> nutritionList = result['nutritionInfoList'] as List<dynamic>;

    // 값이 비어있거나 '-'인 항목은 제외하고 매핑
    return nutritionList
        .where((item) =>
    item['NUTRITION_VALUE'] != null &&
        item['NUTRITION_VALUE'].toString() != '' &&
        item['NUTRITION_VALUE'].toString() != '-')
        .map((item) {
      // 값이 수치인 경우 소수점 처리
      var value = item['NUTRITION_VALUE'];
      String formattedValue;
      if (value is num) {
        formattedValue = value < 1 ? value.toStringAsFixed(2) : value.toStringAsFixed(1);
      } else {
        formattedValue = value.toString();
      }

      return {
        'name': item['NUTRITION_NAME'].toString(),
        'value': formattedValue,
      };
    })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final nutritionInfo = _getNutritionInfo();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: SingleChildScrollView( // 스크롤 가능하도록 추가
        child: Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // 기본 텍스트 색상
                  ),
                  children: [
                    TextSpan(
                      text: '$foodName의 ',
                      style: TextStyle(
                          color: Color(0xFF000000),
                          fontSize: 20,
                          fontWeight: FontWeight.w600
                      ),
                    ),
                    TextSpan(
                      text: '영양정보',
                      style: TextStyle(
                          color: Color(0xFF00914B), // 검정색
                          fontSize: 20,
                          fontWeight: FontWeight.w600
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              // 영양정보 목록
              ...nutritionInfo.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                          item['name']!,
                          style:
                            TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF555555)
                            ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        item['value']!,
                        textAlign: TextAlign.right,
                        style:
                          TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF555555)
                          ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
              const SizedBox(height: 16.0),
              // 닫기 버튼
              Container(
                margin: EdgeInsets.only(bottom: 8.0),  // 하단 여백 16 추가
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('닫기', style: TextStyle(color: Colors.white),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF007130),
                    minimumSize: Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}