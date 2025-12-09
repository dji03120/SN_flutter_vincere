import 'package:Vincere/http/webReqSpring.dart';

Future<Map<String, dynamic>> getUserGradesData({
  required int userId,
  required Map<String, dynamic>? userData,
  required int userAge,
  required List<Map<String, dynamic>>? muscleAgeData,
}) async {
  int msmt003Grade = 0;
  int msmt008Grade = 0;
  int msmt011Grade = 0;
  int msmt012Grade = 0;
  int msmt013Grade = 0;
  double gradeAvg = 0.0;
  String muscleAge = "--";
  List<Map<String, dynamic>> userGradeData = [];

  try {
    ApiService apiService = ApiService();
    Map<String, dynamic> result = await apiService.fetchGetUserGrades(
      userId.toString(),
      userData?["bym"] ?? '',
    );

    if (result.containsKey('userGradeList')) {
      userGradeData = List<Map<String, dynamic>>.from(result['userGradeList']);

      for (var item in userGradeData) {
        String itemCd = item['MSMT_ITEM_CD'];
        dynamic itemValue = item['GRADE'];

        if (itemValue != null) {
          switch (itemCd) {
            case 'MSMT_003':
              msmt003Grade = itemValue;
              break;
            case 'MSMT_008':
              msmt008Grade = itemValue;
              break;
            case 'MSMT_011':
              msmt011Grade = itemValue;
              break;
            case 'MSMT_012':
              msmt012Grade = itemValue;
              break;
            case 'MSMT_013':
              msmt013Grade = itemValue;
              break;
          }
        }
      }

      // 평균 grade 계산
      if ((msmt003Grade != 0 && msmt008Grade != 0 && msmt011Grade != 0) && userAge < 40) {
        gradeAvg = ((msmt003Grade + msmt008Grade + msmt011Grade) / 3).toDouble();
      } else if ((msmt003Grade != 0 && msmt008Grade != 0 && msmt011Grade != 0 && msmt012Grade != 0 && msmt013Grade != 0) && userAge >= 40) {
        gradeAvg = ((msmt003Grade + msmt008Grade + msmt011Grade + msmt012Grade + msmt013Grade) / 5).toDouble();
      }

      // 근육 나이 계산
      if ((muscleAgeData != null && muscleAgeData.isNotEmpty) && userAge != 0) {
        for (var item in muscleAgeData) {
          double maxGrd = double.tryParse(item['MAX_GRADE'].toString()) ?? 0;
          double minGrd = double.tryParse(item['MIN_GRADE'].toString()) ?? 0;
          double ageAdj = double.tryParse(item['MUSCLE_AGE_ADJ'].toString()) ?? 0;

          if (gradeAvg >= minGrd && gradeAvg <= maxGrd) {
            muscleAge = (userAge + ageAdj).toString();
          }
        }
      }
    }
  } catch (e) {
    print('Error in getUserGradesData: $e');
  }

  // 최종 결과 반환
  return {
    'msmt003Grade': msmt003Grade,
    'msmt008Grade': msmt008Grade,
    'msmt011Grade': msmt011Grade,
    'msmt012Grade': msmt012Grade,
    'msmt013Grade': msmt013Grade,
    'gradeAvg': gradeAvg,
    'muscleAge': muscleAge,
    'userGradeData': userGradeData,
  };
}
