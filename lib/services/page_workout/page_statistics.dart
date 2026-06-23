import 'package:Vincere/provider_models.dart';
import 'package:Vincere/services/page_activity/activity_daily_store.dart';
import 'package:Vincere/utils/component/custom_drawer.dart';
import 'package:Vincere/utils/component/custom_widget.dart';
import 'package:Vincere/utils/component/header.dart';
import 'package:Vincere/utils/component/radar_chart.dart';
import 'package:Vincere/utils/http/webReqSpring.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:convert';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => Component4State();
}

class Component4State extends State<StatisticsPage> {
  DateTime _focusedDay = DateTime.now();
  List<Map<String, dynamic>> _selectedDayDatas = []; // 선택된 날짜
  List<String> _muscleNames = []; // 선택된 날짜 강도
  Map<String, List<num>> _muscleIntensity = {}; // 선택된 날짜 강도
  Map<String, List<num>> _muscleDuration = {}; // 선택된 날짜 실행시간
  Map<String, DailyActivitySummary> _activityList = {};
  DailyActivitySummary? _selectedActivitySummary;
  ApiService apiService = ApiService();

  // 예시 운동 기록 데이터
  final Map<DateTime, Map<String, dynamic>> _workoutList = {};
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _async_init();
  }

  @override
  void dispose() {
    _pageController.dispose(); // 여기서 dispose 해야 합니다
    super.dispose();
  }

  Future<void> _async_init() async {
    final userModel = Provider.of<UserModel>(context, listen: false);
    List<dynamic> result =
        (await apiService.selectWorkout(userModel.userId))['workoutList'];
    print("${result.length}, ${userModel.userId}");

    for (int i = 0; i < result.length; i++) {
      try {
        print(result[i]);
        DateTime st = DateTime.fromMillisecondsSinceEpoch(
            result[i]['START_TIME']); //.toUtc();
        DateTime ymdt = DateTime.utc(st.year, st.month, st.day);
        Map<String, dynamic> temp = jsonDecode(result[i]['META_INFO']);
        Map<String, dynamic> meta_data = temp.map((key, value) =>
            MapEntry(key, value is String ? jsonDecode(value) : value));

        _workoutList[ymdt] = meta_data; // calendar data
        _workoutList[st] = meta_data; // list data
        print("${userModel.userId}, ${st}, ${meta_data}");
      } catch (e) {
        print("db workout log parse error... ");
      }
    }
    _activityList = await ActivityDailyStore.loadAll();
    _selectedActivitySummary = _activityList[ActivityDailyStore.todayKey()];
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Set<DateTime> mySelectedDays = _workoutList.keys.toSet();
    final screenHeight = MediaQuery.of(context).size.height;
    final userModel = Provider.of<UserModel>(context);

    return Scaffold(
        backgroundColor: const Color(0xFFF5F4F9),
        appBar: const Header(),
        drawer: CustomDrawer(isLogin: true),
        body: SingleChildScrollView(
            child: Container(
                width: double.infinity,
                child: Container(
                    color: Color(0xFFf5f4f9),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        _backButtonWidget(),
                        SizedBox(height: screenHeight * 0.03),
                        _calendarWidget(userModel, mySelectedDays),
                        SizedBox(height: screenHeight * 0.05),
                        if (_selectedDayDatas.length != 0) _radarChartWidget(),
                        SizedBox(height: screenHeight * 0.05),
                        _activityCalendarWidget(),
                        SizedBox(height: screenHeight * 0.03),
                        if (_selectedActivitySummary != null)
                          _activityDetailWidget(_selectedActivitySummary!),
                        SizedBox(height: screenHeight * 0.1),
                      ],
                    )))));
  }

  // 통계 화면 상단에서 이전 화면으로 돌아가기 위한 기능
  Widget _backButtonWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('뒤로가기'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF007130),
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }

  // UWB/IMU 활동 이력 달력과 선택 상태를 표시하기 위한 기능
  Widget _activityCalendarWidget() {
    final selectedDays = _activityList.keys.toSet();
    final screenWidth = MediaQuery.of(context).size.width;
    return Card(
      elevation: 4,
      margin: const EdgeInsets.fromLTRB(15, 0, 15, 16),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('UWB·IMU 활동 이력',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('날짜별 활동 시간, 움직임 감지, 휴식 시간을 확인합니다.',
                style: TextStyle(color: Color(0xFF666666), fontSize: 14)),
            const SizedBox(height: 12),
            TableCalendar(
              rowHeight: 38,
              locale: 'ko_KR',
              firstDay: DateTime.utc(2000, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: _focusedDay,
              onDaySelected: (selectedDay, focusedDay) {
                final key = ActivityDailyStore.dateKey(selectedDay);
                setState(() {
                  _focusedDay = focusedDay;
                  _selectedActivitySummary = _activityList[key];
                });
              },
              calendarFormat: CalendarFormat.month,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                    color: Color(0xFF92D2B0), shape: BoxShape.circle),
                todayTextStyle: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final key = ActivityDailyStore.dateKey(day);
                  final isHighlighted = selectedDays.contains(key);
                  if (!isHighlighted) return null;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      OverflowBox(
                        maxWidth: double.infinity,
                        child: Container(
                          width: screenWidth / 7,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF007130),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Text('${day.day}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 선택한 날짜의 UWB/IMU 활동 상세 내용을 표시하기 위한 기능
  Widget _activityDetailWidget(DailyActivitySummary summary) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.fromLTRB(15, 0, 15, 16),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${summary.dateKey} 활동 상세',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child: _activityDetailItem(Icons.timer_rounded, '활동 시간',
                        _formatDuration(summary.activeSeconds))),
                Expanded(
                    child: _activityDetailItem(Icons.directions_run_rounded,
                        '움직임 감지', '${summary.movementCount}회')),
                Expanded(
                    child: _activityDetailItem(Icons.self_improvement_rounded,
                        '휴식 시간', _formatDuration(summary.restSeconds))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _activityDetailItem(Icons.insights_rounded, '활동 점수',
                        summary.activityScore.toStringAsFixed(0))),
                Expanded(
                    child: _activityDetailItem(Icons.event_available_rounded,
                        '세션', '${summary.sessionCount}회')),
                Expanded(
                    child: _activityDetailItem(Icons.event_seat_rounded,
                        '휴식 감지', '${summary.restEventCount}회')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // UWB/IMU 활동 상세 항목 하나를 표시하기 위한 기능
  Widget _activityDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF007130), size: 24),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(color: Color(0xFF777777), fontSize: 12)),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(
                color: Color(0xFF111111),
                fontSize: 14,
                fontWeight: FontWeight.w800)),
      ],
    );
  }

  // 초 단위 활동 시간을 보기 좋은 문자열로 변환하기 위한 기능
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainSeconds = seconds % 60;
    if (minutes == 0) return '$remainSeconds초';
    return '$minutes분 $remainSeconds초';
  }

  //
  //
  //
  //
  Widget _calendarWidget(UserModel userModel, Set<DateTime> mySelectedDays) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Card(
      elevation: 4,
      margin: const EdgeInsets.fromLTRB(15, 0, 15, 10),
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: TableCalendar(
          rowHeight: 40,
          locale: 'ko_KR',
          firstDay: DateTime.utc(2000, 1, 1),
          lastDay: DateTime.utc(2100, 12, 31),
          focusedDay: _focusedDay,
          onDaySelected: (selectedDay, focusedDay) {
            //
            //
            _selectedDayDatas = [];
            List<DateTime> dateKeys = _workoutList.keys.toList();
            for (int i = 0; i < dateKeys.length; i++) {
              DateTime dateKey = dateKeys[i];
              DateTime ymdt =
                  DateTime.utc(dateKey.year, dateKey.month, dateKey.day);
              if ((dateKey.hour == 0) & (dateKey.minute == 0)) continue;
              if (ymdt == selectedDay)
                _selectedDayDatas.add(_workoutList[dateKey]!);
            }
            Map<dynamic, dynamic> workoutData = _selectedDayDatas[0];
            //
            //
            if (!workoutData.containsKey('60hz')) return;
            _muscleIntensity['60hz'] = [];
            _muscleIntensity['100hz'] = [];
            _muscleDuration['60hz'] = [];
            _muscleDuration['100hz'] = [];
            _muscleNames = [];
            List<String> keys = workoutData['60hz'].keys.toList();
            print(keys);
            //
            //
            for (int i = 0; i < keys.length; i++) {
              final muscle = keys[i];
              if (workoutData['60hz'][muscle]['type'] == 'paid') {
                if ((userModel.userInfo?['authCd'] ?? '').contains('PAID') ==
                    false) {
                  continue;
                }
              }

              double intensity60 =
                  workoutData['60hz'][muscle]['intensitySum']?.toDouble() ??
                      0.0;
              double duration60 =
                  workoutData['60hz'][muscle]['duration']?.toDouble() ?? 0.0;
              double avg60hz =
                  duration60 == 0 ? 0.0 : (intensity60 / duration60);

              double intensity100 =
                  workoutData['100hz'][muscle]['intensitySum']?.toDouble() ??
                      0.0;
              double duration100 =
                  workoutData['100hz'][muscle]['duration']?.toDouble() ?? 0.0;
              double avg100hz =
                  duration100 == 0 ? 0.0 : (intensity100 / duration100);

              // 리스트에 추가
              _muscleIntensity['60hz']!.add(avg60hz);
              _muscleIntensity['100hz']!.add(avg100hz);
              _muscleDuration['60hz']!.add(duration60);
              _muscleDuration['100hz']!.add(duration100);
              _muscleNames.add(keys[i]);
            }

//
            print("$_muscleNames, $_muscleIntensity, $_muscleDuration");
            setState(() {
              _focusedDay = focusedDay;
            });
          },
          calendarFormat: CalendarFormat.month,
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            headerPadding: EdgeInsets.symmetric(vertical: 6), // 헤더 아래 여백
          ),
          daysOfWeekHeight: 30, // 요일 영역 높이
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(fontSize: 14), // 평일 글자 크기
            weekendStyle:
                TextStyle(fontSize: 14, color: Colors.red), // 주말 글자 크기
          ),
          calendarStyle: const CalendarStyle(
            cellMargin:
                EdgeInsets.symmetric(horizontal: 3, vertical: 4), // 셀 간격
            todayDecoration: BoxDecoration(
                color: Colors.orangeAccent, shape: BoxShape.circle),
            todayTextStyle: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              final isHighlighted = mySelectedDays.any((d) =>
                  d.year == day.year &&
                  d.month == day.month &&
                  d.day == day.day);

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
                    Text('${day.day}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                );
              }

              return null; // 기본 빌더로 렌더링
            },
          ),
        ),
      ),
    );
  }

  //
  //
  //
  //
  Widget _radarChartWidget() {
    final screenHeight = MediaQuery.of(context).size.height;
    return Card(
        elevation: 4,
        margin: const EdgeInsets.fromLTRB(15, 0, 15, 0),
        color: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Container(
              height: 335,
              child: PageView(
                  controller: _pageController,
                  scrollDirection: Axis.horizontal,
                  children: [
                    Column(children: [
                      SizedBox(height: 30),
                      TextCustom(text: 'Intensity', fontSize: 22),
                      SizedBox(height: 20),
                      Container(
                          height: 250,
                          child: RadarChartWidget(
                              ticks: [3, 6, 9, 12, 15],
                              features: _muscleNames,
                              colors: [Colors.orangeAccent, Colors.green],
                              data: [
                                _muscleIntensity['60hz'] ?? [],
                                _muscleIntensity['100hz'] ?? [],
                              ]))
                    ]),
                    Column(children: [
                      SizedBox(height: 30),
                      TextCustom(text: 'Duration', fontSize: 22),
                      SizedBox(height: 20),
                      Container(
                          height: 250,
                          child: RadarChartWidget(
                            ticks: [3, 6, 9, 12, 15, 20],
                            features: _muscleNames,
                            colors: [Colors.blueAccent, Colors.redAccent],
                            data: [
                              _muscleDuration['60hz'] ?? [],
                              _muscleDuration['100hz'] ?? [],
                            ],
                          ))
                    ])
                  ])),
          SmoothPageIndicator(
              controller: _pageController,
              count: 2,
              effect: WormEffect(
                dotColor: Colors.grey.shade300,
                activeDotColor: Colors.orangeAccent,
                dotHeight: 10,
                dotWidth: 10,
              )),
          SizedBox(height: screenHeight * 0.05),
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: MuscleDataTable(
              muscleNames: _muscleNames,
              muscleIntensity: _muscleIntensity,
              muscleDuration: _muscleDuration,
            ),
          ),
          SizedBox(height: screenHeight * 0.05),
        ]));
  }
}

