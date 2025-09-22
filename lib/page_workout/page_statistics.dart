import 'package:Vincere/component/custom_drawer.dart';
import 'package:Vincere/component/header.dart';
import 'package:Vincere/http/webReq.dart';
import 'package:Vincere/provider_models.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:Vincere/component/custom_text.dart';
import 'dart:convert';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => Component4State();
}

class Component4State extends State<StatisticsPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay; // 선택된 날짜
  List<Map<String, dynamic>> _selectedDayDatas = []; // 선택된 날짜
  ApiService apiService = ApiService();

  // 예시 운동 기록 데이터
  final Map<DateTime, Map<String, dynamic>> _workoutList = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay; // 초기값
    _async_init();
  }

  Future<void> _async_init() async {
    final userModel = Provider.of<UserModel>(context, listen: false);
    List<dynamic> result = (await apiService.selectWorkout(userModel.userId))['workoutList'];
    print("${result.length}, ${userModel.userId}");

    for (int i = 0; i < result.length; i++) {
      try {
        print(result[i]);
        DateTime st = DateTime.fromMillisecondsSinceEpoch(result[i]['START_TIME']); //.toUtc();
        DateTime et = DateTime.fromMillisecondsSinceEpoch(result[i]['END_TIME']); //.toUtc();
        DateTime ymdt = DateTime.utc(st.year, st.month, st.day);
        Map<String, dynamic> temp = jsonDecode(result[i]['META_INFO']);
        Map<String, String> meta_data = temp.map((key, value) => MapEntry(key, value.toString()));

        Duration duration = et.difference(st);
        meta_data['duration'] = "${duration.inMinutes}min ${duration.inSeconds % 60}sec";

        _workoutList[ymdt] = meta_data; // calendar data
        _workoutList[st] = meta_data; // list data
        print("${userModel.userId}, ${st}, ${meta_data}");
      } catch (e) {
        print("db workout log parse error... ");
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Set<DateTime> mySelectedDays = _workoutList.keys.toSet();
    final screenHeight = MediaQuery.of(context).size.height - 50;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: const Header(),
      drawer: CustomDrawer(isLogin: true),
      body: Container(
        width: double.infinity,
        child: Container(
          color: Color(0xFFf5f4f9),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.05),
              Card(
                elevation: 4,
                margin: const EdgeInsets.fromLTRB(15, 0, 15, 20),
                color: const Color(0xFFFFFFFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                    padding: const EdgeInsets.all(20),
                    child: TableCalendar(
                      rowHeight: 45,
                      locale: 'ko_KR',
                      firstDay: DateTime.utc(2000, 1, 1),
                      lastDay: DateTime.utc(2100, 12, 31),
                      focusedDay: _focusedDay,
                      onDaySelected: (selectedDay, focusedDay) {
                        _selectedDayDatas = [];
                        List<DateTime> dateKeys = _workoutList.keys.toList();
                        for (int i = 0; i < dateKeys.length; i++) {
                          DateTime dateKey = dateKeys[i];
                          DateTime ymdt = DateTime.utc(dateKey.year, dateKey.month, dateKey.day);
                          if ((dateKey.hour == 0) & (dateKey.minute == 0)) continue;
                          if (ymdt == selectedDay) _selectedDayDatas.add(_workoutList[dateKey]!);
                        }
                        print(_selectedDayDatas);
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      calendarFormat: CalendarFormat.month,
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        headerPadding: EdgeInsets.symmetric(vertical: 12), // 헤더 아래 여백
                      ),
                      daysOfWeekHeight: 30, // 요일 영역 높이
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(fontSize: 14), // 평일 글자 크기
                        weekendStyle: TextStyle(fontSize: 14, color: Colors.red), // 주말 글자 크기
                      ),
                      calendarStyle: const CalendarStyle(
                        cellMargin: EdgeInsets.symmetric(horizontal: 3, vertical: 4), // 셀 간격
                        todayDecoration: BoxDecoration(
                          color: Colors.orangeAccent, // 오늘 날짜 배경 색상
                          shape: BoxShape.circle, // 원 형태
                        ),
                        todayTextStyle: const TextStyle(
                          fontSize: 10, // 평일 글자 크기
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // 오늘 날짜 글자 색상
                        ),
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          final isHighlighted = mySelectedDays.any((d) => d.year == day.year && d.month == day.month && d.day == day.day);

                          if (isHighlighted) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                OverflowBox(
                                    maxWidth: double.infinity,
                                    child: Container(
                                        width: screenWidth / 6,
                                        height: 25,
                                        decoration: BoxDecoration(
                                          color: Colors.orangeAccent,
                                          borderRadius: BorderRadius.circular(10),
                                        ))),
                                Text('${day.day}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            );
                          }

                          return null; // 기본 빌더로 렌더링
                        },
                      ),
                    )),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _selectedDayDatas.length,
                  itemBuilder: (context, index) {
                    final exercise = _selectedDayDatas[index];
                    return SizedBox(
                      width: double.infinity,
                      child: MouseRegion(
                        child: Card(
                          elevation: 4,
                          margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                          color: const Color(0xFFFFFFFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            padding: EdgeInsets.fromLTRB(24, 4, 24, 4),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),
                                TextLarge(
                                  text: '${_selectedDay?.month}월 ${_selectedDay?.day}일',
                                ),
                                SizedBox(height: screenHeight * 0.01),
                                TextMedium(text: '모드 : ${exercise['mode']}'),
                                TextMedium(text: '근육 : ${exercise['muscle']}'),
                                TextMedium(text: '강도 : ${exercise['intensity']}'),
                                TextMedium(text: '시간 : ${exercise['duration']}'),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
