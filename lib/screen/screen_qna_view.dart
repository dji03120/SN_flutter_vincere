import 'package:Vincere/http/webReq.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Vincere/export/screens.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:shared_preferences/shared_preferences.dart';

class QnaView extends StatefulWidget {
  final Map<String, dynamic> qnaData;
  const QnaView({Key? key, required this.qnaData}) : super(key: key);

  @override
  _QnaViewScreenState createState() => _QnaViewScreenState();
}

class _QnaViewScreenState extends State<QnaView> {
  /*
  * Q&A View
  */

  String? userId;
  String? password;

  bool _isLogIn = false;
  Map<String, dynamic>? _qnaViewData;
  bool _modiQna = false;
  bool isModifyButtonEnabled = false;

  String title = "";
  String content = "";
  TextEditingController modiTitleCon = TextEditingController();
  TextEditingController modiContentCon = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSessionData().then((_) {
      if (_isLogIn) {
        _getMyQna();
      }
    });

    modiTitleCon.addListener(_updateModifyButtonState);
    modiContentCon.addListener(_updateModifyButtonState);
  }

  void _updateModifyButtonState() {
    setState(() {
      isModifyButtonEnabled = modiTitleCon.text.isNotEmpty && modiContentCon.text.isNotEmpty;
    });
  }

  String parseHtmlWithLineBreaks(String htmlString) {

    final document = html_parser.parse(htmlString);

    String parsedHtml = document.body?.innerHtml
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')  // <br> > 줄바꿈
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')       // </p> > 줄바꿈
        .replaceAll(RegExp(r'<p.*?>', caseSensitive: false), '')       // <p> > 제거
        .replaceAll(RegExp(r'&nbsp;', caseSensitive: false), ' ')      // &nbsp; > 공백
        .replaceAll(RegExp(r'&lt;', caseSensitive: false), '<')        // &lt; > <
        .replaceAll(RegExp(r'&gt;', caseSensitive: false), '>')        // &gt; > >
        .replaceAll(RegExp(r'&amp;', caseSensitive: false), '&') ?? ''; // &amp; > &

    final cleanText = html_parser.parse(parsedHtml).body?.text ?? '';

    return cleanText;
  }

  Future<void> _loadSessionData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
      password = prefs.getString('password');
      if (userId != null && password != null) {
        _isLogIn = true;
      }
    });
  }

  Future<void> _getMyQna() async {
    try {
      ApiService apiService = ApiService();
      Map<String, dynamic> result = await apiService.fetchQnaView(userId.toString(), widget.qnaData["noticeCd"].toString());
      print('Received data: $result');

      if (result.containsKey('myQnA')) {
        setState(() {
          _qnaViewData = Map<String, dynamic>.from(result['myQnA']);
          modiTitleCon.text = _qnaViewData?["title"] ?? '';
          modiContentCon.text = _qnaViewData?["content"] ?? '';

        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _modifyQna() async {
    try {
      ApiService apiService = ApiService();
      Map<String, dynamic> result = await apiService.fetchModiQna(userId.toString(), title, content, widget.qnaData["noticeCd"].toString());
      print('Received data: $result');

      if (result['result'] == 1) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('수정 완료'),
            content: const Text('회원님의 Q&A를 수정했습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Qna()),
                ),
                child: const Text('확인'),
              )
            ],
          ),
        );
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _delMyQna() async {
    try {
      ApiService apiService = ApiService();
      Map<String, dynamic> result = await apiService.fetchDelQna(widget.qnaData["noticeCd"].toString());
      print('Received data: $result');

      if (result['result'] == 1) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('삭제 완료'),
            content: const Text('회원님의 Q&A를 삭제했습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Qna()),
                ),
                child: const Text('확인'),
              )
            ],
          ),
        );
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  void dispose() {
    modiTitleCon.removeListener(_updateModifyButtonState);
    modiContentCon.removeListener(_updateModifyButtonState);
    modiTitleCon.dispose();
    modiContentCon.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Header(),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: const Padding(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Text(
                  'Q&A 상세',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 30),
          Divider(
            color: Color(0xFFEDEDED),
            thickness: 1,
            height: 1,
          ),
          Container(
            color: Colors.white,
            child: Container(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 30),
                    if (!_modiQna) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '[문의제목] ',
                                    style: TextStyle(
                                        color: const Color(0xFF00914B),
                                        fontFamily: 'NotoSansKR',
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16),
                                  ),
                                  TextSpan(
                                    text: '${_qnaViewData?["title"]}',
                                    style: TextStyle(
                                        color: const Color(0xFF000000),
                                        fontFamily: 'NotoSansKR',
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              (_qnaViewData?["regDtm"] != null && _qnaViewData?["regDtm"] is String)
                                  ? (_qnaViewData?["regDtm"] as String).split(' ')[0]
                                  : '',
                              style: TextStyle(
                                  color: const Color(0xFF8D8D8D),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "${_qnaViewData?["content"] ?? ''}",
                              style: TextStyle(
                                  color: const Color(0xFF555555),
                                  fontFamily: 'NotoSansKR',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      if (_qnaViewData?["ansContent"] != null) ...[
                        Divider(
                          color: Color(0xFFEDEDED),
                          thickness: 1,
                          height: 1,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 30),
                              const Text(
                                '[관리자답변]',
                                style: TextStyle(
                                  fontFamily: 'NotoSansKR',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF00914B),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                (_qnaViewData?["ansRegDtm"] != null && _qnaViewData?["ansRegDtm"] is String)
                                    ? (_qnaViewData?["ansRegDtm"] as String).split(' ')[0]
                                    : '',
                                style: const TextStyle(
                                  fontFamily: 'NotoSansKR',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF8D8D8D),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                parseHtmlWithLineBreaks(_qnaViewData?["ansContent"] ?? ''),
                                style: const TextStyle(
                                  fontFamily: 'NotoSansKR',
                                  fontSize: 15,
                                  color: Color(0xFF555555),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                        Divider(
                          color: Color(0xFFEDEDED),
                          thickness: 1,
                          height: 1,
                        ),
                      ],
                      const SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Q&A 수정하기'),
                                      content: const Text('작성한 Q&A를 수정하시겠습니까?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            setState(() {
                                              _modiQna = true;
                                            });
                                          },
                                          child: const Text('예'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text('아니오'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  fixedSize: Size.fromHeight(56),
                                  side: const BorderSide(color: Color(0xFF555555), width: 1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Center(  // 텍스트를 정확히 가운데로 정렬
                                  child: Text(
                                    '수정하기',
                                    style: TextStyle(
                                      color: Color(0xFF555555),
                                      fontFamily: 'NotoSansKR',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  _delMyQna();
                                },
                                style: ElevatedButton.styleFrom(
                                  fixedSize: Size.fromHeight(56),
                                  backgroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Center(  // 텍스트를 정확히 가운데로 정렬
                                  child: Text(
                                    '삭제하기',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'NotoSansKR',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (_modiQna) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Form(
                              child: Theme(
                                data: ThemeData(
                                  primaryColor: Colors.grey,
                                  inputDecorationTheme: const InputDecorationTheme(
                                    labelStyle: TextStyle(color: Colors.black, fontSize: 15.0),
                                  ),
                                ),
                                child: Builder(
                                  builder: (context) {
                                    return Column(
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              '제목',
                                              style: TextStyle(
                                                  fontSize: 16.0,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black
                                              ),
                                            ),
                                            const SizedBox(height: 8.0),
                                            TextFormField(
                                              controller: modiTitleCon,
                                              autofocus: true,
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return '제목을 입력하세요.';
                                                }
                                                return null;
                                              },
                                              decoration: InputDecoration(
                                                hintText: '문의 제목을 입력해 주세요',
                                                hintStyle: const TextStyle(
                                                  color: Color(0xFF8D8D8D), // hintText 색상 설정
                                                  fontSize: 16, // 폰트 크기
                                                  fontWeight: FontWeight.w400, // 폰트 굵기
                                                ),
                                                filled: true,
                                                fillColor: const Color(0xFFF8F9FB),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(16.0),
                                                  borderSide: const BorderSide(
                                                    color: Color(0xFFEDEDED), // 기본 테두리 색상
                                                    width: 1.0, // 테두리 두께
                                                  ),
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(16.0),
                                                  borderSide: const BorderSide(
                                                    color: Color(0xFFEDEDED), // 기본 테두리 색상
                                                    width: 1.0, // 테두리 두께
                                                  ),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(16.0),
                                                  borderSide: const BorderSide(
                                                    color: Color(0xFFEDEDED), // 기본 테두리 색상
                                                    width: 1.0, // 테두리 두께
                                                  ),
                                                ),
                                                contentPadding: const EdgeInsets.symmetric(
                                                  vertical: 20.0,
                                                  horizontal: 20.0,
                                                ),
                                              ),
                                              keyboardType: TextInputType.text,
                                            ),
                                            const SizedBox(height: 20.0),
                                            const Text(
                                              '문의내용',
                                              style: TextStyle(
                                                  fontSize: 16.0,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black
                                              ),
                                            ),
                                            const SizedBox(height: 8.0),
                                            Stack(
                                              alignment: Alignment.bottomRight,
                                              children: [
                                                TextFormField(
                                                  controller: modiContentCon,
                                                  maxLines: null,
                                                  minLines: 10,
                                                  decoration: InputDecoration(
                                                    hintText: '문의하실 내용을 입력해 주세요',
                                                    hintStyle: const TextStyle(
                                                      color: Color(0xFF8D8D8D), // 기존 hintText 색상
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w400,
                                                    ),
                                                    filled: true,
                                                    fillColor: const Color(0xFFF8F9FB),
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(16.0),
                                                      borderSide: const BorderSide(
                                                        color: Color(0xFFEDEDED), // 기본 테두리 색상
                                                        width: 1.0, // 테두리 두께
                                                      ),
                                                    ),
                                                    enabledBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(16.0),
                                                      borderSide: const BorderSide(
                                                        color: Color(0xFFEDEDED), // 기본 테두리 색상
                                                        width: 1.0, // 테두리 두께
                                                      ),
                                                    ),
                                                    focusedBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(16.0),
                                                      borderSide: const BorderSide(
                                                        color: Color(0xFFEDEDED), // 기본 테두리 색상
                                                        width: 1.0, // 테두리 두께
                                                      ),
                                                    ),
                                                    contentPadding: const EdgeInsets.all(16.0),
                                                    counterText: '',
                                                  ),
                                                  keyboardType: TextInputType.multiline,
                                                ),
                                                Positioned(
                                                  bottom: 10,
                                                  right: 10,
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(16.0), // 패딩 추가
                                                    child: Text(
                                                      '${modiContentCon.text.length}/1000',
                                                      style: const TextStyle(
                                                        fontSize: 14.0,
                                                        color: Color(0xFF8D8D8D),
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 40.0),
                                        Center(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: isModifyButtonEnabled
                                                    ? () {
                                                  title = modiTitleCon.text;
                                                  content = modiContentCon.text;
                                                  _modifyQna();
                                                }
                                                    : null, // 비활성화 처리
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: isModifyButtonEnabled
                                                      ? const Color(0xFF007331) // 활성화 색상
                                                      : Colors.grey, // 비활성화 색상
                                                  foregroundColor: Colors.white,
                                                  minimumSize: const Size(0, 65),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(16.0),
                                                  ),
                                                ),
                                                child: const Text(
                                                  '수정 완료',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),

                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                )
            ),
          ),
        ],
      ),
    );
  }
}