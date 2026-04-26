import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/history_repository_impl.dart';
import '../../domain/entities/history_item.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class HistoryState {
  final List<HistoryItem> items;
  final bool isLoading;
  final String? error;

  const HistoryState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  HistoryState copyWith({
    List<HistoryItem>? items,
    bool? isLoading,
    Object? error = _sentinel,
  }) => HistoryState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        error: error == _sentinel ? this.error : error as String?,
      );
}

const _sentinel = Object();

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final historyProvider =
    NotifierProvider<HistoryNotifier, HistoryState>(HistoryNotifier.new);

class HistoryNotifier extends Notifier<HistoryState> {
  @override
  HistoryState build() {
    final isAuthenticated = ref.watch(
      authProvider.select((a) => a.isAuthenticated),
    );
    if (isAuthenticated) Future.microtask(_fetch);
    return const HistoryState();
  }

  Future<void> _fetch() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(historyRepositoryProvider);
      final items = await repo.fetchHistory();
      state = state.copyWith(items: items, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Geçmiş yüklenemedi.');
    }
  }

  /// Yeni kelime/cümle ekle — recognition provider'dan çağrılır.
  Future<void> add(String text) async {
    if (text.trim().isEmpty) return;
    try {
      final repo = ref.read(historyRepositoryProvider);
      final item = await repo.addHistory(text.trim());
      state = state.copyWith(items: [item, ...state.items]);
    } catch (_) {
      // Sessiz hata — tanıma akışını engellemez
    }
  }

  /// Optimistic silme.
  Future<void> delete(String id) async {
    final prev = state.items;
    state = state.copyWith(items: prev.where((i) => i.id != id).toList());
    try {
      final repo = ref.read(historyRepositoryProvider);
      await repo.deleteHistory(id);
    } catch (_) {
      state = state.copyWith(items: prev);
    }
  }

  /// Tüm geçmişi tek istekle sil.
  Future<void> clearAll() async {
    final prev = state.items;
    state = state.copyWith(items: []);
    try {
      final repo = ref.read(historyRepositoryProvider);
      await repo.clearAllHistory();
    } catch (_) {
      state = state.copyWith(items: prev);
    }
  }

  void retry() => _fetch();
}
