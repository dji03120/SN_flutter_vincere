// UWB와 IMU 센서 기반 신체활동 시제품 대시보드를 제공하기 위한 기능

import 'dart:async';
import 'dart:js_util' as js_util;
import 'dart:math';
import 'dart:typed_data';

import 'package:Vincere/provider_models.dart';
import 'package:Vincere/utils/component/custom_widget.dart';
import 'package:Vincere/utils/export/screens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 신체활동 시제품 화면의 센서 상태와 측정값을 관리하기 위한 기능
class UwbImuActivityPage extends StatefulWidget {
  const UwbImuActivityPage({super.key});

  @override
  State<UwbImuActivityPage> createState() => _UwbImuActivityPageState();
}

// UWB/IMU 시제품 세션 상태와 데모 데이터를 갱신하기 위한 기능
class _UwbImuActivityPageState extends State<UwbImuActivityPage> {
  Timer? _sessionTimer;
  bool _isMonitoring = false;
  bool _isPausedForRest = false;
  bool _isRestDialogOpen = false;
  bool _isWaitingForRestResponse = false;
  int _elapsedSeconds = 0;
  double _sitToStandCount = 8;
  double _walkSeconds = 4.8;
  double _activityScore = 72;
  Offset _tagPosition = const Offset(0.62, 0.38);
  DateTime? _lastMovementAt;
  Uint8List? _previousSensorPacket;

