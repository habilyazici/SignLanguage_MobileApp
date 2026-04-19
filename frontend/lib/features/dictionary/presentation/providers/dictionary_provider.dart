import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/label_provider.dart';
import '../../data/datasources/dictionary_local_datasource.dart';
import '../../data/repositories/dictionary_repository_impl.dart';
import '../../domain/entities/sign_entry.dart';
import '../../domain/repositories/dictionary_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repository provider
// ─────────────────────────────────────────────────────────────────────────────

final _dictionaryRepositoryProvider = Provider<DictionaryRepository>(
  (ref) => DictionaryRepositoryImpl(
    DictionaryLocalDatasource(ref.read(labelRepositoryProvider)),
  ),
);

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class DictionaryState {
  final List<SignEntry> allSigns;
  final List<SignEntry> filteredSigns;
  final String query;
  final String? selectedLetter;

  const DictionaryState({
    this.allSigns = const [],
    this.filteredSigns = const [],
    this.query = '',
    this.selectedLetter,
  });

  DictionaryState copyWith({
    List<SignEntry>? allSigns,
    List<SignEntry>? filteredSigns,
    String? query,
    Object? selectedLetter = _sentinel,
  }) =>
      DictionaryState(
        allSigns: allSigns ?? this.allSigns,
        filteredSigns: filteredSigns ?? this.filteredSigns,
        query: query ?? this.query,
        selectedLetter: selectedLetter == _sentinel
            ? this.selectedLetter
            : selectedLetter as String?,
      );
}

// null ile "değer verilmedi" ayrımı için sentinel nesne
const _sentinel = Object();

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

final dictionaryProvider =
    NotifierProvider<DictionaryNotifier, DictionaryState>(
  DictionaryNotifier.new,
);

class DictionaryNotifier extends Notifier<DictionaryState> {
  @override
  DictionaryState build() {
    final repo = ref.read(_dictionaryRepositoryProvider);
    final all = repo.getAllSigns()
      ..sort((a, b) => _trLower(a.label).compareTo(_trLower(b.label)));
    return DictionaryState(allSigns: all, filteredSigns: all);
  }

  void setQuery(String raw) {
    final q = raw.trim().toLowerCase();
    final filtered = q.isEmpty
        ? state.allSigns
        : state.allSigns
            .where((s) => _trLower(s.label).contains(q))
            .toList();
    state = state.copyWith(
      query: q,
      filteredSigns: filtered,
      selectedLetter: null,
    );
  }

  void setLetter(String? letter) {
    final filtered = letter == null
        ? state.allSigns
        : state.allSigns
            .where(
              (s) =>
                  s.label.isNotEmpty &&
                  _trLower(s.label[0]) == _trLower(letter),
            )
            .toList();
    state = state.copyWith(
      selectedLetter: letter,
      filteredSigns: filtered,
      query: '',
    );
  }

  // ── Türkçe küçük harf normalizer ─────────────────────────────────────────

  static String _trLower(String s) => s
      .toLowerCase()
      .replaceAll('İ', 'i')
      .replaceAll('I', 'ı')
      .replaceAll('Ğ', 'ğ')
      .replaceAll('Ü', 'ü')
      .replaceAll('Ş', 'ş')
      .replaceAll('Ö', 'ö')
      .replaceAll('Ç', 'ç');
}
