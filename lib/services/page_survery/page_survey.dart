// page_survey.dart (데이터 모델을 채용하도록 변경된 최종 버전)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'data_models.dart'; // SurveyItem, SurveyContent, Question, SubQuestion 등의 모델을 임포트합니다.

// =======================================================
// QuestionDisplayWidget: 개별 질문 항목을 렌더링하는 위젯 (Stateful로 변경)
// =======================================================
class QuestionDisplayWidget extends StatefulWidget {
  final Question question;
  final int index;

  const QuestionDisplayWidget({
    required this.question,
    required this.index,
    super.key,
  });

  @override
  State<QuestionDisplayWidget> createState() => _QuestionDisplayWidgetState();
}

class _QuestionDisplayWidgetState extends State<QuestionDisplayWidget> {
  // 스타일 정의
  final Color mainBoxColor = Colors.grey.shade200;
  final Color mainBoxBorderColor = Colors.grey.shade400;
  final Color subBoxColor = Colors.grey.shade200;
  final Color subBoxBorderColor = Colors.grey.shade400;
  final Color mainTitleBoxColor = Colors.grey.shade500;
  final Color detailBoxColor = Colors.grey.shade100; // Level 3 박스 스타일 추가
  final Color detailBoxBorderColor = Colors.grey.shade300; // Level 3 박스 스타일 추가
  static const double leftMargin = 25.0;

  // [추가] Level 3 박스 스타일 정의
  final Color detailSubBoxColor = Colors.grey.shade200;
  final Color detailSubBoxBorderColor = Colors.grey.shade400;

  // 응답 상태 저장
  Map<String, String?> answers = {}; // 메인 답변 (메인 질문 id -> 값 or "a,b,c")
  Map<String, Map<String, String?>> detailAnswers = {}; // 메인 질문 id -> (subId -> 값)

  @override
  void initState() {
    super.initState();
    // 초기화 로직 (예: 저장된 답변 불러오기)
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.question;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16), // 질문 간 간격 유지
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 메인 질문 번호 + 내용 전체를 감싸는 회색 박스 (질문 헤더)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: mainBoxColor, // 밝은 회색 배경
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: mainBoxBorderColor, width: 0.5), // 테두리 추가 (선택사항)
            ),
            child: Row(
              children: [
                // 1-1. 메인 설문 번호 박스 (진한 회색)
                if (question.showId) ...[
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: mainTitleBoxColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      question.id,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ], // 1-2. 메인 질문 제목
                Expanded(
                  child: Text(
                    "${question.title}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12), // Header와 Input 사이 간격

          // 2. 메인 입력 아이템 (박스 없이 기본 출력, 즉 흰색 배경)
          buildMainInput(question),
        ],
      ),
    );
  }

  int _parseTextLines(List<String> options) {
    for (final opt in options) {
      if (opt.startsWith('lines=')) {
        return int.tryParse(opt.replaceFirst('lines=', '')) ?? 1;
      }
      if (opt == 'multiline') {
        return 3;
      }
    }
    return 1; // 기본값
  }

  bool _shouldShowSubQuestion(
    Question question,
    SubQuestion sub,
    String? selectedValue,
    Map<String, dynamic> answers,
  ) {
    if (question.type == 'none') {
      return true;
    }

    if (sub.showIf.isEmpty) return false;

    final String questionId = sub.showIf['question_id']?.toString() ?? '';
    final dynamic conditionValue = sub.showIf['value'];

    if (questionId.isEmpty) return false;

    final String? answerValue = questionId == 'self' ? selectedValue : answers[questionId]?.toString();

    if (answerValue == null || conditionValue == null) return false;

    // value: "주 1일|주 2~3일"
    final Set<String> conditionValues = conditionValue.toString().split('|').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();

    // radio는 단일 값
    return conditionValues.contains(answerValue);
  }

  // ---------------------------
  // buildMainInput: radio / checkbox / text (기존 형태 유지)
  // ---------------------------
  Widget buildMainInput(Question q) {
    final qType = q.type;
    final qId = q.id;
    final selected = answers[qId];
    final options = q.options;

    if (qType == 'none') {
      // ✅ 메인 입력은 없고, subQuestions를 바로 출력
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: q.subQuestions.expand((sub) {
          return [
            Padding(
              padding: const EdgeInsets.only(
                left: leftMargin,
                top: 4.0,
                bottom: 4.0,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: subBoxColor,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: subBoxBorderColor,
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildDetailInputs(q, sub),
                ),
              ),
            )
          ];
        }).toList(),
      );
    }

    if (qType == 'radio') {
      return Column(
        children: options.map((opt) {
          final isSelected = selected == opt;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RadioListTile<String>(
                title: Text(opt),
                value: opt,
                groupValue: selected,
                onChanged: (v) {
                  setState(() {
                    answers[qId] = v;
                  });
                },
              ),

              // ✅ 선택된 옵션일 때만 subQuestion 검사
              if (isSelected)
                ...q.subQuestions.where((sub) => _shouldShowSubQuestion(q, sub, selected, answers)).expand((sub) {
                  return [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: leftMargin,
                        top: 4.0,
                        bottom: 4.0,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: subBoxColor,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: subBoxBorderColor,
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildDetailInputs(q, sub),
                        ),
                      ),
                    )
                  ];
                }).toList(),
            ],
          );
        }).toList(),
      );
    }

    // CHECKBOX (저장 형식: "a,b,c")
    if (qType == 'checkbox') {
      final List<String> selectedList = (selected ?? '').toString().isEmpty ? [] : (selected ?? '').toString().split('|').where((s) => s.isNotEmpty).toList();

      final otherController = TextEditingController(text: answers['${qId}_other'] ?? '');

      return Column(
        children: options.map((opt) {
          final checked = selectedList.contains(opt);
          // final isOther = opt.toLowerCase() == '기타' || opt == 'Other';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
// [수정] CheckboxListTile 바로 아래에 Level 2 SubQuestion 삽입
              CheckboxListTile(
                value: checked,
                title: Text(opt),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      if (!selectedList.contains(opt)) selectedList.add(opt);
                    } else {
                      selectedList.remove(opt);
                    }
                    answers[qId] = selectedList.join(',');
                  });
                },
              ),

