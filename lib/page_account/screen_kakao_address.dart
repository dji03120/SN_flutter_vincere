import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class KakaoAddressSearchScreen extends StatefulWidget {
  @override
  _KakaoAddressSearchScreenState createState() =>
      _KakaoAddressSearchScreenState();
}

class _KakaoAddressSearchScreenState extends State<KakaoAddressSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _results = [];

  // REST API 호출
  Future<void> _searchAddress(String query) async {
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('검색어를 입력해주세요.')),
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
                border: OutlineInputBorder(),
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
                return ListTile(
                  title: Text(item['address_name'] ?? '주소 없음'),
                  subtitle: Text(
                      item['road_address']?['address_name'] ?? '도로명 주소 없음'),
                  onTap: () {
                    Navigator.pop(context, {
                      'zipCd': item['road_address']?['zone_no'] ?? '',
                      'roadAddress':
                          item['road_address']?['address_name'] ?? '',
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
