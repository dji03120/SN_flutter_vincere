// Spring API 통신과 프로필 이미지 응답 정규화를 위한 기능

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  final String baseUrl = 'https://vincerebiohealth.kr/root'; // 운영
  dynamic header = {'Content-Type': 'application/json'};
  // final String baseUrl = 'http://127.0.0.1:8080'; //root'; // 로컬
  Uri get _baseUri => Uri.parse(baseUrl);

  // 2024-08-21 AJG web 통신용 추가

  dynamic checkResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        return json.decode(response.body);
      } catch (e) {
        throw Exception('Failed to decode JSON: ${e.toString()}');
      }
    } else {
      throw Exception(
        'Request failed with status: ${response.statusCode}, body: ${response.body}',
      );
    }
  }

  // app 회원 가입
  Future<Map<String, dynamic>> fetchUserRegist(String userId, String userNm, String bym, String sex, String passWd, String activityLevel, String hpNo, String zipCd, String addr, String addrDtl, String email) async {
    final response = await http.post(
      Uri.parse("$baseUrl/app/registUser.do"),
      headers: header,
      body: json.encode({'userId': userId, 'userNm': userNm, 'bym': bym, 'sex': sex, 'auth': null, 'passWd': passWd, 'activityLevel': activityLevel, 'useYn': 'Y', 'hpNo': hpNo, 'zipCd': zipCd, 'addr': addr, 'addrDtl': addrDtl, 'email': email}),
    );

    return checkResponse(response);
  }

  // 아이디 중복 확인
  Future<Map<String, dynamic>> fetchUserIdDuplication(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getUserIdDuplication.do'),
      headers: header,
      body: json.encode({'userId': userId}),
    );
    return checkResponse(response);
  }

  // app 아이디 문의
  Future<Map<String, dynamic>> fetchIdQnA(String userName, String contactEmail, String contactPhone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/regIdQnA.do'),
      headers: header,
      body: json.encode({'userName': userName, 'contactEmail': contactEmail, 'contactPhone': contactPhone}),
    );
    return checkResponse(response);
  }

  // app 비밀번호 문의
  Future<Map<String, dynamic>> fetchPswdQnA(String userId, String userName, String contactEmail, String contactPhone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/regPswdQnA.do'),
      headers: header,
      body: json.encode({
        'userId': userId,
        'userName': userName,
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
      }),
    );

    return checkResponse(response);
  }

  // app 로그인
  Future<Map<String, dynamic>> fetchUserLogin(String id, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/userLogin.do'),
      headers: header,
      body: json.encode({'loginId': id, 'loginPass': password}),
    );
    print(json.decode(response.body));

    return checkResponse(response);
  }

  // app 비밀번호 재설정
  Future<Map<String, dynamic>> fetchUpdatePassWd(Map<String, String> requestData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/updatePassWd.do'),
      headers: header,
      body: json.encode(requestData),
    );
    return checkResponse(response);
  }

  // app 회원 추가 정보 등록
  Future<Map<String, dynamic>> fetchUserAddInfo(Map<String, dynamic> addInfo) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/regAddUser.do'),
      headers: header,
      body: json.encode(addInfo),
    );
    return checkResponse(response);
  }

  // 회원 추가 정보 항목 선조회 ( 측정항목 )
  Future<Map<String, dynamic>> fetchMsmtPreInfo(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getMsmtPreInfo.do'),
      headers: header,
      body: json.encode({'userId': userId}),
    );
    return checkResponse(response);
  }

  // app 회원 자동 처방 신청
  Future<Map<String, dynamic>> fetchApplyAutoPscp(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/applyAutoPscp.do'),
      headers: header,
      body: json.encode({
        'userId': userId,
      }),
    );

    return checkResponse(response);
  }

  // app 회원 정보 조회
  Future<Map<String, dynamic>> fetchGetUserInfo(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getUserInfo.do'),
      headers: header,
      body: json.encode({
        'userId': userId,
      }),
    );

    return checkResponse(response);
  }

  // app 회원 마이페이지 정보 조회
  Future<Map<String, dynamic>> fetchGetUserMyPage(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getUserMyPage.do'),
      headers: header,
      body: json.encode({'userId': userId}),
    );

    return checkResponse(response);
  }

  // app 회원 마이페이지 정보 수정
  Future<Map<String, dynamic>> fetchUpdateUserMyPage(String userId, String userNm, String email, String hpNo, String bym, String zipCd, String addr, String addrDtl, String activityLevel, String sex) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/updateUserMyPage.do'),
      headers: header,
      body: json.encode({'userId': userId, 'userNm': userNm, 'email': email, 'hpNo': hpNo, 'bym': bym, 'zipCd': zipCd, 'addr': addr, 'addrDtl': addrDtl, 'activityLevel': activityLevel, 'sex': sex}),
    );

    return checkResponse(response);
  }

  // app 회원 건강 정보 조회
  Future<Map<String, dynamic>> fetchGetUserHlthInfo(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getMyHlthInfo.do'),
      headers: header,
      body: json.encode({
        'userId': userId,
      }),
    );

    return checkResponse(response);
  }

  // app 회원 처방 정보 조회
  Future<Map<String, dynamic>> fetchGetLstPscpInfo(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getLstPscpList.do'),
      headers: header,
      body: json.encode({
        'userId': userId,
      }),
    );

    return checkResponse(response);
  }

  // app 회원 건강 정보 이력 조회
  Future<Map<String, dynamic>> fetchGetUserHlthHisInfo(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getMyHlthHisInfo.do'),
      headers: header,
      body: json.encode({
        'userId': userId,
      }),
    );

    return checkResponse(response);
  }

  //fetchGetUserGrades
  Future<Map<String, dynamic>> fetchGetUserGrades(String userId, String bym) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getUserGrades.do'),
      headers: header,
      body: json.encode({
        'userId': userId,
        'bym': bym,
      }),
    );

    return checkResponse(response);
  }

  // 식품 영양 정보 조회
  Future<Map<String, dynamic>> fetchGetFoodInfo() async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getFoodInfo.do'),
      headers: header,
      body: json.encode({
        'ctgCd': 'INF',
      }),
    );

    return checkResponse(response);
  }

  // 나의 필요 영양소 정보 조회
  Future<Map<String, dynamic>> fetchGetMyNutriCheck(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getMyNutriCheck.do'),
      headers: header,
      body: json.encode({
        'userId': userId,
        'ctgCd': 'RCM',
      }),
    );

    return checkResponse(response);
  }

  // 정보 및 기사 List
  Future<Map<String, dynamic>> fetchGetNewsBoard(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getNewsBoardList.do'),
      headers: header,
      body: json.encode({
        'userId': userId,
      }),
    );

    return checkResponse(response);
  }

  // QNA List
  Future<Map<String, dynamic>> fetchGetQna(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getMyQnAList.do'),
      headers: header,
      body: json.encode({
        'userId': userId,
      }),
    );

    return checkResponse(response);
  }

  // QNA Regist
  Future<Map<String, dynamic>> fetchRegQna(String userId, String title, String content) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/regMyQnA.do'),
      headers: header,
      body: json.encode({
        'userId': userId,
        'title': title,
        'content': content,
      }),
    );

    return checkResponse(response);
  }

  // QNA View
  Future<Map<String, dynamic>> fetchQnaView(String userId, String noticeCd) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getMyQnA.do'),
      headers: header,
      body: json.encode({
        'userId': userId,
        'noticeCd': noticeCd,
      }),
    );
    return checkResponse(response);
  }

  // QNA Modify
  Future<Map<String, dynamic>> fetchModiQna(String userId, String title, String content, String noticeCd) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/modMyQnA.do'),
      headers: header,
      body: json.encode({
        'userId': userId,
        'title': title,
        'content': content,
        'noticeCd': noticeCd,
      }),
    );
    return checkResponse(response);
  }

  // QNA Remove
  Future<Map<String, dynamic>> fetchDelQna(String noticeCd) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/delMyQnA.do'),
      headers: header,
      body: json.encode({
        'noticeCd': noticeCd,
      }),
    );
    return checkResponse(response);
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

      final normalizedFileName = _profileImageFileName(userId, fileName, imageBytes);
      final contentType = _profileImageContentType(fileName, imageBytes);

      var multipartFile = http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: normalizedFileName,
        contentType: contentType,
      );

      request.files.add(multipartFile);
      request.fields['userId'] = userId;

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var result = jsonDecode(responseData);

      if (response.statusCode == 200) {
        return result is Map<String, dynamic> ? normalizeProfileImageResponse(result) : {'success': false};
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}, $responseData');
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
        headers: header,
      );

      final result = checkResponse(response);
      return result is Map<String, dynamic> ? normalizeProfileImageResponse(result) : {'success': false};
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

      final result = checkResponse(response);
      return result is Map<String, dynamic> ? normalizeProfileImageResponse(result) : {'success': false};
    } catch (e) {
      print('Error fetching profile image: $e');
      return {'success': false};
    }
  }

  // 프로필 이미지 API 응답 형식을 앱 내부 형식으로 맞추기 위한 기능
  Map<String, dynamic> normalizeProfileImageResponse(Map<String, dynamic> response) {
    final normalized = Map<String, dynamic>.from(response);
    final imageUrl = extractProfileImageUrl(response);
    normalized['success'] = _isSuccessResponse(response) || imageUrl != null;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      normalized['imageUrl'] = imageUrl;
    }

    return normalized;
  }

  // 서버가 내려주는 다양한 이미지 URL 키를 하나로 추출하기 위한 기능
  String? extractProfileImageUrl(Map<String, dynamic> response) {
    final directUrl = _firstStringValue(response, const ['imageUrl', 'profileImageUrl', 'profileImgUrl', 'fileUrl', 'url', 'path']);
    if (directUrl != null) {
      return _normalizeProfileImageUrl(directUrl);
    }

    final result = response['result'];
    if (result is Map<String, dynamic>) {
      return extractProfileImageUrl(result);
    }
    if (result is String && result.trim().isNotEmpty) {
      return _normalizeProfileImageUrl(result);
    }

    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return extractProfileImageUrl(data);
    }

    return null;
  }

  // 서버의 성공 플래그 표현을 bool 값으로 변환하기 위한 기능
  bool _isSuccessResponse(Map<String, dynamic> response) {
    final value = response['success'] ?? response['status'] ?? response['code'];
    if (value is bool) return value;
    if (value is num) return value == 1 || value == 200;
    if (value is String) {
      final lowerValue = value.toLowerCase();
      return lowerValue == 'true' || lowerValue == 'success' || lowerValue == 'ok' || lowerValue == 'y' || lowerValue == '1' || lowerValue == '200';
    }
    return response.containsKey('imageUrl') || response.containsKey('profileImageUrl') || response.containsKey('fileUrl') || response.containsKey('url');
  }

  // 응답 맵에서 첫 번째 문자열 값을 찾기 위한 기능
  String? _firstStringValue(Map<String, dynamic> response, List<String> keys) {
    for (final key in keys) {
      final value = response[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  // 프로필 이미지 경로를 Image.network가 읽을 수 있는 URL로 변환하기 위한 기능
  String _normalizeProfileImageUrl(String imageUrl) {
    final trimmedUrl = imageUrl.trim();
    if (trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://') || trimmedUrl.startsWith('data:image/')) {
      return trimmedUrl;
    }

    if (trimmedUrl.startsWith('/root/')) {
      return '${_baseUri.origin}$trimmedUrl';
    }

    if (trimmedUrl.startsWith('/')) {
      return '$baseUrl$trimmedUrl';
    }

    return '$baseUrl/$trimmedUrl';
  }

  // 업로드 파일명을 사용자 ID와 원본 확장자로 구성하기 위한 기능
  String _profileImageFileName(String userId, String fileName, Uint8List imageBytes) {
    final extension = _imageFileExtension(fileName, imageBytes);
    return 'profile_$userId$extension';
  }

  // 업로드 이미지의 확장자에 맞는 MIME 타입을 지정하기 위한 기능
  MediaType _profileImageContentType(String fileName, Uint8List imageBytes) {
    final extension = _imageFileExtension(fileName, imageBytes);
    switch (extension) {
      case '.png':
        return MediaType('image', 'png');
      case '.webp':
        return MediaType('image', 'webp');
      case '.heic':
        return MediaType('image', 'heic');
      case '.heif':
        return MediaType('image', 'heif');
      case '.jpg':
      case '.jpeg':
      default:
        return MediaType('image', 'jpeg');
    }
  }

  // 원본 파일명과 이미지 바이트에서 확장자를 안전하게 추출하기 위한 기능
  String _imageFileExtension(String fileName, Uint8List imageBytes) {
    final sanitizedFileName = fileName.split('?').first;
    final dotIndex = sanitizedFileName.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < sanitizedFileName.length - 1) {
      final extension = sanitizedFileName.substring(dotIndex).toLowerCase();
      const allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp', '.heic', '.heif'];
      if (allowedExtensions.contains(extension)) {
        return extension;
      }
    }

    return _imageFileExtensionFromBytes(imageBytes);
  }

  // 모바일 브라우저가 확장자 없는 파일명을 줄 때 이미지 바이트로 확장자를 추정하기 위한 기능
  String _imageFileExtensionFromBytes(Uint8List imageBytes) {
    if (imageBytes.length >= 12) {
      if (imageBytes[0] == 0x89 && imageBytes[1] == 0x50 && imageBytes[2] == 0x4E && imageBytes[3] == 0x47) {
        return '.png';
      }
      if (imageBytes[0] == 0xFF && imageBytes[1] == 0xD8 && imageBytes[2] == 0xFF) {
        return '.jpg';
      }
      if (imageBytes[0] == 0x52 && imageBytes[1] == 0x49 && imageBytes[2] == 0x46 && imageBytes[3] == 0x46 && imageBytes[8] == 0x57 && imageBytes[9] == 0x45 && imageBytes[10] == 0x42 && imageBytes[11] == 0x50) {
        return '.webp';
      }
      if (imageBytes[4] == 0x66 && imageBytes[5] == 0x74 && imageBytes[6] == 0x79 && imageBytes[7] == 0x70) {
        final brand = String.fromCharCodes(imageBytes.sublist(8, 12)).toLowerCase();
        if (brand.startsWith('hei') || brand.startsWith('heic') || brand.startsWith('heix')) {
          return '.heic';
        }
        if (brand.startsWith('mif') || brand.startsWith('msf')) {
          return '.heif';
        }
      }
    }

    return '.jpg';
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
        headers: header,
        body: jsonEncode({
          'userId': userId,
          'mealType': mealType,
          'amount': amount,
        }),
      );

      return checkResponse(response);
    } catch (e) {
      print('Error in insertRiceIntake: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchRiceIntake(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/riceIntake.do'),
      headers: header,
      body: jsonEncode({
        'userId': userId,
      }),
    );

    return checkResponse(response);
  }

  // 추천 식품 리스트
  Future<Map<String, dynamic>> fetchGetRcmdFoodList(double carbsCal, double proteinCal) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getRecFoodList.do'),
      headers: header,
      body: json.encode({
        'carbsCal': carbsCal,
        'proteinCal': proteinCal,
      }),
    );
    return checkResponse(response);
  }

  // 영양 상세정보
  Future<Map<String, dynamic>> fetchGetNutritionInfo(String foodId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getNutritionInfo.do'),
      headers: header,
      body: json.encode({'foodId': foodId}),
    );
    return checkResponse(response);
  }

  // 차트 데이터 가져오기  getChartData
  Future<Map<String, dynamic>> getChartData(String code, String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getChartData.do'),
      headers: header,
      body: json.encode({
        'code': code,
        'userId': userId,
      }),
    );
    return checkResponse(response);
  }

  // 섭취량 데이터 가져오기
  Future<Map<String, dynamic>> getIntakeData(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getIntakeData.do'),
      headers: header,
      body: json.encode({
        'userId': userId,
      }),
    );
    return checkResponse(response);
  }

  Future<Map<String, dynamic>> updateUserHealthData(String userId, List<Map<String, dynamic>> healthData) async {
    final String healthDataJson = json.encode(healthData);

    final Map<String, String> requestData = {
      'userId': userId,
      'healthData': healthDataJson // 배열을 문자열로 변환
    };

    final response = await http.post(
      Uri.parse('$baseUrl/app/updateUserHealthData.do'),
      headers: header,
      body: json.encode(requestData),
    );
    return checkResponse(response);
  }

  Future<Map<String, dynamic>> getHealthInfoItems() async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getMsmtItemList.do'),
      headers: header,
      body: json.encode({}),
    );
    return checkResponse(response);
  }

  Future<Map<String, dynamic>> getLastMstmtDte(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getLastMsmtDte.do'),
      headers: header,
      body: json.encode({
        'userId': userId,
      }),
    );

    print("getLastMstmtDte의 resonse 확인 : ${response.body}");
    return checkResponse(response);
  }

  // 근육 나이 리스트 가져오기
  Future<Map<String, dynamic>> getMuscleAgeList() async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getMuscleAgeList.do'),
      headers: header,
      body: json.encode({}),
    );

    print("getMuscleAgeList resonse 확인 : ${response.body}");
    return checkResponse(response);
  }

  // 운동 등록
  Future<Map<dynamic, dynamic>> insertWorkout(String user_id, Map<dynamic, dynamic> meta_data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/registerWorkout.do'),
      headers: header,
      body: json.encode({
        'user_id': user_id,
        'meta_data': meta_data,
        "device_id": "1",
      }),
    );
    return checkResponse(response);
  }

  // 운동 이력 갱신
  Future<Map<dynamic, dynamic>> updateWorkout(String user_id, Map<dynamic, dynamic> meta_data) async {
    print("$user_id, $meta_data");
    final response = await http.post(
      Uri.parse('$baseUrl/app/updateWorkout.do'),
      headers: header,
      body: json.encode({
        'user_id': user_id,
        'meta_data': meta_data,
      }),
    );
    return checkResponse(response);
  }

  // 운동 이력 가져오기
  Future<Map<dynamic, dynamic>> selectWorkout(String user_id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/getWorkoutList.do'),
      headers: header,
      body: json.encode({'user_id': user_id}),
    );
    return checkResponse(response);
  }

  // 운동 이력 가져오기
  Future<Map<dynamic, dynamic>> selectWorkoutRecent(String user_id) async {
    print('$baseUrl/app/selectWorkoutRecent.do');
    final response = await http.post(
      Uri.parse('$baseUrl/app/selectWorkoutRecent.do'),
      headers: header,
      body: json.encode({'user_id': user_id}),
    );
    print(response);
    return checkResponse(response);
  }

  // 운동 종료
  Future<Map<dynamic, dynamic>> updateWorkoutEnd(String user_id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/app/updateWorkoutEndTime.do'),
      headers: header,
      body: json.encode({'user_id': user_id}),
    );
    return checkResponse(response);
  }
}
