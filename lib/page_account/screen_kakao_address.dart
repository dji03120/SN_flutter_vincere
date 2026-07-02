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
  bool _isSearching = false;

  static const String _apiKey = '8de8c18a1f0c18fa6e0c7f14fd081b28';

  // 카카오 주소 REST API를 호출해 검색 결과를 가져오기 위한 기능
  Future<void> _searchAddress(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('검색어를 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final addressResults = await _searchAddressDocuments(trimmedQuery);
      final keywordResults = await _searchKeywordDocuments(trimmedQuery);
      final mergedResults =
          await _mergeAddressResults(addressResults, keywordResults);

      if (!mounted) return;
      setState(() {
        _results = mergedResults;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('주소 검색 실패: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  // 카카오 주소 검색 API에서 주소 문서를 가져오기 위한 기능
  Future<List<Map<String, dynamic>>> _searchAddressDocuments(
      String query) async {
    final url = Uri.parse(
      'https://dapi.kakao.com/v2/local/search/address.json?query=${Uri.encodeComponent(query)}&analyze_type=similar',
    );

    final response = await http.get(
      url,
      headers: {'Authorization': 'KakaoAK $_apiKey'},
    );

    if (response.statusCode != 200) {
      throw '주소 API ${response.statusCode}';
    }

    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data['documents'] ?? []);
  }

  // 도로명 일부 검색을 보완하기 위해 카카오 키워드 검색 결과를 가져오기 위한 기능
  Future<List<Map<String, dynamic>>> _searchKeywordDocuments(
      String query) async {
    final url = Uri.parse(
      'https://dapi.kakao.com/v2/local/search/keyword.json?query=${Uri.encodeComponent(query)}',
    );

    final response = await http.get(
      url,
      headers: {'Authorization': 'KakaoAK $_apiKey'},
    );

    if (response.statusCode != 200) {
      return [];
    }

    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data['documents'] ?? []);
  }

  // 주소 검색과 키워드 검색 결과를 중복 제거하고 우편번호가 있는 주소로 보강하기 위한 기능
  Future<List<Map<String, dynamic>>> _mergeAddressResults(
    List<Map<String, dynamic>> addressResults,
    List<Map<String, dynamic>> keywordResults,
  ) async {
    final merged = <Map<String, dynamic>>[];
    final seenAddresses = <String>{};

    for (final item in addressResults) {
      final resolvedItem = await _completeAddressItem(item);
      _addUniqueAddress(merged, seenAddresses, resolvedItem);
    }

    for (final item in keywordResults.take(10)) {
      final keywordAddress =
          (item['road_address_name'] ?? item['address_name'] ?? '').toString();
      if (keywordAddress.isEmpty) continue;

      final keywordAddressResults =
          await _searchAddressDocuments(keywordAddress);
      if (keywordAddressResults.isNotEmpty) {
        final resolvedItem =
            await _completeAddressItem(keywordAddressResults.first);
        _addUniqueAddress(merged, seenAddresses, resolvedItem);
      }
    }

    final zipResults =
        merged.where((item) => _resolveZipCd(item).isNotEmpty).toList();
    if (zipResults.isNotEmpty) return zipResults;

    return merged;
  }

  // 주소 결과에 우편번호가 없을 때 좌표 기반 역주소로 도로명 우편번호를 보완하기 위한 기능
  Future<Map<String, dynamic>> _completeAddressItem(
      Map<String, dynamic> item) async {
    if (_resolveZipCd(item).isNotEmpty) return item;

    final x = item['x']?.toString() ?? '';
    final y = item['y']?.toString() ?? '';
    if (x.isEmpty || y.isEmpty) return item;

    final url = Uri.parse(
      'https://dapi.kakao.com/v2/local/geo/coord2address.json?x=${Uri.encodeComponent(x)}&y=${Uri.encodeComponent(y)}',
    );
    final response = await http.get(
      url,
      headers: {'Authorization': 'KakaoAK $_apiKey'},
    );

    if (response.statusCode != 200) return item;

    final data = json.decode(response.body);
    final documents = List<Map<String, dynamic>>.from(data['documents'] ?? []);
    if (documents.isEmpty) return item;

    final roadAddress = documents.first['road_address'];
    if (roadAddress == null) return item;

    return {
      ...item,
      'road_address': roadAddress,
    };
  }

  // 화면 목록에 같은 주소가 중복 노출되지 않도록 추가하기 위한 기능
  void _addUniqueAddress(List<Map<String, dynamic>> merged,
      Set<String> seenAddresses, Map<String, dynamic> item) {
    final address = _resolveAddress(item);
    if (address.isEmpty || seenAddresses.contains(address)) return;

    seenAddresses.add(address);
    merged.add(item);
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
                  icon: _isSearching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  onPressed: () {
                    _searchAddress(_searchController.text);
                  },
                ),
              ),
              onSubmitted: _searchAddress,
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