  // 화면 진입 후 BLE notify 수신 리스너를 연결하기 위한 기능
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userModel = Provider.of<UserModel>(context, listen: false);
      _bindSensorNotifications(userModel);
    });
  }

  // 센서 기반 핵심 측정 항목의 표시 데이터를 구성하기 위한 기능
  List<_ActivityMetric> get _metrics => [
        _ActivityMetric(
          title: '앉았다 일어서기',
          value: _sitToStandCount.toStringAsFixed(0),
          unit: '회',
          target: '목표 10회',
          icon: Icons.accessibility_new_rounded,
        ),
        _ActivityMetric(
          title: '4m 걷기',
          value: _walkSeconds.toStringAsFixed(1),
          unit: '초',
          target: '기준 5초 이내',
          icon: Icons.directions_walk_rounded,
        ),
        _ActivityMetric(
          title: '실내 활동량',
          value: _activityScore.toStringAsFixed(0),
          unit: '점',
          target: '권장 80점',
          icon: Icons.sensors_rounded,
        ),
      ];

  // 화면 종료 시 데모 측정 타이머를 정리하기 위한 기능
  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  // 실시간 센서 수집을 가정한 데모 세션을 시작하거나 종료하기 위한 기능
  void _toggleMonitoring() {
    if (_isMonitoring) {
      _sessionTimer?.cancel();
      setState(() => _isMonitoring = false);
      return;
    }

    setState(() {
      _isMonitoring = true;
      _isPausedForRest = false;
      _isWaitingForRestResponse = false;
      _lastMovementAt = DateTime.now();
    });
    _startSessionTimer();
  }

  // 테스트와 실제 측정 세션의 주기 갱신을 시작하기 위한 기능
  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!_isMonitoring || _isPausedForRest || _isWaitingForRestResponse) {
        return;
      }
      setState(() {
        _elapsedSeconds++;
        final wave = sin(_elapsedSeconds / 2);
        final isDemoIdle =
            _elapsedSeconds % 28 >= 10 && _elapsedSeconds % 28 <= 21;
        if (!isDemoIdle) {
          _markMovementDetected();
          _sitToStandCount = (8 + (_elapsedSeconds % 6)).toDouble();
          _walkSeconds = 4.8 - ((_elapsedSeconds % 5) * 0.12);
          _activityScore = (72 + (_elapsedSeconds % 18)).toDouble();
          _tagPosition = Offset(
              0.52 + wave * 0.22, 0.42 + cos(_elapsedSeconds / 3) * 0.18);
        }
      });
      _checkRestPrompt();
    });
  }

  // BLE notify characteristic에서 센서 패킷을 받아 움직임 상태를 갱신하기 위한 기능
  Future<void> _bindSensorNotifications(UserModel userModel) async {
    final notifyChar = userModel.notifyChar;
    if (notifyChar == null) return;

    try {
      await notifyChar.startNotifications();
      js_util.callMethod(notifyChar, 'addEventListener', [
        'characteristicvaluechanged',
        js_util.allowInterop((event) {
          final target = js_util.getProperty(event, 'target');
          final value = js_util.getProperty(target, 'value');
          if (value == null) {
            return;
          }
          final buffer = js_util.getProperty(value, 'buffer');
          final bytes = Uint8List.view(buffer);
          _handleSensorPacket(bytes);
        }),
      ]);
    } catch (e) {
      print('UWB/IMU notification bind failed: $e');
    }
  }

  // 실제 UWB/IMU 패킷 변화량을 활동 데이터로 변환하기 위한 기능
  void _handleSensorPacket(Uint8List bytes) {
    if (!mounted ||
        !_isMonitoring ||
        _isPausedForRest ||
        _isWaitingForRestResponse) {
      return;
    }

    final movementScore = _calculateMovementScore(bytes);
    if (movementScore > 12) {
      setState(() {
        _markMovementDetected();
        _activityScore = (_activityScore + 0.6).clamp(0, 100).toDouble();
        _tagPosition = _deriveTagPosition(bytes);
      });
    }
    _previousSensorPacket = Uint8List.fromList(bytes);
    _checkRestPrompt();
  }

  // 센서 패킷 간 변화량을 계산하기 위한 기능
  int _calculateMovementScore(Uint8List bytes) {
    final previous = _previousSensorPacket;
    if (previous == null || previous.length != bytes.length) return 99;

    int score = 0;
    for (int i = 0; i < bytes.length; i++) {
      score += (bytes[i] - previous[i]).abs();
    }
    return score;
  }

  // 센서 패킷에서 실내 태그 위치 표시 좌표를 추정하기 위한 기능
  Offset _deriveTagPosition(Uint8List bytes) {
    if (bytes.length < 4) return _tagPosition;
    final x = (bytes[0] + bytes[1]) / 510;
    final y = (bytes[2] + bytes[3]) / 510;
    return Offset(
        x.clamp(0.08, 0.92).toDouble(), y.clamp(0.12, 0.88).toDouble());
  }

  // 움직임이 감지된 마지막 시각을 저장하기 위한 기능
  void _markMovementDetected() {
    _lastMovementAt = DateTime.now();
  }

  // 10초 이상 움직임이 없을 때 휴식 여부 팝업을 표시하기 위한 기능
  void _checkRestPrompt() {
    final lastMovementAt = _lastMovementAt;
    if (!_isMonitoring ||
        _isPausedForRest ||
        _isRestDialogOpen ||
        _isWaitingForRestResponse ||
        lastMovementAt == null) return;

    final stoppedSeconds = DateTime.now().difference(lastMovementAt).inSeconds;
    if (stoppedSeconds >= 10) {
      _showRestPrompt();
    }
  }

  // 휴식 여부에 따라 측정 일시정지 또는 재개를 처리하기 위한 기능
  void _showRestPrompt() {
    _isRestDialogOpen = true;
    _sessionTimer?.cancel();
    setState(() => _isWaitingForRestResponse = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 22,
                    offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                      color: const Color(0xFFE2FFF0),
                      borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.self_improvement_rounded,
                      color: Color(0xFF007130), size: 34),
                ),
                const SizedBox(height: 18),
                const Text('잠시 휴식중이십니까?',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87)),
                const SizedBox(height: 8),
                Text(
                  '10초 이상 움직임이 감지되지 않았습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, color: Colors.black.withOpacity(0.62)),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _resumeFromRestPrompt();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF007130),
                          side: const BorderSide(
                              color: Color(0xFF92D2B0), width: 1.4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('아니오',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _pauseForRest();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007130),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('예',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) => _isRestDialogOpen = false);
  }

  // 사용자가 휴식 중이라고 답했을 때 측정을 일시정지하기 위한 기능
  void _pauseForRest() {
    _sessionTimer?.cancel();
    setState(() {
      _isMonitoring = false;
      _isPausedForRest = true;
      _isWaitingForRestResponse = false;
    });
  }

  // 사용자가 휴식이 아니라고 답했을 때 측정을 자동 재개하기 위한 기능
  void _resumeFromRestPrompt() {
    setState(() {
      _isMonitoring = true;
      _isPausedForRest = false;
      _isWaitingForRestResponse = false;
      _lastMovementAt = DateTime.now();
    });
    _startSessionTimer();
  }

  // 화면 전체 레이아웃과 기존 앱 내비게이션을 구성하기 위한 기능
  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel>(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F9),
      appBar: const Header(),
      drawer: CustomDrawer(isLogin: userModel.isLogin),
      body: ScrollConfiguration(
        behavior: DesktopDragScrollBehavior(),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeroSection(userModel),
              const SizedBox(height: 14),
              _buildSensorStatusCard(),
              const SizedBox(height: 14),
              _buildMetricGrid(),
              const SizedBox(height: 14),
              _buildIndoorMapCard(),
              const SizedBox(height: 24),
              _buildInsightCard(),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  // 시제품의 핵심 목적과 측정 시작 버튼을 보여주기 위한 기능
  Widget _buildHeroSection(UserModel userModel) {
    final name = userModel.userInfo?['userNm'] ?? '사용자';
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF92D2B0).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: const Color(0xFF92D2B0), width: 1.4),
                ),
                child: const Icon(Icons.hub_rounded,
                    color: Color(0xFF92D2B0), size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'UWB·IMU 활동 모니터링',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '$name 님의 실내 움직임을 태그와 앵커로 기록합니다.',
            style: TextStyle(
                color: Colors.white.withOpacity(0.78),
                fontSize: 15,
                height: 1.45),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildHeroStat('앵커', '4대', '공간 설치')),
              const SizedBox(width: 10),
              Expanded(child: _buildHeroStat('태그', '1개', '착용 감지')),
              const SizedBox(width: 10),
              Expanded(child: _buildHeroStat('수집', 'UWB+IMU', '위치·자세')),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _toggleMonitoring,
              icon: Icon(_isMonitoring
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded),
              label: Text(_isMonitoring
                  ? '측정 일시정지'
                  : (_isPausedForRest ? '활동 측정 재개' : '활동 측정 시작')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF92D2B0),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 히어로 영역의 센서 구성 요약을 표시하기 위한 기능
  Widget _buildHeroStat(String label, String value, String caption) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(caption,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.58), fontSize: 11)),
        ],
      ),
    );
  }

  // UWB 앵커와 IMU 태그의 연결 상태를 표시하기 위한 기능
  Widget _buildSensorStatusCard() {
    return Card(
      elevation: 4,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('센서 상태',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                _buildLiveChip(),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                    child: _buildStatusItem(
                        Icons.settings_input_antenna_rounded,
                        'UWB 앵커',
                        '4/4 연결')),
                Container(width: 1, height: 48, color: const Color(0xFFE6E6E6)),
                Expanded(
                    child: _buildStatusItem(
                        Icons.watch_rounded, '착용 태그', '정상 수신')),
                Container(width: 1, height: 48, color: const Color(0xFFE6E6E6)),
                Expanded(
                    child: _buildStatusItem(
                        Icons.timer_rounded, '세션', _formatElapsedTime())),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 현재 측정 상태 배지를 보여주기 위한 기능
  Widget _buildLiveChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:
            _isMonitoring ? const Color(0xFFE2FFF0) : const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _isMonitoring ? 'LIVE' : 'READY',
        style: TextStyle(
          color:
              _isMonitoring ? const Color(0xFF007130) : const Color(0xFF777777),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // 센서 상태 항목 하나를 표시하기 위한 기능
  Widget _buildStatusItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF00914B), size: 26),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(color: Color(0xFF777777), fontSize: 12)),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(
                color: Color(0xFF111111),
                fontSize: 13,
                fontWeight: FontWeight.w800)),
      ],
    );
  }

  // 핵심 측정 항목 카드 목록을 표시하기 위한 기능
  Widget _buildMetricGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: _metrics.map((metric) => _buildMetricCard(metric)).toList(),
      ),
    );
  }

  // 핵심 측정 항목의 현재 값을 얇은 카드로 표시하기 위한 기능
  Widget _buildMetricCard(_ActivityMetric metric) {
    return Card(
      elevation: 4,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: const Color(0xFFE2FFF0),
                  borderRadius: BorderRadius.circular(14)),
              child:
                  Icon(metric.icon, color: const Color(0xFF007130), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(metric.title,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111111))),
                  const SizedBox(height: 4),
                  Text(
                    metric.target,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF666666)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: metric.value,
                    style: const TextStyle(
                        color: Color(0xFF111111),
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'NunitoSans'),
                  ),
                  TextSpan(
                      text: metric.unit,
                      style: const TextStyle(
                          color: Color(0xFF555555),
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 실내 앵커 배치와 착용 태그 위치를 시각화하기 위한 기능
  Widget _buildIndoorMapCard() {
    return Card(
      elevation: 4,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('실내 공간 활동량',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('앵커 4대를 기준으로 태그 위치와 이동 밀도를 추정합니다.',
                style: TextStyle(color: Color(0xFF777777), fontSize: 13)),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1.35,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F8F5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD7E8DE)),
                ),
                child: CustomPaint(
                  painter: _IndoorMapPainter(tagPosition: _tagPosition),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 측정 데이터 해석과 앱 제공 정보를 요약하기 위한 기능
  Widget _buildInsightCard() {
    return Card(
      elevation: 4,
      color: const Color(0xFF0F2A1C),
      margin: const EdgeInsets.symmetric(horizontal: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('활동 인사이트',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            SizedBox(height: 12),
            _InsightRow(
                icon: Icons.check_circle_rounded,
                text: '짧은 보행 테스트와 일상 활동량을 같은 화면에서 기록합니다.'),
            _InsightRow(
                icon: Icons.check_circle_rounded,
                text: 'IMU로 자세 변화를 감지하고 UWB로 실내 이동 범위를 보정합니다.'),
            _InsightRow(
                icon: Icons.check_circle_rounded,
                text: '향후 실제 태그 SDK 또는 BLE/WebSocket 수집 모듈과 연결할 수 있습니다.'),
          ],
        ),
      ),
    );
  }

  // 세션 경과 시간을 mm:ss 형태로 변환하기 위한 기능
  String _formatElapsedTime() {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

// 활동 측정 카드에 필요한 값을 묶기 위한 기능
class _ActivityMetric {
  final String title;
  final String value;
  final String unit;
  final String target;
  final IconData icon;

  const _ActivityMetric({
    required this.title,
    required this.value,
    required this.unit,
    required this.target,
    required this.icon,
  });
}

// 실내 지도 위에 앵커와 착용 태그 위치를 그리기 위한 기능
class _IndoorMapPainter extends CustomPainter {
  final Offset tagPosition;

  const _IndoorMapPainter({required this.tagPosition});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFD8E8DE)
      ..strokeWidth = 1;
    final anchorPaint = Paint()..color = const Color(0xFF007130);
    final tagPaint = Paint()..color = const Color(0xFFFFB84D);
    final pathPaint = Paint()
      ..color = const Color(0xFF00914B).withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    for (int i = 1; i < 4; i++) {
      final dx = size.width * i / 4;
      final dy = size.height * i / 4;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    final route = Path()
      ..moveTo(size.width * 0.18, size.height * 0.72)
      ..quadraticBezierTo(size.width * 0.38, size.height * 0.28,
          size.width * 0.62, size.height * 0.42)
      ..quadraticBezierTo(size.width * 0.78, size.height * 0.54,
          size.width * 0.66, size.height * 0.78);
    canvas.drawPath(route, pathPaint);

    final anchors = [
      const Offset(0.08, 0.12),
      const Offset(0.92, 0.12),
      const Offset(0.08, 0.88),
      const Offset(0.92, 0.88),
    ];
    for (final anchor in anchors) {
      final point = Offset(anchor.dx * size.width, anchor.dy * size.height);
      canvas.drawCircle(point, 8, anchorPaint);
      canvas.drawCircle(point, 14,
          Paint()..color = const Color(0xFF007130).withOpacity(0.14));
    }

    final tag =
        Offset(tagPosition.dx * size.width, tagPosition.dy * size.height);
    canvas.drawCircle(
        tag, 18, Paint()..color = const Color(0xFFFFB84D).withOpacity(0.24));
    canvas.drawCircle(tag, 9, tagPaint);
  }

  @override
  bool shouldRepaint(covariant _IndoorMapPainter oldDelegate) {
    return oldDelegate.tagPosition != tagPosition;
  }
}

// 인사이트 문장과 아이콘을 한 줄로 보여주기 위한 기능
class _InsightRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InsightRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF92D2B0), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.82),
                    fontSize: 13,
                    height: 1.45)),
          ),
        ],
      ),
    );
  }
}
