import 'dart:convert';
import 'dart:typed_data';
import 'package:Vincere/component/card_muscle_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as dom;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // 링크를 열기 위한 패키지

class HtmlUtils {
  // HTML을 파싱하여 위젯으로 변환하는 함수
  static Widget parseHtmlContent(String htmlContent) {
    var document = parse(htmlContent); // HTML 파싱
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _parseHtmlNode(document.body),
    );
  }

  // 파싱한 HTML을 Flutter 위젯으로 변환하는 함수
  static List<Widget> _parseHtmlNode(dom.Element? element) {
    List<Widget> widgets = [];

    if (element == null) return widgets;

    for (var node in element.nodes) {
      if (node is dom.Element) {
        switch (node.localName) {
          case 'p': // <p> 태그는 Text 위젯으로 변환
            widgets.add(Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: _parseParagraph(node),
            ));
            break;
          case 'img': // <img> 태그는 Image 위젯으로 변환
            var src = node.attributes['src'];
            if (src != null && src.isNotEmpty) {
              widgets.add(HtmlUtils.buildImage(src));
            }
            break;
          case 'a': // <a> 태그는 Text 위젯으로 변환 (링크를 포함)
            var href = node.attributes['href'];
            if (href != null && href.isNotEmpty) {
              widgets.add(HtmlUtils._buildLink(href, node.text));
            }
            break;
          case 'strong': // <strong> 태그는 강조된 텍스트로 처리
            widgets.add(Text(node.text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)));
            break;
          case 'em': // <em> 태그는 기울인 텍스트로 처리
            widgets.add(Text(node.text, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 16)));
            break;
          default:
            widgets.add(Text(node.text)); // 기본 텍스트로 처리
        }
      }
    }

    return widgets;
  }

  // <p> 태그 내에서 <a> 태그를 처리하는 함수
  static Widget _parseParagraph(dom.Element paragraph) {
    List<Widget> widgets = [];

    for (var node in paragraph.nodes) {
      if (node is dom.Element) {
        if (node.localName == 'a') {
          var href = node.attributes['href'];
          if (href != null && href.isNotEmpty) {
            widgets.add(HtmlUtils._buildLink(href, node.text));
          }
        } else {
          // <a> 태그 외의 다른 텍스트 처리
          widgets.add(Text(node.text, style: const TextStyle(fontSize: 16)));
        }
      } else if (node is dom.Text) {
        widgets.add(Text(node.text, style: const TextStyle(fontSize: 16)));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  // 이미지를 처리하는 함수 (public으로 변경)
  static Widget buildImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Image.network(
        "https://images.pexels.com/photos/2563366/pexels-photo-2563366.jpeg",
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
      );
    }

    try {
      final base64String = imageUrl.split(",").last;
      final Uint8List imageBytes = base64Decode(base64String);
      return Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
      );
    } catch (e) {
      print("Base64 decode error: $e");
      return const Icon(Icons.error);
    }
  }

  // 링크를 처리하는 함수
  static Widget _buildLink(String href, String linkText) {
    return InkWell(
      onTap: () async {
        // URL을 웹 브라우저에서 열기
        if (await canLaunch(href)) {
          print("$href");
          await launch(href);
        } else {
          print("URL을 열 수 없습니다: $href");
        }
      },
      child: Text(
        linkText,
        style: const TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

// 회원 정보 카드 빌더
Widget userInfoCard({required String title, required String value}) {
  return Card(
    color: Colors.white,
    margin: EdgeInsets.symmetric(vertical: 8.0),
    child: Padding(
      padding: EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    ),
  );
}

Container pscpInfoContainer(BuildContext context, List<Map<String, dynamic>> pscpData) {
  return Container(
    color: Colors.blueGrey,
    child: (pscpData.isEmpty)
        ? const Center(
            child: Text(
              '처방 정보가 없습니다.',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          )
        : Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '처방 정보',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: pscpData.map((item) {
                    return buildInfoCard(
                      title: item['hlthFoodNm'] ?? '항목명 없음',
                      value: '${item['pscpDose']}',
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
  );
}

// 회원 정보 카드 빌더
Widget buildUserInfoCard({required String title, required String value}) {
  return Card(
    color: Colors.white,
    margin: EdgeInsets.symmetric(vertical: 8.0),
    child: Padding(
      padding: EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(fontSize: 16)),
        ],
      ),
    ),
  );
}

// 공통 카드 빌더
Widget buildInfoCard({required String title, required String value}) {
  return Card(
    color: Colors.white,
    margin: const EdgeInsets.symmetric(vertical: 8.0),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    ),
  );
}

// ignore: non_constant_identifier_names
int get_birth_to_age(String bym) {
  if (bym.length != 8) return 0; // 생년월일 형식이 맞지 않을 경우

  // bym이 'YYYYMMDD' 형식일 경우
  int birthYear = int.parse(bym.substring(0, 4));
  int birthMonth = int.parse(bym.substring(4, 6));
  int birthDay = int.parse(bym.substring(6, 8));

  DateTime birthDate = DateTime(birthYear, birthMonth, birthDay);
  DateTime currentDate = DateTime.now();
  int age = currentDate.year - birthDate.year;

  // 생일이 아직 지나지 않았다면 1을 빼줌
  if (currentDate.month < birthDate.month || (currentDate.month == birthDate.month && currentDate.day < birthDate.day)) {
    age--;
  }
  return age;
}

class FoodRow extends StatelessWidget {
  final String name; // 음식 이름 (예: 쌀, 고기, 채소 등)
  final Color color; // 아이콘 색상
  final double totalGram; // 음식 총량(g)
  final double kcalRatio; // g → kcal 변환 비율

  const FoodRow({
    super.key,
    required this.name,
    required this.color,
    required this.totalGram,
    required this.kcalRatio,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 16),

            // ● 원형 색상 아이콘
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),

            const SizedBox(width: 10),

            // 음식 이름
            Text(
              name,
              style: const TextStyle(fontSize: 16, color: Color(0xFF000000), fontWeight: FontWeight.w500),
            ),

            const Spacer(),

            // "총"
            const Text(
              '총',
              style: TextStyle(fontSize: 14, color: Color(0xFF555555)),
            ),

            const SizedBox(width: 10),

            // kcal 값
            Text(
              NumberFormat('#,###').format((totalGram * kcalRatio).round()),
              style: const TextStyle(fontSize: 24, color: Color(0xFF000000), fontWeight: FontWeight.w800),
            ),

            const SizedBox(width: 10),

            // kcal 단위
            const Text(
              'kcal',
              style: TextStyle(fontSize: 14, color: Color(0xFF555555)),
            ),

            const SizedBox(width: 5),

            // 괄호 + g 단위
            Text(
              '(${NumberFormat('#,###').format(totalGram.round())}g)',
              style: const TextStyle(fontSize: 14, color: Color(0xFF000000), fontWeight: FontWeight.w800),
            ),

            const SizedBox(width: 16),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.8,
              child: CustomPaint(
                painter: DashedLinePainter(color: Color(0xFFFED144)),
                size: Size(double.infinity, 1), // 높이를 1로 설정
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// 테이블 데이터 셀 위젯
Widget buildTableCell(String text, double breakfastRice, double lunchRice, double dinnerRice, {bool isHeader = false, String? str = ' '}) {
  double numericValue = 0;

  try {
    numericValue = double.parse(text);
  } catch (e) {
    // text가 숫자로 변환할 수 없는 경우 기본값 0 사용
    print("숫자로 변환할 수 없는 텍스트입니다: $text");
  }
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
          Container(
            width: 10, // 동그라미 크기
            height: 10,
            margin: EdgeInsets.only(top: 10, bottom: 3),
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
        if (isHeader) ...[
          SizedBox(height: 15),
        ],
      ],
      // SizedBox(height: 10),
    ),
    Row(
      // 새로운 Row 추가
      mainAxisAlignment: isHeader ? MainAxisAlignment.center : MainAxisAlignment.end, // 중앙 정렬
      //crossAxisAlignment: isHeader ? CrossAxisAlignment.center : CrossAxisAlignment.start,  // 추가: 세로 중앙 정렬
      children: [
        Text(
          // textAlign: TextAlign.center,
          isHeader ? text : '${numericValue.round()}',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: numberColor,
          ),
        ),
        if (!isHeader && str != null && !str.contains('totalRecKcal')) ...[
          Text(
            'kcal',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Color(0xFF555555)),
          ),
          SizedBox(width: 10),
        ],
        if (!isHeader && str != null && str.contains('totalRecKcal')) ...[
          Text(
            'kcal',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Color(0xFF000000)),
          ),
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
          Text(
            '${(numericValue / 4).round().toString()}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF000000)),
          ),
          Text(
            'g',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF555555)),
          ),
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
          Text(
            '${(numericValue / 4).round().toString()}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF000000)),
          ),
          Text(
            'g',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF555555)),
          ),
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
    // padding: const EdgeInsets.symmetric(vertical: 12),
    alignment: Alignment.center,
    height: 76,
    decoration: BoxDecoration(
      color: !isHeader ? cellColor : Colors.white, // 헤더일 때만 초록색 배경
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: children,
    ),
  );
}

