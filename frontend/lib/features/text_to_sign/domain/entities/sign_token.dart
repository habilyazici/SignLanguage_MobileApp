/// Metin → işaret çevirisindeki her token için sealed sınıf.
sealed class SignToken {
  /// Kullanıcının yazdığı orijinal kelime
  final String originalWord;
  const SignToken(this.originalWord);
}

/// Manifest'te eşleşme bulundu — video URL'si mevcut
class SignFound extends SignToken {
  /// Backend video URL'si (ör. https://api.../videos/o/okul.mp4)
  final String videoUrl;

  /// Manifest'teki normalize edilmiş kelime (ör. "okul")
  final String matchedWord;

  const SignFound(super.originalWord, {
    required this.videoUrl,
    required this.matchedWord,
  });
}

/// Manifest'te eşleşme bulunamadı — kelime gösterilir, video yok
class SignNotFound extends SignToken {
  const SignNotFound(super.originalWord);
}
