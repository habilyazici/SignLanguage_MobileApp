import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../features/settings/presentation/providers/settings_provider.dart';
import '../../domain/entities/sign_token.dart';
import '../providers/text_to_sign_provider.dart';
import '../widgets/sign_token_card.dart';

class TranslatorScreen extends ConsumerStatefulWidget {
  const TranslatorScreen({super.key});

  @override
  ConsumerState<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends ConsumerState<TranslatorScreen> {
  final _controller = TextEditingController();
  final _stt = SpeechToText();
  bool _sttReady = false;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _initStt();
  }

  Future<void> _initStt() async {
    final ready = await _stt.initialize();
    if (mounted) setState(() => _sttReady = ready);
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await _stt.stop();
      setState(() => _listening = false);
      return;
    }

    setState(() => _listening = true);
    await _stt.listen(
      onResult: (result) {
        if (result.finalResult) {
          final text = result.recognizedWords;
          _controller.text = text;
          setState(() => _listening = false);
          if (text.trim().isNotEmpty) {
            ref.read(textToSignProvider.notifier).translate(text);
          }
        }
      },
      localeId: 'tr_TR',
    );
  }

  void _translate() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    ref.read(textToSignProvider.notifier).translate(text);
  }

  @override
  void dispose() {
    _controller.dispose();
    _stt.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sttEnabled = ref.watch(settingsProvider).sttEnabled;
    final ttsState = ref.watch(textToSignProvider);
    final notifier = ref.read(textToSignProvider.notifier);
    final manifestReady = !ttsState.isLoading || ttsState.hasTokens;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ── Token grid veya boş alan ──────────────────────────────────
            Expanded(
              flex: 5, // Kamera kartı (Recognition) ile birebir aynı yükseklik!
              child: ttsState.hasTokens
                  ? _TokenGrid(
                      tokens: ttsState.tokens,
                      currentIndex: ttsState.currentIndex,
                      isPlaying: ttsState.isPlaying,
                      onVideoEnd: () {
                        if (ttsState.isPlaying) notifier.next();
                      },
                      onTap: (i) => notifier.goTo(i),
                    )
                  : _EmptyArea(isDark: isDark),
            ),

            const SizedBox(height: 16),

            // ── Alt Kontroller (Oynatma, Metin, Buton) ────────────────────
            Expanded(
              flex:
                  3, // Recognition'daki ResultPanel ile birebir aynı alan boyutu
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment
                              .end, // Yukarıdan boşluk bırakır, aşağı yaslar
                          children: [
                            if (ttsState.hasTokens)
                              _PlaybackBar(
                                isPlaying: ttsState.isPlaying,
                                isFirst: ttsState.currentIndex == 0,
                                isLast: ttsState.isLastToken,
                                onPrev: notifier.previous,
                                onPlay: notifier.play,
                                onPause: notifier.pause,
                                onNext: notifier.next,
                              ).animate().fadeIn(duration: 200.ms),

                            if (ttsState.hasTokens) const SizedBox(height: 12),

                            // ── Metin giriş alanı ──────────────────────────────
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _controller,
                                      decoration: InputDecoration(
                                        hintText: 'Çevrilecek metni girin...',
                                        filled: true,
                                        fillColor: isDark
                                            ? AppTheme.darkSurface
                                            : Colors.black.withValues(
                                                alpha: 0.04,
                                              ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        suffixIcon: ttsState.hasTokens
                                            ? IconButton(
                                                icon: const Icon(
                                                  Icons.close_rounded,
                                                  size: 20,
                                                ),
                                                onPressed: () {
                                                  notifier.reset();
                                                  _controller.clear();
                                                },
                                                tooltip: 'Tümünü Sıfırla',
                                              )
                                            : null,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                      ),
                                      textInputAction: TextInputAction.search,
                                      onSubmitted: (_) => _translate(),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: (sttEnabled && _sttReady)
                                        ? _toggleListening
                                        : null,
                                    child: Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: _listening
                                            ? AppTheme.primaryBlue.withValues(
                                                alpha: 0.2,
                                              )
                                            : (sttEnabled && _sttReady)
                                            ? AppTheme.primaryBlue.withValues(
                                                alpha: 0.12,
                                              )
                                            : Colors.grey.withValues(
                                                alpha: 0.1,
                                              ),
                                        shape: BoxShape.circle,
                                        border: _listening
                                            ? Border.all(
                                                color: AppTheme.primaryBlue,
                                                width: 2,
                                              )
                                            : null,
                                      ),
                                      child: Icon(
                                        _listening
                                            ? Icons.mic_rounded
                                            : (sttEnabled
                                                  ? Icons.mic_none_rounded
                                                  : Icons.mic_off_rounded),
                                        color: (sttEnabled && _sttReady)
                                            ? AppTheme.primaryBlue
                                            : Colors.grey.withValues(
                                                alpha: 0.5,
                                              ),
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: 150.ms, duration: 300.ms),

                            const SizedBox(height: 16),

                            // ── Çevir butonu ──────────────────────────────────
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              child: SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: FilledButton.icon(
                                  onPressed: manifestReady ? _translate : null,
                                  icon: manifestReady
                                      ? const Icon(Icons.translate_rounded)
                                      : const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white54,
                                          ),
                                        ),
                                  label: Text(
                                    manifestReady ? 'Çevir' : 'Hazırlanıyor…',
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppTheme.primaryBlue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Token grid
// ─────────────────────────────────────────────────────────────────────────────

class _TokenGrid extends StatelessWidget {
  const _TokenGrid({
    required this.tokens,
    required this.currentIndex,
    required this.isPlaying,
    required this.onVideoEnd,
    required this.onTap,
  });

  final List<SignToken> tokens;
  final int currentIndex;
  final bool isPlaying;
  final VoidCallback onVideoEnd;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 140,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.75,
        ),
        itemCount: tokens.length,
        itemBuilder: (_, i) {
          final token = tokens[i];
          final isActive = i == currentIndex;

          return GestureDetector(
            onTap: () => onTap(i),
            child: switch (token) {
              SignFound() => SignFoundCard(
                token: token,
                isActive: isActive && isPlaying,
                onVideoEnd: onVideoEnd,
              ),
              SignNotFound() => SignNotFoundCard(token: token),
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Oynatma kontrol çubuğu
// ─────────────────────────────────────────────────────────────────────────────

class _PlaybackBar extends StatelessWidget {
  const _PlaybackBar({
    required this.isPlaying,
    required this.isFirst,
    required this.isLast,
    required this.onPrev,
    required this.onPlay,
    required this.onPause,
    required this.onNext,
  });

  final bool isPlaying;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onPrev;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded),
          onPressed: isFirst ? null : onPrev,
          iconSize: 28,
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: isPlaying ? onPause : onPlay,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(14),
          ),
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 28,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.skip_next_rounded),
          onPressed: isLast ? null : onNext,
          iconSize: 28,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Boş alan (henüz çeviri yapılmamış)
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyArea extends StatelessWidget {
  const _EmptyArea({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkSurface
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sign_language_outlined,
              size: 56,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
            const SizedBox(height: 12),
            Text(
              'Metni girin ve "Çevir"e basın',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white38 : AppTheme.midGrey,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
  }
}
