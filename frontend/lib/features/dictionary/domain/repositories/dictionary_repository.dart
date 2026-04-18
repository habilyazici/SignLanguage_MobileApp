import '../entities/sign_entry.dart';

abstract interface class DictionaryRepository {
  /// Tüm işaret kelimelerini döndürür.
  List<SignEntry> getAllSigns();
}
