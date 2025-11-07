import 'package:Vincere/http/webReq.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Vincere/export/screens.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Qna extends StatefulWidget {
  const Qna({super.key});

  @override
  _QnaScreenState createState() => _QnaScreenState();
}

class _QnaScreenState extends State<Qna> {
  /*
  * Q&A List
  */

  String? userId;
  String? password;
  bool _isLogIn = false;
  List<Map<String, dynamic>> _qnaData = [];
  //int _selectedIndex = 0; // 현재 선택된 탭 인덱스

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
      if (userId != null && password != null) {
        _isLogIn = true;
      }
    });
  }

  Future<void> _getQnaInfo() async {
    try {
      ApiService apiService = ApiService();
      print('userId >>> $userId');
      Map<String, dynamic> result = await apiService.fetchGetQna(userId.toString());
      print('Recevied data: $result');

      if (result.containsKey('myQnAList')) {
        setState(() {
          _qnaData = List<Map<String, dynamic>>.from(result['myQnAList']);
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

/*
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;

      // 탭에 따라 화면 전환 로직 추가 가능
      if (_selectedIndex == 0) {
        // 홈 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyHomePage(title: "홈 화면")),
        );
      } else if (_selectedIndex == 1) {
        // 현재 Q&A 화면
      } else if (_selectedIndex == 2) {
        // 다른 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyHomePage(title: "홈 화면")),
        );
      }
    });
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Header(),
      drawer: CustomDrawer(isLogin: _isLogIn),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: const Padding(
                    padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                    child: Text(
                      'Q&A',
                      textAlign: TextAlign.left,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    )),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            color: Colors.white,
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const SizedBox(height: 30), // 버튼 위 간격
                  SizedBox(
                      height: 48,
                      child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const regQnA()));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFF555555),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                              side: const BorderSide(color: Color(0xFF555555)),
                            ),
                          ),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Text('질문 등록하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF555555))),
                            SizedBox(width: 10),
                            Image.asset('images/arrow_botton_mini_right.png', width: 10),
                          ]))),
                  const SizedBox(height: 30), // 버튼 아래 간격
                ])),
          ),
          const Divider(color: Color(0xFFEDEDED), thickness: 1, height: 1),
          Expanded(
            child: _qnaData.isEmpty
                ? Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      RichText(
                          text: const TextSpan(children: [
                        TextSpan(text: '작성된 ', style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w500)),
                        TextSpan(text: 'Q&A 문의글', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
                        TextSpan(text: '이 없습니다.', style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w500)),
                      ])),
                    ]),
                  )
                : ListView.builder(
                    itemCount: _qnaData.length,
                    itemBuilder: (context, index) {
                      final rowData = _qnaData[index];
                      Color grey = const Color(0xFF555555);
                      return Column(children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => QnaView(qnaData: rowData)));
                          },
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0), // 내부 패딩 추가
                            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEDEDED), width: 1))),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 0),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Expanded(
                                    flex: 3,
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      SizedBox(height: 24),
                                      Text(
                                        rowData['title'] ?? '',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      SizedBox(height: 14),
                                      Row(
                                        children: [
                                          Text(
                                            rowData['ansRegId'] == null || rowData['ansRegId'] == '' ? '미답변' : '답변완료',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: rowData['ansRegId'] == null || rowData['ansRegId'] == '' ? grey : const Color(0xFF00914B),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (rowData['regDtm'] != null)
                                            Row(
                                              children: [
                                                Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Container(height: 12, width: 1, color: grey)),
                                                Text(rowData['regDtm'], style: TextStyle(fontSize: 14, color: grey, fontWeight: FontWeight.w500)),
                                              ],
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: 24),
                                    ])),
                                Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [Text(rowData['date'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey))],
                                    )),
                              ]),
                            ),
                          ),
                        ),
                      ]);
                    }),
          ),
        ],
      ),
    );
  }
}

class QnaData extends DataTableSource {
  final List<Map<String, dynamic>> _qnaData;
  final BuildContext context;

  QnaData(this._qnaData, this.context);

  @override
  DataRow? getRow(int index) {
    final rowData = _qnaData[index];

    return DataRow(cells: [
      DataCell(
        Container(
          child: Center(
            child: Text(
              _qnaData[index]["title"]?.toString() ?? '',
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => QnaView(qnaData: rowData)));
        },
      ),
      DataCell(
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 300),
          child: Text(
            _qnaData[index]["content"]?.toString() ?? '',
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => QnaView(qnaData: rowData)));
        },
      ),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _qnaData.length;

  @override
  int get selectedRowCount => 0;
}
