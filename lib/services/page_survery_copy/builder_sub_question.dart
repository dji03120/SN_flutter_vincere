import 'dart:convert';

import 'package:Vincere/provider_models.dart';
import 'package:Vincere/services/page_survery_copy/builder_detail_question.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

//
//
//
//
//
//
bool hasValue(Map ans) {
  if (ans.isEmpty) return false;
  // 모든 value가 null 또는 빈 문자열이면 false
  return ans.values.any((v) => v != null && v.toString().isNotEmpty);
}
//
//
//
//
//

class SubQuestionBuilder {
  final Map<String, dynamic> mainQuestion;
  final void Function(VoidCallback fn) setState;
  final Function onChanged;
  final int subQuestionId;
  final BuildContext context;

  late Map<String, dynamic> answers;
  late List<Map<String, dynamic>> questions;
  late Map<String, dynamic> subQuestion;
  late List<Map<String, dynamic>> answerItems;
  late final List<Map<String, dynamic>> questionCond;
  late final double minWidth;
  late final String? currentValue;
  late final Widget titleText;
  late UserModel userModel;

  SubQuestionBuilder({
    required this.subQuestionId,
    required this.mainQuestion,
    required this.setState,
    required this.onChanged,
    required this.context,
  }) {
    userModel = Provider.of<UserModel>(context, listen: false);
    questions = userModel.surveyQuestions;
    answers = userModel.surveyAnswers;
    subQuestion = {};
    for (int i = 0; i < questions.length; i++) {
      if (questions[i]["ID"] == subQuestionId) {
        subQuestion = questions[i];
        break;
      }
    }
    answerItems = (jsonDecode(subQuestion['ANSWER_ITEMS'])['items'] as List).cast<Map<String, dynamic>>();
    minWidth = jsonDecode(subQuestion['ANSWER_ITEMS'])['minWidth'] as double;
    questionCond = (jsonDecode(subQuestion['SUB_QUESTION_COND'])['sub_question_cond'] as List).cast<Map<String, dynamic>>();
    currentValue = answers[subQuestion['ID']];

    titleText = Column(children: [
      const SizedBox(height: 6),
      Text("${subQuestion['QUESTION_ID']}. ${subQuestion['QUESTION']}", style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 14),
    ]);
  }

