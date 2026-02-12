// page_survey.dart (데이터 모델을 채용하도록 변경된 최종 버전)

import 'dart:convert';
import 'package:Vincere/provider_models.dart';
import 'package:Vincere/services/page_survery_copy/builder_root_question.dart';
import 'package:provider/provider.dart';

import 'data_models.dart';
import 'package:Vincere/utils/http/webReqFastapi.dart';
import 'package:flutter/material.dart';

//
//
//
//
class QuestionDisplayWidget extends StatefulWidget {
  final Map<String, dynamic> question;
  const QuestionDisplayWidget({required this.question, super.key});

  @override
  State<QuestionDisplayWidget> createState() => _QuestionDisplayWidgetState();
}

class _QuestionDisplayWidgetState extends State<QuestionDisplayWidget> {
  Map<String, String?> answers = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.question;
    return Padding(
        padding: const EdgeInsets.only(bottom: 16), // 질문 간 간격 유지
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // question box
          Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade400, width: 0.5),
              ),
              child: Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.grey.shade500, borderRadius: BorderRadius.circular(6)),
                  child: Text(question['QUESTION_ID'].toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text("${question['QUESTION']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              ])),

          // answer box
          const SizedBox(height: 12), // Header와 Input 사이 간격
          MainQuestionBuilder(
            question: question,
            setState: setState,
            context: context,
          ).build(),
          const SizedBox(height: 30), // question bottom margin
        ]));
  }
}

//
//
//
//
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
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> rootQuestions = [];
  int surveyId = 0;

  @override
  void initState() {
    super.initState();
    surveyId = widget.selectedItem!.id;
    _load_survey_questions();
  }

  Future<void> _load_survey_questions() async {
    try {
      final userModel = Provider.of<UserModel>(context, listen: false);
      await userModel.set_survey_info(widget.selectedItem!.id);

      rootQuestions = [];
      for (int i = 0; i < userModel.surveyQuestions!.length; i++) {
        if (userModel.surveyQuestions![i]['QUESTION_TYPE'] == "ROOT") {
          rootQuestions.add(userModel.surveyQuestions![i]);
        }
      }
      print("initialize survey_questions done!");
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
    if (widget.selectedItem == null) return const Center(child: Text('왼쪽 메뉴에서 설문 항목을 선택해주세요.'));

    final currentPage = widget.selectedItem!.pageNumber;
    final totalPages = widget.maxPageNumber;
    final isLastItem = currentPage == totalPages;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
        color: Colors.white,
        child: Stack(children: [
          // 1. contents
          SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(20, 20, 20, 100 + bottomInset),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('<${widget.selectedItem!.category}>', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.blue[700])),
                const SizedBox(height: 8),
                SizedBox(child: Text(widget.selectedItem!.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87))),
                const Divider(height: 30, thickness: 2),

                // render questions list
                Column(
                    children: rootQuestions.asMap().entries.map((entry) {
                  return QuestionDisplayWidget(question: entry.value);
                }).toList()),
                const SizedBox(height: 60), // 마지막 질문과 하단 바 사이 여백
              ])),

          // 2. pagination
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: buildPaginationBar(currentPage, totalPages, isLastItem),
          ),
        ]));
  }

  //
  //
  //
  //
  Widget buildPaginationBar(int currentPage, int totalPages, bool isLastItem) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        color: Colors.white,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          // prev button
          if (currentPage > 1) ...[
            Flexible(
                child: SizedBox(
                    width: 150, // 버튼의 최대 너비를 지정
                    child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ElevatedButton(
                          onPressed: () async {
                            if (currentPage > 1) widget.onPrevItem();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            foregroundColor: Colors.white,
                          ),
                          child: const Row(
                            spacing: 6,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_back),
                              Text("이전", style: TextStyle(fontSize: 18)),
                            ],
                          ),
                        )))),
          ],
          if (currentPage <= 1) ...[
            Flexible(child: SizedBox(width: 150)),
          ],

          //page explain
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('$currentPage / $totalPages', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          // next or submit button
          Flexible(
              child: SizedBox(
                  width: 150,
                  child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: ElevatedButton(
                        onPressed: () async {
                          ApiServiceFast apiServicFast = ApiServiceFast();
                          final userModel = Provider.of<UserModel>(context, listen: false);

                          await apiServicFast.insert_survey_answer(
                            userModel.userId,
                            widget.selectedItem!.id,
                            userModel.surveyAnswers,
                          );
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            _scrollController.animateTo(
                              0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          });

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
                        child: Row(
                          spacing: 6,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(isLastItem ? '완료' : '다음', style: const TextStyle(fontSize: 18)),
                            if (isLastItem == false) const Icon(Icons.arrow_forward),
                          ],
                        ),
                      ))))
        ]));
  }
}
