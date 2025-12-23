// data_models.dart (최종 수정)

import 'dart:convert';
import 'dart:typed_data';

class SurveyResponse {
  final List<SurveyItem> items;

  SurveyResponse({
    required this.items,
  });

  factory SurveyResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> itemsJson = json['items'] as List<dynamic>;
    final List<SurveyItem> surveyItems = itemsJson.map((itemJson) => SurveyItem.fromJson(itemJson as Map<String, dynamic>)).toList();
    print(surveyItems);
    return SurveyResponse(
      items: surveyItems,
    );
  }
}

class SurveyItem {
  final int id;
  final String category;
  final String title;
  final int pageNumber;

  SurveyItem({
    required this.id,
    required this.category,
    required this.title,
    required this.pageNumber,
  });

  factory SurveyItem.fromJson(Map<String, dynamic> jsonData) {
    return SurveyItem(
      id: jsonData['id'] as int,
      category: jsonData['category']?.toString() ?? '',
      title: jsonData['title']?.toString() ?? '',
      pageNumber: jsonData['pageNumber'] as int,
    );
  }
}
