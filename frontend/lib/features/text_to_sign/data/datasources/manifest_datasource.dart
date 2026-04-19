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
/// TODO: Backend aktifleştiğinde http/Dio import edilerek fetchManifest() doldurulacak.
class ManifestDatasource {
  ManifestDatasource({required this.baseApiUrl});

  final String baseApiUrl;

  // Backend hazır olana kadar stub modda çalış
  static const bool _stubMode = true;

  /// word → videoUrl haritasını döndürür.
  Future<Map<String, String>> fetchManifest() async {
    if (_stubMode) {
      debugPrint('📋 ManifestDatasource: stub mod — boş manifest');
      return {};
    }

    // TODO: Backend hazır olduğunda http paketi ile implement edilecek.
    // Örnek: GET $baseApiUrl/manifest → { baseUrl, words: [...] }
    throw UnimplementedError('ManifestDatasource: backend henüz bağlı değil.');
  }
}
