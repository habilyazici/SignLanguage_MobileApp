import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import 'dart:convert';

final bookmarksDatasourceProvider = Provider((ref) => BookmarksApiDatasource(ref));

class BookmarksApiDatasource {
  final Ref _ref;
  const BookmarksApiDatasource(this._ref);

  Future<Set<int>> fetchBookmarks() async {
    final res = await _ref.apiGet('/api/bookmarks');
    if (res.statusCode != 200) throw Exception('Favoriler yüklenemedi');
    final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    return list.map((b) => b['wordId'] as int).toSet();
  }

  Future<void> addBookmark(int wordId) async {
    final res = await _ref.apiPost('/api/bookmarks/$wordId');
    if (res.statusCode != 201) throw Exception('Ekleme başarısız');
  }

  Future<void> deleteBookmark(int wordId) async {
    final res = await _ref.apiDelete('/api/bookmarks/$wordId');
    if (res.statusCode != 204) throw Exception('Silme başarısız');
  }
}
