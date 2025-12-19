// data_models.dart (최종 수정)

import 'dart:convert';
import 'dart:typed_data';

// 1. 최상위 응답 모델: 'count'와 'items'를 포함
class SurveyResponse {
  final int count;
  final List<SurveyItem> items;

  SurveyResponse({
    required this.count,
    required this.items,
  });

  factory SurveyResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> itemsJson = json['items'] as List<dynamic>;
    final List<SurveyItem> surveyItems = itemsJson.map((itemJson) => SurveyItem.fromJson(itemJson as Map<String, dynamic>)).toList();
    print(surveyItems);

    return SurveyResponse(
      count: json['count'] as int,
      items: surveyItems,
    );
  }
}

// 2. 설문 항목 모델
class SurveyItem {
  final int id;
  final String category;
  final String title;
  final int pageNumber; // ⭐️ 페이지 번호
  final SurveyContent surveyContent;

  SurveyItem({
    required this.id,
    required this.category,
    required this.title,
    required this.pageNumber,
    required this.surveyContent,
  });

  factory SurveyItem.fromJson(Map<String, dynamic> jsonData) {
    final contents = json.decode(jsonData['surveyContent']);
    print(contents);
    final surveyContent = SurveyContent.fromJson(contents);
    return SurveyItem(
      id: jsonData['id'] as int,
      category: jsonData['category']?.toString() ?? '',
      title: jsonData['title']?.toString() ?? '',
      pageNumber: jsonData['pageNumber'] as int,
      surveyContent: surveyContent,
    );
  }
}

// 3. 설문 콘텐츠 모델 (SurveyItem 내의 실제 내용)
class SurveyContent {
  final List<Question> questions;

  SurveyContent({
    required this.questions,
  });

  factory SurveyContent.fromJson(Map<String, dynamic> json) {
    print(json);
    final List<dynamic> questionsJson = json['questions'] as List<dynamic>;
    final List<Question> questions = questionsJson.map((questionJson) => Question.fromJson(questionJson as Map<String, dynamic>)).toList();

    return SurveyContent(
      questions: questions,
    );
  }
}

// 4. 질문 모델
class Question {
  final String id;
  final String title;
  final String type;
  final List<String> options;
  final List<SubQuestion> subQuestions;

  final bool showId;
  Question({
    required this.id,
    required this.title,
    required this.type,
    required this.options,
    required this.subQuestions,
    required this.showId,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final List<dynamic> optionsJson = (json['options'] is List) ? json['options'] as List<dynamic> : [];

    final List<dynamic> subQuestionsJson = (json['subQuestions'] is List) ? json['subQuestions'] as List<dynamic> : [];

    final List<SubQuestion> subQuestions = subQuestionsJson.map((subJson) => SubQuestion.fromJson(subJson as Map<String, dynamic>)).toList();

    return Question(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      options: optionsJson.map((e) => e.toString()).toList(),
      subQuestions: subQuestions,
      showId: json['showId'] is bool ? json['showId'] as bool : true,
    );
  }
}

// 5. 하위 질문 모델 (SubQuestion) (생략)
class SubQuestion {
  final String subId;
  final String subTitle;
  final String subType;
  final List<SubItem> subItems;
  final Map<String, dynamic> showIf; // ⭐️ 추가: 조건부 표시 로직
  final double? subMinWidth; // ⭐️ 추가: 너비 제약 (선택적)
  final String? dateType; // ⭐️ 추가: 날짜 형식 (YYYY, YYYY-MM)

  SubQuestion({
    required this.subId,
    required this.subTitle,
    required this.subType,
    required this.subItems,
    required this.showIf,
    this.subMinWidth,
    this.dateType, // ⭐️ 생성자에 추가
  });

