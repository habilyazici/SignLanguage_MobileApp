import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/sign_entry.dart';
import '../../domain/repositories/dictionary_repository.dart';
import '../datasources/dictionary_api_datasource.dart';

final dictionaryRepositoryProvider = Provider<DictionaryRepository>((ref) {
  final datasource = ref.watch(dictionaryDatasourceProvider);
  return DictionaryRepositoryImpl(datasource);
});

class DictionaryRepositoryImpl implements DictionaryRepository {
  final DictionaryApiDatasource _datasource;
  const DictionaryRepositoryImpl(this._datasource);

  @override
  Future<List<SignEntry>> fetchAll() => _datasource.fetchAll();
}
