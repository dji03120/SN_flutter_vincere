import 'package:flutter/material.dart';

//
//
//
//
class DailyMissionCard extends StatefulWidget {
  final String title;
  final List missionList;

  const DailyMissionCard({
    Key? key,
    required this.title,
    required this.missionList,
  }) : super(key: key);

  @override
  State<DailyMissionCard> createState() => _DailyMissionState();
}

class _DailyMissionState extends State<DailyMissionCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Card(
            elevation: 6,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.flag, color: Colors.green, size: 30),
                        SizedBox(width: 20),
                        Text(widget.title, style: TextStyle(color: Colors.black, fontSize: 26, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 20),
                    ClipRect(
                        child: AnimatedSize(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: Column(
                                children: List.generate(
                                    isExpanded ? widget.missionList.length : (widget.missionList.length >= 3 ? 3 : widget.missionList.length),
                                    (i) => Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: _buildMissionItem(
                                          title: widget.missionList[i]["title"],
                                          detail: widget.missionList[i]["detail"],
                                          completed: widget.missionList[i]['complete'],
                                          onTap: () {
                                            setState(() {
                                              widget.missionList[i]['complete'] = !widget.missionList[i]['complete'];

                                              // 모든 미션이 완료되었는지 체크
                                              bool allCompleted = widget.missionList.every((m) => m['complete'] == true);

                                              if (allCompleted) {
                                                // 완료 팝업 표시
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => Dialog(
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                    child: Container(
                                                      padding: EdgeInsets.all(20),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                      child: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.emoji_events, color: Colors.orangeAccent, size: 60),
                                                          SizedBox(height: 10),
                                                          Text("축하합니다! 🎉", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                                                          SizedBox(height: 10),
                                                          Text(
                                                            "오늘의 모든 목표를 완료했습니다.",
                                                            textAlign: TextAlign.center,
                                                            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                                                          ),
                                                          SizedBox(height: 20),
                                                          SizedBox(
                                                            width: double.infinity,
                                                            child: ElevatedButton(
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor: Colors.green,
                                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                                padding: EdgeInsets.symmetric(vertical: 14),
                                                              ),
                                                              onPressed: () => {Navigator.of(context).pop()},
                                                              child: Text("확인", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }
                                            });
                                          },
                                        ))))))
                  ])),
              InkWell(
                  onTap: () => setState(() => isExpanded = !isExpanded),
                  child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                      ),
                      child: AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: Duration(milliseconds: 250),
                        child: Icon(Icons.keyboard_arrow_down, color: Colors.grey[800], size: 32),
                      )))
            ])));
  }

  Widget _buildMissionItem({
    required String title,
    required String detail,
    required bool completed,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.grey[50],
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: 6,
              height: 72,
              decoration: BoxDecoration(
                color: completed ? Colors.green : Colors.grey.shade300,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              ),
            ),
            SizedBox(width: 14),
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(children: [
                  AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: completed ? Colors.green : Colors.white,
                        border: Border.all(color: completed ? Colors.green : Colors.grey, width: 2),
                      ),
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 400),
                        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                        child: completed ? Icon(Icons.check, key: ValueKey(true), color: Colors.white, size: 18) : SizedBox(key: ValueKey(false)),
                      )),
                  SizedBox(width: 15),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)),
                    SizedBox(height: 4),
                    Text(detail, style: TextStyle(fontSize: 15, color: Colors.grey[600])),
                  ])
                ])),
            Spacer(),
            AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
              child: completed ? Icon(Icons.check_circle, key: ValueKey("on"), color: Colors.green) : Icon(Icons.radio_button_unchecked, key: ValueKey("off"), color: Colors.blueGrey),
            ),
            SizedBox(width: 20),
          ],
        ),
      ),
    );
  }
}
