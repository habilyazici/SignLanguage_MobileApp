import '../../domain/entities/sign_entry.dart';

/// Sözlük veri kaynağı.
///
/// AI/recognition tarafındaki labels.csv (226 kelime) ile ilgisi yoktur —
/// sözlük verisi backend'den gelecek. Backend hazır olana kadar boş liste
/// döner; UI "henüz içerik yok" durumunu gösterir.
class DictionaryLocalDatasource {
  const DictionaryLocalDatasource();

  List<SignEntry> readAll() => const [];
}
