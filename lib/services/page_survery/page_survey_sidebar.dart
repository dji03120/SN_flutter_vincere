// page_surveys.dart (최종 수정: Container color/decoration 에러 해결)

import 'package:flutter/material.dart';
import 'data_models.dart'; // SurveyItem 모델을 사용합니다.

// 1. 메뉴 표시 단계를 정의하는 Enum
enum MenuStage {
  categoryList, // 카테고리 목록을 보여주는 상태 (초기 상태)
  titleList, // 선택된 카테고리의 제목 목록을 보여주는 상태
}

// =========================================================================
// 2. 전체 사이드바를 관리하는 최상위 위젯 (메뉴 단계 탐색 관리)
// =========================================================================
class SurveySidePanel extends StatefulWidget {
  final Map<String, List<SurveyItem>> groupedData; // 카테고리별로 그룹화된 설문 데이터
  final int? selectedId; // 현재 선택된 설문 항목의 ID
  final ValueChanged<int> onSelect; // 설문 항목 선택 시 호출될 콜백 함수

  const SurveySidePanel({
    required this.groupedData,
    required this.selectedId,
    required this.onSelect,
    super.key,
  });

  @override
  State<SurveySidePanel> createState() => _SurveySidePanelState();
}

class _SurveySidePanelState extends State<SurveySidePanel> {
  // 현재 메뉴의 표시 단계 상태
  MenuStage _currentStage = MenuStage.categoryList;

  // 현재 선택된 카테고리
  String? _selectedCategory;

  void didUpdateWidget(covariant SurveySidePanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    // selectedId가 변경되었을 때만 처리합니다.
    if (widget.selectedId != oldWidget.selectedId && widget.selectedId != null) {
      // 1. 새로운 selectedId에 해당하는 SurveyItem의 카테고리를 찾습니다.
      String? newCategory;
      // groupedData를 순회하며 해당 ID를 포함하는 카테고리를 찾습니다.
      for (var entry in widget.groupedData.entries) {
        // entry.value는 List<SurveyItem> 입니다.
        if (entry.value.any((item) => item.id == widget.selectedId)) {
          newCategory = entry.key; // 카테고리 이름
          break;
        }
      }

      // 2. 새로운 카테고리가 찾아졌고, 현재 상태를 업데이트해야 하는 경우 setState를 호출합니다.
      if (newCategory != null) {
        // (선택된 카테고리가 다르거나) OR (현재 메뉴가 카테고리 목록을 보여주는 상태일 때) 업데이트합니다.
        if (newCategory != _selectedCategory || _currentStage == MenuStage.categoryList) {
          setState(() {
            _selectedCategory = newCategory;
            _currentStage = MenuStage.titleList; // 제목 목록 단계로 전환
          });
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // 초기 상태 설정: 데이터가 있는지 확인하고, 있다면 첫 번째 카테고리를 선택하여 제목 목록으로 진입합니다.
    if (widget.groupedData.keys.isNotEmpty) {
      _selectedCategory = widget.groupedData.keys.first;
      _currentStage = MenuStage.titleList;
    } else {
      _currentStage = MenuStage.categoryList;
    }
  }

  // 카테고리를 선택했을 때 호출되는 함수
  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _currentStage = MenuStage.titleList;
    });
  }

