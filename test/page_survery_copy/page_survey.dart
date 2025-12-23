// page_survey.dart (데이터 모델을 채용하도록 변경된 최종 버전)

import 'dart:convert';
import 'data_models.dart';
import 'package:Vincere/utils/http/webReqFastapi.dart';
import 'package:flutter/material.dart';

//
//
//
//
class QuestionDisplayWidget extends StatefulWidget {
  final Map<String, dynamic> question;
  final List<Map<String, dynamic>> questions;
  const QuestionDisplayWidget({required this.question, required this.questions, super.key});

  @override
  State<QuestionDisplayWidget> createState() => _QuestionDisplayWidgetState();
}

class _QuestionDisplayWidgetState extends State<QuestionDisplayWidget> {
  // 스타일 정의
  final Color mainBoxColor = Colors.grey.shade200;
  final Color mainBoxBorderColor = Colors.grey.shade400;
  final Color subBoxColor = Colors.grey.shade200;
  final Color subBoxBorderColor = Colors.grey.shade400;
  final Color detailBoxColor = Colors.grey.shade100; // Level 3 박스 스타일 추가
  final Color detailBoxBorderColor = Colors.grey.shade300; // Level 3 박스 스타일 추가
  static const double leftMargin = 25.0;

  // [추가] Level 3 박스 스타일 정의
  final Color detailSubBoxColor = Colors.grey.shade200;
  final Color detailSubBoxBorderColor = Colors.grey.shade400;

  Map<String, String?> answers = {};
  List<Map<String, dynamic>> subQuestions = [];

  //
  //
  //
  //
  @override
  void initState() {
    super.initState();
    for (final question in widget.questions) {
      if (question['QUESTION_TYPE'] == 'SUB') {
        subQuestions.add(question);
      }
    }
  }

  //
  //
  //
  //
  @override
  Widget build(BuildContext context) {
    final question = widget.question;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16), // 질문 간 간격 유지
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // question box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(color: mainBoxColor, borderRadius: BorderRadius.circular(6), border: Border.all(color: mainBoxBorderColor, width: 0.5)),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.grey.shade500, borderRadius: BorderRadius.circular(6)),
                  child: Text(question['ID'].toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text("${question['QUESTION']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              ],
            ),
          ),

          // answer box
          const SizedBox(height: 12), // Header와 Input 사이 간격
          buildMainInput(question),
        ],
      ),
    );
  }