  factory SubQuestion.fromJson(Map<String, dynamic> json) {
    final List<dynamic> subItemsJson = (json['subItems'] is List) ? json['subItems'] as List<dynamic> : [];

    final List<SubItem> subItems = subItemsJson.map((subItemJson) => SubItem.fromJson(subItemJson as Map<String, dynamic>)).toList();

// ⭐️ show_if 파싱: Map 타입이 아니거나 null이면 빈 맵으로 처리하여 안전성 확보
    final Map<String, dynamic> showIf = (json['show_if'] is Map<String, dynamic>) ? json['show_if'] as Map<String, dynamic> : {};
// ⭐️ 너비 필드 파싱: int 또는 double을 double?로 안전하게 캐스팅
    final subMinWidth = (json['subMinWidth'] is num) ? (json['subMinWidth'] as num).toDouble() : null;
    // ⭐️ dateType 파싱
    final dateType = json['dateType']?.toString(); // ⭐️ dateType 추가

    return SubQuestion(
      subId: json['subId']?.toString() ?? '',
      subTitle: json['subTitle']?.toString() ?? '',
      subType: json['subType']?.toString() ?? '',
      subItems: subItems,
      showIf: showIf,
      subMinWidth: subMinWidth,
      dateType: dateType, // ⭐️ 생성자에 추가
    );
  }
}

// 6. SubQuestion 내 항목 모델 (SubItem) (생략)
class SubItem {
  final String id;
  final String label;
  final int input;
  final String unit;
  final String inItemType;
  final String items;
  final List<DetailSubQuestion> detailSubQuestions;

  SubItem({
    required this.id,
    required this.label,
    required this.input,
    required this.unit,
    required this.inItemType,
    required this.items,
    required this.detailSubQuestions,
  });

  factory SubItem.fromJson(Map<String, dynamic> json) {
    final List<dynamic> detailSubQuestionsJson = (json['detailSubQuestions'] is List) ? json['detailSubQuestions'] as List<dynamic> : [];

    final List<DetailSubQuestion> detailSubQuestions = detailSubQuestionsJson?.map((detailJson) => DetailSubQuestion.fromJson(detailJson as Map<String, dynamic>)).toList() ?? [];

    return SubItem(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      input: json['input'] as int,
      unit: json['unit']?.toString() ?? '',
      inItemType: json['inItemType']?.toString() ?? '',
      items: json['items']?.toString() ?? '',
      detailSubQuestions: detailSubQuestions,
    );
  }
}

// 7. 상세 하위 질문 모델: SubItem 내의 중첩 질문 (detailSubQuestions)
class DetailSubQuestion {
  final String detailSubId;
  final String detailSubTitle;
  final String detailSubType;
  final String detailUnit;
  final double detailItemMinWidth;
  final Map<String, dynamic> showIf;
  final String? detailDateType; // nullable 필드

  DetailSubQuestion({
    required this.detailSubId,
    required this.detailSubTitle,
    required this.detailSubType,
    required this.detailUnit,
    required this.detailItemMinWidth,
    required this.showIf,
    this.detailDateType,
  });

  factory DetailSubQuestion.fromJson(Map<String, dynamic> json) {
    // show_if는 Map<String, dynamic> 타입이거나 없을 수 있으므로 안전하게 처리합니다.
    final Map<String, dynamic> showIf = (json['show_if'] is Map<String, dynamic>) ? json['show_if'] as Map<String, dynamic> : {};

    return DetailSubQuestion(
      // ⚠️ [핵심 수정]: String 필드에 대해 null 안전성 및 타입 캐스팅을 적용합니다.
      // json['key']가 null일 경우 (키가 없거나 값이 null) toStirng()을 호출하지 않고,
      // 최종적으로 non-nullable인 경우 빈 문자열('')을 반환합니다.
      detailSubId: json['detailSubId']?.toString() ?? '',
      detailSubTitle: json['detailSubTitle']?.toString() ?? '',
      detailSubType: json['detailSubType']?.toString() ?? '',
      detailUnit: json['detailUnit']?.toString() ?? '',
      detailItemMinWidth: json['detailItemMinWidth']?.toDouble() ?? 0,
      showIf: showIf,
      detailDateType: json['detailDateType']?.toString(), // nullable String
    );
  }
}
