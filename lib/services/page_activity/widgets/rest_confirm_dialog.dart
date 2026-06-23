// UWB/IMU 활동 측정 중 휴식 여부를 확인하는 팝업을 제공하기 위한 기능

import 'package:flutter/material.dart';

// 휴식 여부 응답 결과를 구분하기 위한 기능
enum RestConfirmResult { resume, rest }

// 10초 이상 움직임이 없을 때 휴식 여부를 묻기 위한 기능
Future<RestConfirmResult?> showRestConfirmDialog(BuildContext context) {
  return showDialog<RestConfirmResult>(
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
                      onPressed: () =>
                          Navigator.pop(context, RestConfirmResult.resume),
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
                      onPressed: () =>
                          Navigator.pop(context, RestConfirmResult.rest),
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
  );
}