//
//
//
//
//
//
//
//
  //
  Widget buildMainInput(Map<String, dynamic> question) {
    List<dynamic> decode1 = jsonDecode(question['ANSWER_ITEMS'])['items'];
    List<dynamic> decode2 = jsonDecode(question['SUB_QUESTION_COND'])['sub_question_cond'];

    final List<Map<String, dynamic>> answerItems = (decode1 as List).cast<Map<String, dynamic>>();
    final List<Map<String, dynamic>> questionCond = (decode2 as List).cast<Map<String, dynamic>>();
    final currentValue = answers[question["ID"].toString()];

    final subBox = BoxDecoration(color: subBoxColor, borderRadius: BorderRadius.circular(8.0), border: Border.all(color: subBoxBorderColor, width: 1.0));

    //
    //
    //
    //
    if (question['FORM_TYPE'] == 'none') {
      // subQuestions를 바로 출력
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: questionCond.expand((cond) {
            return [
              Padding(
                padding: const EdgeInsets.only(left: leftMargin, top: 4.0, bottom: 4.0),
                child: Container(width: double.infinity, padding: const EdgeInsets.all(12.0), decoration: subBox, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _buildSubQuestion(question, cond['id']))),
              )
            ];
          }).toList());
    }
    //
    //
    //
    //
    if (question['FORM_TYPE'] == 'radio') {
      return Column(
          children: answerItems.map((opt) {
        final isSelected = currentValue == opt['text'];
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RadioListTile<String>(
              title: Text(opt["text"]),
              value: opt['text'],
              groupValue: currentValue,
              onChanged: (v) {
                answers[question["ID"].toString()] = v;
                setState(() {});
              }),
          if (isSelected)
            ...questionCond.where((cond) => cond['value'] == opt['text']).expand((cond) {
              return [
                Padding(
                    padding: const EdgeInsets.only(left: leftMargin, top: 4.0, bottom: 4.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12.0),
                      decoration: subBox,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _buildSubQuestion(question, cond['id'])), //,
                    ))
              ];
            }).toList(),
        ]);
      }).toList());
    }
    //
    //
    //
    //
    if (question['FORM_TYPE'] == 'checkbox') {
      final List<String> selectedList = (currentValue ?? '').toString().isEmpty ? [] : currentValue.toString().split('|').where((s) => s.isNotEmpty).toList();
      final otherController = TextEditingController(text: answers['${question['ID']}_other'] ?? '');

      return Column(
        children: answerItems.map((opt) {
          final checked = selectedList.contains(opt['text']);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CheckboxListTile(
                  value: checked,
                  title: Text(opt['text']),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        if (!selectedList.contains(opt['text'])) selectedList.add(opt['text']);
                      } else {
                        selectedList.remove(opt['text']);
                      }
                      answers[question["ID"].toString()] = selectedList.join('|');
                    });
                  }),

              //
              if (checked)
                ...questionCond.expand((sub) {
                  return [
                    Padding(
                      padding: const EdgeInsets.only(left: 40.0, top: 4.0, bottom: 4.0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12.0), // 내용물 내부 패딩
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50, // 밝은 파란색 배경
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.blue.shade200, width: 1.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildSubQuestion(question, sub['id']),
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
    //
    //
    //
    //
    // TEXT
    if (question['FORM_TYPE'] == 'text') {
      final controller = TextEditingController(text: answers[question['ID'].toString()] ?? '');
      final int lines = 1; //_parseTextLines(answerItems);

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
          answers[question["ID"].toString()] = v;
        },
      );
    }

    //
    //
    //
    //
    // CHECKBOX WITH INPUT (checkbox 와 동일한 레이아웃)
    if (question['FORM_TYPE'] == 'checkbox_with_input') {
      final List<String> selectedList = (currentValue ?? '').toString().isEmpty ? [] : currentValue.toString().split('|').where((s) => s.isNotEmpty).toList();

      return Column(
        children: answerItems.map((rawOpt) {
          String label = rawOpt['text'];
          bool alwaysShowInput = false;

          if (rawOpt['text'].contains('|')) {
            final parts = rawOpt['text'].split('|');
            label = parts[0];
            alwaysShowInput = parts.length > 1 && parts[1] == 'true';
          }

          final checked = selectedList.contains(label);
          final inputKey = '${question['ID'].toString()}_${label}_input';
          final controller = TextEditingController(text: answers[inputKey] ?? '');

          return CheckboxListTile(
            controlAffinity: ListTileControlAffinity.leading,
            value: checked,
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  if (!selectedList.contains(label)) selectedList.add(label);
                } else {
                  selectedList.remove(label);
                }
                answers[question['ID'].toString()] = selectedList.join('|');
              });
            },

            // ✅ title 영역에 Row 삽입
            title: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
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
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    onChanged: (v) => answers[inputKey] = v,
                  ),
                )
              ]
            ]),
          );
        }).toList(),
      );
    }

    //
    //
    //
    //
    if (question['FORM_TYPE'] == 'text_with_input') {
      final List<String> opts = (answerItems as List).map((e) => e['text'].toString()).toList();
      final String prefixLabel = opts.first;

      // 마지막 처리
      String lastRaw = opts.last;
      bool hasClosingParen = lastRaw.endsWith(')');
      String lastUnit = hasClosingParen ? lastRaw.substring(0, lastRaw.length - 1) : lastRaw;
      final List<String> units = [...opts.sublist(1, opts.length - 1), lastUnit];

      return Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 6, children: [
        Text(prefixLabel),
        ...units.map((unit) {
          final String key = '${question['ID'].toString()}_$unit';
          return Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: 70,
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                onChanged: (v) => answers[key] = v,
              ),
            ),
            const SizedBox(width: 4),
            Text(unit),
          ]);
        }),
        if (hasClosingParen) const Text(')'),
      ]);
    }

    // 기본값 (지원하지 않는 타입이면 빈박스)
    return const SizedBox.shrink();
  }

