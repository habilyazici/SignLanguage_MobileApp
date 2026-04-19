import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Backend manifest endpoint'ini çeker ve word → videoUrl haritasını döndürür.
///
/// Manifest JSON formatı (backend'den beklenen):
/// ```json
/// {
///   "baseUrl": "https://api.hearmeout.app/videos",
///   "words": ["aile", "arkadaş", "araba", "baba", ...]
/// }
/// ```
/// Video URL'leri: {baseUrl}/{ilkHarf}/{kelime}.mp4
///
/// Backend hazır olmadan STUB_MODE=true ile çalışır — boş manifest döner.
class ManifestDatasource {
  ManifestDatasource({required this.dio, required this.baseApiUrl});

  final Dio dio;
  final String baseApiUrl;

  // Backend hazır olana kadar stub modda çalış
  static const bool _stubMode = true;

  /// word → videoUrl haritasını döndürür.
  Future<Map<String, String>> fetchManifest() async {
    if (_stubMode) {
      debugPrint('📋 ManifestDatasource: stub mod — boş manifest');
      return {};
    }

    try {
      final response = await dio.get('$baseApiUrl/manifest');
      final data = response.data as Map<String, dynamic>;
      final videoBase = data['baseUrl'] as String;
      final words = (data['words'] as List).cast<String>();

      return {
        for (final word in words)
          word: '$videoBase/${word[0]}/$word.mp4',
      };
    } catch (e) {
      debugPrint('❌ Manifest fetch hatası: $e');
      return {};
    }
  }
}
