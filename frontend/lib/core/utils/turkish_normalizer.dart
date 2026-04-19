/// Türkçe kelime normalizer — manifest tabanlı suffix stripping.
///
/// Kullanım: Kullanıcı "okula" yazar, manifest'te "okul" var.
/// [findStem] kelimeyi manifest'teki bilinen kelimelerle eşleştirir.
/// Dilbilimsel değil, manifest-driven: sadece gerçekten var olan gövdeyi döndürür.
abstract final class TurkishNormalizer {
  // Uzundan kısaya sıralı — önce uzun ek eşleşirse kısa ekin yanlış kesmesi önlenir.
  // (ör. "larından" önce denenirse "lar" + "ından" ayrı ayrı denenmez)
  static const List<String> _suffixes = [
    // Çoğul + uzun ekler
    'larından', 'lerinden',
    'larında', 'lerinde',
    'larıyla', 'leriyle',
    'larınca', 'lerince',
    // Çoğul + hal
    'lardan', 'lerden',
    'larla', 'lerle',
    'larda', 'lerde',
    'ların', 'lerin',
    'lara', 'lere',
    'ları', 'leri',
    // Çoğul
    'lar', 'ler',
    // Fiil — uzun
    'acaksın', 'eceksin',
    'acaklar', 'ecekler',
    'acağım', 'eceğim',
    'acaktı', 'ecekti',
    'ıyorum', 'iyorum', 'uyorum', 'üyorum',
    'maktan', 'mekten',
    'makta', 'mekte',
    'madan', 'meden',
    'acak', 'ecek',
    'arak', 'erek',
    'ıyor', 'iyor', 'uyor', 'üyor',
    'mış', 'miş', 'muş', 'müş',
    'tım', 'tim', 'tum', 'tüm',
    'dım', 'dim', 'dum', 'düm',
    'mak', 'mek',
    'sun', 'sün',
    'tı', 'ti', 'tu', 'tü',
    'dı', 'di', 'du', 'dü',
    // İsim halleri — uzun
    'ndan', 'nden',
    'nın', 'nin', 'nun', 'nün',
    'nda', 'nde',
    'nla', 'nle',
    'na', 'ne',
    // İsim halleri — kısa
    'dan', 'den',
    'tan', 'ten',
    'yı', 'yi', 'yu', 'yü',
    'ya', 'ye',
    'da', 'de',
    'ta', 'te',
    'ın', 'in', 'un', 'ün',
    'ı', 'i', 'u', 'ü',
    'a', 'e',
  ];

  /// [word]'ü [knownWords] içinde arar.
  /// Tam eşleşme yoksa suffix kırparak bilinen en uzun gövdeyi bulur.
  /// Hiç bulunamazsa null döner.
  static String? findStem(String word, Set<String> knownWords) {
    final normalized = _trLower(word.trim());
    if (normalized.isEmpty) return null;

    // 1. Tam eşleşme
    if (knownWords.contains(normalized)) return normalized;

    // 2. Suffix kırpma — uzundan kısaya
    for (final suffix in _suffixes) {
      if (normalized.length <= suffix.length) continue;
      if (!normalized.endsWith(suffix)) continue;
      final stem = normalized.substring(0, normalized.length - suffix.length);
      // Çok kısa gövdeleri reddet (2 karakter minimum)
      if (stem.length < 2) continue;
      if (knownWords.contains(stem)) return stem;
    }

    return null;
  }

  /// Metni kelimelere böler, noktalama temizler.
  static List<String> tokenize(String text) {
    return text
        .split(RegExp(r'[\s,\.!?;:\-]+'))
        .map(_trLower)
        .where((w) => w.length >= 2)
        .toList();
  }

  static String _trLower(String s) => s
      .toLowerCase()
      .replaceAll('İ', 'i')
      .replaceAll('I', 'ı')
      .replaceAll('Ğ', 'ğ')
      .replaceAll('Ü', 'ü')
      .replaceAll('Ş', 'ş')
      .replaceAll('Ö', 'ö')
      .replaceAll('Ç', 'ç');
}
