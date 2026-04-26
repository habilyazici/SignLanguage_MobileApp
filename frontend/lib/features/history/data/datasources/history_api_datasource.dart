import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/history_item.dart';

final historyDatasourceProvider = Provider((ref) => HistoryApiDatasource(ref));

class HistoryApiDatasource {
  final Ref _ref;
  const HistoryApiDatasource(this._ref);

  Future<List<HistoryItem>> fetchHistory() async {
    final res = await _ref.apiGet('/api/history');
    if (res.statusCode != 200) throw Exception('Geçmiş yüklenemedi');
    final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    return list.map(HistoryItem.fromJson).toList();
  }

  Future<HistoryItem> addHistory(String text) async {
    final res = await _ref.apiPost('/api/history', body: {'text': text});
    if (res.statusCode != 201) throw Exception('Ekleme başarısız');
    return HistoryItem.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> deleteHistory(String id) async {
    final res = await _ref.apiDelete('/api/history/$id');
    if (res.statusCode != 204) throw Exception('Silme başarısız');
  }

  Future<void> clearAllHistory() async {
    final res = await _ref.apiDelete('/api/history');
    if (res.statusCode != 204) throw Exception('Temizleme başarısız');
  }
}
