import 'dart:convert';

import 'package:Vincere/provider_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class DetailQuestionBuilder {
  final Map<String, dynamic> mainQuestion;
  final Map<String, dynamic> subQuestion;
  final void Function(VoidCallback fn) setState;
  final int detailQuestionId;
  final int subQuestionItemId;
  final BuildContext context;

  late Map<String, dynamic> answers;
  late List<Map<String, dynamic>> questions;
  late List<Map<String, dynamic>> answerItems;
  late Map<String, dynamic> detailQuestion;
  late final List<Map<String, dynamic>> questionCond;
  late final String? currentValue;
  late final Widget titleText;
  late final Map ans;

  DetailQuestionBuilder({
    required this.subQuestion,
    required this.mainQuestion,
    required this.subQuestionItemId,
    required this.detailQuestionId,
    required this.setState,
    required this.context,
  }) {
    final userModel = Provider.of<UserModel>(context, listen: false);
    questions = userModel.surveyQuestions;
    answers = userModel.surveyAnswers;
    detailQuestion = {};
    for (int i = 0; i < questions.length; i++) {
      if (questions[i]["ID"] == detailQuestionId) {
        detailQuestion = questions[i];
        break;
      }
    }
    answerItems = (jsonDecode(detailQuestion['ANSWER_ITEMS'])['items'] as List).cast<Map<String, dynamic>>();
    questionCond = (jsonDecode(detailQuestion['SUB_QUESTION_COND'])['sub_question_cond'] as List).cast<Map<String, dynamic>>();
    final did = detailQuestion['ID'].toString();
    answers.putIfAbsent(did, () => {});
    ans = answers[did];

    titleText = Column(
      children: [
        const SizedBox(height: 6),
        Text("${detailQuestion['ID']}. ${detailQuestion['QUESTION']}", style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
      ],
    );
  }
  //
  //
  //
  //
  List<Widget> wrapper(List<Widget> children) {
    // 박스모양
    return [
      Padding(
          padding: const EdgeInsets.only(left: 8, top: 4, bottom: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
          ))
    ];
  }

  List<Widget> build() {
    switch (detailQuestion['FORM_TYPE']) {
      case 'text':
        return wrapper(_build_text());
      case 'radio':
        return wrapper(_build_radio());
      case 'checkbox':
        return wrapper(_build_check());
      case 'text_with_date':
        return wrapper(_build_text_with_date());
      default:
        return [];
    }
  }

//
//
//
//
  List<Widget> _build_text() {
    // 입력 컨트롤러들 (index별)
    List<TextEditingController> controllers = List.generate(
      answerItems.length == 1 ? 1 : answerItems.length - 1,
      (i) => TextEditingController(text: ans["${i + 1}"] ?? ''),
    );
    return [
      titleText,
      Builder(builder: (context) {
        final List<Widget> widgets = [];

        // 특수 케이스: dsqUnit == ""
        if (answerItems.length <= 1) {
          widgets.add(const SizedBox(width: 6));
          widgets.add(SizedBox(
              width: 100,
              child: TextField(
                controller: controllers[0],
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                onChanged: (v) => ans['1'] = v,
              )));
          widgets.add(const SizedBox(width: 6));
        } else {
          for (int i = 0; i < answerItems.length; i++) {
            final text = answerItems[i]['text'].trim();
            // 텍스트 출력
            if (text.isNotEmpty) widgets.add(Text(text));

            // 마지막이 아니면 input 삽입
            if (i == answerItems.length - 1) break;
            widgets.add(const SizedBox(width: 6));
            widgets.add(SizedBox(
                width: 100,
                child: TextField(
                  controller: controllers[i],
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  onChanged: (v) => ans['${i + 1}'] = v,
                )));
            widgets.add(const SizedBox(width: 6));
          }
        }
        return SizedBox(
          child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: widgets),
        );
      }),
    ];
  }

//
//
//
//
  List<Widget> _build_text_with_date() {
    return [
      titleText,
      SizedBox(
          width: 200,
          child: Row(children: [
            Expanded(
                child: TextField(
                    controller: TextEditingController(text: ans['1'] ?? ''),
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    onChanged: (v) {
                      ans['1'] = v;
                    })),
            const SizedBox(width: 8),
            IconButton(
                icon: const Icon(Icons.calendar_today, size: 18),
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
                            ))),
                  );
                  if (year != null) {
                    ans['1'] = year.toString();
                    setState(() {});
                  }
                })
          ]))
    ];
  }

//
//
//
//
  List<Widget> _build_radio() {
    print(ans);
    return [
      titleText,
      Builder(builder: (context) {
        final selectedValue = ans['1'] ?? '';
        return buildDetailSelectableWrap(
            itemMinWidth: 200,
            children: answerItems.map((item) {
              return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Radio<String>(value: item['text'], groupValue: selectedValue, onChanged: (v) => setState(() => ans['1'] = v)),
                Text(item['text'] ?? ''),

                /// INPUT (선택된 경우만 활성화)
                if ((item['type'] == 'text_with_input' || item['type'] == 'text_with_input1')) ...[
                  const SizedBox(width: 6),
                  Expanded(
                      child: TextField(
                    controller: TextEditingController(text: selectedValue),
                    decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                    onChanged: (v) {},
                  )),
                  if (item['type'] == 'text_with_input1') Text(")"),
                ]
              ]);
            }).toList());
      }),
    ];
  }

//
//
//
//
  List<Widget> _build_check() {
    return [
      titleText,
      Builder(builder: (context) {
        return buildDetailSelectableWrap(
          itemMinWidth: 200,
          children: answerItems.map((item) {
            final label = item['text'] ?? '';
            final type = item['type'] ?? '';
            final isChecked = (ans[label] ?? '') == 'Y';
            final ctrl = TextEditingController(text: ans['${label}_value'] ?? '');

            return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Checkbox(
                value: isChecked,
                onChanged: (v) {
                  ans[label] = v == true ? 'Y' : '';
                  setState(() {});
                },
              ),
              Text(label),
              if (type == 'text_with_input' || type == 'text_with_input1') ...[
                const SizedBox(width: 6),
                Expanded(
                    child: TextField(
                        controller: ctrl,
                        decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                        onChanged: (v) {
                          ans['${label}_value'] = v;
                        }))
              ],
              if (type == 'text_with_input1') Text(')'),
            ]);
          }).toList(),
        );
      })
    ];
  }

  Widget buildDetailSelectableWrap({required double itemMinWidth, required List<Widget> children}) {
    const double spacing = 12;
    return LayoutBuilder(builder: (context, constraints) {
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
    });
  }
}

//
//
//
//
