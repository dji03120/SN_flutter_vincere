import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'https://vincerebiohealth.kr/root'; // 운영
  //final String baseUrl = 'http://127.0.0.1:8080'; //root'; // 로컬

  // 2024-08-21 AJG web 통신용 추가

  // app 회원 가입
  Future<Map<String, dynamic>> fetchUserRegist(String userId, String userNm, String bym, String sex, String passWd, String activityLevel, String hpNo, String zipCd, String addr, String addrDtl, String email) async {
    final response = await http.post(
      Uri.parse("$baseUrl/app/registUser.do"),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'userId': userId, 'userNm': userNm, 'bym': bym, 'sex': sex, 'auth': null, 'passWd': passWd, 'activityLevel': activityLevel, 'useYn': 'Y', 'hpNo': hpNo, 'zipCd': zipCd, 'addr': addr, 'addrDtl': addrDtl, 'email': email}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user Regist');
    }
  }

  // 아이디 중복 확인
  Future<Map<String, dynamic>> fetchUserIdDuplication(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getUserIdDuplication.do'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'userId': userId}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to check user ID duplication');
    }
  }

  // app 아이디 문의
  Future<Map<String, dynamic>> fetchIdQnA(String userName, String contactEmail, String contactPhone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/regIdQnA.do'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'userName': userName, 'contactEmail': contactEmail, 'contactPhone': contactPhone}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to add user Id QnA');
    }
  }

  // app 비밀번호 문의
  Future<Map<String, dynamic>> fetchPswdQnA(String userId, String userName, String contactEmail, String contactPhone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/regPswdQnA.do'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
        'userName': userName,
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to add user Pswd QnA');
    }
  }

  // app 로그인
  Future<Map<String, dynamic>> fetchUserLogin(String id, String password) async {
    print(id);
    print(password);
    final response = await http.post(
      Uri.parse('$baseUrl/app/userLogin.do'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'loginId': id, 'loginPass': password}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print(response.body);
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user AddInfo');
    }
  }

  // app 비밀번호 재설정
  Future<Map<String, dynamic>> fetchUpdatePassWd(Map<String, String> requestData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/updatePassWd.do'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user AddInfo');
    }
  }

  // app 회원 추가 정보 등록
  Future<Map<String, dynamic>> fetchUserAddInfo(Map<String, dynamic> addInfo) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/regAddUser.do'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(addInfo),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user AddInfo');
    }
  }

  // 회원 추가 정보 항목 선조회 ( 측정항목 )
  Future<Map<String, dynamic>> fetchMsmtPreInfo(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getMsmtPreInfo.do'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user AddInfo');
    }
  }

  // app 회원 자동 처방 신청
  Future<Map<String, dynamic>> fetchApplyAutoPscp(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/applyAutoPscp.do'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load get User Info');
    }
  }

  // app 회원 정보 조회
  Future<Map<String, dynamic>> fetchGetUserInfo(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getUserInfo.do'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load get User Info');
    }
  }

  // app 회원 마이페이지 정보 조회
  Future<Map<String, dynamic>> fetchGetUserMyPage(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getUserMyPage.do'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'userId': userId}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load get User MyPage');
    }
  }

  // app 회원 마이페이지 정보 수정
  Future<Map<String, dynamic>> fetchUpdateUserMyPage(String userId, String userNm, String email, String hpNo, String bym, String zipCd, String addr, String addrDtl, String activityLevel, String sex) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/updateUserMyPage.do'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'userId': userId, 'userNm': userNm, 'email': email, 'hpNo': hpNo, 'bym': bym, 'zipCd': zipCd, 'addr': addr, 'addrDtl': addrDtl, 'activityLevel': activityLevel, 'sex': sex}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load update User MyPage');
    }
  }

  // app 회원 건강 정보 조회
  Future<Map<String, dynamic>> fetchGetUserHlthInfo(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getMyHlthInfo.do'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load get User Info');
    }
  }

  // app 회원 처방 정보 조회
  Future<Map<String, dynamic>> fetchGetLstPscpInfo(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getLstPscpList.do'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load get User Info');
    }
  }

  // app 회원 건강 정보 이력 조회
  Future<Map<String, dynamic>> fetchGetUserHlthHisInfo(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getMyHlthHisInfo.do'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load get User His Info');
    }
  }

  //fetchGetUserGrades
  Future<Map<String, dynamic>> fetchGetUserGrades(String userId, String bym) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getUserGrades.do'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
        'bym': bym,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load get User His Info');
    }
  }

  // 식품 영양 정보 조회
  Future<Map<String, dynamic>> fetchGetFoodInfo() async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getFoodInfo.do'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'ctgCd': 'INF',
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load get User Info');
    }
  }

  // 나의 필요 영양소 정보 조회
  Future<Map<String, dynamic>> fetchGetMyNutriCheck(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getMyNutriCheck.do'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
        'ctgCd': 'RCM',
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load get User Info');
    }
  }

  // 정보 및 기사 List
  Future<Map<String, dynamic>> fetchGetNewsBoard(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getNewsBoardList.do'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load get User Info');
    }
  }

  // QNA List
  Future<Map<String, dynamic>> fetchGetQna(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getMyQnAList.do'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load get User Info');
    }
  }

  // QNA Regist
  Future<Map<String, dynamic>> fetchRegQna(String userId, String title, String content) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/regMyQnA.do'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
        'title': title,
        'content': content,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load get User Info');
    }
  }

  // QNA View
  Future<Map<String, dynamic>> fetchQnaView(String userId, String noticeCd) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getMyQnA.do'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
        'noticeCd': noticeCd,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load get User Info');
    }
  }

  // QNA Modify
  Future<Map<String, dynamic>> fetchModiQna(String userId, String title, String content, String noticeCd) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/modMyQnA.do'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
        'title': title,
        'content': content,
        'noticeCd': noticeCd,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load get User Info');
    }
  }

  // QNA Remove
  Future<Map<String, dynamic>> fetchDelQna(String noticeCd) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/delMyQnA.do'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'noticeCd': noticeCd,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load get User Info');
    }
  }

  // UserActivityLevel Modify
  Future<Map<String, dynamic>> updateUserActivityLevel(String userId, String activityLevel) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/modUserActivityLevel.do'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
        'activityLevel': activityLevel,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load get User Info');
    }
  }

  // ApiService 클래스에 추가
  Future<Map<String, dynamic>> fetchCalculatedValue(Map<String, dynamic> requestData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/app/calculateValue.do'), // 실제 API 엔드포인트로 수정
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to calculate value');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> uploadProfileImage(
    String userId,
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/app/uploadProfileImage.do'),
      );

      var multipartFile = http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: 'profile_$userId.jpg',
      );

      request.files.add(multipartFile);
      request.fields['userId'] = userId;

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var result = jsonDecode(responseData);

      if (response.statusCode == 200) {
        return result;
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      print('Error uploading profile image: $e');
      throw e;
    }
  }

  // 프로필 이미지 삭제
  Future<Map<String, dynamic>> deleteProfileImage(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/app/deleteProfileImage.do'),
        body: jsonEncode({'userId': userId}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to delete image');
      }
    } catch (e) {
      print('Error deleting profile image: $e');
      throw e;
    }
  }

  // 프로필 이미지 불러오기
  Future<Map<String, dynamic>> fetchProfileImage(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/app/getProfileImage.do'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{'userId': userId}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load profile image');
      }
    } catch (e) {
      print('Error fetching profile image: $e');
      return {'success': false};
    }
  }

  // 쌀 섭취량 입력
  Future<Map<String, dynamic>> insertRiceIntake(
    String userId,
    String mealType,
    double amount,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/app/insertRiceIntake.do'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'mealType': mealType,
          'amount': amount,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to insert rice intake');
      }
    } catch (e) {
      print('Error in insertRiceIntake: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchRiceIntake(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/riceIntake.do'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get rice intake');
    }
  }

  // 추천 식품 리스트
  Future<Map<String, dynamic>> fetchGetRcmdFoodList(double carbsCal, double proteinCal) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getRecFoodList.do'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'carbsCal': carbsCal,
        'proteinCal': proteinCal,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load get User Info');
    }
  }

  // 영양 상세정보
  Future<Map<String, dynamic>> fetchGetNutritionInfo(String foodId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getNutritionInfo.do'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'foodId': foodId}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load get User Info');
    }
  }

  // 차트 데이터 가져오기  getChartData
  Future<Map<String, dynamic>> getChartData(String code, String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getChartData.do'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'code': code,
        'userId': userId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load get User Info');
    }
  }

  // 섭취량 데이터 가져오기
  Future<Map<String, dynamic>> getIntakeData(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getIntakeData.do'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load get User Info');
    }
  }

  Future<Map<String, dynamic>> updateUserHealthData(String userId, List<Map<String, dynamic>> healthData) async {
    final String healthDataJson = json.encode(healthData);

    final Map<String, String> requestData = {
      'userId': userId,
      'healthData': healthDataJson // 배열을 문자열로 변환
    };

    final response = await http.post(
      Uri.parse('$baseUrl/app/updateUserHealthData.do'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load get User Info');
    }
  }

  Future<Map<String, dynamic>> getHealthInfoItems() async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getMsmtItemList.do'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load get User Info');
    }
  }

  Future<Map<String, dynamic>> getLastMstmtDte(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getLastMsmtDte.do'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
      }),
    );

    print("getLastMstmtDte의 resonse 확인 : ${response.body}");
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load get User Info');
    }
  }

  // 근육 나이 리스트 가져오기
  Future<Map<String, dynamic>> getMuscleAgeList() async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getMuscleAgeList.do'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({}),
    );

    print("getMuscleAgeList resonse 확인 : ${response.body}");
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load get User Info');
    }
  }
}
