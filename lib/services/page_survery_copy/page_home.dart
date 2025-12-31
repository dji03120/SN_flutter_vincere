// page_home.dart
import 'package:Vincere/services/page_survery_copy/data_models.dart';
import 'package:Vincere/utils/http/webReqFastapi.dart';
import 'package:flutter/material.dart';
import 'page_survey_sidebar.dart';
import 'page_survey.dart';
import 'package:collection/collection.dart';

class HealthSurveyScreen extends StatefulWidget {
  const HealthSurveyScreen({super.key});

  @override
  State<HealthSurveyScreen> createState() => _HealthSurveyScreenState();
}

class _HealthSurveyScreenState extends State<HealthSurveyScreen> {
  // 1. 상태 변수
  Future<List<SurveyItem>>? _surveyDataFuture;

  // 2. 메뉴 상태
  int? _selectedSurveyId;
  bool _isMenuVisible = false;
  Map<String, List<SurveyItem>> _groupedByCategory = {};
  static const double menuWidth = 300.0;

  @override
  void initState() {
    super.initState();
    _surveyDataFuture = _fetchAndProcessSurveys();
  }

  Future<List<SurveyItem>> _fetchAndProcessSurveys() async {
    final ApiServiceFast surveyService = ApiServiceFast();
    final items = await surveyService.fetchAllSurveys(); //load survey data
    _groupedByCategory = groupBy(items, (item) => item.category); // category group
    if (items.isNotEmpty && _selectedSurveyId == null) {
      _selectedSurveyId = items.first.id; // init setting = first item
    }
    return items;
  }

  // select handler
  void _selectSurveyItem(int id) {
    setState(() {
      _selectedSurveyId = id;
      _isMenuVisible = false;
    });
  }

  void _toggleMenuVisibility() {
    setState(() {
      _isMenuVisible = !_isMenuVisible;
    });
  }

  // page handler
  void _goToPrevItem() async {
    final allItems = await _surveyDataFuture;
    if (allItems == null || _selectedSurveyId == null) return;

    final currentIndex = allItems.indexWhere((item) => item.id == _selectedSurveyId);
    if (currentIndex > 0) {
      _selectSurveyItem(allItems[currentIndex - 1].id);
    }
  }

  void _goToNextItem() async {
    final allItems = await _surveyDataFuture;
    if (allItems == null || _selectedSurveyId == null) return;

    final currentIndex = allItems.indexWhere((item) => item.id == _selectedSurveyId);
    if (currentIndex != -1 && currentIndex < allItems.length - 1) {
      _selectSurveyItem(allItems[currentIndex + 1].id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('건강 설문 앱'),
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: _toggleMenuVisibility),
        actions: [IconButton(icon: const Icon(Icons.home), onPressed: () => Navigator.pop(context))],
      ),
      body: FutureBuilder<List<SurveyItem>>(
        future: _surveyDataFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('데이터 로드 오류: ${snapshot.error}'));
          }

          if (snapshot.hasData) {
            final List<SurveyItem> allItems = snapshot.data!;

            // 현재 선택된 아이템 찾기
            final selectedItem = allItems.firstWhereOrNull((item) => item.id == _selectedSurveyId);

            // --- [핵심 수정: 카테고리별 페이지 계산] ---
            int categoryTotalPages = 0;
            if (selectedItem != null) {
              // 현재 아이템의 카테고리에 속한 리스트 추출
              final currentCategoryList = _groupedByCategory[selectedItem.category] ?? [];
              categoryTotalPages = currentCategoryList.length; // 해당 카테고리 전체 수
            }
            // ------------------------------------------

            return Stack(
              children: <Widget>[
                // 1. 설문 콘텐츠 영역 (전달 인자 수정)
                RightContentPanel(
                  selectedItem: selectedItem, // 전체 개수가 아닌 카테고리별 개수를 전달
                  maxPageNumber: categoryTotalPages, // 현재 카테고리 내 번호를 넘기고 싶다면 RightContentPanel 정의를 수정하여 활용 가능
                  onPrevItem: _goToPrevItem,
                  onNextItem: _goToNextItem,
                ),

                // 2. 사이드바
                if (_isMenuVisible) ...[
                  GestureDetector(onTap: _toggleMenuVisibility, child: Container(color: Colors.black54)),
                ],
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  left: _isMenuVisible ? 0 : -menuWidth,
                  top: 0,
                  bottom: 0,
                  width: menuWidth,
                  child: SurveySidePanel(
                    groupedData: _groupedByCategory,
                    selectedId: _selectedSurveyId,
                    onSelect: _selectSurveyItem,
                  ),
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
