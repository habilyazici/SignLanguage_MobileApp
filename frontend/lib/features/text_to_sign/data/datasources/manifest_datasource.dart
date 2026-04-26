import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';

final manifestDatasourceProvider = Provider((ref) => const ManifestDatasource());

/// Backend'den kelime → videoUrl haritasını çeker.
/// Uygulama açılışında bir kez yüklenir, bellekte tutulur.
class ManifestDatasource {
  const ManifestDatasource();

  Future<Map<String, String>> fetchManifest() async {
    final uri = Uri.parse('$kApiBaseUrl/api/words/manifest');
    final res = await http.get(
      uri,
      headers: {'bypass-tunnel-reminder': 'true'},
    ).timeout(const Duration(seconds: 20));

    if (res.statusCode != 200) {
      throw Exception('Manifest yüklenemedi: ${res.statusCode}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final words = body['words'] as Map<String, dynamic>;
    return words.map((k, v) => MapEntry(k, v as String));
  }
}