// Level 2 SubQuestion Indentation: 체크된 Checkbox 옵션 바로 아래에 40.0 들여쓰기로 출력
              if (checked) // 체크된 경우에만 표시
                ..._getConditionalSubQuestions(q, opt).expand((sub) {
                  return [
                    Padding(
                      padding: const EdgeInsets.only(left: 40.0, top: 4.0, bottom: 4.0),
                      child: Container(
                        // [추가] SubQuestion 전체를 감싸는 박스
                        width: double.infinity,
                        padding: const EdgeInsets.all(12.0), // 내용물 내부 패딩
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50, // 밝은 파란색 배경
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.blue.shade200, width: 1.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildDetailInputs(q, sub), // 세부 설문 (Level 2) 렌더링
                        ),
                      ),
                    )
                  ];
                }).toList(),
            ],
          );
        }).toList(),
      );
    }

    // TEXT
    if (qType == 'text') {
      final controller = TextEditingController(text: answers[qId] ?? '');
      final int lines = _parseTextLines(options);

      return TextField(
        controller: controller,
        minLines: lines,
        maxLines: lines,
        keyboardType: lines > 1 ? TextInputType.multiline : TextInputType.text,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          alignLabelWithHint: true,
        ),
        onChanged: (v) {
          answers[qId] = v;
        },
      );
    }

    // CHECKBOX WITH INPUT (checkbox 와 동일한 레이아웃)
    if (qType == 'checkbox_with_input') {
      final List<String> selectedList = (answers[qId] ?? '').toString().isEmpty ? [] : (answers[qId] ?? '').toString().split('|').where((s) => s.isNotEmpty).toList();

      return Column(
        children: options.map((rawOpt) {
          String label = rawOpt;
          bool alwaysShowInput = false;

          if (rawOpt.contains('|')) {
            final parts = rawOpt.split('|');
            label = parts[0];
            alwaysShowInput = parts.length > 1 && parts[1] == 'true';
          }

          final checked = selectedList.contains(label);
          final inputKey = '${qId}_${label}_input';
          final controller = TextEditingController(text: answers[inputKey] ?? '');

          return CheckboxListTile(
            controlAffinity: ListTileControlAffinity.leading,
            value: checked,
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  if (!selectedList.contains(label)) {
                    selectedList.add(label);
                  }
                } else {
                  selectedList.remove(label);
                }
                answers[qId] = selectedList.join('|');
              });
            },

            // ✅ title 영역에 Row 삽입
            title: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(label),
                if (alwaysShowInput) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 160,
                    height: 36,
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (v) {
                        answers[inputKey] = v;
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      );
    }

    if (qType == 'text_with_input') {
      final List<String> opts = (options as List).map((e) => e.toString()).toList();

      final String prefixLabel = opts.first;

      // 마지막 처리
      String lastRaw = opts.last;
      bool hasClosingParen = lastRaw.endsWith(')');
      String lastUnit = hasClosingParen ? lastRaw.substring(0, lastRaw.length - 1) : lastRaw;

      // 👉 input 대상 단위들
      final List<String> units = [
        ...opts.sublist(1, opts.length - 1),
        lastUnit,
      ];

      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: [
          // 앞 라벨
          Text(prefixLabel),

          // 단위 + input
          ...units.map((unit) {
            final String key = '${qId}_$unit';

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 70,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      answers[key] = v;
                    },
                  ),
                ),
                const SizedBox(width: 4),
                Text(unit),
              ],
            );
          }),

          // 닫는 괄호
          if (hasClosingParen) const Text(')'),
        ],
      );
    }

    // 기본값 (지원하지 않는 타입이면 빈박스)
    return const SizedBox.shrink();
  }

  // ---------------------------
  // 7) 특정 선택지에 의해 트리거되는 subQuestions 추출
  // ---------------------------
  List<dynamic> _getConditionalSubQuestions(Question parent, String selectedValue) {
    final subQuestions = parent.subQuestions as List<SubQuestion>;
    if (subQuestions.isEmpty) return [];

    return subQuestions.where((SubQuestion sub) {
      final showIf = sub.showIf;
      if (showIf.isEmpty) return false;

      // 3. showIf 맵에서 값을 안전하게 추출합니다. (?.toString() ?? ''를 사용)
      final pId = showIf['question_id']?.toString() ?? ''; // 부모 id (메인 질문 id)
      final pValue = showIf['value']?.toString().trim() ?? ''; // 조건 값

      // 필수 조건 값이 없으면 숨김
      if (pId.isEmpty || pValue.isEmpty) return false;

      // 메인 질문 ID가 일치하는지 확인 (parent.id는 Question 모델에서 String 타입입니다.)
      if (pId != parent.id) return false;

      // 현재 선택된 값(selectedValue)이 조건 값(pValue)과 일치하는지 확인
      return selectedValue.trim() == pValue;
    }).toList();
  }

  // Part 3 of 3: _buildDetailInputs (put this inside the same class _PageSurveyState)
  Widget buildDetailSubsIfAny({
    required BuildContext context,
    required String mainId,
    required String subId,
    required String keyValue,
    required bool visible,
    required List<DetailSubQuestion> detailSubQuestions,
    required Map<String, Map<String, String?>> detailAnswers,
    required VoidCallback refresh,
    required double leftMargin,
    required Color detailSubBoxColor,
    required Color detailSubBoxBorderColor,
  }) {
    if (detailSubQuestions.isEmpty) return const SizedBox.shrink();
    if (!visible) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(left: leftMargin, top: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: detailSubQuestions.where((DetailSubQuestion dsq) {
          final showIf = dsq.showIf;
          if (showIf == null || showIf.isEmpty) return true;

          final value = showIf['value']?.toString();
          if (value == '선택됨') {
            return visible;
          }
          return false;
        }).map<Widget>((DetailSubQuestion dsq) {
          final dsqId = dsq.detailSubId;
          final dsqTitle = dsq.detailSubTitle;
          final dsqType = dsq.detailSubType;
          final dsqUnit = dsq.detailUnit;
          final dsqDateType = dsq.detailDateType ?? 'YYYY';
          final dsqItemMinWidth = dsq.detailItemMinWidth ?? 200;

          detailAnswers[mainId] ??= {};
          final dsqKey = '${keyValue}_dsq_$dsqId';
          final saved = detailAnswers[mainId]![dsqKey] ?? '';
          final ctrl = TextEditingController(text: saved);

          ctrl.selection = TextSelection.fromPosition(
            TextPosition(offset: ctrl.text.length),
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: detailSubBoxColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: detailSubBoxBorderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$dsqId. $dsqTitle",
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),

                  // TEXT
                  if (dsqType == 'text') ...[
                    Builder(builder: (context) {
                      final parts = dsqUnit.split('|'); // "," 기준 분리
                      final List<Widget> widgets = [];

                      // 입력 컨트롤러들 (index별)
                      List<TextEditingController> controllers = List.generate(
                        parts.length == 1 ? 1 : parts.length - 1,
                        (i) => TextEditingController(
                          text: detailAnswers[mainId]!['${dsqKey}_$i'] ?? '',
                        ),
                      );

                      // 특수 케이스: dsqUnit == ""
                      if (dsqUnit.trim().isEmpty) {
                        widgets.add(
                          Expanded(
                            child: TextField(
                              controller: controllers[0],
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (v) {
                                detailAnswers[mainId]!['${dsqKey}_0'] = v;
                              },
                            ),
                          ),
                        );
                      } else {
                        for (int i = 0; i < parts.length; i++) {
                          final text = parts[i].trim();

                          // 텍스트 출력
                          if (text.isNotEmpty) {
                            widgets.add(Text(text));
                          }

                          // 마지막이 아니면 input 삽입
                          if (i < parts.length - 1) {
                            widgets.add(const SizedBox(width: 6));
                            widgets.add(
                              SizedBox(
                                width: 100,
                                child: TextField(
                                  controller: controllers[i],
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  onChanged: (v) {
                                    detailAnswers[mainId]!['${dsqKey}_$i'] = v;
                                  },
                                ),
                              ),
                            );
                            widgets.add(const SizedBox(width: 6));
                          }
                        }
                      }

                      return SizedBox(
                        width: dsqItemMinWidth,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: widgets,
                        ),
                      );
                    }),
                  ],

                  // TEXT + DATE
                  if (dsqType == 'text_with_date') ...[
                    SizedBox(
                      width: dsqItemMinWidth,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: ctrl,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (v) {
                                detailAnswers[mainId]![dsqKey] = v;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.calendar_today, size: 18),
                            onPressed: () async {
                              if (dsqDateType == 'YYYY') {
                                final year = await showDialog<int>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    content: SizedBox(
                                      width: 300,
                                      height: 300,
                                      child: YearPicker(
                                        firstDate: DateTime(1900),
                                        lastDate: DateTime(2100),
                                        selectedDate: DateTime.now(),
                                        onChanged: (d) => Navigator.pop(context, d.year),
                                      ),
                                    ),
                                  ),
                                );
                                if (year != null) {
                                  ctrl.text = year.toString();
                                  detailAnswers[mainId]![dsqKey] = year.toString();
                                  refresh();
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (dsqType == 'radio') ...[
                    Builder(builder: (context) {
                      final items = dsqUnit.split('|').map((e) => e.trim()).where((e) => e.isNotEmpty).map((e) {
                        final parts = e.split('--');
                        return {
                          'label': parts[0],
                          'type': parts.length > 1 ? parts[1] : 'text',
                        };
                      }).toList();

                      final selectedValue = detailAnswers[mainId]![dsqKey] ?? '';

                      return buildDetailSelectableWrap(
                        itemMinWidth: dsqItemMinWidth,
                        children: items.map((item) {
                          final label = item['label']!;
                          final type = item['type']!;
                          final safeLabel = label.replaceAll(' ', '_');
                          final valueKey = '${dsqKey}_$safeLabel';

                          final isSelected = selectedValue == safeLabel;

                          final ctrl = TextEditingController(
                            text: detailAnswers[mainId]!['${valueKey}_value'] ?? '',
                          );

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              /// RADIO
                              Radio<String>(
                                value: safeLabel,
                                groupValue: selectedValue,
                                onChanged: (v) {
                                  if (v == null) return;
                                  detailAnswers[mainId]![dsqKey] = v;
                                  refresh();
                                },
                              ),

                              /// LABEL
                              Text(label),

                              /// INPUT (선택된 경우만 활성화)
                              if ((type == 'text_with_input' || type == 'text_with_input1') && isSelected) ...[
                                const SizedBox(width: 6),
                                Expanded(
                                  child: TextField(
                                    controller: ctrl,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (v) {
                                      detailAnswers[mainId]!['${valueKey}_value'] = v;
                                    },
                                  ),
                                ),
                                if (type == 'text_with_input1') Text(')'),
                              ],
                            ],
                          );
                        }).toList(),
                      );
                    }),
                  ],

                  if (dsqType == 'checkbox') ...[
                    Builder(builder: (context) {
                      final items = dsqUnit.split('|').map((e) => e.trim()).where((e) => e.isNotEmpty).map((e) {
                        final parts = e.split('--');
                        return {
                          'label': parts[0],
                          'type': parts.length > 1 ? parts[1] : 'text',
                        };
                      }).toList();

                      return buildDetailSelectableWrap(
                        itemMinWidth: dsqItemMinWidth,
                        children: items.map((item) {
                          final label = item['label']!;
                          final type = item['type']!;
                          final safeLabel = label.replaceAll(' ', '_');
                          final checkedKey = '${dsqKey}_$safeLabel';
                          final isChecked = (detailAnswers[mainId]![checkedKey] ?? '') == 'Y';

                          final ctrl = TextEditingController(
                            text: detailAnswers[mainId]!['${checkedKey}_value'] ?? '',
                          );

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Checkbox(
                                value: isChecked,
                                onChanged: (v) {
                                  detailAnswers[mainId]![checkedKey] = v == true ? 'Y' : '';
                                  refresh();
                                },
                              ),
                              Text(label),
                              if (type == 'text_with_input' || type == 'text_with_input1') ...[
                                const SizedBox(width: 6),
                                Expanded(
                                  child: TextField(
                                    controller: ctrl,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (v) {
                                      detailAnswers[mainId]!['${checkedKey}_value'] = v;
                                    },
                                  ),
                                ),
                              ],
                              if (type == 'text_with_input1') Text(')'),
                            ],
                          );
                        }).toList(),
                      );
                    }),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget buildSubItemRow({
    required BuildContext context,
    required bool checked,
    required String label,
    required int inputType,
    required String unit,
    required String inItemType,
    required String itemsStr,
    required String mainId,
    required String subId,
    required String keyValue,
    required Map<String, Map<String, String?>> detailAnswers,
    required TextEditingController controller1,
    required TextEditingController controller2,
    required TextEditingController textController,
    required VoidCallback refresh,
    required ValueChanged<bool?> onCheckedChanged,
    bool isRadio = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isRadio)
          Radio<bool>(
            value: true,
            groupValue: checked,
            onChanged: onCheckedChanged,
          )
        else
          Checkbox(
            value: checked,
            onChanged: onCheckedChanged,
          ),
        const SizedBox(width: 4),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(label, overflow: TextOverflow.ellipsis),

              // ---------------- inputType 1 (unit 분해 기반 동적 처리) ----------------
              if (inputType == 1) ...[
                Builder(builder: (context) {
                  final units = unit.split('|').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

                  // unit 이 없으면 input 1개만
                  if (units.isEmpty) {
                    return SizedBox(
                      width: 80,
                      child: TextField(
                        controller: controller1,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) {
                          detailAnswers[mainId]!['${keyValue}_1'] = v;
                        },
                      ),
                    );
                  }

                  // unit 개수만큼 input 생성
                  return Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: List.generate(units.length, (i) {
                      final ctrl = TextEditingController(
                        text: detailAnswers[mainId]!['${keyValue}_${i + 1}'] ?? '',
                      );

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 70,
                            child: TextField(
                              controller: ctrl,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (v) {
                                detailAnswers[mainId]!['${keyValue}_${i + 1}'] = v;
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(units[i]),
                        ],
                      );
                    }),
                  );
                }),
              ],
              // ---------------- inputType 2 ----------------
              if (inputType == 2) ...[
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: controller1,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      detailAnswers[mainId]!['${keyValue}_1'] = v;
                    },
                  ),
                ),
                const Text(')'),
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: controller2,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      detailAnswers[mainId]!['${keyValue}_2'] = v;
                    },
                  ),
                ),
                if (unit.isNotEmpty) Text(unit),
              ],

              // ---------------- inputType 3 ----------------
              if (inputType == 3) ...[
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: controller1,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      detailAnswers[mainId]!['${keyValue}_1'] = v;
                    },
                  ),
                ),
                if (unit.isNotEmpty) Text(unit),
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: controller2,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      detailAnswers[mainId]!['${keyValue}_2'] = v;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_month, size: 20),
                  onPressed: () async {
                    final year = await showDialog<int>(
                      context: context,
                      builder: (_) => AlertDialog(
                        content: SizedBox(
                          width: 300,
                          height: 300,
                          child: YearPicker(
                            firstDate: DateTime(1900),
                            lastDate: DateTime(2100),
                            selectedDate: DateTime.now(),
                            onChanged: (d) => Navigator.pop(context, d.year),
                          ),
                        ),
                      ),
                    );
                    if (year != null) {
                      controller2.text = year.toString();
                      detailAnswers[mainId]!['${keyValue}_2'] = year.toString();
                      refresh();
                    }
                  },
                ),
                Text(")"),
              ],

              // ---------------- inputType 4 ----------------
              if (inputType == 4) ...[
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: controller1,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      detailAnswers[mainId]!['${keyValue}_1'] = v;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_month, size: 20),
                  onPressed: () async {
                    final year = await showDialog<int>(
                      context: context,
                      builder: (_) => AlertDialog(
                        content: SizedBox(
                          width: 300,
                          height: 300,
                          child: YearPicker(
                            firstDate: DateTime(1900),
                            lastDate: DateTime(2100),
                            selectedDate: DateTime.now(),
                            onChanged: (d) => Navigator.pop(context, d.year),
                          ),
                        ),
                      ),
                    );
                    if (year != null) {
                      controller1.text = year.toString();
                      detailAnswers[mainId]!['${keyValue}_1'] = year.toString();
                      refresh();
                    }
                  },
                ),
              ],

              // ---------------- inputType 5 ----------------
              if (inputType == 5) ...[
                if (inItemType == 'text')
                  SizedBox(
                    width: 160,
                    child: TextField(
                      controller: textController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) {
                        detailAnswers[mainId]!['${keyValue}_text'] = v;
                      },
                    ),
                  ),
                if (inItemType == 'checkbox')
                  ...itemsStr.split('|').map((item) {
                    String subLabel;
                    String? extType;
                    if (item.contains('--')) {
                      final parts = item.split('--');
                      subLabel = parts[0];
                      extType = parts[1];
                    } else {
                      subLabel = item;
                      extType = "text";
                    }
                    final subKey = '${keyValue}_$subLabel';
                    final saved = detailAnswers[mainId]![subKey] ?? '';
                    final set = saved.isNotEmpty ? saved.split(',').toSet() : <String>{};
                    final subChecked = set.contains(subLabel);

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // --- 체크박스 ---
                        Checkbox(
                          value: subChecked,
                          onChanged: (v) {
                            if (v == true) {
                              set.add(subLabel);
                            } else {
                              set.remove(subLabel);
                              detailAnswers[mainId]!['${subKey}_input'] = '';
                            }
                            detailAnswers[mainId]![subKey] = set.join(',');
                            refresh();
                          },
                        ),
                        Text(subLabel),
                        if (extType == 'text_with_input') ...[
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 120,
                            child: TextField(
                              enabled: true,
                              decoration: const InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (v) {
                                detailAnswers[mainId]!['${subKey}_input'] = v;
                              },
                            ),
                          ),
                        ],
                      ],
                    );
                  }),
                if (inItemType == 'radio')
                  ...itemsStr.split('|').map((subLabel) {
                    final subKey = '${keyValue}_radio';
                    final selected = detailAnswers[mainId]![subKey] ?? '';

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Radio<String>(
                          value: subLabel,
                          groupValue: selected,
                          onChanged: (v) {
                            detailAnswers[mainId]![subKey] = v;
                            refresh();
                          },
                        ),
                        Text(subLabel),
                      ],
                    );
                  }),
                if (unit.isNotEmpty) Text(unit),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget buildDetailSelectableWrap({
    required double itemMinWidth,
    required List<Widget> children,
  }) {
    const double spacing = 12;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        int perRow;
        if (itemMinWidth <= 0) {
          perRow = 1; // ⭐ 핵심
        } else {
          perRow = (availableWidth + spacing) ~/ (itemMinWidth + spacing);
          if (perRow < 1) perRow = 1;
        }

        final itemWidth = (availableWidth - spacing * (perRow - 1)) / perRow;

        return Wrap(
          spacing: spacing,
          runSpacing: 8,
          children: children.map((child) {
            return SizedBox(
              width: itemWidth,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }

// ---------------------------
// _buildDetailInputs: subQuestion 처리 (text, text_with_date, checkbox_with_input, checkbox, radio)
// - inputType 0~5 포함
// - detailSubQuestions 자동 펼침 (있으면 표시, 없으면 기존 처리)
// ---------------------------
  List<Widget> _buildDetailInputs(Question parent, SubQuestion sub) {
    final mainId = parent.id;
    final subId = sub.subId;
    detailAnswers[mainId] ??= {};

    final subType = sub.subType;
    final subTitle = sub.subTitle;
    final savedValue = detailAnswers[mainId]![subId];

// [수정] 서브 질문 제목 (간단한 Text로 변경. 전체 SubQuestion에 박스를 씌우므로 내부 박스 제거)
    final Widget subQuestionHeader = Padding(
      padding: const EdgeInsets.only(bottom: 10.0), // 아래 여백만 유지
      child: Text(
        "$subId. $subTitle",
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0, color: Colors.blueGrey), // 색상 조정
      ),
    );

    // 1) TEXT 입력
    if (subType == 'text') {
      final controller = TextEditingController(text: savedValue ?? '');
      return [
        Text("$subId. $subTitle", style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "$subTitle 입력",
            filled: true,
            fillColor: Colors.white,
            border: const OutlineInputBorder(),
          ),
          onChanged: (v) {
            detailAnswers[mainId]![subId] = v;
          },
        ),
        const SizedBox(height: 12),
      ];
    }

    // 2) TEXT + DATE 입력
    if (subType == 'text_with_date') {
      final controller = TextEditingController(text: savedValue ?? '');
      final String dateType = sub.dateType ?? 'YYYY';
      final double maxWidth = sub.subMinWidth ?? 100.0;

      return [
        Text("$subId. $subTitle", style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Row(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onChanged: (v) {
                  detailAnswers[mainId]![subId] = v;
                },
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  DateTime? pickedDate;
                  if (dateType == 'YYYY') {
                    int? pickedYear = await showDialog<int>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text("연도를 선택하세요"),
                          content: SizedBox(
                            width: 300,
                            height: 300,
                            child: YearPicker(
                              firstDate: DateTime(1900),
                              lastDate: DateTime(2100),
                              selectedDate: DateTime.now(),
                              onChanged: (DateTime dateTime) {
                                Navigator.pop(context, dateTime.year);
                              },
                            ),
                          ),
                        );
                      },
                    );
                    if (pickedYear != null) {
                      controller.text = pickedYear.toString();
                      detailAnswers[mainId]![subId] = pickedYear.toString();
                    }
                  } else {
                    pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      String formattedDate = dateType == 'YYYY-MM' ? "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}" : "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                      controller.text = formattedDate;
                      detailAnswers[mainId]![subId] = formattedDate;
                    }
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ];
    }

    // 3) checkbox_with_input (모든 inputType 처리 + detailSubQuestions 펼침)
    if (subType == 'checkbox_with_input') {
      final subItems = sub.subItems;
      // [수정 1] subMinWidth 값을 가져옴 (기본값 200, 0이 들어오면 0으로 처리)
      final double subMinWidth = sub.subMinWidth ?? 200.0;
      const double spacing = 12;

      return [
        Text("$subId. $subTitle", style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        LayoutBuilder(builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          int perRow;
          // [수정 2] subMinWidth가 0 이하이면 무조건 1열(한 행에 한 아이템)
          if (subMinWidth <= 0) {
            perRow = 1;
          } else {
            // 공간 계산: (전체너비 + 간격) / (최소너비 + 간격)
            int calculatedPerRow = (availableWidth + spacing) ~/ (subMinWidth + spacing);
            // 최소 1개는 출력
            if (calculatedPerRow < 1) calculatedPerRow = 1;

            // (선택 사항) 최대 2개까지만 나열하고 싶다면 아래 주석 해제
            // if (calculatedPerRow > 2) calculatedPerRow = 2;

            perRow = calculatedPerRow;
          }

          // [수정 3] 아이템 하나의 정확한 너비 계산
          // perRow가 1이면 (availableWidth / 1)이 되어 꽉 차게 됨
          final itemWidth = (availableWidth - (spacing * (perRow - 1))) / perRow;

          return Wrap(
            spacing: spacing,
            runSpacing: 8,
            children: subItems.map<Widget>((SubItem item) {
              final itemId = item.id;
              final label = item.label;
              final keyValue = '$subId|$itemId'; // 구분자로 | 사용 (안전)
              final inputType = item.input;
              final unit = item.unit;
              final inItemType = item.inItemType;
              final itemsStr = item.items;

              // detailSubQuestions (있으면 펼쳐서 detailSub 처리)
              final detailSubQuestions = item.detailSubQuestions;

              // 체크박스 상태 (해당 sub의 선택들 모음)
              detailAnswers[mainId] ??= {};
              final selectedSet = detailAnswers[mainId]![subId] != null ? detailAnswers[mainId]![subId]!.split(',').where((s) => s.isNotEmpty).toSet() : <String>{};
              final checked = selectedSet.contains(itemId);

              // controllers (local)
              final controller1 = TextEditingController(text: detailAnswers[mainId]!['${keyValue}_1'] ?? '');
              final controller2 = TextEditingController(text: detailAnswers[mainId]!['${keyValue}_2'] ?? '');
              final textController = TextEditingController(text: detailAnswers[mainId]!['${keyValue}_text'] ?? '');

              // Build the main item row (checkbox + label + optional inputs)
              return ConstrainedBox(
                constraints: BoxConstraints(minWidth: subMinWidth, maxWidth: itemWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildSubItemRow(
                      context: context,
                      checked: checked,
                      label: label,
                      inputType: inputType,
                      unit: unit,
                      inItemType: inItemType,
                      itemsStr: itemsStr,
                      mainId: mainId,
                      subId: subId,
                      keyValue: keyValue,
                      detailAnswers: detailAnswers,
                      controller1: controller1,
                      controller2: controller2,
                      textController: textController,
                      refresh: () => setState(() {}),
                      onCheckedChanged: (v) {
                        setState(() {
                          if (v == true) {
                            selectedSet.add(itemId);
                          } else {
                            selectedSet.remove(itemId);

                            detailAnswers[mainId]!.removeWhere(
                              (k, _) => k.startsWith('$subId|$itemId') || k.contains('_dsq_'),
                            );
                          }

                          detailAnswers[mainId]![subId] = selectedSet.join(',');
                        });
                      },
                    ), // Show detailSubQuestions if exist and checked
                    buildDetailSubsIfAny(
                      context: context,
                      mainId: mainId,
                      subId: subId,
                      keyValue: keyValue,
                      visible: checked,
                      detailSubQuestions: (detailSubQuestions ?? []).cast<DetailSubQuestion>(),
                      detailAnswers: detailAnswers,
                      refresh: () => setState(() {}),
                      leftMargin: leftMargin,
                      detailSubBoxColor: detailSubBoxColor,
                      detailSubBoxBorderColor: detailSubBoxBorderColor,
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              );
            }).toList(),
          );
        }),
        const SizedBox(height: 12),
      ];
    }

    // 5) radio_with_input 처리
    if (subType == 'radio_with_input') {
      final subItems = sub.subItems;
      final double subMinWidth = sub.subMinWidth ?? 200.0;
      const double spacing = 12;

      detailAnswers[mainId] ??= {};
      final selectedValue = detailAnswers[mainId]![subId] ?? '';

      return [
        Text("$subId. $subTitle", style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        LayoutBuilder(builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;

          int perRow;
          if (subMinWidth <= 0) {
            perRow = 1;
          } else {
            int calculatedPerRow = (availableWidth + spacing) ~/ (subMinWidth + spacing);
            if (calculatedPerRow < 1) calculatedPerRow = 1;
            perRow = calculatedPerRow;
          }

          final itemWidth = (availableWidth - spacing * (perRow - 1)) / perRow;

          return Wrap(
            spacing: spacing,
            runSpacing: 8,
            children: subItems.map<Widget>((item) {
              final itemId = item.id;
              final label = item.label;
              final inputType = item.input;
              final unit = item.unit;
              final inItemType = item.inItemType;
              final itemsStr = item.items;

              final keyValue = '$subId|$itemId';
              final checked = selectedValue == itemId;

              // detailSubQuestions
              final detailSubQuestions = item.detailSubQuestions;

              // controllers
              final controller1 = TextEditingController(text: detailAnswers[mainId]!['${keyValue}_1'] ?? '');
              final controller2 = TextEditingController(text: detailAnswers[mainId]!['${keyValue}_2'] ?? '');
              final textController = TextEditingController(text: detailAnswers[mainId]!['${keyValue}_text'] ?? '');

              return ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: subMinWidth <= 0 ? availableWidth : subMinWidth,
                  maxWidth: itemWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// radio + label + input
                    buildSubItemRow(
                      context: context,
                      checked: checked,
                      label: label,
                      inputType: inputType,
                      unit: unit,
                      inItemType: inItemType,
                      itemsStr: itemsStr,
                      mainId: mainId,
                      subId: subId,
                      keyValue: keyValue,
                      detailAnswers: detailAnswers,
                      controller1: controller1,
                      controller2: controller2,
                      textController: textController,
                      refresh: () => setState(() {}),
                      isRadio: true, // ⭐ radio 모드
                      onCheckedChanged: (v) {
                        setState(() {
                          if (v == true) {
                            // 기존 radio 선택값 제거 + dsq 정리
                            detailAnswers[mainId]!.removeWhere(
                              (k, _) => k.startsWith('$subId|') || k.contains('_dsq_'),
                            );
                            detailAnswers[mainId]![subId] = itemId;
                          }
                        });
                      },
                    ),

                    /// detailSubQuestions (선택된 radio만)
                    buildDetailSubsIfAny(
                      context: context,
                      mainId: mainId,
                      subId: subId,
                      keyValue: keyValue,
                      visible: checked,
                      detailSubQuestions: (detailSubQuestions ?? []).cast<DetailSubQuestion>(),
                      detailAnswers: detailAnswers,
                      refresh: () => setState(() {}),
                      leftMargin: leftMargin,
                      detailSubBoxColor: detailSubBoxColor,
                      detailSubBoxBorderColor: detailSubBoxBorderColor,
                    ),

                    const SizedBox(height: 6),
                  ],
                ),
              );
            }).toList(),
          );
        }),
        const SizedBox(height: 12),
      ];
    }

    if (subType == 'text_with_input') {
      final subItems = sub.subItems;
      final double subMinWidth = sub.subMinWidth ?? 0;
      const double spacing = 8;

      return [
        Text(
          "$subId. $subTitle",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;

            return Wrap(
              spacing: spacing,
              runSpacing: 8,
              children: subItems.map<Widget>((item) {
                final itemId = item.id;
                final label = item.label;
                final inputType = item.input;
                final unit = item.unit;
                final items = item.items;

                final keyValue = '$subId|$itemId';

                detailAnswers[mainId] ??= {};

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: subMinWidth <= 0 ? availableWidth : subMinWidth,
                    maxWidth: availableWidth,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      /// label
                      Text(label),
                      const SizedBox(width: 6),

                      /// -------- inputType == 1 : unit 기반 동적 처리 --------
                      if (inputType == 1)
                        Builder(builder: (context) {
                          final units = unit.split('|').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

                          // unit 없으면 input 1개
                          if (units.isEmpty) {
                            final ctrl = TextEditingController(
                              text: detailAnswers[mainId]!['${keyValue}_1'] ?? '',
                            );

                            return SizedBox(
                              width: 70,
                              child: TextField(
                                controller: ctrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                ),
                                onChanged: (v) {
                                  detailAnswers[mainId]!['${keyValue}_1'] = v;
                                },
                              ),
                            );
                          }

                          // unit 개수만큼 input + unit 반복
                          return Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: List.generate(units.length, (i) {
                              final ctrl = TextEditingController(
                                text: detailAnswers[mainId]!['${keyValue}_${i + 1}'] ?? '',
                              );

                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 70,
                                    child: TextField(
                                      controller: ctrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                      ),
                                      onChanged: (v) {
                                        detailAnswers[mainId]!['${keyValue}_${i + 1}'] = v;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(units[i]),
                                ],
                              );
                            }),
                          );
                        }),

                      /// -------- inputType == 2 (기존 유지) --------
                      if (inputType == 2) ...[
                        SizedBox(
                          width: 70,
                          child: TextField(
                            controller: TextEditingController(
                              text: detailAnswers[mainId]!['${keyValue}_1'] ?? '',
                            ),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                            ),
                            onChanged: (v) {
                              detailAnswers[mainId]!['${keyValue}_1'] = v;
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 70,
                          child: TextField(
                            controller: TextEditingController(
                              text: detailAnswers[mainId]!['${keyValue}_2'] ?? '',
                            ),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                            ),
                            onChanged: (v) {
                              detailAnswers[mainId]!['${keyValue}_2'] = v;
                            },
                          ),
                        ),
                      ],

                      const SizedBox(width: 6),

                      /// items (suffix text)
                      if (items.isNotEmpty) Text(items),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 12),
      ];
    }

    // default
    return [const SizedBox.shrink()];
  }
}

