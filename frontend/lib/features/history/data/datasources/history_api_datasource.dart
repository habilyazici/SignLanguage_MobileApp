import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/history_item.dart' show HistoryItem, HistoryItemType;

final historyDatasourceProvider = Provider((ref) => HistoryApiDatasource(ref));

class HistoryApiDatasource {
  final Ref _ref;
  const HistoryApiDatasource(this._ref);

  Future<List<HistoryItem>> fetchHistory({int offset = 0, int limit = 50}) async {
    final res = await _ref.apiGet('/api/history?offset=$offset&limit=$limit');
    if (res.statusCode != 200) throw Exception('Geçmiş yüklenemedi');
    final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    return list.map(HistoryItem.fromJson).toList();
  }

  Future<HistoryItem> addHistory(String text, {HistoryItemType type = HistoryItemType.recognition}) async {
    final typeStr = switch (type) {
      HistoryItemType.dictionary => 'DICTIONARY',
      HistoryItemType.translation => 'TRANSLATION',
      _ => 'RECOGNITION',
    };
    final res = await _ref.apiPost('/api/history', body: {'text': text, 'type': typeStr});
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
