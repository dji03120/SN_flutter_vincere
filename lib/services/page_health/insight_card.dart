import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class InsightSummaryCard extends StatelessWidget {
  final String title;
  final String summary;
  final List<Map<String, dynamic>> insights;
  final VoidCallback onActionTap;

  const InsightSummaryCard({
    super.key,
    required this.title,
    required this.summary,
    required this.insights,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: Offset(0, 3),
            )
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 헤더
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.insights, color: Colors.green, size: 30),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),

            const SizedBox(height: 24),

            /// 🔹 요약 문장
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: AutoSizeText(
                summary,
                maxLines: 3,
                minFontSize: 13,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),

            const SizedBox(height: 12),

            /// 🔹 핵심 인사이트 리스트
            Column(
              children: insights.map((item) {
                final Color color = item['color'];
                final IconData icon = item['icon'];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AutoSizeText(
                          item['text'],
                          maxLines: 1,
                          minFontSize: 12,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            /// 🔹 CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
                onPressed: onActionTap,
                child: const Text(
                  "추천 운동 · 식단 플랜",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
