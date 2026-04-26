import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/sign_entry.dart';

final dictionaryDatasourceProvider = Provider((ref) => DictionaryApiDatasource(ref));

/// Tüm kelimeleri backend'den sayfalı olarak çeker.
class DictionaryApiDatasource {
  final Ref _ref;
  const DictionaryApiDatasource(this._ref);

  Future<List<SignEntry>> fetchAll() async {
    final all = <SignEntry>[];
    int page = 1;
    const limit = 200;

    while (true) {
      final res = await _ref.apiGet('/api/words?page=$page&limit=$limit');

      if (res.statusCode != 200) {
        throw Exception('Kelimeler yüklenemedi (HTTP ${res.statusCode}).');
      }

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final data = (body['data'] as List).cast<Map<String, dynamic>>();

      for (final item in data) {
        all.add(SignEntry(
          id: item['id'] as int,
          label: item['word'] as String,
          category: item['letter'] as String,
          description: item['meaningEn'] as String?,
          videoUrl: item['videoUrl'] as String?,
        ));
      }

      final pages = body['pages'] as int;
      if (page >= pages) break;
      page++;
    }

    return all;
  }
}
