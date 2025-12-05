
// 회원 정보 컨테이너
/*
  Container userInfoContainer(BuildContext context, Map<String, dynamic>? userData) {
    // 함수 시작시 현재 활동량 설정
    currentActivityLevel = userData?["activityLevel"] ?? "LOW";

    return Container(
      color: Colors.blueGrey,
      child: (userData == null)
          ? Center(
              child: Text(
                '회원 정보가 없습니다.',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '회원 정보',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                // 프로필 사진 섹션 추가
                Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          // 프로필 이미지
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: _buildProfileImage(),
                          ),
                          // 편집 버튼
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (BuildContext context) {
                                  return SafeArea(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        ListTile(
                                          leading: Icon(Icons.photo_library),
                                          title: Text('갤러리에서 선택'),
                                          onTap: () async {
                                            Navigator.pop(context);
                                            try {
                                              final ImagePicker picker = ImagePicker();
                                              final XFile? image = await picker.pickImage(
                                                source: ImageSource.gallery,
                                              );
                                              if (image != null) {
                                                setState(() {
                                                  _profileImage = image; // XFile 직접 저장
                                                });
                                                await _uploadImage(image);
                                              }
                                            } catch (e) {
                                              if (e is UnimplementedError) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('이 기능은 현재 플랫폼에서 지원되지 않습니다.')),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다.')),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                        ListTile(
                                          leading: Icon(Icons.photo_camera),
                                          title: Text('카메라로 촬영'),
                                          onTap: () async {
                                            Navigator.pop(context);
                                            try {
                                              final ImagePicker picker = ImagePicker();
                                              final XFile? image = await picker.pickImage(
                                                source: ImageSource.camera,
                                              );
                                              if (image != null) {
                                                setState(() {
                                                  _profileImage = image; // File 대신 XFile 사용
                                                });
                                                await _uploadImage(image);
                                              }
                                            } catch (e) {
                                              if (e is UnimplementedError) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('카메라 기능은 현재 플랫폼에서 지원되지 않습니다.')),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('카메라 사용 중 오류가 발생했습니다.')),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                        if (_profileImage != null)
                                          ListTile(
                                            leading: Icon(Icons.delete),
                                            title: Text('프로필 사진 삭제'),
                                            onTap: () async {
                                              Navigator.pop(context);
                                              await _deleteProfileImage();
                                            },
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                              ),
                              child: Icon(Icons.edit, size: 20, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                      if (_isLoading)
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.all(16),
                    children: [
                      buildUserInfoCard(title: '회원 아이디', value: userData["userId"] ?? "N/A"),
                      buildUserInfoCard(title: '회원 이름', value: userData["userNm"] ?? "N/A"),
                      buildUserInfoCard(title: '생년월일', value: userData["bym"] ?? "N/A"),
                      buildUserInfoCard(title: '성별', value: userData?["sex"] == "M" ? "남성" : "여성"),
                      StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      '활동량 구분',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 7,
                                    child: DropdownButton<String>(
                                      value: currentActivityLevel,
                                      items: [
                                        DropdownMenuItem(value: 'LOW', child: Text('좌업자')),
                                        DropdownMenuItem(value: 'NORMAL', child: Text('보통활동')),
                                        DropdownMenuItem(value: 'HIGH', child: Text('육체활동')),
                                      ],
                                      onChanged: (String? value) async {
                                        if (value != null && currentActivityLevel != value) {
                                          // 확인 다이얼로그
                                          bool? confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text('활동량 변경'),
                                                content: Text('활동량을 변경하시겠습니까?'),
                                                actions: <Widget>[
                                                  TextButton(
                                                    child: Text('취소'),
                                                    onPressed: () => Navigator.of(context).pop(false),
                                                  ),
                                                  TextButton(
                                                    child: Text('확인'),
                                                    onPressed: () => Navigator.of(context).pop(true),
                                                  ),
                                                ],
                                              );
                                            },
                                          );

                                          if (confirm == true) {
                                            try {
                                              ApiService apiService = ApiService();
                                              Map<String, dynamic> result = await apiService.updateUserActivityLevel(
                                                userData["userId"],
                                                value,
                                              );

                                              if (result['result'] == 1) {
                                                setState(() {
                                                  currentActivityLevel = value;
                                                  // userData도 함께 업데이트
                                                  userData?["activityLevel"] = value;
                                                });
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('활동량이 업데이트되었습니다.'),
                                                    backgroundColor: Colors.green,
                                                  ),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('활동량 업데이트에 실패했습니다.'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              print('Error updating activity level: $e');
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('오류가 발생했습니다. 다시 시도해주세요.'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                      isExpanded: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }



  
// 이미지 삭제 처리
  Future<void> _deleteProfileImage() async {
    try {
      setState(() {
        _isLoading = true;
      });

      ApiService apiService = ApiService();
      var result = await apiService.deleteProfileImage(
        userId.toString(),
      );

      if (result['success'] == true) {
        setState(() {
          _profileImage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 이미지가 삭제되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이미지 삭제에 실패했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 업로드 메서드 수정
  Future<void> _uploadImage(XFile image) async {
    try {
      setState(() {
        _isLoading = true;
      });

      ApiService apiService = ApiService();
      var result = await apiService.uploadProfileImage(
        userId.toString(),
        await image.readAsBytes(), // XFile을 bytes로 변환
        image.name, // 파일 이름 전달
      );

      if (result['success'] == true) {
        await _getProfileImage();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필 이미지가 업로드되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이미지 업로드에 실패했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  
  Container tabContainer(BuildContext context, Color tabColor, String tabText) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      color: tabColor,
      padding: const EdgeInsets.all(16.0),
      // 전체 화면에 여백 추가
      child: (tabText == "홈")
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 첫 번째 줄: "나의 건강 정보 이력" & "나의 영양 상태 평가 및 식단 추천"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_isLogIn) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const HisHealth()),
                            );
                          } else {
                            _showLoginPrompt();
                          }
                        },
                        child: const Text(
                          '나의 건강 정보 이력',
                          style: TextStyle(fontSize: 24), // 글자 크기 2배로 설정
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_isLogIn) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const MyNutriCheck()),
                            );
                          } else {
                            _showLoginPrompt();
                          }
                        },
                        child: const Text(
                          '나의 영양 상태 평가 및 식단 추천',
                          style: TextStyle(fontSize: 24), // 글자 크기 2배로 설정
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 두 번째 줄: "식품별 영양 정보" & "Q&A"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const FoodInfo()),
                          );
                        },
                        child: const Text(
                          '식품별 영양 정보',
                          style: TextStyle(fontSize: 24), // 글자 크기 2배로 설정
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_isLogIn) {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const Qna()));
                          } else {
                            _showLoginPrompt();
                          }
                        },
                        child: const Text(
                          'Q&A',
                          style: TextStyle(fontSize: 24), // 글자 크기 2배로 설정
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 세 번째 줄: "나의 건강 정보 입력 및 자동 처방 신청"
                ElevatedButton(
                  onPressed: () {
                    if (_isLogIn) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const InputInfoScreen()));
                    } else {
                      _showLoginPrompt();
                    }
                  },
                  child: const Text('나의 건강 정보 입력 및 자동 처방 신청', style: TextStyle(fontSize: 24)),
                ),
              ],
            )
          : (tabText == "마이페이지")
              // ? userInfoContainer(context, userData)
              ? MyPage(
                  userData: userData,
                  onProfileImageChange: updateProfileImage, // 콜백 함수 전달
                  onActivityLevelChange: updateActivityLevl,
                )
              : (tabText == "건강정보&처방")
                  ? Column(
                      children: [
                        Expanded(
                          child: ScreenHealthInfo(
                            healthData: userHlthData, // 기존 전달된 데이터
                            healthInfoItemsFuture: healthInfoItemsFuture, // Future 객체 전달
                            userId: userId, // 사용자 ID 전달
                            initializeData: _initializeData, // 초기화 함수 전달
                            msmtItemData: msmtItemData,
                          ),
                        ),
                        Expanded(child: pscpInfoContainer(context, userPscpData)),
                      ],
                    )
                  : Container(),
    );
  }

  */