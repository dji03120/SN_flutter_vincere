import 'package:Vincere/component/custom_drawer.dart';
import 'package:Vincere/component/header.dart';
import 'package:Vincere/page_ble_device/ble_utils.dart';
import 'package:Vincere/provider_models.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:Vincere/component/custom_text.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => Component4State();
}

class Component4State extends State<StatisticsPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay; // 선택된 날짜
  bool _isHovered = false;

  // 예시 운동 기록 데이터
  final Map<DateTime, Map<String, String>> _exerciseData = {
    DateTime.utc(2025, 9, 4): {
      'mode': '수동',
      'intensity': '중간',
      'duration': '90min',
    },
    DateTime.utc(2025, 9, 5): {
      'mode': '수동',
      'intensity': '중간',
      'duration': '90min',
    },
    DateTime.utc(2025, 9, 6): {
      'mode': '수동',
      'intensity': '중간',
      'duration': '90min',
    },
    DateTime.utc(2025, 9, 15): {
      'mode': '능동',
      'intensity': '높음',
      'duration': '60min',
    },
    DateTime.utc(2025, 9, 20): {
      'mode': '수동',
      'intensity': '낮음',
      'duration': '30min',
    },
  };

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay; // 초기값
  }

  @override
  Widget build(BuildContext context) {
    Set<DateTime> mySelectedDays = _exerciseData.keys.toSet();
    final screenHeight = MediaQuery.of(context).size.height - 50;
    final screenWidth = MediaQuery.of(context).size.width;

    // 선택된 날짜의 운동 기록 가져오기
    final exercise = _exerciseData[_selectedDay] ?? {'mode': '-', 'intensity': '-', 'duration': '-'};

    return Scaffold(
      appBar: const Header(),
      drawer: CustomDrawer(isLogin: true),
      body: Container(
        width: double.infinity,
        child: Container(
          color: Color(0xFFf5f4f9),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.1),
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
                          final isFocused = day.year == _focusedDay.year && day.month == _focusedDay.month && day.day == _focusedDay.day;

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
                                    ),
                                  ),
                                ),
                                Text('${day.day}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    )),
                              ],
                            );
                          }

                          return null; // 기본 빌더로 렌더링
                        },
                      ),
                    )),
              ),
              SizedBox(height: screenHeight * 0.02),
              SizedBox(
                width: double.infinity,
                child: MouseRegion(
                  onEnter: (_) => setState(() => _isHovered = true),
                  onExit: (_) => setState(() => _isHovered = false),
                  child: AnimatedScale(
                    scale: _isHovered ? 1.05 : 1.0,
                    duration: Duration(milliseconds: 300),
                    child: Card(
                      elevation: 4,
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      color: const Color(0xFFFFFFFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 20),
                          TextLarge(
                            text: '${_selectedDay?.month}월 ${_selectedDay?.day}일 의 운동 기록',
                          ),
                          TextMedium(text: '모드 : ${exercise['mode']}'),
                          TextMedium(text: '강도 : ${exercise['intensity']}'),
                          TextMedium(text: '운동시간 : ${exercise['duration']}'),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
