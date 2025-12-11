import 'dart:math';

import 'package:Vincere/component/custom_widget.dart';
import 'package:Vincere/component/metric_chart_dialog.dart';
import 'package:Vincere/page_home/utils.dart';
import 'package:Vincere/page_nutrition/screen_nutrition_info_popup.dart';
import 'package:Vincere/provider_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:Vincere/http/webReqSpring.dart';

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
class PlateRiceCard extends StatelessWidget {
  final UserModel userModel;

  const PlateRiceCard({
    super.key,
    required this.userModel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
        height: 200,
        child: Card(
            color: const Color(0xFF0B8043),
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 10),
                  _titleSection(),
                  const SizedBox(height: 20),
                  _buttonSection(context),
                ]))));
  }

  // 1. 상단 타이틀 + 이미지
  // ---------------------------------------------
  Widget _titleSection() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('오늘하루', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: Colors.white)),
        Text('쌀 섭취량 입력', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: Colors.white)),
        SizedBox(height: 20),
      ]),
      Image.asset('images/rice_img.png', width: 90, height: 74),
    ]);
  }

  // 2. 버튼 구역 (입력하기 / 섭취량 추이)
  // ---------------------------------------------
  Widget _buttonSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      SizedBox(
        width: screenWidth * 0.35,
        height: 42,
        child: ElevatedButton(
          onPressed: () => _openRiceInputDialog(context),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: const Color(0xFF0B8043),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white, width: 2)),
          ),
          child: const Text("입력하기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      ),
      SizedBox(
          width: screenWidth * 0.35,
          child: ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => MetricChartDialog(title: "쌀 섭취량(g)", code: "riceIntake", userId: userModel.userId),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text("섭취량 추이"),
          ))
    ]);
  }

  // 3. "입력하기" 다이얼로그
  // ---------------------------------------------
  void _openRiceInputDialog(BuildContext context) {
    final breakfast = TextEditingController(text: userModel.plateData["breakfastRice"]?.toString() ?? "");
    final lunch = TextEditingController(text: userModel.plateData["lunchRice"]?.toString() ?? "");
    final dinner = TextEditingController(text: userModel.plateData["dinnerRice"]?.toString() ?? "");

    showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 4),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              titlePadding: const EdgeInsets.only(top: 30, bottom: 30, left: 24, right: 24),

              // Title
              title: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(text: '섭취한 쌀의 ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black)),
                      TextSpan(text: '총량', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF00914B))),
                      TextSpan(text: '을 입력해주세요', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(children: [
                  const Text("백미,현미,흑미,잡곡 등 종류 상관없음", style: TextStyle(fontSize: 16, color: Color(0xFF555555))),
                  const Spacer(),
                  GestureDetector(onTap: () => _openRiceInfoDialog(context), child: Image.asset('images/question_mark.png', width: 20, height: 20)),
                ])
              ]),

              // input
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RiceWeightInput(label: "아침", controller: breakfast, onSubmit: (v) => insertRiceIntake(userModel, "BREAKFAST", v)),
                    const SizedBox(height: 8),
                    RiceWeightInput(label: "점심", controller: lunch, onSubmit: (v) => insertRiceIntake(userModel, "LUNCH", v)),
                    const SizedBox(height: 8),
                    RiceWeightInput(label: "저녁", controller: dinner, onSubmit: (v) => insertRiceIntake(userModel, "DINNER", v)),
                  ],
                ),
              ),

              // close
              actions: [
                Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 30),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007130),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text("닫기", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                    ))
              ]);
        });
  }

  // ---------------------------------------------
  // 4. "?" 버튼 누르면 나오는 안내 Dialog
  // ---------------------------------------------
  void _openRiceInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Stack(
            alignment: Alignment.topRight,
            children: [Image.asset('images/rice_calculate_info.png', fit: BoxFit.contain), Positioned(top: 1, right: 1, child: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)))],
          )),
    );
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
class PlateSection extends StatelessWidget {
  const PlateSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel>(context); // 상태 접근
    final plateData = userModel.plateData;
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(spacing: 16, runSpacing: 16, children: [
                Container(
                  margin: const EdgeInsets.only(left: 20, right: 20),
                  width: constraints.maxWidth > 300 ? (constraints.maxWidth - 16) : constraints.maxWidth,
                  height: 300,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    image: DecorationImage(image: AssetImage('images/yellow_back.png'), fit: BoxFit.cover),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 36),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10),
                            Text('입력한 쌀 섭취량으로 알아보세요!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF000000))),
                            SizedBox(height: 4),
                            Text('오늘 먹은 총 칼로리 섭취량', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF000000))),
                          ],
                        ),
                      ),
                      // 영양소 정보 rows
                      Container(
                        width: constraints.maxWidth > 300 ? (constraints.maxWidth - 32) : constraints.maxWidth - 32,
                        height: 160,
                        decoration: BoxDecoration(color: Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(padding: const EdgeInsets.symmetric(vertical: 0), child: FoodRow(color: Color(0xFF007130), name: '쌀', totalGram: plateData['totalRice'], kcalRatio: 1.46)),
                            Padding(padding: const EdgeInsets.symmetric(vertical: 0), child: FoodRow(color: Color(0xFF00914B), name: '탄수화물', totalGram: plateData['carbCalories'] / 4, kcalRatio: 4)),
                            Padding(padding: const EdgeInsets.symmetric(vertical: 0), child: FoodRow(color: Color(0xFF9D895B), name: '단백질', totalGram: plateData['proteinCalories'] / 4, kcalRatio: 4)),
                          ],
                        ),
                      )
                    ],
                  ),
                )
              ]);
            },
          ),
          SizedBox(height: 16),

          // 탄수화물/단백질 섭취누적량
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 탄수화물 카드
              Flexible(
                child: Container(
                  margin: const EdgeInsets.only(left: 16),
                  constraints: const BoxConstraints(minWidth: 175, maxWidth: 300),
                  height: 180, // 적절한 높이 설정
                  child: Card(
                    color: Colors.black, // 검은색 배경
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 10),
                          const Text('탄수화물\n섭취누적량', style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.02)),
                          Spacer(),
                          Center(
                            child: HomeScreenButton(
                              text: '섭취량 추이',
                              width: 135,
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return MetricChartDialog(title: '탄수화물 섭취량(g)', code: 'carbsIntake', userId: userModel.userId);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 단백질 카드
              Flexible(
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  constraints: BoxConstraints(minWidth: 175, maxWidth: 300), // 적절한 너비 설정
                  height: 180, // 적절한 높이 설정
                  child: Card(
                    color: Colors.grey[700], // 회색 배경
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 10),
                          const Text('단백질\n섭취누적량', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.02)),
                          Spacer(),
                          Center(
                            child: HomeScreenButton(
                              text: '섭취량 추이',
                              width: 135,
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return MetricChartDialog(title: '단백질 섭취량(g)', code: 'proteinIntake', userId: userModel.userId);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 칼로리 그리드
          // 칼로리 그리드 섹션
          Container(
            margin: const EdgeInsets.only(left: 8, right: 8, top: 48),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 섹션 제목
                Text('${userModel.userInfo?["userNm"] ?? ""} 님이 오늘 하루 한 끼에', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(text: TextSpan(text: '섭취해야 할 권장 칼로리는? ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black))),
                    Row(
                      children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: Color(0xFFFABE00), shape: BoxShape.circle)), SizedBox(width: 4), Container(margin: EdgeInsets.only(right: 8), child: const Text('섭취완료', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF555555))))],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // 그리드 레이아웃
                Container(
                  clipBehavior: Clip.antiAlias, // 모서리 부분 클리핑 처리
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Table(
                    border: TableBorder.all(color: Colors.grey[300]!, width: 1, borderRadius: BorderRadius.circular(16)),
                    // defaultVerticalAlignment: TableCellVerticalAlignment.fill,
                    children: [
                      // 헤더 행 (이제 첫 번째 열이 됨)
                      TableRow(
                        children: [
                          _buildTableHeader(NumberFormat('#,###').format(plateData['recDailyEnergy'].round())),
                          _buildTableCell('한끼  권장\n칼   로   리', userModel, isHeader: true),
                          _buildTableCell('탄수화물\n필  요  량', userModel, isHeader: true),
                          _buildTableCell('단  백  질\n필  요  량', userModel, isHeader: true),
                        ],
                      ),
                      // 아침 행
                      TableRow(
                        children: [
                          _buildTableHeader('아침'),
                          _buildTableCell('${(plateData['recBreakfastEnergy']).round()}', userModel, str: 'breakfastTotalRecKcal'),
                          _buildTableCell('${(plateData['recBreakfastEnergy']).round()}', userModel, str: 'recBreakfastCarbs'),
                          _buildTableCell('${(plateData['recBreakfastEnergy']).round()}', userModel, str: 'recBreakfastProtein'),
                        ],
                      ),
                      // 점심 행
                      TableRow(
                        children: [
                          _buildTableHeader('점심'),
                          _buildTableCell('${(plateData['recLunchEnergy']).round()}', userModel, str: 'lunchTotalRecKcal'),
                          _buildTableCell('${(plateData['recLunchCarbs']).round()}', userModel, str: 'recLunchCarbs'),
                          _buildTableCell('${(plateData['recLunchProtein']).round()}', userModel, str: 'recLunchProtein'),
                        ],
                      ),
                      // 저녁 행
                      TableRow(
                        children: [
                          _buildTableHeader('저녁'),
                          _buildTableCell('${(plateData['recDinnerEnergy']).round()}', userModel, str: 'dinnerTotalRecKcal'),
                          _buildTableCell('${(plateData['recDinnerCarbs']).round()}', userModel, str: 'recDinnerCarbs'),
                          _buildTableCell('${(plateData['recDinnerProtein']).round()}', userModel, str: 'recDinnerProtein'),
                        ],
                      ),
                    ],
                  ),
                ),
                (plateData['breakfastRice'] != 0 && plateData['lunchRice'] != 0 && plateData['dinnerRice'] != 0) && (plateData['dailyCarbsLackCal'] != 0 || plateData['dailyProteinLackCal'] != 0)
                    ? Text(
                        '"탄수화물 ${plateData['dailyCarbsLackCal']}kcal, 단백질 ${plateData['dailyProteinLackCal']}kcal 부족해요. 근육과 건강을 위해 파이팅!"',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      )
                    : const SizedBox(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //
  //
  //
  //
  Widget _buildTableCell(String text, UserModel userModel, {bool isHeader = false, String? str = ' '}) {
    double breakfastRice = userModel.plateData['breakfastRice'];
    double lunchRice = userModel.plateData['lunchRice'];
    double dinnerRice = userModel.plateData['dinnerRice'];
    double numericValue = 0;

    try {
      numericValue = double.parse(text);
    } catch (e) {}
    Color dotColor;
    Color numberColor;

    if (!isHeader && str != null && ((str.contains('recBreakfastCarbs') && breakfastRice > 0) || (str.contains('recBreakfastProtein') && breakfastRice > 0) || (str.contains('recLunchCarbs') && lunchRice > 0) || (str.contains('recLunchProtein') && lunchRice > 0) || (str.contains('recDinnerCarbs') && dinnerRice > 0) || (str.contains('recDinnerProtein') && dinnerRice > 0))) {
      dotColor = const Color(0xFFFABE00);
    } else if (!isHeader && str != null && str.contains('TotalRecKcal') && ((str == 'breakfastTotalRecKcal' && breakfastRice > 0) || (str == 'lunchTotalRecKcal' && lunchRice > 0) || (str == 'dinnerTotalRecKcal' && dinnerRice > 0))) {
      dotColor = const Color(0xFFFABE00);
    } else if (!isHeader && str != ' ') {
      dotColor = const Color(0xFFDEDEDE);
    } else {
      dotColor = const Color(0xFFF5F5F5);
    }

    if (!isHeader && str != null && str.contains('Carbs')) {
      numberColor = const Color(0xFF00914B);
    } else if (!isHeader && str != null && str.contains('Protein')) {
      numberColor = const Color(0xFF9D895B);
    } else {
      numberColor = const Color(0xFF000000);
    }

    List<Widget> children = [
      Row(
        mainAxisAlignment: MainAxisAlignment.start, // 좌측 정렬
        children: [
          SizedBox(width: 10),
          if (!isHeader) ...[
            Container(width: 10, height: 10, margin: EdgeInsets.only(top: 10, bottom: 3), decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          ],
          if (isHeader) ...[SizedBox(height: 15)],
        ],
        // SizedBox(height: 10),
      ),
      Row(
        // 새로운 Row 추가
        mainAxisAlignment: isHeader ? MainAxisAlignment.center : MainAxisAlignment.end, // 중앙 정렬
        //crossAxisAlignment: isHeader ? CrossAxisAlignment.center : CrossAxisAlignment.start,  // 추가: 세로 중앙 정렬
        children: [
          Text(
            isHeader ? text : '${numericValue.round()}',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: numberColor),
          ),
          if (!isHeader && str != null && !str.contains('totalRecKcal')) ...[
            Text('kcal', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Color(0xFF555555))),
            SizedBox(width: 10),
          ],
          if (!isHeader && str != null && str.contains('totalRecKcal')) ...[
            Text('kcal', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Color(0xFF000000))),
            SizedBox(width: 10),
          ],
          // SizedBox(width: 8),
        ],
      ),
    ];

    if (!isHeader && str != null && ((str.contains('recBreakfastCarbs') && breakfastRice > 0) || (str.contains('recBreakfastProtein') && breakfastRice > 0) || (str.contains('recLunchCarbs') && lunchRice > 0) || (str.contains('recLunchProtein') && lunchRice > 0) || (str.contains('recDinnerCarbs') && dinnerRice > 0) || (str.contains('recDinnerProtein') && dinnerRice > 0))) {
      children.addAll([
        Row(
          mainAxisAlignment: MainAxisAlignment.end, // 우측 정렬
          children: [
            Text('${(numericValue / 4).round().toString()}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF000000))),
            Text('g', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF555555))),
            SizedBox(width: 10),
          ],
        ),
      ]);
    } else if (!isHeader && str != ' ' && str != null && !str.contains('TotalRecKcal')) {
      // 탄수화물 필요량 또는 단백질 필요량 cell인 경우
      children.addAll([
        Row(
          mainAxisAlignment: MainAxisAlignment.end, // 우측 정렬
          children: [
            Text('${(numericValue / 4).round().toString()}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF000000))),
            Text('g', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF555555))),
            SizedBox(width: 10),
          ],
        ),
      ]);
    } else if (!isHeader && str != ' ' && str != null && str.contains('totalRecKcal')) {
      children.addAll([
        SizedBox(height: 20),
      ]);
    }

    Color cellColor;
    switch (str) {
      case String s when s.contains('Carbs'):
        cellColor = const Color(0xFFF0F9F4);
      case String s when s.contains('Protein'):
        cellColor = const Color(0xFFF9F8F5);
      default:
        cellColor = const Color(0xFFF5F5F5);
        break;
    }

    return Container(
      alignment: Alignment.center,
      height: 76,
      decoration: BoxDecoration(color: !isHeader ? cellColor : Colors.white),
      child: Column(mainAxisAlignment: MainAxisAlignment.start, children: children),
    );
  }

  // 테이블 헤더 셀 위젯
  Widget _buildTableHeader(String text) {
    if (text.contains('아침') || text.contains('점심') || text.contains('저녁')) {
      return Container(alignment: Alignment.center, height: 76, color: Colors.white, child: Text(text, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Color(0xFF000000))));
    } else {
      return Container(
        color: Colors.white,
        // padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        height: 76,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('총', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 10, color: Color(0xFF000000))),
                Text(text, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Color(0xFF000000))),
                Text('Kcal', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 10, color: Color(0xFF000000))),
              ],
            ),
            SizedBox(height: 3),
            Text('기준', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
      );
    }
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
class DailyEnergySection extends StatelessWidget {
  final UserModel userModel;

