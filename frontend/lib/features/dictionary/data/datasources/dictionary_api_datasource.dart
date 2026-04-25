import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/sign_entry.dart';

/// Tüm kelimeleri backend'den çeker.
/// 1989 kelime ~100KB JSON — uygulama açılışında bir kez yüklenir.
class DictionaryApiDatasource {
  const DictionaryApiDatasource();

  Future<List<SignEntry>> fetchAll() async {
    final all = <SignEntry>[];
    int page = 1;
    const limit = 200;

    while (true) {
      final uri = Uri.parse('$kApiBaseUrl/api/words?page=$page&limit=$limit');
      final res = await http.get(uri).timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) break;

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
