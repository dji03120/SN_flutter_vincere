import 'package:Vincere/custom_widget/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:Vincere/custom_widget/custom_text.dart';

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
    DateTime.utc(2025, 8, 4): {
      'mode': '수동',
      'intensity': '중간',
      'duration': '90min',
    },
    DateTime.utc(2025, 8, 15): {
      'mode': '능동',
      'intensity': '높음',
      'duration': '60min',
    },
    DateTime.utc(2025, 8, 20): {
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

    // 선택된 날짜의 운동 기록 가져오기
    final exercise = _exerciseData[_selectedDay] ?? {'mode': '-', 'intensity': '-', 'duration': '-'};

    return Scaffold(
      appBar: AppBar(title: const Text("운동 통계 화면")),
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
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                color: const Color(0xFFFFFFFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: TableCalendar(
                    rowHeight: screenHeight * 0.05,
                    locale: 'ko_KR',
                    firstDay: DateTime.utc(2000, 1, 1),
                    lastDay: DateTime.utc(2100, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) {
                      // 특정 날짜들을 강조
                      return mySelectedDays.contains(day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    calendarFormat: CalendarFormat.month,
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false, // FormatButton 숨김
                    ),
                  ),
                ),
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
