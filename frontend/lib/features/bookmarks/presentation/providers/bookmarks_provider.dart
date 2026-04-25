import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

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

final bookmarksProvider =
    NotifierProvider<BookmarksNotifier, BookmarksState>(BookmarksNotifier.new);

class BookmarksNotifier extends Notifier<BookmarksState> {
  @override
  BookmarksState build() {
    final auth = ref.watch(authProvider);
    if (auth.isAuthenticated) Future.microtask(_fetch);
    return const BookmarksState();
  }

  Future<void> _fetch() async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final res = await http.get(
        Uri.parse('$kApiBaseUrl/api/bookmarks'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
        final ids = list.map((b) => b['wordId'] as int).toSet();
        state = state.copyWith(wordIds: ids, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> toggle(int wordId) async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    final wasBookmarked = state.wordIds.contains(wordId);

    // Optimistic update
    final newIds = Set<int>.from(state.wordIds);
    if (wasBookmarked) {
      newIds.remove(wordId);
    } else {
      newIds.add(wordId);
    }
    state = state.copyWith(wordIds: newIds);

    try {
      if (wasBookmarked) {
        await http.delete(
          Uri.parse('$kApiBaseUrl/api/bookmarks/$wordId'),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 10));
      } else {
        await http.post(
          Uri.parse('$kApiBaseUrl/api/bookmarks/$wordId'),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 10));
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