  const DailyEnergySection({
    required this.userModel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: max(380, MediaQuery.of(context).size.width),
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          _header(context),
          const SizedBox(height: 30),
          _calculatorButton(context),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 40;
    double dailyRequireEnergy = userModel.plateData['recDailyEnergy'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: '${userModel.userInfo?["userNm"] ?? ""}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF007130))),
              const TextSpan(text: ' 님의', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black)),
            ],
          ),
        ),
        SizedBox(
          width: width,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('일일 에너지 권장량', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              RichText(
                  text: TextSpan(children: [
                const TextSpan(text: '총 ', style: TextStyle(fontSize: 16)),
                TextSpan(text: NumberFormat('#,###').format(userModel.userHealthData?['기초대사량'][0] ?? dailyRequireEnergy), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                const TextSpan(text: ' kcal', style: TextStyle(fontSize: 16)),
              ]))
            ],
          ),
        ),
      ],
    );
  }

  Widget _calculatorButton(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width - 40,
      child: Center(
        child: ElevatedButton(
          onPressed: () => _showCalorieDialog(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFA2BC11),
            minimumSize: const Size(262, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text('쌀 칼로리 계산기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.9))),
        ),
      ),
    );
  }

  // ✔ 팝업만 StatefulBuilder 사용 → StatelessWidget과 충돌 없음
  void _showCalorieDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        Map<String, dynamic> calories = {'total': 0, 'carb': 0, 'protein': 0};

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('쌀 칼로리 계산'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: controller),
                  ElevatedButton(
                    onPressed: () {
                      double intake = double.tryParse(controller.text) ?? 0;
                      setState(() => calories = calculateRiceCalorie(intake));
                    },
                    child: const Text('입력'),
                  ),
                  Text('총 칼로리: ${calories['total']}'),
                  Text('탄수화물: ${calories['carb']}'),
                  Text('단백질: ${calories['protein']}'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Map<String, dynamic> calculateRiceCalorie(double intake) {
    try {
      int carbCalorie = (intake * 1.32).round();
      int proteinCalorie = (intake * 0.092).round();
      int totalCalorie = (intake * 1.46).round(); // 총 칼로리
      return {'total': totalCalorie, 'carb': carbCalorie, 'protein': proteinCalorie};
    } catch (e) {
      print('Error calculating calorie: $e');
      return {'total': 0, 'carb': 0, 'protein': 0};
    }
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
//
//
//
//
//
//
//
class RecommandFood extends StatefulWidget {
  const RecommandFood({super.key});

  @override
  State<RecommandFood> createState() => _RecommandFoodState();
}

class _RecommandFoodState extends State<RecommandFood> {
  late UserModel userModel;
  bool isExpanded1 = false;
  bool isExpanded2 = false;

  @override
  void initState() {
    super.initState();
    userModel = Provider.of<UserModel>(context, listen: false);
  }

  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        margin: const EdgeInsets.only(left: 16, right: 16, top: 36),
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
                '${userModel.userInfo?["userNm"] ?? ""} 님의 권장 필요'
                '\n에너지량에 따른 음식추천',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF000000))),
          ],
        ),
      ),

      // 첫 번째 추천 음식 섹션
      Container(
        margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias, // 모서리 부분 잘라내기
        child: ExpansionTile(
          collapsedBackgroundColor: Colors.transparent, // 접혀있을 때의 배경색
          backgroundColor: Colors.transparent, // 펼쳐졌을 때의 배경색
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.black),
                    children: [
                      TextSpan(text: '탄수화물', style: TextStyle(color: Color(0xFF00914B), fontSize: 13, fontWeight: FontWeight.w700)),
                      TextSpan(text: '만 먼저 채우고 싶어요!', style: TextStyle(color: Color(0xFF000000), fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(11, 0),
                child: Container(
                  width: 76,
                  height: 24,
                  padding: EdgeInsets.symmetric(horizontal: 0.6, vertical: 1.0),
                  // margin: EdgeInsets.only(left: 24.0),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Color(0xFF00914B), width: 2)),
                  child: Text(' 추천음식', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00914B), fontSize: 11, letterSpacing: -0.04), textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
          onExpansionChanged: (bool expanded) {
            setState(() {
              isExpanded1 = expanded;
            });
          },
          children: [
            Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(thickness: 1.0),
                  // 표 헤더
                  const Row(
                    children: [
                      Expanded(flex: 3, child: Text('식품명', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFF000000), fontWeight: FontWeight.w500))),
                      Expanded(flex: 2, child: Text('중량', style: TextStyle(fontSize: 12, color: Color(0xFF000000), fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
                      Expanded(flex: 2, child: Text('탄수화물', style: TextStyle(fontSize: 12, color: Color(0xFF000000), fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
                      Expanded(flex: 2, child: Text('단백질', style: TextStyle(fontSize: 12, color: Color(0xFF000000), fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
                      Expanded(flex: 2, child: SizedBox())
                      // SizedBox(width: 40), // 버튼을 위한 공간
                    ],
                  ),
                  Divider(thickness: 1.0),
                  // 표 데이터 행들
                  ...userModel.plateData['carbsFoodListData']
                      .map((food) => _buildTableRow(
                            food['food_id'],
                            food['food_name'],
                            food['food_weight'],
                            food['TOTAL_CARB_CAL'].round(),
                            food['TOTAL_PROTEIN_CAL'].round(),
                            // '식품명1', '500g','150kcal', '250kcal'
                          ))
                      .toList(),
                ],
              ),
            ),
          ],
        ),
      ),

      // 두 번째 추천 음식 섹션
      Container(
          margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias, // 모서리 부분 잘라내기
          child: ExpansionTile(
              collapsedBackgroundColor: Colors.transparent, // 투명하게 설정하여 Container의 배경색이 보이도록
              backgroundColor: Colors.transparent, // 투명하게 설정하여 Container의 배경색이 보이도록
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                      child: RichText(
                          text: const TextSpan(
                    style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.black),
                    children: [TextSpan(text: '단백질', style: TextStyle(color: Color(0xFF9D895B), fontSize: 13, fontWeight: FontWeight.w700)), TextSpan(text: '만 먼저 채우고 싶어요!', style: TextStyle(color: Color(0xFF000000), fontSize: 13, fontWeight: FontWeight.w600))],
                  ))),
                  Transform.translate(
                    offset: Offset(11, 0),
                    child: Container(
                      width: 76,
                      height: 24,
                      padding: EdgeInsets.symmetric(horizontal: 0.6, vertical: 1.0),
                      // margin: EdgeInsets.only(left: 16.0),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Color(0xFF9D895B), width: 2)),
                      child: Text(' 추천음식', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF9D895B), fontSize: 11, letterSpacing: -0.04), textAlign: TextAlign.center),
                    ),
                  ),
                ],
              ),
              onExpansionChanged: (bool expanded) {
                setState(() {
                  isExpanded2 = expanded;
                });
              },
              children: [
                Container(
                    padding: EdgeInsets.all(16.0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Divider(thickness: 1.0),
                      // 표 헤더
                      Container(
                        padding: EdgeInsets.zero,
                        child: const Row(
                          children: [
                            Expanded(flex: 3, child: Text('식품명', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFF000000), fontWeight: FontWeight.w500))),
                            Expanded(flex: 2, child: Text('중량', style: TextStyle(fontSize: 12, color: Color(0xFF000000), fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
                            Expanded(flex: 2, child: Text('탄수화물', style: TextStyle(fontSize: 12, color: Color(0xFF000000), fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
                            Expanded(flex: 2, child: Text('단백질', style: TextStyle(fontSize: 12, color: Color(0xFF000000), fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
                            Expanded(flex: 2, child: SizedBox())
                            // SizedBox(width: 40), // 버튼을 위한 공간
                          ],
                        ),
                      ),
                      Divider(thickness: 1.0),
                      // 표 데이터 행들
                      ...userModel.plateData['proteinFoodListData']
                          .map((food) => _buildTableRow(
                                food['food_id'],
                                food['food_name'],
                                food['food_weight'],
                                food['TOTAL_CARB_CAL'].round(),
                                food['TOTAL_PROTEIN_CAL'].round(),
                                // '식품명1', '500g','150kcal', '250kcal'
                              ))
                          .toList(),
                    ]))
              ]))
    ]);
  }

  // 표 행을 생성하는 helper 메소드
  Widget _buildTableRow(String foodId, String name, String totalAmt, double carb, double protein) {
    return Container(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        // padding: EdgeInsets.zero,
        child: Row(children: [
          Expanded(flex: 3, child: Container(child: Text(name, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF555555))))),
          Expanded(flex: 2, child: Container(child: Text(totalAmt, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF000000))))),
          Expanded(
              flex: 2,
              child: Container(
                  padding: EdgeInsets.zero,
                  child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(children: [
                        TextSpan(text: '${carb.toString()}\n', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF00914B))),
                        TextSpan(text: 'kcal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF8D8D8D))),
                      ])))),
          Expanded(
              flex: 2,
              child: Container(
                  child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(children: [
                        TextSpan(text: '${protein.toString()}\n', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF9D859B))),
                        const TextSpan(text: 'kcal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF8D8D8D))),
                      ])))),
          Expanded(
              flex: 2,
              child: Container(
                  child: ElevatedButton(
                onPressed: () async {
                  try {
                    ApiService apiService = ApiService();
                    Map<String, dynamic> result = await apiService.fetchGetNutritionInfo(foodId);
                    print("result 확인 : $result");
                    if (result != null) {
                      showDialog(context: context, builder: (BuildContext context) => NutritionInfoPopup(foodName: name, result: result));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('영양정보를 불러오는데 실패했습니다.')),
                      );
                    }
                  } catch (e) {
                    print('Error fetching nutrition info: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('영양정보 조회 중 오류가 발생했습니다.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                  minimumSize: Size(40, 15),
                  backgroundColor: Color(0xFF555555),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  '영양정보',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF)),
                ),
              )))
        ]));
  }
}
