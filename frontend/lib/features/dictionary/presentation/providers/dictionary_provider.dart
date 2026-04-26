import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/turkish_normalizer.dart';
import '../../data/repositories/dictionary_repository_impl.dart';
import '../../domain/entities/sign_entry.dart';



// ─────────────────────────────────────────────────────────────────────────────

class DictionaryState {
  final List<SignEntry> allSigns;
  final List<SignEntry> filteredSigns;
  final String query;
  final String? selectedLetter;
  final bool isLoading;
  final String? error;

  const DictionaryState({
    this.allSigns = const [],
    this.filteredSigns = const [],
    this.query = '',
    this.selectedLetter,
    this.isLoading = false,
    this.error,
  });

  DictionaryState copyWith({
    List<SignEntry>? allSigns,
    List<SignEntry>? filteredSigns,
    String? query,
    Object? selectedLetter = _sentinel,
    bool? isLoading,
    Object? error = _sentinel,
  }) => DictionaryState(
    allSigns: allSigns ?? this.allSigns,
    filteredSigns: filteredSigns ?? this.filteredSigns,
    query: query ?? this.query,
    selectedLetter: selectedLetter == _sentinel ? this.selectedLetter : selectedLetter as String?,
    isLoading: isLoading ?? this.isLoading,
    error: error == _sentinel ? this.error : error as String?,
  );
}

const _sentinel = Object();

// ─────────────────────────────────────────────────────────────────────────────

final dictionaryProvider =
    NotifierProvider<DictionaryNotifier, DictionaryState>(DictionaryNotifier.new);

class DictionaryNotifier extends Notifier<DictionaryState> {
  @override
  DictionaryState build() {
    Future.microtask(_load);
    return const DictionaryState(isLoading: true);
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(dictionaryRepositoryProvider);
      final all = await repo.fetchAll()
        ..sort((a, b) => TurkishNormalizer.trLower(a.label)
            .compareTo(TurkishNormalizer.trLower(b.label)));
      state = state.copyWith(allSigns: all, filteredSigns: all, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Veriler yüklenemedi.');
    }
  }

  void setQuery(String raw) {
    final q = TurkishNormalizer.trLower(raw.trim());
    final filtered = q.isEmpty
        ? state.allSigns
        : state.allSigns
            .where((s) => TurkishNormalizer.trLower(s.label).contains(q))
            .toList();
    state = state.copyWith(query: q, filteredSigns: filtered, selectedLetter: null);
  }

  void setLetter(String? letter) {
    final filtered = letter == null
        ? state.allSigns
        : state.allSigns
            .where((s) =>
                s.label.isNotEmpty &&
                TurkishNormalizer.trLower(s.label[0]) ==
                    TurkishNormalizer.trLower(letter))
            .toList();
    state = state.copyWith(selectedLetter: letter, filteredSigns: filtered, query: '');
  }

  void retry() {
    state = state.copyWith(isLoading: true, error: null);
    _load();
  }
}
