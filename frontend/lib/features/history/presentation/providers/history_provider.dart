import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/sentinel.dart';
import '../../data/repositories/history_repository_impl.dart';
import '../../domain/entities/history_item.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class HistoryState {
  final List<HistoryItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  const HistoryState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  HistoryState copyWith({
    List<HistoryItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error = sentinel,
  }) => HistoryState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: error == sentinel ? this.error : error as String?,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final historyProvider =
    NotifierProvider<HistoryNotifier, HistoryState>(HistoryNotifier.new);

class HistoryNotifier extends Notifier<HistoryState> {
  static const _pageSize = 50;
  int _offset = 0;

  @override
  HistoryState build() {
    final isAuthenticated = ref.watch(
      authProvider.select((a) => a.isAuthenticated),
    );
    if (isAuthenticated) Future.microtask(_fetch);
    return const HistoryState();
  }

  Future<void> _fetch() async {
    _offset = 0;
    state = state.copyWith(isLoading: true, error: null, hasMore: true);
    try {
      final repo = ref.read(historyRepositoryProvider);
      final items = await repo.fetchHistory(offset: 0, limit: _pageSize);
      _offset = items.length;
      state = state.copyWith(
        items: items,
        isLoading: false,
        hasMore: items.length == _pageSize,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Geçmiş yüklenemedi.');
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final repo = ref.read(historyRepositoryProvider);
      final more = await repo.fetchHistory(offset: _offset, limit: _pageSize);
      _offset += more.length;
      state = state.copyWith(
        items: [...state.items, ...more],
        isLoadingMore: false,
        hasMore: more.length == _pageSize,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Yeni kelime/cümle ekle — recognition provider'dan çağrılır.
  Future<void> add(String text) async {
    if (text.trim().isEmpty) return;
    try {
      final repo = ref.read(historyRepositoryProvider);
      final item = await repo.addHistory(text.trim());
      _offset++;
      state = state.copyWith(items: [item, ...state.items]);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ History add hatası: $e');
    }
  }

  /// Optimistic silme.
  Future<void> delete(String id) async {
    final prev = state.items;
    state = state.copyWith(items: prev.where((i) => i.id != id).toList());
    _offset = state.items.length;
    try {
      final repo = ref.read(historyRepositoryProvider);
      await repo.deleteHistory(id);
    } catch (_) {
      state = state.copyWith(items: prev);
      _offset = prev.length;
    }
  }

  /// Tüm geçmişi tek istekle sil.
  Future<void> clearAll() async {
    final prev = state.items;
    _offset = 0;
    state = state.copyWith(items: [], hasMore: false);
    try {
      final repo = ref.read(historyRepositoryProvider);
      await repo.clearAllHistory();
    } catch (_) {
      state = state.copyWith(items: prev, hasMore: true);
      _offset = prev.length;
    }
  }

  void retry() => _fetch();
}
