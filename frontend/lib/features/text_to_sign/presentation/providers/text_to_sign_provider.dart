import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/manifest_datasource.dart';
import '../../data/repositories/text_to_sign_repository_impl.dart';
import '../../domain/entities/sign_token.dart';
import '../../domain/repositories/text_to_sign_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repository provider
// ─────────────────────────────────────────────────────────────────────────────

final _textToSignRepositoryProvider = Provider<TextToSignRepository>((ref) {
  return TextToSignRepositoryImpl(
    datasource: const ManifestDatasource(),
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class TextToSignState {
  final List<SignToken> tokens;
  final int currentIndex;
  final bool isPlaying;
  final bool isLoading;
  final String inputText;

  const TextToSignState({
    this.tokens = const [],
    this.currentIndex = 0,
    this.isPlaying = false,
    this.isLoading = false,
    this.inputText = '',
  });

  bool get hasTokens => tokens.isNotEmpty;
  bool get isLastToken => currentIndex >= tokens.length - 1;

  SignToken? get currentToken => tokens.isEmpty ? null : tokens[currentIndex];

  TextToSignState copyWith({
    List<SignToken>? tokens,
    int? currentIndex,
    bool? isPlaying,
    bool? isLoading,
    String? inputText,
  }) => TextToSignState(
    tokens: tokens ?? this.tokens,
    currentIndex: currentIndex ?? this.currentIndex,
    isPlaying: isPlaying ?? this.isPlaying,
    isLoading: isLoading ?? this.isLoading,
    inputText: inputText ?? this.inputText,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

final textToSignProvider =
    NotifierProvider<TextToSignNotifier, TextToSignState>(
      TextToSignNotifier.new,
    );

class TextToSignNotifier extends Notifier<TextToSignState> {
  late final TextToSignRepository _repo;

  @override
  TextToSignState build() {
    _repo = ref.read(_textToSignRepositoryProvider);
    _repo.initialize();
    return const TextToSignState();
  }

  /// Metni parse edip token listesi oluşturur
  void translate(String text) {
    if (text.trim().isEmpty) return;
    final tokens = _repo.parse(text);
    state = state.copyWith(
      tokens: tokens,
      currentIndex: 0,
      isPlaying: false,
      inputText: text,
    );
  }

  /// Oynatmayı başlatır / devam ettirir
  void play() => state = state.copyWith(isPlaying: true);

  /// Oynatmayı duraklatır
  void pause() => state = state.copyWith(isPlaying: false);

  /// Sonraki kelimeye geç — video bitince çağrılır
  void next() {
    if (state.isLastToken) {
      state = state.copyWith(isPlaying: false);
      return;
    }
    state = state.copyWith(currentIndex: state.currentIndex + 1);
  }

  /// Önceki kelimeye geç
  void previous() {
    if (state.currentIndex == 0) return;
    state = state.copyWith(
      currentIndex: state.currentIndex - 1,
      isPlaying: false,
    );
  }

  /// Belirli bir token'a git
  void goTo(int index) {
    if (index < 0 || index >= state.tokens.length) return;
    state = state.copyWith(currentIndex: index, isPlaying: false);
  }

  /// Çeviriyi sıfırla
  void reset() => state = const TextToSignState();
}
