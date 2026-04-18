import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

class LabelMapper {
  static final Map<int, String> _trLabels = {};
  static bool _isLoaded = false;

  /// CSV dosyasını okuyup hafızaya alır. Uygulama açılışında bir kere çağırılmalıdır.
  static Future<void> loadLabels() async {
    if (_isLoaded) return;

    try {
      final csvString = await rootBundle.loadString('assets/models/labels.csv');
      final lines = csvString.split('\n');

      // İlk satır başlık (Header) olduğu için 1'den başlıyoruz
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final parts = line.split(',');
        if (parts.length >= 2) {
          final classId = int.tryParse(parts[0]);
          if (classId != null) {
            _trLabels[classId] = parts[1].trim();
          }
        }
      }
      _isLoaded = true;
    } catch (e) {
      debugPrint('Label CSV yüklenirken hata oluştu: $e');
    }
  }

  /// Yüklü tüm etiketleri (id, kelime) çifti olarak döndürür.
  static List<(int, String)> getAllEntries() =>
      _trLabels.entries.map((e) => (e.key, e.value)).toList();

  /// TFLite'dan çıkan index numarasını vererek Türkçe kelime karşılığını alır.
  static String getTrWord(int index) {
    if (!_isLoaded) {
      debugPrint('Uyarı: loadLabels() henüz çağrılmadı!');
    }
    return _trLabels[index] ?? 'Bilinmiyor';
  }
}