// =======================================================
// RightContentPanel: 선택된 SurveyItem의 질문들을 렌더링하는 컨테이너
// =======================================================
class RightContentPanel extends StatelessWidget {
  final SurveyItem? selectedItem;
  final int maxPageNumber; // 전체 페이지 수 (전체 SurveyItem의 개수)
  final VoidCallback onPrevItem;
  final VoidCallback onNextItem;

  const RightContentPanel({
    required this.selectedItem,
    required this.maxPageNumber,
    required this.onPrevItem,
    required this.onNextItem,
    super.key,
  });

  // 제출 로직 (더미)
  void _submitSurvey() {
    // TODO: 실제 서버 제출 로직 구현
    print('Survey Submitted!');
    // 제출 후 다음 항목으로 이동하거나 완료 메시지 표시
    onNextItem();
  }

  // --------------------------
  // 하단 페이지 바 (이전으로, 현재/전체, 다음으로)
  // --------------------------
  Widget buildPaginationBar(int currentPage, int totalPages, bool isLastItem) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: Colors.white,
      child: Row(
        // Row의 자식들을 가운데로 정렬합니다.
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. 이전 버튼
          // 버튼의 최대 크기를 제한하기 위해 Expanded 대신 Flexible을 사용합니다.
          Flexible(
            // 버튼이 너무 커지지 않도록 최대 너비를 설정하거나
            // Flexible의 flex 속성을 조정할 수 있습니다. (기본값 flex: 1)
            child: SizedBox(
              width: 150, // 버튼의 최대 너비를 지정
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ElevatedButton.icon(
                  onPressed: currentPage > 1 ? onPrevItem : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text("이전", style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
          ),

          // 2. 현재 페이지 / 전체 페이지 번호
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '$currentPage / $totalPages',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),

          // 3. 다음 버튼 또는 제출 버튼
          // 버튼의 최대 크기를 제한하기 위해 Expanded 대신 Flexible을 사용합니다.
          Flexible(
            child: SizedBox(
              width: 150, // 버튼의 최대 너비를 지정
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: ElevatedButton(
                  // 마지막 항목인 경우 _submitSurvey 호출, 아니면 다음 항목으로 이동 요청
                  onPressed: isLastItem ? _submitSurvey : onNextItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLastItem ? Colors.green : Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isLastItem ? '제출' : '다음', style: const TextStyle(fontSize: 18)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (selectedItem == null) {
      return const Center(child: Text('왼쪽 메뉴에서 설문 항목을 선택해주세요.'));
    }

    final List<Question> currentQuestions = selectedItem!.surveyContent.questions;
    final currentPage = selectedItem!.pageNumber;
    final totalPages = maxPageNumber;
    final isLastItem = currentPage == totalPages;

    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          // 1. 메인 콘텐츠 (스크롤 영역)
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // 하단 탐색 바 높이만큼 패딩
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 설문 제목 및 부가 정보
                Text(
                  '<${selectedItem!.category}>',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.blue[700]),
                ),
                const SizedBox(height: 8), // 카테고리와 제목 사이 간격
                // ⭐️ [수정] 제목이 전체 너비를 사용하도록 SizedBox.expand/double.infinity로 감쌉니다.
                SizedBox(
                  width: double.infinity,
                  child: Text(selectedItem!.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                ),
                const Divider(height: 30, thickness: 2),

                // ⭐️ QuestionDisplayWidget을 사용하여 질문 목록 렌더링
                ...currentQuestions.asMap().entries.map((entry) {
                  return QuestionDisplayWidget(
                    question: entry.value,
                    index: entry.key + 1,
                  );
                }).toList(),

                const SizedBox(height: 20), // 마지막 질문과 하단 바 사이 여백
              ],
            ),
          ),

          // 2. 하단 페이지 탐색 바 (화면 하단에 고정)
          Positioned(bottom: 0, left: 0, right: 0, child: buildPaginationBar(currentPage, totalPages, isLastItem)),
        ],
      ),
    );
  }
}
