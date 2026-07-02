// 카카오 주소 검색 결과를 선택해 우편번호와 주소를 반환하기 위한 기능

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class KakaoAddressSearchScreen extends StatefulWidget {
  const KakaoAddressSearchScreen({super.key});

  @override
  State<KakaoAddressSearchScreen> createState() =>
      _KakaoAddressSearchScreenState();
}

class _KakaoAddressSearchScreenState extends State<KakaoAddressSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _results = [];

  // 카카오 주소 REST API를 호출해 검색 결과를 가져오기 위한 기능
  Future<void> _searchAddress(String query) async {
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('검색어를 입력해주세요.')),
      );
      return;
    }

    const String apiKey = '8de8c18a1f0c18fa6e0c7f14fd081b28'; // 발급받은 키
    final url = Uri.parse(
        'https://dapi.kakao.com/v2/local/search/address.json?query=${Uri.encodeComponent(query)}&analyze_type=similar');

    final response = await http.get(
      url,
      headers: {'Authorization': 'KakaoAK $apiKey'},
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _results = data['documents'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('주소 검색 실패: ${response.statusCode}')),
      );
    }
  }

  // 도로명 우편번호를 우선 사용하고 없으면 지번 우편번호를 보완하기 위한 기능
  String _resolveZipCd(Map<String, dynamic> item) {
    final String roadZoneNo = item['road_address']?['zone_no'] ?? '';
    if (roadZoneNo.isNotEmpty) return roadZoneNo;

    return item['address']?['zip_code'] ?? '';
  }

  // 도로명 주소가 없을 때 지번 주소로 화면과 저장값을 보완하기 위한 기능
  String _resolveAddress(Map<String, dynamic> item) {
    final String roadAddress = item['road_address']?['address_name'] ?? '';
    if (roadAddress.isNotEmpty) return roadAddress;

    final String jibunAddress = item['address']?['address_name'] ?? '';
    if (jibunAddress.isNotEmpty) return jibunAddress;

    return item['address_name'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주소 검색'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: '검색어 입력',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    _searchAddress(_searchController.text);
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final item = _results[index];
                final zipCd = _resolveZipCd(item);
                final address = _resolveAddress(item);
                return ListTile(
                  title: Text(address.isNotEmpty ? address : '주소 없음'),
                  subtitle: Text(zipCd.isNotEmpty ? '우편번호 $zipCd' : '우편번호 없음'),
                  onTap: () {
                    Navigator.pop(context, {
                      'zipCd': zipCd,
                      'roadAddress': address,
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
