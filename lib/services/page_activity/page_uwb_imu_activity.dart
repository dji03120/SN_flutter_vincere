// UWB와 IMU 센서 기반 신체활동 시제품 대시보드를 제공하기 위한 기능

import 'dart:async';
import 'dart:js_util' as js_util;
import 'dart:math';
import 'dart:typed_data';

import 'package:Vincere/provider_models.dart';
import 'package:Vincere/services/page_activity/activity_daily_store.dart';
import 'package:Vincere/services/page_activity/logic/activity_sensor_parser.dart';
import 'package:Vincere/services/page_activity/models/uwb_imu_activity_models.dart';
import 'package:Vincere/services/page_activity/widgets/indoor_activity_map_card.dart';
import 'package:Vincere/services/page_activity/widgets/rest_confirm_dialog.dart';
import 'package:Vincere/services/page_activity/widgets/uwb_imu_activity_result_page.dart';
import 'package:Vincere/services/page_workout/page_statistics.dart';
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
  Timer? _restTimer;
  Timer? _manualPauseRestDelayTimer;
  bool _isMonitoring = false;
  bool _isPausedForRest = false;
  bool _isRestDialogOpen = false;
  bool _isWaitingForRestResponse = false;
  bool _hasStartedSession = false;
  String _activityDateKey = ActivityDailyStore.todayKey();
  Map<String, DailyActivitySummary> _dailyActivityRecords = {};
  int _elapsedSeconds = 0;
  int _mockSignalStep = 0;
  int _activeSeconds = 0;
  int _restSeconds = 0;
  int _movementCount = 0;
  int _restEventCount = 0;
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
      _loadDailyActivity();
    });
  }

  // 저장된 오늘 활동 데이터와 최근 평균 비교 데이터를 불러오기 위한 기능
  Future<void> _loadDailyActivity() async {
    final records = await ActivityDailyStore.loadAll();
    final todayKey = ActivityDailyStore.todayKey();
    final today = records[todayKey] ?? DailyActivitySummary.empty(todayKey);
    if (!mounted) return;
    setState(() {
      _dailyActivityRecords = records;
      _activityDateKey = todayKey;
      _activeSeconds = today.activeSeconds;
      _restSeconds = today.restSeconds;
      _movementCount = today.movementCount;
      _restEventCount = today.restEventCount;
      _activityScore = today.activityScore == 0 ? 72 : today.activityScore;
      _hasStartedSession = today.sessionCount > 0 || today.activeSeconds > 0;
    });
  }

  // 센서 기반 핵심 측정 항목의 표시 데이터를 구성하기 위한 기능
  List<ActivityMetric> get _metrics => [
        ActivityMetric(
          title: '앉았다 일어서기',
          value: _sitToStandCount.toStringAsFixed(0),
          unit: '회',
          target: '목표 10회',
          icon: Icons.accessibility_new_rounded,
        ),
        ActivityMetric(
          title: '4m 걷기',
          value: _walkSeconds.toStringAsFixed(1),
          unit: '초',
          target: '기준 5초 이내',
          icon: Icons.directions_walk_rounded,
        ),
        ActivityMetric(
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
    _restTimer?.cancel();
    _manualPauseRestDelayTimer?.cancel();
    super.dispose();
  }

  // 실시간 센서 수집을 가정한 데모 세션을 시작하거나 일시정지하기 위한 기능
  void _toggleMonitoring() {
    if (_isMonitoring) {
      _sessionTimer?.cancel();
      setState(() {
        _isMonitoring = false;
        _isPausedForRest = true;
      });
      _startManualPauseRestDelay();
      return;
    }

    _manualPauseRestDelayTimer?.cancel();
    setState(() {
      _isMonitoring = true;
      _isPausedForRest = false;
      _isWaitingForRestResponse = false;
      _hasStartedSession = true;
      if (_elapsedSeconds == 0) {
        _saveTodayActivity(sessionCount: _todaySessionCount() + 1);
      }
      _lastMovementAt = DateTime.now();
    });
    _restTimer?.cancel();
    _startSessionTimer();
  }

  // 현재 측정 세션을 종료하고 결과 화면으로 이동하기 위한 기능
  void _finishMonitoring() {
    _sessionTimer?.cancel();
    _restTimer?.cancel();
    _manualPauseRestDelayTimer?.cancel();
    setState(() {
      _isMonitoring = false;
      _isPausedForRest = false;
      _isWaitingForRestResponse = false;
      _lastMovementAt = null;
    });
    _openSummaryPage();
  }

  // 측정 세션의 시간과 활동 데이터를 초기값으로 되돌리기 위한 기능
  void _resetSession() {
    _sessionTimer?.cancel();
    _restTimer?.cancel();
    _manualPauseRestDelayTimer?.cancel();
    setState(() {
      _isMonitoring = false;
      _isPausedForRest = false;
      _isWaitingForRestResponse = false;
      _isRestDialogOpen = false;
      _hasStartedSession = false;
      _elapsedSeconds = 0;
      _mockSignalStep = 0;
      _activeSeconds = 0;
      _restSeconds = 0;
      _movementCount = 0;
      _restEventCount = 0;
      _sitToStandCount = 8;
      _walkSeconds = 4.8;
      _activityScore = 72;
      _tagPosition = const Offset(0.62, 0.38);
      _lastMovementAt = null;
      _previousSensorPacket = null;
    });
    _saveTodayActivity(forceEmpty: true);
  }

  // 테스트와 실제 측정 세션의 주기 갱신을 시작하기 위한 기능
  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _syncDailyResetIfNeeded();
      if (!_isMonitoring || _isPausedForRest || _isWaitingForRestResponse) {
        return;
      }
      setState(() {
        _elapsedSeconds++;
        _mockSignalStep = (_elapsedSeconds ~/ 3) % 3;
        final wave = sin(_elapsedSeconds / 2);
        final isDemoIdle =
            _elapsedSeconds % 28 >= 10 && _elapsedSeconds % 28 <= 21;
        if (!isDemoIdle) {
          _markMovementDetected();
          _activeSeconds++;
          if (_elapsedSeconds % 2 == 0) {
            _movementCount++;
          }
          _sitToStandCount = (8 + (_elapsedSeconds % 6)).toDouble();
          _walkSeconds = 4.8 - ((_elapsedSeconds % 5) * 0.12);
          _activityScore = (72 + (_elapsedSeconds % 18)).toDouble();
          _tagPosition = Offset(
              0.52 + wave * 0.22, 0.42 + cos(_elapsedSeconds / 3) * 0.18);
        }
      });
      _saveTodayActivity();
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

    final movementScore = ActivitySensorParser.calculateMovementScore(
        bytes, _previousSensorPacket);
    if (movementScore > 12) {
      setState(() {
        _markMovementDetected();
        _movementCount++;
        _activeSeconds++;
        _activityScore = (_activityScore + 0.6).clamp(0, 100).toDouble();
        _tagPosition =
            ActivitySensorParser.deriveTagPosition(bytes, _tagPosition);
      });
      _saveTodayActivity();
    }
    _previousSensorPacket = Uint8List.fromList(bytes);
    _checkRestPrompt();
  }

  // 움직임이 감지된 마지막 시각을 저장하기 위한 기능
  void _markMovementDetected() {
    _lastMovementAt = DateTime.now();
    _restTimer?.cancel();
    _manualPauseRestDelayTimer?.cancel();
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
  Future<void> _showRestPrompt() async {
    _isRestDialogOpen = true;
    _sessionTimer?.cancel();
    _restEventCount++;
    setState(() => _isWaitingForRestResponse = true);
    final result = await showRestConfirmDialog(context);
    _isRestDialogOpen = false;
    if (!mounted) return;
    if (result == RestConfirmResult.rest) {
      _pauseForRest();
      return;
    }
    _resumeFromRestPrompt();
  }

  // 사용자가 휴식 중이라고 답했을 때 측정을 일시정지하기 위한 기능
  void _pauseForRest() {
    _sessionTimer?.cancel();
    _manualPauseRestDelayTimer?.cancel();
    setState(() {
      _isMonitoring = false;
      _isPausedForRest = true;
      _isWaitingForRestResponse = false;
    });
    _startRestTimer();
  }

  // 사용자가 휴식이 아니라고 답했을 때 측정을 자동 재개하기 위한 기능
  void _resumeFromRestPrompt() {
    _restTimer?.cancel();
    _manualPauseRestDelayTimer?.cancel();
    setState(() {
      _isMonitoring = true;
      _isPausedForRest = false;
      _isWaitingForRestResponse = false;
      _lastMovementAt = DateTime.now();
    });
    _startSessionTimer();
  }

  // 휴식으로 확정된 뒤부터 휴식 시간을 실시간으로 누적하기 위한 기능
  void _startRestTimer() {
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isPausedForRest) return;
      setState(() => _restSeconds++);
      _saveTodayActivity();
    });
  }

  // 날짜가 바뀌면 오늘 활동 데이터를 새 날짜 기준으로 초기화하기 위한 기능
  void _syncDailyResetIfNeeded() {
    final todayKey = ActivityDailyStore.todayKey();
    if (_activityDateKey == todayKey) return;
    _activityDateKey = todayKey;
    _elapsedSeconds = 0;
    _activeSeconds = 0;
    _restSeconds = 0;
    _movementCount = 0;
    _restEventCount = 0;
    _activityScore = 72;
    _hasStartedSession = false;
  }

  // 오늘 활동 데이터를 로컬 저장소에 저장하기 위한 기능
  Future<void> _saveTodayActivity(
      {bool forceEmpty = false, int? sessionCount}) async {
    final todayKey = ActivityDailyStore.todayKey();
    final summary = forceEmpty
        ? DailyActivitySummary.empty(todayKey)
        : DailyActivitySummary(
            dateKey: todayKey,
            activeSeconds: _activeSeconds,
            restSeconds: _restSeconds,
            movementCount: _movementCount,
            restEventCount: _restEventCount,
            activityScore: _activityScore,
            sessionCount: sessionCount ?? _todaySessionCount(),
          );
    await ActivityDailyStore.saveToday(summary);
    _dailyActivityRecords[todayKey] = summary;
  }

  // 오늘 활동 세션 수를 조회하기 위한 기능
  int _todaySessionCount() {
    return _dailyActivityRecords[_activityDateKey]?.sessionCount ?? 0;
  }

  // 수동 일시정지 후 3초가 지나면 휴식 시간 누적을 시작하기 위한 기능
  void _startManualPauseRestDelay() {
    _manualPauseRestDelayTimer?.cancel();
    _restTimer?.cancel();
    _manualPauseRestDelayTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted || _isMonitoring || !_isPausedForRest) return;
      _startRestTimer();
    });
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
              const SizedBox(height: 12),
              _buildTodaySummaryCard(),
              const SizedBox(height: 12),
              _buildMetricGrid(),
              const SizedBox(height: 14),
              IndoorActivityMapCard(tagPosition: _tagPosition),
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
                child: const Icon(Icons.monitor_heart_outlined,
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
          const SizedBox(height: 18),
          _buildHeroSensorStatus(),
          const SizedBox(height: 18),
          _buildMeasurementControls(),
        ],
      ),
    );
  }

  // 히어로 영역 안에서 센서 상태를 작게 표시하기 위한 기능
  Widget _buildHeroSensorStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildHeroSignalItem('UWB 앵커', _getAnchorStatus())),
          Container(
              width: 1, height: 34, color: Colors.white.withOpacity(0.14)),
          Expanded(child: _buildHeroSignalItem('수신 감도', _getSignalStatus())),
          Container(
              width: 1, height: 34, color: Colors.white.withOpacity(0.14)),
          Expanded(child: _buildHeroTextItem('세션', _formatElapsedTime())),
        ],
      ),
    );
  }

  // 히어로 센서 상태에서 점 색상만 상태에 따라 바꾸기 위한 기능
  Widget _buildHeroSignalItem(String label, SignalStatus signalStatus) {
    return Column(
      children: [
        Text(label,
            style:
                TextStyle(color: Colors.white.withOpacity(0.72), fontSize: 13)),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: signalStatus.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(signalStatus.label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ],
    );
  }

  // 히어로 센서 상태에서 고정 텍스트 값을 표시하기 위한 기능
  Widget _buildHeroTextItem(String label, String value) {
    return Column(
      children: [
        Text(label,
            style:
                TextStyle(color: Colors.white.withOpacity(0.72), fontSize: 13)),
        const SizedBox(height: 5),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800)),
      ],
    );
  }

  // 활동 측정 시작과 종료 및 초기화 버튼을 제공하기 위한 기능
  Widget _buildMeasurementControls() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _toggleMonitoring,
            icon: Icon(
                _isMonitoring ? Icons.pause_rounded : Icons.play_arrow_rounded),
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
        if (_hasStartedSession) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _finishMonitoring,
                  icon: const Icon(Icons.fact_check_rounded, size: 18),
                  label: const Text('종료 후 결과 보기'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.32)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetSession,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('리셋'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.32)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
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
                    child: _buildConnectionStatusItem(
                        Icons.settings_input_antenna_rounded,
                        'UWB 앵커',
                        _getAnchorStatus())),
                Container(width: 1, height: 48, color: const Color(0xFFE6E6E6)),
                Expanded(
                    child: _buildConnectionStatusItem(
                        Icons.watch_rounded, '수신 감도', _getSignalStatus())),
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

  // 연결 상태를 신호등 상태로 표시하기 위한 기능
  Widget _buildConnectionStatusItem(
      IconData icon, String label, SignalStatus signalStatus) {
    return Column(
      children: [
        Icon(icon, color: signalStatus.color, size: 26),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(color: Color(0xFF777777), fontSize: 12)),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: signalStatus.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(signalStatus.label,
                style: const TextStyle(
                    color: Color(0xFF111111),
                    fontSize: 13,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ],
    );
  }

  // UWB 앵커 연결 상태를 테스트 데이터와 실제 상태에 맞춰 결정하기 위한 기능
  SignalStatus _getAnchorStatus() {
    if (_isPausedForRest || _isWaitingForRestResponse) {
      return const SignalStatus('보통', Color(0xFFFFC107));
    }

    if (!_isMonitoring) {
      return const SignalStatus('좋음', Color(0xFF00914B));
    }

    if (_previousSensorPacket == null) {
      final anchorStep = (_mockSignalStep + 1) % 3;
      if (anchorStep == 1) {
        return const SignalStatus('보통', Color(0xFFFFC107));
      }
      if (anchorStep == 2) {
        return const SignalStatus('약함', Color(0xFFE53935));
      }
      return const SignalStatus('좋음', Color(0xFF00914B));
    }

    return _getSignalStatus();
  }

  // 마지막 수신 상태를 기준으로 감도 색상과 문구를 결정하기 위한 기능
  SignalStatus _getSignalStatus() {
    if (_isPausedForRest || _isWaitingForRestResponse) {
      return const SignalStatus('보통', Color(0xFFFFC107));
    }

    if (!_isMonitoring) {
      return const SignalStatus('좋음', Color(0xFF00914B));
    }

    if (_previousSensorPacket == null) {
      if (_mockSignalStep == 1) {
        return const SignalStatus('보통', Color(0xFFFFC107));
      }
      if (_mockSignalStep == 2) {
        return const SignalStatus('약함', Color(0xFFE53935));
      }
      return const SignalStatus('좋음', Color(0xFF00914B));
    }

    final lastMovementAt = _lastMovementAt;
    if (lastMovementAt == null) {
      return const SignalStatus('약함', Color(0xFFE53935));
    }

    final seconds = DateTime.now().difference(lastMovementAt).inSeconds;
    if (seconds >= 8) {
      return const SignalStatus('약함', Color(0xFFE53935));
    }
    if (seconds >= 4) {
      return const SignalStatus('보통', Color(0xFFFFC107));
    }
    return const SignalStatus('좋음', Color(0xFF00914B));
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
  Widget _buildMetricCard(ActivityMetric metric) {
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

  // 측정 중 핵심 활동 요약을 숫자로 보여주기 위한 기능
  Widget _buildTodaySummaryCard() {
    return Card(
      elevation: 4,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('오늘 활동 요약',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                TextButton(
                  onPressed: _openSummaryPage,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF007130),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  child: const Text('결과 보기',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _buildSummaryStat(Icons.timer_rounded, '활동 시간',
                        _formatDuration(_activeSeconds))),
                Container(width: 1, height: 36, color: const Color(0xFFE6E6E6)),
                Expanded(
                    child: _buildSummaryStat(Icons.directions_run_rounded,
                        '움직인 횟수', '$_movementCount회')),
                Container(width: 1, height: 36, color: const Color(0xFFE6E6E6)),
                Expanded(
                    child: _buildSummaryStat(Icons.self_improvement_rounded,
                        '휴식 시간', _formatDuration(_restSeconds))),
                Container(width: 1, height: 36, color: const Color(0xFFE6E6E6)),
                Expanded(
                    child: _buildSummaryAction(
                        Icons.calendar_month_rounded, '통계 보기')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 활동 요약 카드의 숫자 항목 하나를 표시하기 위한 기능
  Widget _buildSummaryStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF00914B), size: 21),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Color(0xFF777777), fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Color(0xFF111111),
                fontSize: 13,
                fontWeight: FontWeight.w800)),
      ],
    );
  }

  // 활동 요약 카드에서 활동 통계 화면으로 이동하기 위한 기능
  Widget _buildSummaryAction(IconData icon, String label) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _openActivityStatistics,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF00914B), size: 21),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF007130),
                    fontSize: 12,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF007130), size: 17),
          ],
        ),
      ),
    );
  }

  // UWB/IMU 활동 통계 달력 화면으로 이동하기 위한 기능
  void _openActivityStatistics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StatisticsPage()),
    );
  }

  // 측정 결과 요약 화면으로 이동하기 위한 기능
  void _openSummaryPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UwbImuActivityResultPage(
          summary: ActivitySessionSummary(
            activeSeconds: _activeSeconds,
            restSeconds: _restSeconds,
            movementCount: _movementCount,
            restEventCount: _restEventCount,
            activityScore: _activityScore,
            sitToStandCount: _sitToStandCount,
            walkSeconds: _walkSeconds,
            recentSummaries: _recentActivitySummaries(),
          ),
        ),
      ),
    );
  }

  // 오늘을 제외한 최근 활동 요약 데이터를 평균 비교용으로 가져오기 위한 기능
  List<DailyActivitySummary> _recentActivitySummaries() {
    final todayKey = ActivityDailyStore.todayKey();
    final records = _dailyActivityRecords.values
        .where((summary) => summary.dateKey != todayKey)
        .toList()
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
    return records.take(7).toList();
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

  // 초 단위 시간을 사용자에게 읽기 쉬운 형태로 변환하기 위한 기능
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainSeconds = seconds % 60;
    if (minutes == 0) {
      return '$remainSeconds초';
    }
    return '$minutes분 $remainSeconds초';
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
