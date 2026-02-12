import 'dart:convert';

import 'package:Vincere/provider_models.dart';
import 'package:Vincere/services/page_survery_copy/builder_sub_question.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class MainQuestionBuilder {
  final Map<String, dynamic> question;
  final void Function(VoidCallback fn) setState;
  final BuildContext context;

  late Map<String, dynamic> answers;
  late List<Map<String, dynamic>> questions;
  late final List<Map<String, dynamic>> answerItems;
  late final List<Map<String, dynamic>> questionCond;
  late final String? currentValue;
  late UserModel userModel;
  final Map<String, TextEditingController> _controllers = {};

  MainQuestionBuilder({
    required this.question,
    required this.setState,
    required this.context,
  }) {
    userModel = Provider.of<UserModel>(context, listen: false);
    questions = userModel.surveyQuestions;
    answers = userModel.surveyAnswers;
    answerItems = (jsonDecode(question['ANSWER_ITEMS'])['items'] as List).cast<Map<String, dynamic>>();
    questionCond = (jsonDecode(question['SUB_QUESTION_COND'])['sub_question_cond'] as List).cast<Map<String, dynamic>>();
    currentValue = answers[question['ID'].toString()].toString();
  }

  TextEditingController ctrl(String key, String initial) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(text: answers[key] ?? initial);
    }
    return _controllers[key]!;
  }

  Widget build() {
    switch (question['FORM_TYPE']) {
      case 'none':
        return _buildNone();
      case 'radio':
        return _buildRadio();
      case 'checkbox':
        return _buildCheckbox();
      case 'text':
        return _buildText();
      case 'checkbox_with_input':
        return _buildCheckboxWithInput();
      case 'text_with_input':
        return _buildTextWithInput();
      default:
        return const SizedBox.shrink();
    }
  }

//
//
//
//
  Widget _buildNone() {
    final subBox = BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(8.0),
      border: Border.all(color: Colors.grey.shade400, width: 1.0),
    );

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: questionCond.expand((cond) {
          return [
            Padding(
                padding: const EdgeInsets.only(left: 12.0, top: 4.0, bottom: 4.0),
                child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12.0),
                    decoration: subBox,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: SubQuestionBuilder(
                        subQuestionId: cond['id'],
                        mainQuestion: question,
                        setState: setState,
                        onChanged: (v) => setState(() {
                          print(answers);
                        }),
                        context: context,
                      ).build(),
                    )))
          ];
        }).toList());
  }

//
//
//
//
  Widget _buildRadio() {
    final subBox = BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(8.0),
      border: Border.all(color: Colors.grey.shade400, width: 1.0),
    );
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: answerItems.map((opt) {
          final isSelected = currentValue == opt['text'];
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            RadioListTile<String>(
              title: Text(opt["text"]),
              value: opt['text'],
              groupValue: currentValue,
              onChanged: (v) => setState(() => userModel.save_answer(question['ID'].toString(), v)),
            ),
            if (isSelected)
              ...questionCond
                  .where(
                (cond) => cond['value'].toString().split('|').contains(opt['text']),
              )
                  .expand((cond) {
                return [
                  Padding(
                      padding: const EdgeInsets.only(left: 12.0, top: 4.0, bottom: 4.0),
                      child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12.0),
                          decoration: subBox,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: SubQuestionBuilder(
                                subQuestionId: cond['id'],
                                mainQuestion: question,
                                setState: setState,
                                onChanged: (v) => setState(() {
                                  print(answers);
                                }),
                                context: context,
                              ).build())))
                ];
              }).toList(),
          ]);
        }).toList());
  }

//
//
//
//
  Widget _buildCheckbox() {
    final List<String> selectedList = (currentValue ?? '').toString().isEmpty ? [] : currentValue.toString().split('|').where((s) => s.isNotEmpty).toList();
    return Column(
        children: answerItems.map((opt) {
      final checked = selectedList.contains(opt['text']);

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CheckboxListTile(
            value: checked,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(opt['text'], softWrap: true, maxLines: null),
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  if (!selectedList.contains(opt['text'])) {
                    selectedList.add(opt['text']);
                  }
                } else {
                  selectedList.remove(opt['text']);
                }
                setState(() => userModel.save_answer(question['ID'].toString(), selectedList.join('|')));
              });
            }),
        if (checked)
          ...questionCond.where((sub) => sub['value'].contains(opt['text'])).expand((sub) {
            return [
              Padding(
                  padding: const EdgeInsets.only(left: 12.0, top: 4.0, bottom: 4.0),
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
                      children: SubQuestionBuilder(
                        subQuestionId: sub['id'],
                        mainQuestion: question,
                        setState: setState,
                        onChanged: (v) => setState(() {
                          print(answers);
                        }),
                        context: context,
                      ).build(),
                    ),
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
  Widget _buildText() {
    final int lines = 5; //_parseTextLines(answerItems);

    return Column(
      children: [
        TextField(
          controller: ctrl(question['ID'].toString(), ''),
          minLines: lines,
          maxLines: lines,
          keyboardType: lines > 1 ? TextInputType.multiline : TextInputType.text,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          onChanged: (v) => userModel.save_answer(question["ID"].toString(), v),
        ),
        SizedBox(height: 100),
      ],
    );
  }

//
//
//
//
  Widget _buildCheckboxWithInput() {
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
        final controller = ctrl(inputKey, '');

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
              setState(() => userModel.save_answer(question['ID'].toString(), selectedList.join('|')));
            });
          },
          title: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(child: Text(label, softWrap: true, maxLines: null)),
            if (alwaysShowInput) ...[
              const SizedBox(width: 8),
              SizedBox(
                  width: 160,
                  height: 36,
                  child: TextField(
                    controller: controller,
                    onChanged: (v) => userModel.save_answer(inputKey, v),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    ),
                  ))
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
  Widget _buildTextWithInput() {
    final List<String> opts = (answerItems as List).map((e) => e['text'].toString()).toList();
    final String prefixLabel = opts.first;

    // 마지막 처리
    String lastRaw = opts.last;
    bool hasClosingParen = lastRaw.endsWith(')');
    String lastUnit = hasClosingParen ? lastRaw.substring(0, lastRaw.length - 1) : lastRaw;
    final List<String> units = [...opts.sublist(1, opts.length - 1), lastUnit];

    final qid = question['ID'].toString();
    return Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 6, children: [
      Text(prefixLabel),
      ...units.map((unit) {
        final String key = '${question['ID'].toString()}_$unit';

        return Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.ltr,
          children: [
            SizedBox(
              width: 70,
              child: TextField(
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                onChanged: (v) {
                  answers.putIfAbsent(qid, () => {});
                  answers[qid][unit] = v;
                  print(answers);
                }, //userModel.save_answer(key, v)),
              ),
            ),
            const SizedBox(width: 4),
            Text(unit),
          ],
        );
      }),
      if (hasClosingParen) const Text(')'),
    ]);
  }
}
