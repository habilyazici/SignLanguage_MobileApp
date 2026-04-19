import '../entities/sign_token.dart';

abstract interface class TextToSignRepository {
  /// Manifest'i backend'den çeker ve cache'ler.
  Future<void> initialize();

  /// [text]'i tokenize edip her kelime için [SignToken] döndürür.
  /// Suffix stripping ile "okula" → "okul" eşleşmesi yapılır.
  List<SignToken> parse(String text);

  /// Manifest yüklü mü?
  bool get isReady;
}
