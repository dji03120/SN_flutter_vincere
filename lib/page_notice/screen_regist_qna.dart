import 'package:Vincere/http/webReq.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Vincere/export/screens.dart';
import 'package:shared_preferences/shared_preferences.dart';

class regQnA extends StatefulWidget {
  const regQnA({super.key});

  @override
  _RegQnaScreenState createState() => _RegQnaScreenState();
}

class _RegQnaScreenState extends State<regQnA> {
  /*
  * Q&A Regist
  */

  TextEditingController titleCon = TextEditingController();
  TextEditingController contentCon = TextEditingController();
  int maxCharacters = 1000;

  String? userId;
  String? password;
  bool _isLogIn = false;
  String title = "";
  String content = "";
  bool isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSessionData();

    titleCon.addListener(_updateButtonState);
    contentCon.addListener(_updateButtonState);

    contentCon.addListener(() {
      if (contentCon.text.length > maxCharacters) {
        contentCon.text = contentCon.text.substring(0, maxCharacters);
        contentCon.selection = TextSelection.fromPosition(
          TextPosition(offset: contentCon.text.length),
        );
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    titleCon.removeListener(_updateButtonState);
    contentCon.removeListener(_updateButtonState);
    titleCon.dispose();
    contentCon.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    setState(() {
      isButtonEnabled = titleCon.text.isNotEmpty && contentCon.text.isNotEmpty;
    });
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

  Future<void> _regQna() async {
    try {
      ApiService apiService = ApiService();
      Map<String, dynamic> result = await apiService.fetchRegQna(userId.toString(), title, content);
      print('Recevied data: $result');
      if (_isLogIn) {
        if (result['result'] == 1) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('질문 등록 완료'),
              content: Text('회원님의 질문을 등록하였습니다.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Qna())),
                  child: Text('확인'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Header(),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: const Padding(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Text(
                  'Q&A 입력',
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Container(
              color: Colors.white,
              child: Padding(
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
                                      style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500, color: Colors.black),
                                    ),
                                    const SizedBox(height: 8.0),
                                    TextFormField(
                                      controller: titleCon,
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
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFEDEDED), // 기본 테두리 색상
                                            width: 1.0, // 테두리 두께
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFEDEDED),
                                            width: 1.0,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFEDEDED),
                                            width: 1.0,
                                          ),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          vertical: 20,
                                          horizontal: 16.0,
                                        ),
                                      ),
                                      keyboardType: TextInputType.text,
                                    ),
                                    const SizedBox(height: 30.0),
                                    const Text(
                                      '문의내용',
                                      style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500, color: Colors.black),
                                    ),
                                    const SizedBox(height: 8.0),
                                    Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        SizedBox(
                                          height: 218,
                                          child: TextFormField(
                                            controller: contentCon,
                                            maxLines: null,
                                            minLines: 10,
                                            decoration: InputDecoration(
                                              filled: true,
                                              fillColor: const Color(0xFFF8F9FB),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(16),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFEDEDED),
                                                  width: 1.0,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(16),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFEDEDED),
                                                  width: 1.0,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(16),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFEDEDED),
                                                  width: 1.0,
                                                ),
                                              ),
                                              contentPadding: const EdgeInsets.all(16.0),
                                              counterText: '',
                                            ),
                                            keyboardType: TextInputType.multiline,
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 10,
                                          right: 10,
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0), // 상하좌우 16 패딩 추가
                                            child: Text(
                                              '${contentCon.text.length}/$maxCharacters',
                                              style: const TextStyle(fontSize: 14.0, color: Color(0xFF8D8D8D), fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 40.0,
                                ),
                                Center(
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: isButtonEnabled
                                          ? () {
                                              title = titleCon.text;
                                              content = contentCon.text;
                                              _regQna();
                                            }
                                          : null, // 비활성화 처리
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isButtonEnabled
                                            ? const Color(0xFF007130) // 활성화 색상
                                            : Colors.grey, // 비활성화 색상
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(0, 65),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16.0),
                                        ),
                                      ),
                                      child: const Text(
                                        '질문 등록하기',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
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
            )
          ],
        ),
      ),
    );
  }
}
