import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/bookmarks_api_datasource.dart';

final bookmarksRepositoryProvider = Provider<BookmarksRepository>((ref) {
  final datasource = ref.watch(bookmarksDatasourceProvider);
  return BookmarksRepositoryImpl(datasource);
});

abstract class BookmarksRepository {
  Future<Set<int>> fetchBookmarks();
  Future<void> addBookmark(int wordId);
  Future<void> deleteBookmark(int wordId);
}

class BookmarksRepositoryImpl implements BookmarksRepository {
  final BookmarksApiDatasource _datasource;
  const BookmarksRepositoryImpl(this._datasource);

  @override
  Future<Set<int>> fetchBookmarks() => _datasource.fetchBookmarks();

  @override
  Future<void> addBookmark(int wordId) => _datasource.addBookmark(wordId);

  @override
  Future<void> deleteBookmark(int wordId) => _datasource.deleteBookmark(wordId);
}
