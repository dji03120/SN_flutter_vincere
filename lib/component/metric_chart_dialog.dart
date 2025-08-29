import 'dart:core';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../http/webReq.dart';

class MetricBarGraph extends StatelessWidget {
  final String title;
  final List<dynamic> chartData;
  final String code;

  const MetricBarGraph({
    Key? key,
    required this.title,
    required this.chartData,
    required this.code,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String strDate = "";
    String strVal = "";
    double strInterval = 100;

    if(code == 'riceIntake') {
      strDate = 'INTAKE_DATE';
      strVal = 'TOTAL_RICE';
      strInterval = 500;
    } else if(code == 'carbsIntake') {
      strDate = 'INTAKE_DATE';
      strVal = 'TOTAL_CARBS';
    } else if(code == 'proteinIntake') {
      strDate = 'INTAKE_DATE';
      strVal = 'TOTAL_PROTEIN';
      strInterval = 50;
    }else {
      strDate = 'MSMT_DATE';
      strVal = 'MSMT_VALUE';
      strInterval = 10;
    }

    // API 데이터를 차트 데이터 형식으로 변환
    final formattedData = chartData.map((item) => {
      'date': item[strDate],
      'value': double.parse(item[strVal].toString())
    }).toList();

    // 최대값 계산
    final maxValue = formattedData
        .map((e) => e['value'] as double)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: EdgeInsets.all(8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width: max(MediaQuery.of(context).size.width - 100, formattedData.length * 200.0), // 데이터 개수에 따라 너비 조정
          child: Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 20),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.start,  // 왼쪽부터 시작
                //maxY: maxValue * 1.2, // 최대값의 120%
                minY: 0,
                groupsSpace: 20, // 그룹 간 간격 설정
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey.withOpacity(0.9),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${formattedData[groupIndex]['value'].toStringAsFixed(2)}',
                        TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < formattedData.length) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                              child: Text(
                                formattedData[value.toInt()]['date'],
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 10,
                                  letterSpacing: -0.05,
                                ),
                                textAlign: TextAlign.center,
                              ),
                          );
                        }
                        return Text('');
                      },
                      reservedSize: 40,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30, // 왼쪽 여백 조정
                      interval: strInterval, // Y축 간격 설정
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Color(0xFF555555),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.black12,
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.black, width: 1),
                    left: BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                barGroups: formattedData.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value['value'],
                        color: Color(0xFF3DC58A),
                        width: 40,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MetricChartDialog extends StatefulWidget {
  final String? title;
  final String? code;
  final String? userId;

  const MetricChartDialog({
    Key? key,
    this.title,
    this.code,
    this.userId
  }) : super(key: key);

  @override
  State<MetricChartDialog> createState() => _MetricChartDialogState();
}

class _MetricChartDialogState extends State<MetricChartDialog> {
  Map<String, dynamic>? chartData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    try {
      if (widget.code != null && widget.userId != null) {
        Map<String, dynamic> result;
        ApiService apiService = ApiService();

        if(widget.code == 'riceIntake'
            || widget.code == 'carbsIntake'
            || widget.code == 'proteinIntake') {
          result = await apiService.getIntakeData(widget.userId!);
        } else {
          result = await apiService.getChartData(widget.code!, widget.userId!);
        }

        if (mounted) {
          setState(() {
            chartData = result;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error: $e');
      if (mounted) {
        setState(() {
          isLoading = false;  // 에러 발생시에도 로딩 상태 해제
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중일 때는 로딩 인디케이터 표시
    if (isLoading) {
      return Dialog(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('데이터를 불러오는 중입니다...'),
            ],
          ),
        ),
      );
    }

    if (chartData == null || (chartData?['chartDataList'] ?? []).isEmpty) {
      return AlertDialog(
        content: Text(
          "데이터가 존재하지 않습니다.",
          textAlign: TextAlign.center,
        ),
        actions: <Widget>[
          TextButton(
            child: Text("확인"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    }

    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.title ?? '제목 없음'} 변화추이',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF000000),
                letterSpacing: -0.02,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 250,
              child: MetricBarGraph(
                title: widget.title ?? '',
                chartData: chartData?['chartDataList'] ?? [],
                code: widget.code ?? '',
              ),
            ),
            Container(
              margin: EdgeInsets.only(bottom: 6.0),  // 하단 여백 16 추가
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('닫기', style: TextStyle(color: Colors.white),),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF007130),
                  minimumSize: Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}