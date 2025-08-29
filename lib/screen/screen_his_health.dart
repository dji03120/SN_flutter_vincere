import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Vincere/http/webReq.dart';
import 'package:Vincere/export/screens.dart';
import 'package:Vincere/component/header.dart';

class HisHealth extends StatefulWidget {
  const HisHealth({super.key});

  @override
  _HisHealthScreenState createState() => _HisHealthScreenState();
}

class _HisHealthScreenState extends State<HisHealth> {
  List<Map<String, dynamic>> _healthData = [];
  List<Map<String, dynamic>> _filteredHealthData = [];
  Map<String, List<Map<String, dynamic>>> _groupedHealthData = {};

  String? userId;
  String? password;
  bool _isLogIn = false;
  String? _selectedSeq;
  String? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadSessionData().then((_) {
      _getHisHealth();
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

  Future<void> _getHisHealth() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('userId');

      ApiService apiService = ApiService();
      Map<String, dynamic> result =
          await apiService.fetchGetUserHlthHisInfo(userId!);
      print('Received data: $result');

      if (result.containsKey('listResultMap')) {
        setState(() {
          _healthData =
              List<Map<String, dynamic>>.from(result['listResultMap']);
          _groupHealthData();

          // 최신 MSMT_SEQ를 찾아 _selectedSeq와 _selectedDate에 설정
          List<String> seqOptions = _groupedHealthData.keys.toList()
            ..sort((a, b) {
              int seqA = int.tryParse(a) ?? 0;
              int seqB = int.tryParse(b) ?? 0;
              return seqB.compareTo(seqA); // 내림차순
            });

          if (seqOptions.isNotEmpty) {
            _selectedSeq = seqOptions.first; // 가장 최신 MSMT_SEQ 선택
            _selectedDate = _formatTimestampToDate(
                _groupedHealthData[_selectedSeq]!.first['MSMT_DAT']);
          }

          // 최신 MSMT_SEQ에 해당하는 데이터를 필터링
          _filteredHealthData = _groupedHealthData[_selectedSeq] ?? [];
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _groupHealthData() {
    _groupedHealthData = {};

    for (var item in _healthData) {
      String seq = item['MSMT_SEQ'].toString();
      String date = _formatTimestampToDate(item['MSMT_DAT']);
      if (!_groupedHealthData.containsKey(seq)) {
        _groupedHealthData[seq] = [];
        print("11111");
      }
      _groupedHealthData[seq]!.add(item);
      print("22222");
    }
    print("_groupedHealthData 확인 : $_groupedHealthData");
  }

  String _formatTimestampToDate(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      var dateTime =
          DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp.toString()));
      return DateFormat('yyyy-MM-dd').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  void _onSeqChanged(String? newValue) {
    setState(() {
      _selectedSeq = newValue;
      if (_selectedSeq != null) {
        _selectedDate = _formatTimestampToDate(
            _groupedHealthData[_selectedSeq]!.first['MSMT_DAT']);
      }
      _filteredHealthData = _groupedHealthData[newValue] ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get the list of seq options and sort them in descending order
    List<String> seqOptions = _groupedHealthData.keys.toList()
      ..sort((a, b) {
        // MSMT_SEQ를 숫자로 변환
        int seqA = int.tryParse(a) ?? 0;
        int seqB = int.tryParse(b) ?? 0;

        // 날짜를 문자열로 변환
        String dateA =
            _formatTimestampToDate(_groupedHealthData[a]!.first['MSMT_DAT']);
        String dateB =
            _formatTimestampToDate(_groupedHealthData[b]!.first['MSMT_DAT']);

        // MSMT_SEQ 우선 비교
        int seqComparison = seqB.compareTo(seqA); // 내림차순
        if (seqComparison != 0) {
          return seqComparison;
        }

        // MSMT_DAT로 비교
        return dateB.compareTo(dateA); // 내림차순
      });

    return Scaffold(
      appBar: const Header(),
      backgroundColor: Colors.white,
      drawer: CustomDrawer(isLogin: _isLogIn),
      body: SingleChildScrollView(
        child: Container(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '나의 건강정보 이력',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 30),
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0xFF555555), width: 1),
                  ),
                  alignment:
                      Alignment.center, // Center alignment for dropdown content
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSeq,
                      hint: const Center(
                        child: Text(
                          '선택',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ),
                      onChanged: _onSeqChanged,
                      items: seqOptions
                          .map<DropdownMenuItem<String>>((String seq) {
                        String date = _formatTimestampToDate(
                            _groupedHealthData[seq]!.first['MSMT_DAT']);
                        return DropdownMenuItem<String>(
                          value: seq,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0), // 내부 아이템에 패딩 추가
                            child: Center(
                              child: Text(
                                '$seq차   $date',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'NotoSansKR',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: Color(0xFF555555),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      style: const TextStyle(
                          fontFamily: 'NotoSansKR',
                          color: Color(0xFF555555),
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                      dropdownColor: Colors.white,
                      isExpanded: true,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Color(0xFFDEDEDE),
                    dividerTheme: const DividerThemeData(
                      color: Color(0xFFDEDEDE), // 구분선 색상
                      thickness: 1.0, // 구분선 두께
                      space: 0.0, // 위아래 간격 (원하는 경우 설정 가능)
                      indent: 0.0, // 시작 들여쓰기
                      endIndent: 0.0, // 끝 들여쓰기
                    ),
                    cardTheme: const CardThemeData(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero, // BorderRadius 제거
                      ),
                      elevation: 0,
                    ),
                    cardColor: Colors.white,
                    dataTableTheme: DataTableThemeData(
                      dividerThickness: 1,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFDEDEDE),
                            width: 1.0,
                          ),
                        ),
                      ),
                      headingRowColor: MaterialStateProperty.all(
                          Color(0xFFF5F4F9)), // 헤더 배경색
                      dataRowColor:
                          MaterialStateProperty.all(Colors.white), // 데이터 행 배경색
                      headingTextStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: Colors.black, // 헤더 텍스트 색상
                      ),
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.black, // 페이지네이션 텍스트 색상
                          backgroundColor: Colors.white),
                    ),
                  ),
                  child: _filteredHealthData.isEmpty
                      ? SizedBox(
                          height: 300,
                          child: Center(
                            child: Text(
                              '데이터가 없습니다.',
                              style: TextStyle(
                                fontFamily: 'NotoSansKR',
                                fontWeight: FontWeight.w500,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          child: PaginatedDataTable(
                            source: HealthData(_filteredHealthData),
                            rowsPerPage: 10,
                            horizontalMargin: 0,
                            columnSpacing: 42.0,
                            showFirstLastButtons: true,
                            columns: const [
                              DataColumn(
                                label: Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "측정항목",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "측정수치",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HealthData extends DataTableSource {
  final List<Map<String, dynamic>> _healthData;

  HealthData(this._healthData);

  @override
  DataRow? getRow(int index) {
    return DataRow(cells: [
      DataCell(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0), // 좌우 패딩 설정
          child: Align(
            alignment: Alignment.centerLeft, // 텍스트 왼쪽 정렬
            child: RichText(
              textAlign: TextAlign.left, // 텍스트 왼쪽 정렬
              overflow: TextOverflow.ellipsis, // 텍스트 길 경우 줄임표 처리
              maxLines: 1,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: _healthData[index]["MSMT_ITEM_NM"]?.toString() ?? '',
                    style: const TextStyle(
                      fontFamily: 'NotoSansKR',
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text:
                        ' (${_healthData[index]["MSMT_UNIT"]?.toString() ?? ''})',
                    style: const TextStyle(
                      fontFamily: 'NotoSansKR',
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      DataCell(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0), // 좌우 패딩 설정
          child: Align(
            alignment: Alignment.centerLeft, // 텍스트 왼쪽 정렬
            child: Text(
              _healthData[index]["MSMT_VALUE"]?.toString() ?? '',
              textAlign: TextAlign.left, // 텍스트 왼쪽 정렬
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                fontFamily: 'NunitoSans',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF555555),
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  // String _formatTimestampToDate(dynamic timestamp) {
  //   if (timestamp == null) return '';
  //   try {
  //     var dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp.toString()));
  //     return DateFormat('yyyy-MM-dd').format(dateTime);
  //   } catch (e) {
  //     return '';
  //   }
  // }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _healthData.length;

  @override
  int get selectedRowCount => 0;
}
