import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiServiceFast {
  final String baseUrl = 'https://vincerebiohealth.kr/api/vincere'; // 운영
  dynamic header = {'Content-Type': 'application/json'};
  // final String baseUrl = 'http://127.0.0.1:8080'; //root'; // 로컬

  // 2024-08-21 AJG web 통신용 추가

  dynamic checkResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final decodedBody = utf8.decode(response.bodyBytes);
        final result = json.decode(decodedBody);
        print(result);
        return result;
      } catch (e) {
        throw Exception('Failed to decode JSON: ${e.toString()}');
      }
    } else {
      throw Exception(
        'Request failed with status: ${response.statusCode}, body: ${response.body}',
      );
    }
  }

  //
  //
  //
  Future<Map<String, dynamic>> selectUserInfo(String user_id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/select-user-info'),
      headers: header,
      body: json.encode({'user_id': user_id}),
    );
    return checkResponse(response);
  }

  //
  //
  //
  Future<Map<String, dynamic>> selectUserHealth(String user_id) async {
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
}