  List<Widget> build() {
    switch (subQuestion['FORM_TYPE']) {
      case 'text':
        return _build_text();
      case 'checkbox_with_input':
        return _build_checkbox_with_input();
      case 'text_with_date':
        return _build_text_with_date();
      case 'radio_with_input':
        return _build_radio_with_input();
      case 'text_with_input':
        return _build_text_with_input();
      default:
        return [const SizedBox.shrink()];
    }
  }

//
//
//
//
  List<Widget> _build_text() {
    final controller = TextEditingController(text: currentValue ?? '');
    return [
      titleText,
      TextField(
        controller: controller,
        onChanged: (v) => answers[subQuestion['ID'].toString()] = v,
        decoration: InputDecoration(
          hintText: "${subQuestion['QUESTION']} 입력",
          filled: true,
          fillColor: Colors.white,
          border: const OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
    ];
  }

//
//
//
//
  List<Widget> _build_checkbox_with_input() {
    const double spacing = 12;

    return [
      titleText,
      LayoutBuilder(builder: (context, constraints) {
        final qid = subQuestion['ID'].toString();
        answers.putIfAbsent(qid, () => {});
        for (int i = 0; i < answerItems.length; i++) {
          if (answerItems[i].containsKey('id')) {
            answers[qid]!.putIfAbsent(answerItems[i]['id'].toString(), () => {});
          }
        }
        return Wrap(
          spacing: spacing,
          runSpacing: 8,
          children: answerItems.map<Widget>((item) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: minWidth <= 0 ? 10 : minWidth,
                maxWidth: minWidth <= 0 ? 115 : minWidth + 100,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SurveySubItem(
                    item: item,
                    subQuestion: subQuestion,
                    isRadio: false,
                    context: context,
                    onChanged: onChanged,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ...questionCond.where((cond) {
                        print(answers["${subQuestion['ID']}"]["${item['id']}"]);
                        print(cond);
                        print(item);
                        return hasValue(answers["${subQuestion['ID']}"]["${item['id']}"]) && (cond['value'] == item['text']);
                      }).expand((cond) {
                        return DetailQuestionBuilder(
                          subQuestion: subQuestion,
                          mainQuestion: mainQuestion,
                          subQuestionItemId: item['id'],
                          detailQuestionId: cond['id'],
                          setState: setState,
                          context: context,
                        ).build();
                      })
                    ],
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

//
//
//
//
  List<Widget> _build_text_with_date() {
    TextEditingController controller = TextEditingController(text: answers[subQuestion['ID'].toString()] ?? '');
    String dateType = 'YYYY';
    double maxWidth = 100.0;

    return [
      titleText,
      Row(
        children: [
          ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onChanged: (v) => answers[subQuestion['ID'].toString()] = v,
              )),
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
                                  onChanged: (DateTime dateTime) => Navigator.pop(context, dateTime.year),
                                )));
                      });
                  if (pickedYear != null) {
                    controller.text = pickedYear.toString();
                    setState(() => userModel.save_answer(subQuestion['ID'].toString(), pickedYear.toString()));
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
                    setState(() => userModel.save_answer(subQuestion['ID'].toString(), formattedDate));
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

  List<Widget> _build_radio_with_input() {
    const double spacing = 12;
    return [
      titleText,
      LayoutBuilder(builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final double effectiveMinWidth = minWidth <= 0 ? availableWidth : minWidth;
        final qid = subQuestion['ID'].toString();
        answers.putIfAbsent(qid, () => {});
        for (int i = 0; i < answerItems.length; i++) {
          if (answerItems[i].containsKey('id')) {
            answers[qid]!.putIfAbsent(answerItems[i]['id'].toString(), () => {});
          }
        }
        return Wrap(
          spacing: spacing,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: answerItems.map<Widget>((item) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: minWidth <= 0 ? 10 : minWidth,
                maxWidth: minWidth <= 0 ? 115 : minWidth + 100,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SurveySubItem(
                    item: item,
                    subQuestion: subQuestion,
                    isRadio: true,
                    context: context,
                    onChanged: onChanged,
                  ),
                  ...questionCond.where((cond) {
                    return (answers["${subQuestion['ID']}"]['checked'] == item['text']) && (cond['value'] == item['text']);
                  }).expand(
                    (cond) {
                      return DetailQuestionBuilder(
                        subQuestion: subQuestion,
                        mainQuestion: mainQuestion,
                        subQuestionItemId: 0,
                        detailQuestionId: cond['id'],
                        setState: setState,
                        context: context,
                      ).build();
                    },
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

//
//
//

//
  List<Widget> _build_text_with_input() {
    final subItems = answerItems;
    const double spacing = 8;
    answers.putIfAbsent('${subQuestion['ID']}', () => {});

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

            return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth),
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
                        return SizedBox(
                            width: 70,
                            child: TextField(
                                controller: TextEditingController(text: answers['${subQuestion['ID']}']['1'] ?? ''),
                                keyboardType: TextInputType.number,
                                onChanged: (v) => answers['${subQuestion['ID']}']['1'] = v,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                )));
                      }

                      // unit 개수만큼 input + unit 반복
                      return Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: List.generate(units.length, (i) {
                            return Row(mainAxisSize: MainAxisSize.min, children: [
                              SizedBox(
                                  width: 70,
                                  child: TextField(
                                      controller: TextEditingController(text: answers['${subQuestion['ID']}'][units[i]] ?? ''),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) => answers['${subQuestion['ID']}'][units[i]] = v,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                      ))),
                              const SizedBox(width: 4),
                              Text(units[i]),
                            ]);
                          }));
                    }),

                  /// -------- inputType == 2 (기존 유지) --------
                  if (inputType == 2) ...[
                    SizedBox(
                        width: 70,
                        child: TextField(
                            controller: TextEditingController(text: answers['${subQuestion['ID']}']['1'] ?? ''),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => answers['${subQuestion['ID']}']['1'] = v,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                            ))),
                    const SizedBox(width: 6),
                    SizedBox(
                        width: 70,
                        child: TextField(
                          controller: TextEditingController(text: answers['${subQuestion['ID']}']['2'] ?? ''),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => answers['${subQuestion['ID']}']['2'] = v,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                          ),
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
class SurveySubItem extends StatefulWidget {
  final Map subQuestion;
  final bool isRadio;
  final BuildContext context;
  final Map item;
  final Function onChanged;

  late Map<String, dynamic> answers;
  late UserModel userModel;

  SurveySubItem({
    super.key,
    required this.item,
    required this.subQuestion,
    required this.isRadio,
    required this.context,
    required this.onChanged,
  }) {
    userModel = Provider.of<UserModel>(context, listen: false);
    answers = userModel.surveyAnswers;
  }

  @override
  State<SurveySubItem> createState() => _SurveySubItemState();
}

class _SurveySubItemState extends State<SurveySubItem> {
  final Map<String, TextEditingController> _controllers = {};

  TextEditingController ctrl(String key, String initial) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(text: widget.answers[key] ?? initial);
    }
    return _controllers[key]!;
  }

  @override
  Widget build(BuildContext context) {
    final qid = widget.subQuestion['ID'].toString();
    return Column(children: [_buildSubItemRow(qid, widget.item)]);
  }

  //
  //
  Widget _buildSubItemRow(String qid, Map item) {
    final iid = item['id'].toString();
    final label = item['text'] ?? '';
    final unit = item['unit'] ?? '';
    final inputType = item['input'].toString();
    final inItemType = item['inItemType'] ?? '';
    final itemsStr = item['items'] ?? '';
    print(inputType);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: inputType == '0' ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          widget.isRadio
              ? Radio<String>(
                  value: "${label}",
                  groupValue: widget.answers[qid]['checked'],
                  onChanged: (v) {
                    widget.answers[qid]['checked'] = v;
                    print(widget.answers);
                    widget.onChanged(v);
                  },
                )
              : Checkbox(
                  value: hasValue(widget.answers[qid][iid]),
                  onChanged: (v) => setState(() {
                    if (hasValue(widget.answers[qid][iid])) {
                      widget.answers[qid][iid].clear();
                      _controllers.forEach((k, c) => c.text = '');
                    } else {
                      widget.answers[qid][iid]['checked'] = label;
                    }
                    print(widget.answers);
                    print(widget.answers[qid][iid]);
                    widget.onChanged(v);
                  }),
                ),
          const SizedBox(width: 6),
          Expanded(child: _buildInputByType(widget.answers[qid][iid], iid, label, unit, inputType, inItemType, itemsStr))
        ],
      ),
    );
  }

  // ---------- input dispatcher ----------
  Widget _buildInputByType(Map ans, String iid, String label, String unit, String inputType, String inItemType, String itemsStr) {
    switch (inputType) {
      case '1':
        return _inputType1(ans, iid, label, unit);
      case '2':
        return _inputType2(ans, iid, label, unit);
      case '3':
        return _inputType3(ans, iid, label, unit);
      case '4':
        return _inputType4(ans, iid, label, unit);
      case '5':
        return _inputType5(ans, iid, label, inItemType, itemsStr, unit);
      default:
        return Text(label);
    }
  }

  //
  //
  //
  //
  Widget _inputType1(Map ans, String iid, String label, String unit) {
    List units = unit.split('|').where((e) => e.isNotEmpty).toList();
    if (units.isEmpty) {
      units = [""];
    }

    return Wrap(
      spacing: 3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(label),
        SizedBox(width: 10),
        ...List.generate(units.isEmpty ? 1 : units.length, (i) {
          final key = units[i]; //'${i + 1}';
          return Container(
            padding: EdgeInsets.fromLTRB(0, 0, 0, 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 35,
                  width: 60,
                  child: TextField(
                      controller: ctrl('$iid-$key', ans[key] ?? ''),
                      decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                      onChanged: (v) {
                        ans[key] = v;
                        widget.onChanged(v);
                      }),
                ),
                if (units.isNotEmpty) ...[
                  SizedBox(width: 3),
                  Text(units[i]),
                  SizedBox(width: 3),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  //
  //
  //
  //
  Widget _inputType2(Map ans, String iid, String label, String unit) {
    return Wrap(
      spacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(label),
        SizedBox(
            height: 35,
            width: 70,
            child: TextField(
              controller: ctrl('$iid-1', ans['1'] ?? ''),
              onChanged: (v) {
                ans['1'] = v;
                widget.onChanged(v);
              },
            )),
        const Text('('),
        SizedBox(
            height: 35,
            width: 70,
            child: TextField(
              controller: ctrl('$iid-2', ans['2'] ?? ''),
              onChanged: (v) {
                ans['2'] = v;
                widget.onChanged(v);
              },
            )),
        const Text(')'),
        if (unit.isNotEmpty) Text(unit),
      ],
    );
  }

  //
  //
  //
  //
  Widget _inputType3(Map ans, String iid, String label, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(label),
            SizedBox(
              height: 35,
              width: 60,
              child: TextField(
                controller: ctrl('$iid-1', ans['1'] ?? ''),
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                onChanged: (v) {
                  ans['1'] = v;
                  widget.onChanged(v);
                },
              ),
            ),
            Spacer(),
          ],
        ),
        SizedBox(height: 4),
        Wrap(
          spacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (unit.isNotEmpty) Text(unit),
            SizedBox(
              height: 35,
              width: 60,
              child: TextField(
                controller: ctrl('$iid-2', ans['2'] ?? ''),
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                onChanged: (v) {
                  ans['2'] = v;
                  widget.onChanged(v);
                },
              ),
            ),
            Spacer(),
          ],
        ),
      ],
    );
  }

  //
  //
  //
  //
  Widget _inputType4(Map ans, String iid, String label, String unit) {
    final c = ctrl('$iid-year', ans['1'] ?? '');
    return Row(
      spacing: 6,
      crossAxisAlignment: CrossAxisAlignment.center, // 중앙 정렬
      children: [
        Text(label),
        SizedBox(
          width: 60,
          height: 35,
          child: TextField(
            controller: c,
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
            onChanged: (v) {
              ans['1'] = v;
              widget.onChanged(v);
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.calendar_month, size: 18),
          onPressed: () async {
            final year = await showDialog<int>(
              context: context,
              builder: (_) => AlertDialog(
                  content: SizedBox(
                      height: 400,
                      width: 300,
                      child: YearPicker(
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                        selectedDate: DateTime.now(),
                        onChanged: (d) => Navigator.pop(context, d.year),
                      ))),
            );
            if (year != null) {
              c.text = year.toString();
              ans['1'] = year.toString();
              widget.onChanged(year.toString());
            }
          },
        ),
      ],
    );
  }

  //
  //
  //
  //
  Widget _inputType5(
    Map ans,
    String iid,
    String label,
    String inItemType,
    String itemsStr,
    String unit,
  ) {
    List<dynamic> checkboxKeys = ans.keys.toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label),
      if (unit != '') ...[
        Wrap(
            spacing: 6,
            children: itemsStr.split('|').map((label) {
              return Column(children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Checkbox(
                      value: checkboxKeys.contains(label),
                      onChanged: (v) {
                        if (v == true) {
                          ans[label] = true;
                        } else {
                          ans.remove(label);
                        }
                        widget.onChanged(v);
                      }),
                  Text(label),
                ])
              ]);
            }).toList()),
      ],
      Row(spacing: 6, children: [
        SizedBox(
            height: 35,
            width: 60,
            child: TextField(
                controller: ctrl('$iid-2', ans['1'] ?? ''),
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                onChanged: (v) {
                  ans['2'] = v;
                  widget.onChanged(v);
                })),
        Text(unit)
      ])
    ]);
  }
}
