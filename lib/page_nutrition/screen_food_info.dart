import 'package:Vincere/http/webReq.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Vincere/export/screens.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FoodInfo extends StatefulWidget {
  const FoodInfo({super.key});

  @override
  _FoodInfoScreenState createState() => _FoodInfoScreenState();
}

class _FoodInfoScreenState extends State<FoodInfo> {
  List<Map<String, dynamic>> _foodData = [];

  String? userId;
  String? password;
  bool _isLogIn = false;

  @override
  void initState() {
    super.initState();
    _loadSessionData().then((_){
      _getFoodInfo();
    });
  }

  // 세션에서 userId와 password 불러오기
  Future<void> _loadSessionData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
      password = prefs.getString('password');
      if(userId != null && password != null){
        _isLogIn = true;
      }
    });
  }

  Future<void> _getFoodInfo() async {
    try {
      ApiService apiService = ApiService();
      Map<String, dynamic> result = await apiService.fetchGetFoodInfo();
      print('Received data: $result');

      // foodInfoList 데이터를 추출하여 _foodData에 저장
      if (result.containsKey('foodInfoList')) {
        setState(() {
          _foodData = List<Map<String, dynamic>>.from(result['foodInfoList']);
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Header(),
      drawer: CustomDrawer(isLogin: _isLogIn),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 50,
              child: const Padding(
                padding: EdgeInsets.fromLTRB(20, 15, 0, 0),
                child: Text(
                  '식품별 영양 정보',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.height,
              color: Colors.green,
              padding: const EdgeInsets.all(20.0),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.white,
                child: PaginatedDataTable(
                  source: FoodData(_foodData),
                  rowsPerPage: 10,
                  horizontalMargin: 0,
                  columnSpacing: 50.0,
                  showFirstLastButtons: true,
                  columns: const [
                    DataColumn(
                      label: Expanded(
                        flex: 1,
                        child: Center(
                          child: Text(
                            "식품명",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Expanded(
                        flex: 3,
                        child: Center(
                          child: Text(
                            "영양 정보",
                            textAlign: TextAlign.center,
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
    );
  }
}

class FoodData extends DataTableSource {
  final List<Map<String, dynamic>> _foodData;

  FoodData(this._foodData);

  @override
  DataRow? getRow(int index) {
    return DataRow(cells: [
      DataCell(
        Center(
          child: Text(
            _foodData[index]["title"]?.toString() ?? '',
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
      DataCell(
        Container(
          child: Center(
            child: Text(
              _foodData[index]["content"]?.toString() ?? '',
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      ),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _foodData.length;

  @override
  int get selectedRowCount => 0;
}
