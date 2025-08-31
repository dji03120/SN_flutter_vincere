import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as dom;
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
                    return _buildInfoCard(
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

// 공통 카드 빌더
Widget _buildInfoCard({required String title, required String value}) {
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
