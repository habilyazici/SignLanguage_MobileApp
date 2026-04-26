import '../entities/history_item.dart';

abstract class HistoryRepository {
  Future<List<HistoryItem>> fetchHistory();
  Future<HistoryItem> addHistory(String text);
  Future<void> deleteHistory(String id);
  Future<void> clearAllHistory();
}
