// 인바디 장비 측정을 위한 사용자 QR 발급 기능

import 'package:Vincere/provider_models.dart';
import 'package:Vincere/utils/component/custom_drawer.dart';
import 'package:Vincere/utils/component/header.dart';
import 'package:Vincere/utils/http/webReqFastapi.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PageInbodyMachineMeasurement extends StatefulWidget {
  const PageInbodyMachineMeasurement({super.key});

  @override
  State<PageInbodyMachineMeasurement> createState() =>
      _PageInbodyMachineMeasurementState();
}

class _PageInbodyMachineMeasurementState
    extends State<PageInbodyMachineMeasurement> {
  late String _issuedAt;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _refreshQrIssuedTime();
  }

  // QR 발급 시각을 현재 측정 세션 기준으로 갱신하기 위한 기능
  void _refreshQrIssuedTime() {
    _issuedAt = DateTime.now().toUtc().toIso8601String();
  }

  // 운영 환경에서 사용할 InBody UserID 기본값을 로그인 ID와 맞추기 위한 기능
  String _buildOperationalInbodyUserId(UserModel userModel) {
    final userId = userModel.userId.trim();
    if (userId.isEmpty) return '';
    return userId;
  }

  // 인바디 장비가 InBody UserID로 사용자를 식별할 수 있는 QR 값을 만들기 위한 기능
  String _buildQrPayload(UserModel userModel) {
    return _buildOperationalInbodyUserId(userModel);
  }

  // QR 재발급을 사용자 조작으로 처리하기 위한 기능
  void _regenerateQr() {
    setState(_refreshQrIssuedTime);
  }

  // QR 문자열을 클립보드로 복사하고 안내하기 위한 기능
  Future<void> _copyQrPayload(String payload) async {
    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR 데이터가 복사되었습니다.')),
    );
  }

  // 인바디 서버 측정 결과를 조회하고 Vincere DB 저장 후 화면 데이터를 갱신하기 위한 기능
  Future<void> _syncInbodyMeasurement(UserModel userModel) async {
    final userId = _buildOperationalInbodyUserId(userModel);
    if (userId.isEmpty || _isSyncing) return;

    setState(() => _isSyncing = true);
    try {
      final apiService = ApiServiceFast();
      final result = await apiService.syncInbodyMeasurement(userId);
      if (!mounted) return;

      if (result.containsKey('result')) {
        await userModel.set_user_info();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('인바디 측정 결과가 저장되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['error']?.toString() ?? '저장할 측정 결과가 없습니다.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('인바디 결과 동기화 중 오류가 발생했습니다: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel>(context);
    final qrPayload = _buildQrPayload(userModel);
    final isQrReady = userModel.userId.isNotEmpty;

    return Scaffold(
      appBar: const Header(),
      drawer: const CustomDrawer(isLogin: true),
      backgroundColor: const Color(0xFFF5F4F9),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AutoSizeText(
                '인바디 장비 측정',
                maxLines: 1,
                minFontSize: 18,
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                '장비에서 QR을 스캔하면 InBody UserID로 측정 기록을 연결할 수 있습니다.',
                style: TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: Colors.black.withValues(alpha: 0.62)),
              ),
              const SizedBox(height: 28),
              _QrPanel(
                qrPayload: qrPayload,
                isUserReady: isQrReady,
                issuedAt: _issuedAt,
                idLabel: 'InBody UserID',
                emptyLabel: 'InBody UserID 없음',
                isSyncing: _isSyncing,
                onRefresh: _regenerateQr,
                onCopy: () => _copyQrPayload(qrPayload),
                onSync: () => _syncInbodyMeasurement(userModel),
              ),
              const SizedBox(height: 22),
              const _MeasurementGuideCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrPanel extends StatelessWidget {
  final String qrPayload;
  final bool isUserReady;
  final String issuedAt;
  final String idLabel;
  final String emptyLabel;
  final bool isSyncing;
  final VoidCallback onRefresh;
  final VoidCallback onCopy;
  final VoidCallback onSync;

  const _QrPanel({
    required this.qrPayload,
    required this.isUserReady,
    required this.issuedAt,
    required this.idLabel,
    required this.emptyLabel,
    required this.isSyncing,
    required this.onRefresh,
    required this.onCopy,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 244,
            height: 244,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE1E6EA)),
            ),
            child: isUserReady
                ? QrImageView(
                    data: qrPayload,
                    version: QrVersions.auto,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                    backgroundColor: Colors.white,
                  )
                : Center(
                    child: Text(
                      emptyLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
          ),
          const SizedBox(height: 18),
          Text(
            '발급 시각: $issuedAt',
            style: TextStyle(
                fontSize: 13, color: Colors.black.withValues(alpha: 0.48)),
          ),
          const SizedBox(height: 8),
          SelectableText(
            qrPayload.isEmpty ? emptyLabel : '$idLabel: $qrPayload',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black.withValues(alpha: 0.72)),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('재발급'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Color(0xFFD4DDE5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isUserReady ? onCopy : null,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('복사'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF92D2B0),
                    foregroundColor: Colors.black87,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isUserReady && !isSyncing ? onSync : null,
              icon: isSyncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_done_rounded, size: 18),
              label: Text(isSyncing ? '불러오는 중' : '측정 결과 불러오기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeasurementGuideCard extends StatelessWidget {
  const _MeasurementGuideCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('개인 측정 진행 순서',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          SizedBox(height: 14),
          _GuideStep(index: '1', text: '인바디 장비에서 사용자 ID 등록 또는 QR 스캔을 선택합니다.'),
          _GuideStep(index: '2', text: '앱에 표시된 QR을 장비 스캐너에 보여줍니다.'),
          _GuideStep(index: '3', text: '측정 완료 후 서버 저장 연동 단계에서 결과를 불러옵니다.'),
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  final String index;
  final String text;

  const _GuideStep({
    required this.index,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: const Color(0xFF92D2B0),
            child: Text(index,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87)),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 15, height: 1.35))),
        ],
      ),
    );
  }
}
