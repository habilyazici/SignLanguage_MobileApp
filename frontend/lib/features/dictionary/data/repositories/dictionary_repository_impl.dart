import '../../domain/entities/sign_entry.dart';
import '../../domain/repositories/dictionary_repository.dart';
import '../datasources/dictionary_api_datasource.dart';

class DictionaryRepositoryImpl implements DictionaryRepository {
  const DictionaryRepositoryImpl([
    this._datasource = const DictionaryApiDatasource(),
  ]);

  final DictionaryApiDatasource _datasource;

  @override
  Future<List<SignEntry>> fetchAll() => _datasource.fetchAll();
}