//
//
//
//
//
//
//
//
//

//
//
//
//
//
  List<Widget> _buildSubQuestion(Map<String, dynamic> question, int subQuestionId) {
    Map subQuestion = {};
    for (int i = 0; i < widget.questions.length; i++) {
      if (widget.questions[i]["ID"] == subQuestionId) {
        subQuestion = widget.questions[i];
        break;
      }
    }
    List<dynamic> decode1 = jsonDecode(subQuestion['ANSWER_ITEMS'])['items'];
    List<dynamic> decode2 = jsonDecode(subQuestion['SUB_QUESTION_COND'])['sub_question_cond'];

    final List<Map<String, dynamic>> answerItems = (decode1 as List).cast<Map<String, dynamic>>();
    final List<Map<String, dynamic>> questionCond = (decode2 as List).cast<Map<String, dynamic>>();

    final currentValue = answers[subQuestion["ID"].toString()];
    Widget titleText = Column(
      children: [
        const SizedBox(height: 6),
        Text("${subQuestion['ID']}. ${subQuestion['QUESTION']}", style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );

    if (subQuestion['FORM_TYPE'] == 'text') {
      final controller = TextEditingController(text: currentValue ?? '');
      return [
        titleText,
        TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: "${subQuestion['QUESTION']} 입력",
              filled: true,
              fillColor: Colors.white,
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) => answers[subQuestion['ID'].toString()] = v),
        const SizedBox(height: 12),
      ];
    }

    // 3) checkbox_with_input (모든 inputType 처리 + detailSubQuestions 펼침)
    if (subQuestion['FORM_TYPE'] == 'checkbox_with_input') {
      // [수정 1] subMinWidth 값을 가져옴 (기본값 200, 0이 들어오면 0으로 처리)
      const double subMinWidth = 200.0;
      const double spacing = 12;

      return [
        titleText,
        LayoutBuilder(builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          int perRow;
          if (subMinWidth <= 0) {
            perRow = 1;
          } else {
            // 공간 계산: (전체너비 + 간격) / (최소너비 + 간격)
            int calculatedPerRow = (availableWidth + spacing) ~/ (subMinWidth + spacing);
            if (calculatedPerRow < 1) calculatedPerRow = 1; // 최소 1개는 출력
            perRow = calculatedPerRow;
          }

          // [수정 3] 아이템 하나의 정확한 너비 계산
          // perRow가 1이면 (availableWidth / 1)이 되어 꽉 차게 됨
          final itemWidth = (availableWidth - (spacing * (perRow - 1))) / perRow;
          return Wrap(
            spacing: spacing,
            runSpacing: 8,
            children: answerItems.map<Widget>((item) {
              return ConstrainedBox(
                constraints: BoxConstraints(minWidth: subMinWidth, maxWidth: itemWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildSubItemRow(question, subQuestion, item, false),
                    /*buildDetailSubsIfAny(),*/
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

    // 2) TEXT + DATE 입력
    if (subQuestion['FORM_TYPE'] == 'text_with_date') {
      final controller = TextEditingController(text: currentValue ?? '');
      String dateType = 'YYYY';
      double maxWidth = 100.0;

      return [
        titleText,
        Row(
          children: [
            ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: TextField(controller: controller, decoration: const InputDecoration(border: OutlineInputBorder()), onChanged: (v) => answers[subQuestion['ID'].toString()] = v)),
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
                      answers[subQuestion['ID'].toString()] = pickedYear.toString();
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
                      answers[subQuestion['ID'].toString()] = formattedDate;
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

    // 5) radio_with_input 처리
    if (subQuestion['FORM_TYPE'] == 'radio_with_input') {
      final double subMinWidth = 200.0;
      const double spacing = 12;

      return [
        titleText,
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
            children: answerItems.map<Widget>((item) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: subMinWidth <= 0 ? availableWidth : subMinWidth,
                  maxWidth: itemWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// radio + label + input
                    buildSubItemRow(question, subQuestion, item, true),

                    /// detailSubQuestions (선택된 radio만)
                    //buildDetailSubsIfAny(),
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

    if (subQuestion['FORM_TYPE'] == 'text_with_input') {
      final subItems = answerItems;
      double subMinWidth = 0;
      const double spacing = 8;

      return [
        titleText,
        LayoutBuilder(builder: (context, constraints) {
          return Wrap(
            spacing: spacing,
            runSpacing: 8,
            children: subItems.map<Widget>((item) {
              final itemId = item['id'];
              final label = item['text'];
              final inputType = item['input'];
              final unit = item['unit'];
              final items = item['items'];
              final String unitStr = (unit ?? '').toString();

              final keyValue = '$subQuestionId|$itemId';

              return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth,
                  ),
                  child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                    /// label
                    Text(label),
                    const SizedBox(width: 6),

                    /// -------- inputType == 1 : unit 기반 동적 처리 --------
                    if (inputType == 1)
                      Builder(builder: (context) {
                        final units = unitStr.split('|').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

                        // unit 없으면 input 1개
                        if (units.isEmpty) {
                          final ctrl = TextEditingController(text: answers['${question['ID']}_${keyValue}_1'] ?? '');
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
                              onChanged: (v) => answers['${question['ID']}_${keyValue}_1'] = v,
                            ),
                          );
                        }

                        // unit 개수만큼 input + unit 반복
                        return Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: List.generate(units.length, (i) {
                            final ctrl = TextEditingController(text: answers['${question['ID']}_${keyValue}_${i + 1}'] ?? '');

                            return Row(mainAxisSize: MainAxisSize.min, children: [
                              SizedBox(
                                  width: 70,
                                  child: TextField(
                                    controller: ctrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8)),
                                    onChanged: (v) {
                                      answers['${question['ID']}_${keyValue}_${i + 1}'] = v;
                                    },
                                  )),
                              const SizedBox(width: 4),
                              Text(units[i]),
                            ]);
                          }),
                        );
                      }),

                    /// -------- inputType == 2 (기존 유지) --------
                    if (inputType == 2) ...[
                      SizedBox(
                        width: 70,
                        child: TextField(
                          controller: TextEditingController(text: answers['${question['ID']}_${keyValue}_1'] ?? ''),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8)),
                          onChanged: (v) {
                            answers['${question['ID']}_${keyValue}_1'] = v;
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                          width: 70,
                          child: TextField(
                            controller: TextEditingController(text: answers['${question['ID']}_${keyValue}_2'] ?? ''),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8)),
                            onChanged: (v) {
                              answers['${question['ID']}_${keyValue}_2'] = v;
                            },
                          ))
                    ],
                    const SizedBox(width: 6),
                    if (items.isNotEmpty) Text(items),
                  ]));
            }).toList(),
          );
        }),
        const SizedBox(height: 12),
      ];
    }
    // default
    return [titleText];
  }

  Widget buildSubItemRow(Map question, Map subQuestion, Map item, bool isRadio) {
    String label = item['text'].toString();
    String unit = item['unit'].toString();
    String inputType = item['input'].toString();
    String inItemType = item['inItemType'].toString();
    String itemsStr = item['items'].toString();
    String mainId = question['ID'].toString();
    final keyValue = '${subQuestion['ID']}|${item['id']}';
    final controller1 = TextEditingController(text: answers['${mainId}_${keyValue}_1'] ?? '');
    final controller2 = TextEditingController(text: answers['${mainId}_${keyValue}_2'] ?? '');
    final textController = TextEditingController(text: answers['${mainId}_${keyValue}_text'] ?? '');

    final currentValue = answers[subQuestion["ID"].toString()];
    final isSelected = currentValue;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isRadio)
          Radio<String>(
            value: item['id'].toString(),
            groupValue: currentValue,
            onChanged: (v) {
              setState(() {});
            },
          )
        else
          Checkbox(
            value: answers["${subQuestion["ID"]}_${item['id']}_check"] == '',
            onChanged: (v) {
              setState(() {
                answers["${subQuestion["ID"]}_${item['id']}_check"] = 'o';
              });
            },
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
              if (inputType == '1') ...[
                Builder(builder: (context) {
                  final units = unit.split('|').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

                  // unit 이 없으면 input 1개만
                  if (units.isEmpty) {
                    return SizedBox(
                      width: 80,
                      child: TextField(
                        controller: controller1,
                        decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                        onChanged: (v) => answers['${mainId}_${keyValue}_1'] = v,
                      ),
                    );
                  }
                  // unit 개수만큼 input 생성
                  return Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: List.generate(units.length, (i) {
                        final ctrl = TextEditingController(text: answers['${mainId}_${keyValue}_${i + 1}'] ?? '');
                        return Row(mainAxisSize: MainAxisSize.min, children: [
                          SizedBox(
                            width: 70,
                            child: TextField(
                              controller: ctrl,
                              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                              onChanged: (v) => answers['${mainId}_${keyValue}_${i + 1}'] = v,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(units[i]),
                        ]);
                      }));
                })
              ],

              // ---------------- inputType 2 ----------------
              if (inputType == '2') ...[
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: controller1,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    onChanged: (v) {
                      answers['${mainId}_${keyValue}_1'] = v;
                    },
                  ),
                ),
                const Text(')'),
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: controller2,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    onChanged: (v) {
                      answers['${mainId}_${keyValue}_2'] = v;
                    },
                  ),
                ),
                if (unit.isNotEmpty) Text(unit),
              ],

              // ---------------- inputType 3 ----------------
              if (inputType == '3') ...[
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: controller1,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    onChanged: (v) {
                      answers['${mainId}_${keyValue}_1'] = v;
                    },
                  ),
                ),
                if (unit.isNotEmpty) Text(unit),
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: controller2,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    onChanged: (v) {
                      answers['${mainId}_${keyValue}_2'] = v;
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
                      answers['${mainId}_${keyValue}_2'] = year.toString();
                      setState(() {});
                    }
                  },
                ),
                Text(")"),
              ],

              // ---------------- inputType 4 ----------------
              if (inputType == '4') ...[
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: controller1,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    onChanged: (v) {
                      answers['${mainId}_${keyValue}_1'] = v;
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
                      answers['${mainId}_${keyValue}_1'] = year.toString();
                    }
                  },
                ),
              ],

              // ---------------- inputType 5 ----------------
              if (inputType == '5') ...[
                if (inItemType == 'text')
                  SizedBox(
                    width: 160,
                    child: TextField(
                      controller: textController,
                      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                      onChanged: (v) {
                        answers['${mainId}_${keyValue}_text'] = v;
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
                    final saved = answers['${mainId}_${keyValue}_$subLabel'] ?? '';
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
                              answers['${mainId}_${subKey}_input'] = '';
                            }
                            answers['${mainId}_${subKey}'] = set.join(',');
                            setState(() {});
                          },
                        ),
                        Text(subLabel),
                        if (extType == 'text_with_input') ...[
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 120,
                            child: TextField(
                              enabled: true,
                              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                              onChanged: (v) {
                                answers['${mainId}_${subKey}_input'] = v;
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
                    final selected = answers['${mainId}_${subKey}'] ?? '';

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Radio<String>(
                          value: subLabel,
                          groupValue: selected,
                          onChanged: (v) {
                            answers['${mainId}_${subKey}'] = v;
                            setState(() {});
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
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
/*
  // Part 3 of 3: _buildDetailInputs (put this inside the same class _PageSurveyState)
  Widget buildDetailSubsIfAny(
    Map question,
    Map subQuestion,
    Map item
    ) {
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
*/

  //
  //
  //
  //
  //
  //
  //
  //
  //
  //
  //
  //
  //
  //
  //
  //
  //
  //
  //
  //
  //
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
          perRow = 1;
        } else {
          perRow = (availableWidth + spacing) ~/ (itemMinWidth + spacing);
          if (perRow < 1) perRow = 1;
        }

        final itemWidth = (availableWidth - spacing * (perRow - 1)) / perRow;

        return Wrap(
          spacing: spacing,
          runSpacing: 8,
          children: children.map((child) {
            return SizedBox(width: itemWidth, child: child);
          }).toList(),
        );
      },
    );
  }
}

class RightContentPanel extends StatefulWidget {
  final SurveyItem? selectedItem;
  final int maxPageNumber;
  final VoidCallback onPrevItem;
  final VoidCallback onNextItem;

  const RightContentPanel({
    required this.selectedItem,
    required this.maxPageNumber,
    required this.onPrevItem,
    required this.onNextItem,
    super.key,
  });

  @override
  State<RightContentPanel> createState() => _RightContentPanelState();
}

class _RightContentPanelState extends State<RightContentPanel> {
  List<Map<String, dynamic>> questions = [];
  List<Map<String, dynamic>> rootQuestions = [];

  @override
  void initState() {
    super.initState();
    _load_survey_questions();
  }

  Future<void> _load_survey_questions() async {
    try {
      final ApiServiceFast apiService = ApiServiceFast();
      questions = (await apiService.select_survey_questions(widget.selectedItem!.id));
      rootQuestions = []; // init
      for (int i = 0; i < questions.length; i++) {
        if (questions[i]['QUESTION_TYPE'] == "ROOT") {
          rootQuestions.add(questions[i]);
        }
      }
      print("initialize survey questions done");
      setState(() {});
    } catch (e) {
      print('Error initializing data: $e');
    }
  }

  @override
  void didUpdateWidget(covariant RightContentPanel oldWidget) {
    // 부모 Prop(survey/page_home.dart) 변경을 기다린 후에 db를 업데이트 해야함
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedItem?.id != widget.selectedItem?.id) {
      _load_survey_questions();
    }
  }

  void _submitSurvey() {
    print('Survey Submitted!');
    widget.onNextItem();
  }

  @override
  Widget build(BuildContext context) {
    print(widget.selectedItem?.id);
    if (widget.selectedItem == null) {
      return const Center(child: Text('왼쪽 메뉴에서 설문 항목을 선택해주세요.'));
    }

    //final List<Question> currentQuestions = selectedItem!.surveyContent.questions;
    final currentPage = widget.selectedItem!.pageNumber;
    final totalPages = widget.maxPageNumber;
    final isLastItem = currentPage == totalPages;

    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          // 1. contents
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // 하단 탐색 바 높이만큼 패딩
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('<${widget.selectedItem!.category}>', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.blue[700])),
                const SizedBox(height: 8),
                SizedBox(child: Text(widget.selectedItem!.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87))),
                const Divider(height: 30, thickness: 2),

                // render questions list
                Column(
                    children: rootQuestions.asMap().entries.map((entry) {
                  return QuestionDisplayWidget(question: entry.value, questions: questions);
                }).toList()),
                const SizedBox(height: 20), // 마지막 질문과 하단 바 사이 여백
              ],
            ),
          ),

          // 2. pagination
          Positioned(bottom: 0, left: 0, right: 0, child: buildPaginationBar(currentPage, totalPages, isLastItem)),
        ],
      ),
    );
  }

  //
  //
  //
  //
  Widget buildPaginationBar(int currentPage, int totalPages, bool isLastItem) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // prev button
            Flexible(
                child: SizedBox(
                    width: 150, // 버튼의 최대 너비를 지정
                    child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (currentPage > 1) {
                              widget.onPrevItem();
                            } else {}
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text("이전", style: TextStyle(fontSize: 18)),
                        )))),
            //page explain
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('$currentPage / $totalPages', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
            ),
            // next or submit button
            Flexible(
                child: SizedBox(
                    width: 150, // 버튼의 최대 너비를 지정
                    child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: ElevatedButton(
                          onPressed: () async {
                            if (isLastItem) {
                              _submitSurvey();
                            } else {
                              widget.onNextItem();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isLastItem ? Colors.green : Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            foregroundColor: Colors.white,
                          ),
                          child: Text(isLastItem ? '제출' : '다음', style: const TextStyle(fontSize: 18)),
                        ))))
          ],
        ));
  }
}
