import 'package:Vincere/page_home/utils.dart';
import 'package:Vincere/utils/export/screens.dart';
import 'package:Vincere/utils/http/webReqSpring.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewsBoard extends StatefulWidget {
  const NewsBoard({super.key});

  @override
  _NewsBoardState createState() => _NewsBoardState();
}

class _NewsBoardState extends State<NewsBoard> {
  String? userId;
  String? password;
  bool _isLogIn = false;
  List<Map<String, dynamic>> _qnaData = [];

  @override
  void initState() {
    super.initState();
    _loadSessionData().then((_) {
      if (_isLogIn) {
        _getQnaInfo();
      }
    });
  }

  Future<void> _loadSessionData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
      password = prefs.getString('password');
      _isLogIn = (userId != null && password != null);
    });
  }

  Future<void> _getQnaInfo() async {
    try {
      ApiService apiService = ApiService();
      print('userId >>> $userId');
      Map<String, dynamic> result = await apiService.fetchGetNewsBoard(userId.toString());

      if (result.containsKey('newsBoardList')) {
        setState(() {
          _qnaData = List<Map<String, dynamic>>.from(result['newsBoardList']);
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: const Header(),
      //drawer: CustomDrawer(isLogin: _isLogIn),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0), // 전체 영역에 16의 패딩 추가
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 50,
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                  child: Text(
                    '건강뉴스',
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 32), // 내부 패딩
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage('images/news_top_img.png'), // 배경 이미지 경로
                  fit: BoxFit.cover, // 이미지 채우기 스타일
                ),
                borderRadius: BorderRadius.circular(16.0), // 모서리를 둥글게
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '유용한 건강소식',
                          style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 12),
                        Text(
                          '근육을 키우는 데 도움이 되는 식단 정보',
                          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _qnaData.isEmpty
                  ? const Center(
                      child: Text('등록된 뉴스가 없습니다.', style: TextStyle(fontSize: 18)),
                    )
                  : ListView.separated(
                      itemCount: _qnaData.length,
                      separatorBuilder: (context, index) => const Column(
                        children: [
                          SizedBox(height: 16), // 상단 여백
                          Divider(color: Color(0xFFEDEDED), thickness: 1, height: 1),
                          SizedBox(height: 16), // 하단 여백
                        ],
                      ),
                      itemBuilder: (context, index) {
                        final item = _qnaData[index];
                        return InkWell(
                          onTap: () {
                            // QnaView로 이동하면서 데이터 전달
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QnaView(qnaData: item),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 120, // 썸네일 너비
                                height: 72, // 썸네일 높이
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16.0),
                                  child: HtmlUtils.buildImage(item["imageUrl"]),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  item["title"] ?? "제목 없음",
                                  style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14, color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}

class QnaView extends StatelessWidget {
  final Map<String, dynamic> qnaData;

  const QnaView({super.key, required this.qnaData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Header(),
      backgroundColor: Colors.white, // 배경색 설정
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              qnaData["title"] ?? "제목 없음",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black),
            ),
            const SizedBox(height: 30),
            const Divider(
              color: Color(0xFFEDEDED),
              thickness: 1,
              height: 1,
            ),
            const SizedBox(height: 30),
            HtmlUtils.parseHtmlContent(qnaData["content"] ?? "내용 없음"),
            const SizedBox(height: 20),
            if (qnaData["imageUrl"] != null) HtmlUtils.buildImage(qnaData["imageUrl"]),
          ],
        ),
      ),
    );
  }
}