  // 뒤로가기 버튼을 눌렀을 때 호출되는 함수
  void _backToCategoryList() {
    setState(() {
      _currentStage = MenuStage.categoryList;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasData = widget.groupedData.isNotEmpty;
    final bool isTitleListValid = _currentStage == MenuStage.titleList && _selectedCategory != null && widget.groupedData[_selectedCategory]?.isNotEmpty == true;

    return Container(
      // ⚠️ [수정된 부분] Container의 color 속성을 제거하고 decoration 내부에만 color를 둡니다.
      decoration: BoxDecoration(
        color: Colors.white, // ✅ 배경색을 BoxDecoration 내부에서 지정
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10.0)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildHeader(hasData),
          const Divider(height: 1, thickness: 1),

          // 2. 내용 영역 (카테고리 목록 또는 제목 목록)
          Expanded(
            child: !hasData
                ? const Center(child: Text('표시할 설문 데이터가 없습니다.', style: TextStyle(color: Colors.grey)))
                : _currentStage == MenuStage.categoryList
                    ? _CategoryListWidget(
                        categories: widget.groupedData.keys.toList(),
                        onSelect: _selectCategory,
                      )
                    : isTitleListValid
                        ? _TitleListWidget(
                            category: _selectedCategory!,
                            items: widget.groupedData[_selectedCategory]!,
                            selectedId: widget.selectedId,
                            onSelect: widget.onSelect,
                          )
                        : const Center(child: Text('선택된 카테고리에 설문 항목이 없습니다.', style: TextStyle(color: Colors.grey))),
          ),
          // 뒤로가기 버튼
          const Divider(height: 1, thickness: 1),
          SizedBox(height: 20),
          TextButton.icon(
              icon: const Icon(Icons.home, size: 28, color: Color(0xff333333)), // 홈 아이콘
              label: const Text('홈으로 돌아가기', style: TextStyle(fontSize: 18, color: Color(0xff333333))), // 홈 텍스트
              onPressed: () {
                Navigator.pop(context);
              }),
          SizedBox(height: 20),
          // 1. 헤더 (뒤로가기 버튼 또는 타이틀)
        ],
      ),
    );
  }

  // 헤더 위젯 빌더
  Widget _buildHeader(bool hasData) {
    if (!hasData) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        alignment: Alignment.centerLeft,
        height: 60,
        child: const Text('설문 카테고리', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      alignment: Alignment.centerLeft,
      height: 60,
      child: _currentStage == MenuStage.titleList && _selectedCategory != null
          ? Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.blueGrey),
                  onPressed: _backToCategoryList,
                  tooltip: '카테고리 목록으로 돌아가기',
                ),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(
                  _selectedCategory!,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  overflow: TextOverflow.ellipsis,
                ))
              ],
            )
          : const Text('설문 카테고리', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }
}

// -------------------------------------------------------------------------
// 3. 카테고리 목록을 표시하는 위젯
// -------------------------------------------------------------------------
class _CategoryListWidget extends StatelessWidget {
  final List<String> categories;
  final ValueChanged<String> onSelect;

  const _CategoryListWidget({
    required this.categories,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: categories.map((category) {
        return InkWell(
          onTap: () => onSelect(category),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const Icon(Icons.folder, color: Colors.orange),
                const SizedBox(width: 16.0),
                Expanded(child: Text(category, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500))),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// -------------------------------------------------------------------------
// 4. 선택된 카테고리의 제목 목록을 표시하는 위젯
// -------------------------------------------------------------------------
class _TitleListWidget extends StatefulWidget {
  final String category;
  final List<SurveyItem> items;
  final int? selectedId;
  final ValueChanged<int> onSelect;

  const _TitleListWidget({
    required this.category,
    required this.items,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  State<_TitleListWidget> createState() => _TitleListWidgetState();
}

class _TitleListWidgetState extends State<_TitleListWidget> {
  @override
  Widget build(BuildContext context) {
    final List<SurveyItem> items = widget.items;

    final Color defaultBackgroundColor = Colors.white;
    final Color selectedColor = Colors.blue.shade100;
    final Color selectedHighlightColor = Colors.blue.shade700;

    return ListView(
      key: const ValueKey('TitleList'),
      children: items.map((item) {
        final isSelected = item.id == widget.selectedId;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              widget.onSelect(item.id);
            },
            child: Container(
              color: isSelected ? selectedColor : defaultBackgroundColor,
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.article,
                    color: isSelected ? selectedHighlightColor : Colors.grey[600],
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? selectedHighlightColor : Colors.black87,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                  if (isSelected) const Icon(Icons.check, size: 18, color: Colors.blue)
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
