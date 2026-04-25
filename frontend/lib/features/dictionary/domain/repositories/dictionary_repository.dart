import '../entities/sign_entry.dart';

abstract interface class DictionaryRepository {
  Future<List<SignEntry>> fetchAll();
}
