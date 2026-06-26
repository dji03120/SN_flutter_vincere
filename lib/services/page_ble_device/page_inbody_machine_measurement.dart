// 인바디 장비 측정을 위한 사용자 QR 발급 기능

import 'package:Vincere/provider_models.dart';
import 'package:Vincere/services/page_health/screen_my_health_info.dart';
import 'package:Vincere/utils/component/custom_drawer.dart';
import 'package:Vincere/utils/component/header.dart';
import 'package:Vincere/utils/http/webReqFastapi.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
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
  final TextEditingController _lookupController = TextEditingController();
  bool _isSyncing = false;
  bool _isQrMode = false;
  bool _isLookupMode = false;

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

  // 사용자가 QR 측정 흐름으로 진입할 때 QR 발급 시각을 갱신하기 위한 기능
  void _openQrMeasurement() {
    setState(() {
      _refreshQrIssuedTime();
      _isQrMode = true;
      _isLookupMode = false;
    });
  }

  // 사용자가 InBody 측정 방식 선택 화면으로 돌아가기 위한 기능
  void _closeQrMeasurement() {
    setState(() {
      _isQrMode = false;
      _isLookupMode = false;
    });
  }

  // 사용자가 기존 인바디 기록 조회 입력 화면으로 진입하기 위한 기능
  void _openLookupInput() {
    setState(() {
      _isQrMode = false;
      _isLookupMode = true;
    });
  }

  // 사용자가 입력한 인바디 조회값을 서버 조회 기준값으로 정리하기 위한 기능
  String _normalizeLookupValue(String value) {
    final trimmedValue = value.trim();
    final isPhoneLike = RegExp(r'^[0-9\-\s()+]+$').hasMatch(trimmedValue);
    if (!isPhoneLike) return trimmedValue;
    return trimmedValue.replaceAll(RegExp(r'[^0-9]'), '');
  }

  // 인바디 동기화 API 응답이 실제 저장 성공을 의미하는지 판단하기 위한 기능
  bool _isSyncSuccess(Map<String, dynamic> result) {
    if (result['success'] == false || result.containsKey('error')) return false;

    final syncResult = result['result'];
    if (syncResult is Map && syncResult.containsKey('synced_count')) {
      final syncedCount = syncResult['synced_count'];
      if (syncedCount is num) return syncedCount > 0;
      return int.tryParse(syncedCount.toString()) != null &&
          int.parse(syncedCount.toString()) > 0;
    }
    if (result['success'] == true) return true;
    if (syncResult is Map) return syncResult.isNotEmpty;
    if (syncResult is List) return syncResult.isNotEmpty;
    if (syncResult is String) return syncResult.isNotEmpty;
    return syncResult != null;
  }

  // 인바디 서버 측정 결과를 조회하고 Vincere DB 저장 후 화면 데이터를 갱신하기 위한 기능
  Future<void> _syncInbodyMeasurement(
    UserModel userModel, {
    String? inbodyUserId,
    bool fallbackToQr = false,
  }) async {
    final userId = _buildOperationalInbodyUserId(userModel);
    if (userId.isEmpty || _isSyncing) return;

    setState(() => _isSyncing = true);
    try {
      final apiService = ApiServiceFast();
      final result = await apiService.syncInbodyMeasurement(
        userId,
        inbodyUserId: inbodyUserId,
      );
      if (!mounted) return;

      if (_isSyncSuccess(result)) {
        await userModel.set_user_info();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('데이터를 성공적으로 불러왔습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ScreenHealthInfo()),
        );
      } else {
        if (fallbackToQr) _openQrMeasurement();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['error']?.toString() ??
                  (fallbackToQr
                      ? '기존 기록이 없어 QR 측정 화면으로 이동합니다.'
                      : '저장할 측정 결과가 없습니다.'),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (fallbackToQr) _openQrMeasurement();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fallbackToQr
                ? '기존 기록을 찾지 못해 QR 측정 화면으로 이동합니다.'
                : '인바디 결과 동기화 중 오류가 발생했습니다: $e',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  // 입력된 인바디 ID 또는 전화번호로 기존 측정 기록을 가져오기 위한 기능
  void _importExistingInbodyData(UserModel userModel) {
    final lookupValue = _normalizeLookupValue(_lookupController.text);
    if (lookupValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디 또는 전화번호를 입력해주세요.')),
      );
      return;
    }

    _syncInbodyMeasurement(
      userModel,
      inbodyUserId: lookupValue,
      fallbackToQr: true,
    );
  }

  @override
  void dispose() {
    _lookupController.dispose();
    super.dispose();
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
                _isQrMode
                    ? '장비에서 QR을 스캔하면 InBody UserID로 측정 기록을 연결할 수 있습니다.'
                    : _isLookupMode
                        ? '이전에 인바디 장비에 입력했던 아이디 또는 전화번호로 기록을 조회합니다.'
                        : '기존 InBody 서버 기록을 가져오거나 QR로 새 측정을 진행할 수 있습니다.',
                style: TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: Colors.black.withValues(alpha: 0.62)),
              ),
              const SizedBox(height: 28),
              if (_isQrMode) ...[
                _QrPanel(
                  qrPayload: qrPayload,
                  isUserReady: isQrReady,
                  issuedAt: _issuedAt,
                  idLabel: 'InBody UserID',
                  emptyLabel: 'InBody UserID 없음',
                  isSyncing: _isSyncing,
                  onSync: () => _syncInbodyMeasurement(userModel),
                  onBack: _closeQrMeasurement,
                ),
                const SizedBox(height: 22),
                const _MeasurementGuideCard(),
              ] else if (_isLookupMode) ...[
                _InbodyLookupPanel(
                  controller: _lookupController,
                  isUserReady: isQrReady,
                  isSyncing: _isSyncing,
                  onSubmit: () => _importExistingInbodyData(userModel),
                  onBack: _closeQrMeasurement,
                ),
              ] else
                _InbodyMeasurementChoicePanel(
                  isUserReady: isQrReady,
                  isSyncing: _isSyncing,
                  onImportExisting: _openLookupInput,
                  onOpenQr: _openQrMeasurement,
                ),
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
  final VoidCallback onSync;
  final VoidCallback onBack;

  const _QrPanel({
    required this.qrPayload,
    required this.isUserReady,
    required this.issuedAt,
    required this.idLabel,
    required this.emptyLabel,
    required this.isSyncing,
    required this.onSync,
    required this.onBack,
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isSyncing ? null : onBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('측정 방식 다시 선택'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: const BorderSide(color: Color(0xFFD4DDE5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 기존 인바디 기록 조회를 위한 아이디 또는 전화번호 입력 화면을 표시하기 위한 기능
class _InbodyLookupPanel extends StatelessWidget {
  final TextEditingController controller;
  final bool isUserReady;
  final bool isSyncing;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const _InbodyLookupPanel({
    required this.controller,
    required this.isUserReady,
    required this.isSyncing,
    required this.onSubmit,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '아이디 혹은 전화번호를 입력해주세요',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '이전에 인바디 장비 회원번호 칸에 입력했던 값으로 조회합니다.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.black.withValues(alpha: 0.58),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: controller,
            enabled: !isSyncing,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (isUserReady && !isSyncing) onSubmit();
            },
            decoration: InputDecoration(
              hintText: '예: 회원번호 또는 01012345678',
              filled: true,
              fillColor: const Color(0xFFF6F8FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD4DDE5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD4DDE5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF92D2B0), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: isUserReady && !isSyncing ? onSubmit : null,
            icon: isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_download_rounded, size: 18),
            label: Text(isSyncing ? '불러오는 중' : '데이터 불러오기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: isSyncing ? null : onBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('측정 방식 다시 선택'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              side: const BorderSide(color: Color(0xFFD4DDE5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// 인바디 기존 기록 가져오기와 QR 측정 진입을 선택하기 위한 기능
class _InbodyMeasurementChoicePanel extends StatelessWidget {
  final bool isUserReady;
  final bool isSyncing;
  final VoidCallback onImportExisting;
  final VoidCallback onOpenQr;

  const _InbodyMeasurementChoicePanel({
    required this.isUserReady,
    required this.isSyncing,
    required this.onImportExisting,
    required this.onOpenQr,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ChoiceCard(
          icon: Icons.cloud_download_rounded,
          title: '기존 InBody 데이터 받아오기',
          subtitle: 'InBody 서버에 저장된 측정 기록을 가져옵니다.',
          isLoading: isSyncing,
          onTap: isUserReady && !isSyncing ? onImportExisting : null,
        ),
        const SizedBox(height: 16),
        _ChoiceCard(
          icon: Icons.qr_code_2_rounded,
          title: 'QR로 측정하기',
          subtitle: '장비에서 QR을 스캔해 새 측정을 진행합니다.',
          onTap: isUserReady && !isSyncing ? onOpenQr : null,
        ),
      ],
    );
  }
}

// 인바디 측정 방식 선택 카드를 표시하기 위한 기능
class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLoading;
  final VoidCallback? onTap;

  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF92D2B0).withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(13),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(icon, color: Colors.black87, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoading ? '불러오는 중' : title,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          color: Colors.black.withValues(alpha: 0.58)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.black45),
            ],
          ),
        ),
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