//
//
//
//
class MuscleDataTable extends StatelessWidget {
  final List<String> muscleNames;
  final Map<String, List<num>> muscleIntensity;
  final Map<String, List<num>> muscleDuration;

  const MuscleDataTable({
    Key? key,
    required this.muscleNames,
    required this.muscleIntensity,
    required this.muscleDuration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (muscleNames.isEmpty) {
      return const Text("운동 기록이 없습니다.");
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        headingRowHeight: 40.0,
        dataRowHeight: 35.0,
        columns: const [
          DataColumn(label: Text("근육 부위")),
          DataColumn(label: Text("강도(60hz)")),
          DataColumn(label: Text("강도(100hz)")),
          DataColumn(label: Text("시간(60hz)")),
          DataColumn(label: Text("시간(100hz)")),
        ],
        rows: List<DataRow>.generate(muscleNames.length, (index) {
          final name = muscleNames[index];
          return DataRow(cells: [
            DataCell(Text(
              name,
              style: const TextStyle(fontSize: 14),
            )),
            DataCell(Text(
              muscleIntensity['60hz']?[index].toStringAsFixed(1) ?? '0.0',
              style: const TextStyle(fontSize: 14),
            )),
            DataCell(Text(
              muscleIntensity['100hz']?[index].toStringAsFixed(1) ?? '0.0',
              style: const TextStyle(fontSize: 14),
            )),
            DataCell(Text(
              muscleDuration['60hz']?[index].toStringAsFixed(1) ?? '0.0',
              style: const TextStyle(fontSize: 14),
            )),
            DataCell(Text(
              muscleDuration['100hz']?[index].toStringAsFixed(1) ?? '0.0',
              style: const TextStyle(fontSize: 14),
            )),
          ]);
        }),
      ),
    );
  }
}
