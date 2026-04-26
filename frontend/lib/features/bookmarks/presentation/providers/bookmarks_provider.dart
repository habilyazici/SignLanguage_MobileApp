import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/bookmarks_repository_impl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class BookmarksState {
  final Set<int> wordIds;
  final bool isLoading;

  const BookmarksState({this.wordIds = const {}, this.isLoading = false});

  BookmarksState copyWith({Set<int>? wordIds, bool? isLoading}) => BookmarksState(
        wordIds: wordIds ?? this.wordIds,
        isLoading: isLoading ?? this.isLoading,
      );

  bool contains(int wordId) => wordIds.contains(wordId);
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final bookmarksProvider =
    NotifierProvider<BookmarksNotifier, BookmarksState>(BookmarksNotifier.new);

class BookmarksNotifier extends Notifier<BookmarksState> {
  @override
  BookmarksState build() {
    final isAuthenticated = ref.watch(
      authProvider.select((a) => a.isAuthenticated),
    );
    if (isAuthenticated) Future.microtask(_fetch);
    return const BookmarksState();
  }

  Future<void> _fetch() async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(bookmarksRepositoryProvider);
      final ids = await repo.fetchBookmarks();
      state = state.copyWith(wordIds: ids, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> toggle(int wordId) async {
    final wasBookmarked = state.wordIds.contains(wordId);

    // Optimistic Update (Hızlı geri bildirim için önce arayüzü güncelle)
    final newIds = Set<int>.from(state.wordIds);
    if (wasBookmarked) {
      newIds.remove(wordId);
    } else {
      newIds.add(wordId);
    }
    state = state.copyWith(wordIds: newIds);

    try {
      final repo = ref.read(bookmarksRepositoryProvider);
      if (wasBookmarked) {
        await repo.deleteBookmark(wordId);
      } else {
        await repo.addBookmark(wordId);
      }
    } catch (_) {
      // Hata durumunda optimistic update'i geri al
      final revert = Set<int>.from(state.wordIds);
      if (wasBookmarked) {
        revert.add(wordId);
      } else {
        revert.remove(wordId);
      }
      state = state.copyWith(wordIds: revert);
    }
  }
}
