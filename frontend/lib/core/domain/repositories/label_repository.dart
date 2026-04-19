/// Etiket verilerine (labels.csv) erişim için soyut arayüz.
abstract interface class LabelRepository {
  /// TFLite index → Türkçe kelime
  String getTrWord(int index);

  /// Yüklü toplam kelime sayısı
  int get count;

  /// Tüm (id, kelime) çiftlerini döndürür
  List<(int, String)> getAllEntries();
}
