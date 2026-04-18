import '../../domain/entities/sign_entry.dart';
import '../../domain/repositories/dictionary_repository.dart';
import '../datasources/dictionary_local_datasource.dart';

class DictionaryRepositoryImpl implements DictionaryRepository {
  const DictionaryRepositoryImpl(this._datasource);

  final DictionaryLocalDatasource _datasource;

  @override
  List<SignEntry> getAllSigns() => _datasource.readAll();
}