class RiceCaloriesRow extends StatelessWidget {
  final String text;
  final int totalCalories; // 총 칼로리 값
  final Color color;

  const RiceCaloriesRow({super.key, required this.totalCalories, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF000000),
                letterSpacing: -0.02,
              ),
            ),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$totalCalories ',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const TextSpan(
                    text: 'kcal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF555555),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class RiceWeightInput extends StatelessWidget {
  final String label; // 라벨 (아침, 점심, 저녁 등)
  final TextEditingController controller; // 입력 컨트롤러
  final void Function(double) onSubmit; // 입력 완료 콜백

  const RiceWeightInput({
    super.key,
    required this.label,
    required this.controller,
    required this.onSubmit,
  });

  void _handleSubmit(BuildContext context) {
    if (controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('섭취량을 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final double? amount = double.tryParse(controller.text);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('올바른 숫자를 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('0보다 큰 값을 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    onSubmit(amount); // 콜백 실행
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 12),

        // 라벨 (아침/점심/저녁)
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF000000),
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(width: 12),

        // 입력 필드
        Expanded(
          flex: 4,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Color(0xFF007330),
            ),
            decoration: const InputDecoration(
              filled: true,
              fillColor: Color(0xFFF5F4F9),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                borderSide: BorderSide(color: Color(0xFFEDEDED), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                borderSide: BorderSide(color: Color(0xFFEDEDED), width: 1),
              ),
              suffixIcon: Center(
                widthFactor: 1.0,
                child: Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Text(
                    'g',
                    style: TextStyle(color: Color(0xFF555555), fontSize: 14),
                  ),
                ),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
        ),

        const SizedBox(width: 8),

        // 입력 버튼
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: () => _handleSubmit(context),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(width: 1, color: Color(0xFF555555)),
                ),
              ),
              child: const Text(
                '입력',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF555555),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// 정보 행을 만드는 헬퍼 메서드
Widget _buildInfoRow({
  required String label,
  required String value,
  required BoxConstraints constraints,
}) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(
      horizontal: constraints.maxWidth < 400 ? 4 : 8,
      vertical: constraints.maxWidth < 400 ? 2 : 4,
    ),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey[300]!),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: constraints.maxWidth < 400 ? 12 : 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: constraints.maxWidth < 400 ? 12 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

// 건강 정보 위젯 추출
Widget _buildHealthInfo(String label, List<Map<String, dynamic>> data, String code, String unit) {
  return Row(
    children: [
      Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      SizedBox(width: 4),
      Text(
          data
                  .firstWhere(
                    (item) => item['MSMT_ITEM_CD'] == code,
                    orElse: () => {'MSMT_VALUE': '--', 'MSMT_UNIT': unit},
                  )['MSMT_VALUE']
                  ?.toString() ??
              '--',
          style: TextStyle(fontSize: 12)),
      Text(unit),
    ],
  );
}
