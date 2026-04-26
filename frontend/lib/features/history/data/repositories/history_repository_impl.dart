import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/history_item.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_api_datasource.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final datasource = ref.watch(historyDatasourceProvider);
  return HistoryRepositoryImpl(datasource);
});

class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryApiDatasource _datasource;
  const HistoryRepositoryImpl(this._datasource);

  @override
  Future<List<HistoryItem>> fetchHistory() => _datasource.fetchHistory();

  @override
  Future<HistoryItem> addHistory(String text) => _datasource.addHistory(text);

  @override
  Future<void> deleteHistory(String id) => _datasource.deleteHistory(id);

  @override
  Future<void> clearAllHistory() => _datasource.clearAllHistory();
}
