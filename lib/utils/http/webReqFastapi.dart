// FastAPI 서버와 Vincere 앱 데이터를 연동하기 위한 기능

import 'dart:convert';
import 'package:Vincere/page_home/utils.dart';
import 'package:Vincere/provider_models.dart';
import 'package:Vincere/services/page_survery_copy/data_models.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

// 서버 오류 원문을 사용자 화면에 노출하지 않기 위한 기능
class ApiRequestException implements Exception {
  final int statusCode;
  final String message;

  ApiRequestException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiServiceFast {
  final String baseUrl = 'https://vincerebiohealth.kr/api/vincere'; // 운영
  dynamic header = {'Content-Type': 'application/json'};

  // 서버 오류 응답을 사용자용 안내 문구로 변환하기 위한 기능
  String _buildSafeErrorMessage(http.Response response) {
    try {
      final decodedBody = utf8.decode(response.bodyBytes);
      final decodedJson = json.decode(decodedBody);
      final rawMessage = decodedJson is Map
          ? (decodedJson['message'] ?? decodedJson['error'])?.toString().trim()
          : null;
      final hasUnsafeDetails = rawMessage != null &&
          (rawMessage.contains('Traceback') ||
              rawMessage.contains('Client Error') ||
              rawMessage.contains('Bad Request') ||
              rawMessage.contains('HTTPError') ||
              rawMessage.contains('lookinbody.com'));

      if (rawMessage != null && rawMessage.isNotEmpty && !hasUnsafeDetails) {
        return rawMessage;
      }
    } catch (_) {
      // 오류 응답 본문 파싱에 실패하면 상태 코드 기반 기본 문구를 사용한다.
    }

    if (response.statusCode == 400 || response.statusCode == 404) {
      return '조회 가능한 데이터가 없습니다.';
    }
    if (response.statusCode >= 500) {
      return '서버에서 데이터를 처리하지 못했습니다. 잠시 후 다시 시도해주세요.';
    }
    return '요청을 처리하지 못했습니다. 입력값을 확인해주세요.';
  }

  dynamic checkResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final decodedBody = utf8.decode(response.bodyBytes);
        final result = json.decode(decodedBody);
        return result;
      } catch (e) {
        throw Exception('Failed to decode JSON: ${e.toString()}');
      }
    } else {
      throw ApiRequestException(
        response.statusCode,
        _buildSafeErrorMessage(response),
      );
    }
  }

  //
  //
  //
  Future<Map<String, dynamic>> selectUserHealth(String user_id) async {
    print('$baseUrl/select-user-health');
    final response = await http.post(
      Uri.parse('$baseUrl/select-user-health'),
      headers: header,
      body: json.encode({'user_id': user_id}),
    );
    return checkResponse(response);
  }

  //
  //
  //
  Future<Map<String, dynamic>> updateUserHealth(
    String user_id,
    String item_nm,
    String new_value,
  ) async {
    print('$baseUrl/select-user-health');
    final response = await http.post(
      Uri.parse('$baseUrl/select-user-health'),
      headers: header,
      body: json.encode({
        'user_id': user_id,
        'item_nm': item_nm,
        'value': new_value,
      }),
    );
    return checkResponse(response);
  }

  //
  //
  //
  dynamic sanitizeForJson(dynamic value) {
    if (value is double && value.isNaN) return null;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k, sanitizeForJson(v)));
    }
    if (value is List) {
      return value.map((v) => sanitizeForJson(v)).toList();
    }
    return value;
  }

  Future<Map<String, dynamic>> insertUserHealth(
    String user_id,
    Map<String, dynamic> health_data,
  ) async {
    print('$baseUrl/insert-user-health');
    print("$user_id $health_data");
    final response = await http.post(
      Uri.parse('$baseUrl/insert-user-health'),
      headers: header,
      body: json.encode({
        'user_id': user_id,
        'health_data': health_data,
      }),
    );
    return checkResponse(response);
  }

  // 인바디 서버 측정값을 Vincere DB에 동기화하기 위한 기능
  Future<Map<String, dynamic>> syncInbodyMeasurement(
    String userId, {
    String? inbodyUserId,
    String? datetimes,
  }) async {
    print('$baseUrl/sync-inbody-measurement');
    final Map<String, dynamic> param = {
      'user_id': userId,
      if (inbodyUserId != null && inbodyUserId.isNotEmpty)
        'inbody_user_id': inbodyUserId,
      if (datetimes != null && datetimes.isNotEmpty) 'datetimes': datetimes,
    };
    final response = await http.post(
      Uri.parse('$baseUrl/sync-inbody-measurement'),
      headers: header,
      body: json.encode(param),
    );
    return checkResponse(response);
  }

  //
  //
  //
  Future<Map<String, dynamic>> requestOSDBFP(
      UserModel userModel, double voltage) async {
    print('$baseUrl/proxy-osd-bodyfat');
    final Map<String, dynamic> param = {
      'param': {
        "age": calculateAge(userModel.userInfo?["bym"]),
        "gender": userModel.userInfo?["sex"] == "M" ? "male" : "female",
        "height": userModel.userHealthData?['키'][0],
        "voltage": voltage,
        "weight": userModel.userHealthData?['몸무게'][0],
      }
    };
    print(param);
    final response = await http.post(
      Uri.parse('$baseUrl/proxy-osd-bodyfat'),
      headers: header,
      body: jsonEncode(param),
    );
    return checkResponse(response);
  }

  //
  //
  //
  Future<Map<String, dynamic>> requestOSDPPG(
      UserModel userModel, List<int> ppgList) async {
    print('$baseUrl/proxy-osd-ppg');
    final Map<String, dynamic> param = {
      "age": calculateAge(userModel.userInfo?["bym"]),
      "ppg_raw_list": ppgList,
    };
    final response = await http.post(
      Uri.parse('$baseUrl/proxy-osd-ppg'),
      headers: header,
      body: jsonEncode(param),
    );
    return checkResponse(response);
  }

  //
  //
  //
  Future<Map<String, dynamic>> select_workout_plan(String plan_nm) async {
    final Map<String, dynamic> param = {"plan_nm": plan_nm};
    print(param);
    final response = await http.post(
      Uri.parse('$baseUrl/select-workout-plan'),
      headers: header,
      body: jsonEncode(param),
    );
    return checkResponse(response);
  }

  //
  //
  //
  Future<Map<String, dynamic>> select_plate_plan(String plan_nm) async {
    final Map<String, dynamic> param = {"plan_nm": plan_nm};
    print(param);
    final response = await http.post(
      Uri.parse('$baseUrl/select-plate-plan'),
      headers: header,
      body: jsonEncode(param),
    );
    return checkResponse(response);
  }

  //
  //
  //
  Future<Map<String, dynamic>> create_qa(
    String user_id,
    String title,
    String content,
  ) async {
    final Map<String, dynamic> param = {
      "user_id": user_id,
      "title": title,
      "content": content,
    };
    print(param);
    final response = await http.post(
      Uri.parse('$baseUrl/create-qna'),
      headers: header,
      body: jsonEncode(param),
    );
    return checkResponse(response);
  }

  //
  //
  //
  Future<List<SurveyItem>> fetchAllSurveys() async {
    // 모든 survey loading
    print('$baseUrl/survery');
    final response =
        await http.get(Uri.parse('$baseUrl/survery'), headers: header);

    if (response.statusCode == 200) {
      final jsonRes = checkResponse(response);
      final SurveyResponse surveyResponse = SurveyResponse.fromJson(jsonRes);
      return surveyResponse.items;
    } else {
      throw Exception(
          'Failed to load surveys from API. Status code: ${response.statusCode}');
    }
  }

  //
  //
  //
  Future<List<dynamic>> select_all_surveys() async {
    // survey table의 id에 해당하는 모든 question 로딩
    print('$baseUrl/survery');
    final response =
        await http.get(Uri.parse('$baseUrl/survery'), headers: header);
    return checkResponse(response)['items'];
  }

  //
  //
  //
  Future<List<Map<String, dynamic>>> select_survey_questions(
      int surveyId) async {
    // survey table의 id에 해당하는 모든 question 로딩
    print('$baseUrl/survery-question/$surveyId');
    final response = await http
        .get(Uri.parse('$baseUrl/survery-question/$surveyId'), headers: header);
    final jsonRes = checkResponse(response)['result'];
    final questions = (jsonRes as List)
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .toList();
    return questions;
  }

  //
  //
  //
  Future<Map<String, dynamic>> select_survey_question_one(
      int questionId) async {
    print('$baseUrl/survery-question-one/$questionId');
    final response = await http.get(
        Uri.parse('$baseUrl/survery-question-one/$questionId'),
        headers: header);
    return checkResponse(response)['result'];
  }

  //
  //
  //
  Future<void> insert_survey_answer(
      String userId, int surveyId, Map answers) async {
    // survey table의 id에 해당하는 모든 question 로딩
    print('$baseUrl/insert-survey-answer');
    final Map<String, dynamic> param = {
      "user_id": userId,
      "survey_id": surveyId,
      "answers": answers,
    };
    print(param);
    final response = await http.post(
      Uri.parse('$baseUrl/insert-survey-answer'),
      headers: header,
      body: jsonEncode(param),
    );
    checkResponse(response);
  }
}

Future<void> saveMeasureResult(BuildContext context) async {
  final userModel = Provider.of<UserModel>(context, listen: false);
  try {
    // API 호출
    ApiServiceFast apiService = ApiServiceFast();
    print("\n\n\n\n");
    print(userModel.userHealthData);
    Map<String, dynamic> result = await apiService.insertUserHealth(
        userModel.userId, userModel.userHealthData ?? {});
    // 결과 처리
    if (result.containsKey("result")) {
      await userModel.set_user_info();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('건강정보가 성공적으로 업데이트되었습니다.'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green),
      );
    }
    if (result.containsKey("error")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('업데이트 중 오류가 발생했습니다.'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red),
      );
    }
  } catch (e) {
    print("저장 중 오류 발생: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('알 수 없는 오류가 발생했습니다.'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red),
    );
  }
}
