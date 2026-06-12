import 'package:Vincere/services/page_ble_device/page_inbody_blood_pressure_large.dart';
import 'package:Vincere/services/page_ble_device/page_inbody_blood_pressure_small.dart';
import 'package:Vincere/utils/component/header.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class PageSelectBloodPressMeasureType extends StatelessWidget {
  const PageSelectBloodPressMeasureType({super.key});

  @override
  Widget build(BuildContext context) {
    final data = [1.1, 2.1, 3.1];
    return Scaffold(
      appBar: const Header(),
      backgroundColor: const Color(0xFFF5F4F9),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AutoSizeText(
                "측정하실 항목을 선택해주세요",
                maxLines: 1,
                minFontSize: 16,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 40),
              _buildItem(context, icon: Icons.medical_services, title: "병원용 혈압 측정기", desc: "의료기관 전용 고정밀 혈압 측정", type: "inbody BPBIO320"),
              _buildItem(context, icon: Icons.home_rounded, title: "가정용 혈압 측정기", desc: "집에서 간편하게 측정하는 혈압 관리", type: "inbody BP170B"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String desc,
    required String type,
  }) {
    return InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          if (type == "inbody BPBIO320") {
            Navigator.push(context, MaterialPageRoute(builder: (_) => PageInbodyBloodPressureLarge()));
          }
          if (type == "inbody BP170B") {
            Navigator.push(context, MaterialPageRoute(builder: (_) => PageInbodyBloodPressureSmall()));
          }
        },
        child: Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.black.withOpacity(0.08)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 6))],
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFF003366), borderRadius: BorderRadius.circular(18)),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 22),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AutoSizeText(title, maxLines: 1, minFontSize: 12, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
                const SizedBox(height: 6),
                AutoSizeText(desc, maxLines: 1, minFontSize: 12, style: TextStyle(fontSize: 15, color: Colors.black.withOpacity(0.6))),
              ])),
              const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black38),
            ])));
  }
}
