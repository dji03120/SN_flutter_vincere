// import 'package:Vincere/http/webReq.dart';
// import 'package:Vincere/export/screens.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class MyHomePage extends StatefulWidget {
//   final String title;
//
//   const MyHomePage({
//     super.key,
//     required this.title,
//   });
//
//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }
//
// class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
//   late TabController _tabController; // 하단 홈, 마이페이지 등의 버튼 컨트롤러
//   int _selectedIndex = 0; // 하단 홈, 마이페이지 등의 버튼 선택 숫자
//   bool _isLogIn = false;
//   String? userId;
//   String? password;
//   Map<String, dynamic>? userData; // 마이페이지 회원 정보
//   List<Map<String, dynamic>> userHlthData = []; // 마이페이지 회원 건강 정보
//   List<Map<String, dynamic>> userPscpData = []; // 마이페이지 회원 처방 정보
//
//   // 초기 설정
//   @override
//   void initState() {
//     super.initState();
//     _loadSessionData().then((_) {
//       if (_isLogIn) {
//         _getUserInfo();
//         _getUserHlthInfo();
//         _getUserPscpInfo();
//       }
//     });
//     _tabController = TabController(length: 3, vsync: this);
//     _tabController.addListener(() =>
//         setState(() => _selectedIndex = _tabController.index));
//   }
//
//   // 세션에서 userId와 password 불러오기
//   Future<void> _loadSessionData() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     setState(() {
//       userId = prefs.getString('userId');
//       password = prefs.getString('password');
//       if (userId != null && password != null) {
//         _isLogIn = true;
//       }
//     });
//   }
//
//   // 회원 정보 가져오기
//   Future<void> _getUserInfo() async {
//     try {
//       ApiService apiService = ApiService();
//       Map<String, dynamic> result = await apiService.fetchGetUserInfo(
//           userId.toString());
//
//       setState(() {
//         userData = result["userOne"];
//       });
//     } catch (e) {
//       print('Error: $e');
//     }
//   }
//
//   // 회원 건강 정보 가져오기
//   Future<void> _getUserHlthInfo() async {
//     try {
//       ApiService apiService = ApiService();
//       Map<String, dynamic> result = await apiService.fetchGetUserHlthInfo(
//           userId.toString());
//
//       if (result.containsKey('listResultMap')) {
//         setState(() {
//           userHlthData =
//           List<Map<String, dynamic>>.from(result["listResultMap"]);
//         });
//       }
//     } catch (e) {
//       print('Error: $e');
//     }
//   }
//
//   // 회원 최신 처방 정보 가져오기
//   Future<void> _getUserPscpInfo() async {
//     try {
//       ApiService apiService = ApiService();
//       Map<String, dynamic> result = await apiService.fetchGetLstPscpInfo(
//           userId.toString());
//
//       if (result.containsKey('lstPscpList')) {
//         setState(() {
//           userPscpData = List<Map<String, dynamic>>.from(result['lstPscpList']);
//         });
//       }
//     } catch (e) {
//       print('Error: $e');
//     }
//   }
//
//   // 로그인 세션에 아이디와 비밀번호 없을 시 알람
//   void _showLoginPrompt() {
//     showDialog(
//       context: context,
//       builder: (context) =>
//           AlertDialog(
//             title: Text('사용 불가'),
//             content: Text('로그인을 하셔야 이용 가능합니다.'),
//             actions: [
//               TextButton(
//                 onPressed: () =>
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => const LoginScreen(),
//                       ),
//                     ),
//                 child: Text('로그인 하기'),
//               ),
//               TextButton(
//                 onPressed: () {
//                   Navigator.of(context).pop(); // '아니오'를 선택하면 알림창만 닫힘
//                 },
//                 child: const Text('취소'),
//               ),
//             ],
//           ),
//     );
//   }
//
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: const Header(),
//       drawer: CustomDrawer(isLogin: _isLogIn),
//       bottomNavigationBar: SizedBox(
//         height: 80,
//         child: TabBar(
//           indicatorColor: Colors.transparent,
//           labelColor: Colors.black,
//           controller: _tabController,
//           tabs: <Widget>[
//             Tab(
//               icon: Icon(
//                 _selectedIndex == 0 ? Icons.home : Icons.home_outlined,
//               ),
//               text: "홈",
//             ),
//             Tab(
//               icon: Icon(
//                 _selectedIndex == 1 ? Icons.person : Icons.person_2_outlined,
//               ),
//               text: "마이페이지",
//             ),
//             Tab(
//               icon: Icon(
//                 _selectedIndex == 2 ? Icons.assignment : Icons
//                     .assignment_outlined,
//               ),
//               text: "건강정보&처방",
//             ),
//           ],
//         ),
//       ),
//       body: _selectedIndex == 0
//           ? tabContainer(context, Colors.amber, "홈")
//           : _selectedIndex == 1
//           ? tabContainer(context, Color.fromRGBO(172, 185, 255, 1), "마이페이지")
//           : tabContainer(context, Colors.blueGrey, "건강정보&처방"),
//     );
//   }
//
//   Container tabContainer(BuildContext context, Color tabColor, String tabText) {
//     return Container(
//       width: MediaQuery.of(context).size.width,
//       height: MediaQuery.of(context).size.height,
//       color: tabColor,
//       padding: const EdgeInsets.all(16.0), // 전체 화면에 여백 추가
//       child: (tabText == "홈")
//           ? Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           // 첫 번째 줄: "나의 건강 정보 이력" & "나의 영양 상태 평가 및 식단 추천"
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               Expanded(
//                 child: ElevatedButton(
//                   onPressed: () {
//                     if (_isLogIn) {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) => const HisHealth()),
//                       );
//                     } else {
//                       _showLoginPrompt();
//                     }
//                   },
//                   child: const Text(
//                     '나의 건강 정보 이력',
//                     style: TextStyle(fontSize: 24), // 글자 크기 2배로 설정
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 20),
//               Expanded(
//                 child: ElevatedButton(
//                   onPressed: () {
//                     if (_isLogIn) {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) => const MyNutriCheck()),
//                       );
//                     } else {
//                       _showLoginPrompt();
//                     }
//                   },
//                   child: const Text(
//                     '나의 영양 상태 평가 및 식단 추천',
//                     style: TextStyle(fontSize: 24), // 글자 크기 2배로 설정
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//
//           // 두 번째 줄: "식품별 영양 정보" & "Q&A"
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               Expanded(
//                 child: ElevatedButton(
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                           builder: (context) => const FoodInfo()),
//                     );
//                   },
//                   child: const Text(
//                     '식품별 영양 정보',
//                     style: TextStyle(fontSize: 24), // 글자 크기 2배로 설정
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 20),
//               Expanded(
//                 child: ElevatedButton(
//                   onPressed: () {
//                     if (_isLogIn) {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (context) => const Qna()),
//                       );
//                     } else {
//                       _showLoginPrompt();
//                     }
//                   },
//                   child: const Text(
//                     'Q&A',
//                     style: TextStyle(fontSize: 24), // 글자 크기 2배로 설정
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//
//           // 세 번째 줄: "나의 건강 정보 입력 및 자동 처방 신청"
//           ElevatedButton(
//             onPressed: () {
//               if (_isLogIn) {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => const InputInfoScreen(),
//                   ),
//                 );
//               } else {
//                 _showLoginPrompt();
//               }
//             },
//             child: const Text(
//               '나의 건강 정보 입력 및 자동 처방 신청',
//               style: TextStyle(fontSize: 24), // 글자 크기 2배로 설정
//             ),
//           ),
//         ],
//       )
//           : (tabText == "마이페이지")
//           ? userInfoContainer(context, userData)
//           : (tabText == "건강정보&처방")
//           ? Column(
//         children: [
//           Expanded(
//             child: healthInfoContainer(context, userHlthData),
//           ),
//           Expanded(
//             child: pscpInfoContainer(context, userPscpData),
//           ),
//         ],
//       )
//           : Container(),
//     );
//   }
//
// // 상태 변수 추가 (클래스의 필드로)
//   String currentActivityLevel = "LOW";
//
// // 회원 정보 컨테이너
//   Container userInfoContainer(BuildContext context,
//       Map<String, dynamic>? userData) {
//     // 함수 시작시 현재 활동량 설정
//     currentActivityLevel = userData?["activityLevel"] ?? "LOW";
//
//     return Container(
//       color: Colors.blueGrey,
//       child: (userData == null)
//           ? Center(
//         child: Text(
//           '회원 정보가 없습니다.',
//           style: TextStyle(color: Colors.white, fontSize: 20),
//         ),
//       )
//           : Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Text(
//               '회원 정보',
//               style: TextStyle(fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white),
//             ),
//           ),
//           Expanded(
//             child: ListView(
//               padding: EdgeInsets.all(16),
//               children: [
//                 _buildUserInfoCard(
//                   title: '회원 아이디',
//                   value: userData["userId"] ?? "N/A",
//                 ),
//                 _buildUserInfoCard(
//                   title: '회원 이름',
//                   value: userData["userNm"] ?? "N/A",
//                 ),
//                 _buildUserInfoCard(
//                   title: '생년월일',
//                   value: userData["bym"] ?? "N/A",
//                 ),
//                 _buildUserInfoCard(
//                   title: '성별',
//                   value: userData?["sex"] == "M" ? "남성" : "여성",
//                 ),
//                 StatefulBuilder(
//                   builder: (BuildContext context, StateSetter setState) {
//                     return Card(
//                       child: Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Row(
//                           children: [
//                             Expanded(
//                               flex: 3,
//                               child: Text(
//                                 '활동량 구분',
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 16,
//                                 ),
//                               ),
//                             ),
//                             Expanded(
//                               flex: 7,
//                               child: DropdownButton<String>(
//                                 value: currentActivityLevel,
//                                 items: [
//                                   DropdownMenuItem(value: 'LOW', child: Text('좌업자')),
//                                   DropdownMenuItem(value: 'NORMAL', child: Text('보통활동')),
//                                   DropdownMenuItem(value: 'HIGH', child: Text('육체활동')),
//                                 ],
//                                 onChanged: (String? value) async {
//                                   if (value != null && currentActivityLevel != value) {
//                                     // 확인 다이얼로그
//                                     bool? confirm = await showDialog<bool>(
//                                       context: context,
//                                       builder: (BuildContext context) {
//                                         return AlertDialog(
//                                           title: Text('활동량 변경'),
//                                           content: Text('활동량을 변경하시겠습니까?'),
//                                           actions: <Widget>[
//                                             TextButton(
//                                               child: Text('취소'),
//                                               onPressed: () =>
//                                                   Navigator.of(context).pop(false),
//                                             ),
//                                             TextButton(
//                                               child: Text('확인'),
//                                               onPressed: () =>
//                                                   Navigator.of(context).pop(true),
//                                             ),
//                                           ],
//                                         );
//                                       },
//                                     );
//
//                                     if (confirm == true) {
//                                       try {
//                                         ApiService apiService = ApiService();
//                                         Map<String, dynamic> result =
//                                         await apiService.updateUserActivityLevel(
//                                           userData["userId"],
//                                           value,
//                                         );
//
//                                         if (result['result'] == 1) {
//                                           setState(() {
//                                             currentActivityLevel = value;
//                                             // userData도 함께 업데이트
//                                             userData?["activityLevel"] = value;
//                                           });
//                                           ScaffoldMessenger.of(context).showSnackBar(
//                                             SnackBar(
//                                               content: Text('활동량이 업데이트되었습니다.'),
//                                               backgroundColor: Colors.green,
//                                             ),
//                                           );
//                                         } else {
//                                           ScaffoldMessenger.of(context).showSnackBar(
//                                             SnackBar(
//                                               content: Text('활동량 업데이트에 실패했습니다.'),
//                                               backgroundColor: Colors.red,
//                                             ),
//                                           );
//                                         }
//                                       } catch (e) {
//                                         print('Error updating activity level: $e');
//                                         ScaffoldMessenger.of(context).showSnackBar(
//                                           SnackBar(
//                                             content: Text('오류가 발생했습니다. 다시 시도해주세요.'),
//                                             backgroundColor: Colors.red,
//                                           ),
//                                         );
//                                       }
//                                     }
//                                   }
//                                 },
//                                 isExpanded: true,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
// // 회원 정보 카드 빌더
//   Widget _buildUserInfoCard({required String title, required String value}) {
//     return Card(
//       color: Colors.white,
//       margin: EdgeInsets.symmetric(vertical: 8.0),
//       child: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               title,
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             Text(
//               value,
//               style: TextStyle(fontSize: 16),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
// // 건강 정보 컨테이너
//   Container healthInfoContainer(BuildContext context,
//       List<Map<String, dynamic>> healthData) {
//     return Container(
//       color: Colors.blueGrey,
//       child: (healthData.isEmpty)
//           ? Center(
//         child: Text(
//           '건강 정보가 없습니다.',
//           style: TextStyle(color: Colors.white, fontSize: 20),
//         ),
//       )
//           : Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Text(
//               '건강 정보',
//               style: TextStyle(fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white),
//             ),
//           ),
//           Expanded(
//             child: ListView(
//               padding: EdgeInsets.all(16),
//               children: healthData.map((item) {
//                 return _buildInfoCard(
//                   title: item['MSMT_ITEM_NM'] ?? '항목명 없음',
//                   value: '${item['MSMT_VALUE']} ${item['MSMT_UNIT']}',
//                 );
//               }).toList(),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Container pscpInfoContainer(BuildContext context,
//       List<Map<String, dynamic>> pscpData) {
//     return Container(
//       color: Colors.blueGrey,
//       child: (pscpData.isEmpty)
//           ? Center(
//         child: Text(
//           '처방 정보가 없습니다.',
//           style: TextStyle(color: Colors.white, fontSize: 20),
//         ),
//       )
//           : Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Text(
//               '처방 정보',
//               style: TextStyle(fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white),
//             ),
//           ),
//           Expanded(
//             child: ListView(
//               padding: EdgeInsets.all(16),
//               children: pscpData.map((item) {
//                 return _buildInfoCard(
//                   title: item['hlthFoodNm'] ?? '항목명 없음',
//                   value: '${item['pscpDose']}',
//                 );
//               }).toList(),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // 공통 카드 빌더
//   Widget _buildInfoCard({required String title, required String value}) {
//     return Card(
//       color: Colors.white,
//       margin: EdgeInsets.symmetric(vertical: 8.0),
//       child: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               title,
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             Text(
//               value,
//               style: TextStyle(fontSize: 16),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
