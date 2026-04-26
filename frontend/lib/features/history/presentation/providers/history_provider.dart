import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class HistoryItem {
  final String id;
  final String text;
  final DateTime createdAt;

  const HistoryItem({
    required this.id,
    required this.text,
    required this.createdAt,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> j) => HistoryItem(
        id: j['id'] as String,
        text: j['text'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
      );
}

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
    final auth = ref.watch(authProvider);
    if (auth.isAuthenticated) Future.microtask(_fetch);
    return const HistoryState();
  }

  Future<void> _fetch() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ref.apiGet('/api/history');
      if (res.statusCode == 200) {
        final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
        state = state.copyWith(
          items: list.map(HistoryItem.fromJson).toList(),
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false, error: 'Geçmiş yüklenemedi.');
      }
    } on UnauthorizedException {
      state = state.copyWith(isLoading: false, items: []);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Bağlantı hatası.');
    }
  }

  /// Yeni kelime/cümle ekle — recognition provider'dan çağrılır.
  Future<void> add(String text) async {
    if (text.trim().isEmpty) return;
    try {
      final res = await ref.apiPost('/api/history', body: {'text': text.trim()});
      if (res.statusCode == 201) {
        final item = HistoryItem.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>,
        );
        state = state.copyWith(items: [item, ...state.items]);
      }
    } catch (_) {
      // Sessiz hata — tanıma akışını engellemez
    }
  }

  /// Optimistic silme.
  Future<void> delete(String id) async {
    final prev = state.items;
    state = state.copyWith(items: prev.where((i) => i.id != id).toList());
    try {
      final res = await ref.apiDelete('/api/history/$id');
      if (res.statusCode != 204) state = state.copyWith(items: prev);
    } on UnauthorizedException {
      state = state.copyWith(items: []);
    } catch (_) {
      state = state.copyWith(items: prev);
    }
  }

  /// Tüm geçmişi tek istekle sil.
  Future<void> clearAll() async {
    final prev = state.items;
    state = state.copyWith(items: []);
    try {
      final res = await ref.apiDelete('/api/history');
      if (res.statusCode != 204) state = state.copyWith(items: prev);
    } on UnauthorizedException {
      state = state.copyWith(items: []);
    } catch (_) {
      state = state.copyWith(items: prev);
    }
  }

  void retry() => _fetch();
}
