import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// CSV dosyasından yüklenen TFLite sınıf indekslerini Türkçe kelimelere eşler.
/// Instance-based — main.dart'ta yüklenir, [labelRepositoryProvider] üzerinden inject edilir.
class LabelMapper {
  final Map<int, String> _labels = {};

  Future<void> loadLabels() async {
    try {
      final csv = await rootBundle.loadString('assets/models/labels.csv');
      final lines = csv.split('\n');
      // İlk satır başlık.
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final parts = line.split(',');
        if (parts.length >= 2) {
          final id = int.tryParse(parts[0]);
          if (id != null) _labels[id] = parts[1].trim();
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Label CSV yüklenirken hata: $e');
    }
  }

  int get count => _labels.length;

  List<(int, String)> getAllEntries() =>
      _labels.entries.map((e) => (e.key, e.value)).toList();

  String getTrWord(int index) => _labels[index] ?? 'Bilinmiyor';
}
