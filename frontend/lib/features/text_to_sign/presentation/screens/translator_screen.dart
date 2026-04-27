import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:video_player/video_player.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../features/settings/presentation/providers/settings_provider.dart';
import '../../domain/entities/sign_token.dart';
import '../providers/text_to_sign_provider.dart';

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
  Timer? _debounce;

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

  void _onTextChanged(String text) {
    final ts = ref.read(textToSignProvider);
    if (ts.isLoading || ts.error != null) return;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      final trimmed = text.trim();
      if (trimmed.isEmpty) {
        ref.read(textToSignProvider.notifier).reset();
      } else {
        ref.read(textToSignProvider.notifier).translate(trimmed);
      }
    });
  }

  void _translateNow() {
    _debounce?.cancel();
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    ref.read(textToSignProvider.notifier).translate(text);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _stt.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sttEnabled = ref.watch(settingsProvider).sttEnabled;
    final ts = ref.watch(textToSignProvider);
    final notifier = ref.read(textToSignProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppTheme.darkBg, AppTheme.gradientDeep]
                : [AppTheme.softGrey, const Color(0xFFD6E2F0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),

              // ── Video Sahnesi — kamera kartıyla birebir aynı şablon ───────
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _VideoStage(
                    token: ts.currentToken,
                    isPlaying: ts.isPlaying,
                    isDark: isDark,
                    error: ts.error,
                    isLoading: ts.isLoading,
                    onRetry: notifier.retryInit,
                    onVideoEnd: () {
                      if (ts.isPlaying) notifier.next();
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Alt Panel — ResultPanel ile birebir aynı şablon ──────────
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white70,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (ts.hasTokens) ...[
                        _TokenStrip(
                          tokens: ts.tokens,
                          currentIndex: ts.currentIndex,
                          isDark: isDark,
                          onTap: notifier.goTo,
                        ).animate().fadeIn(duration: 200.ms),
                        const SizedBox(height: 8),
                        _PlaybackBar(
                          isPlaying: ts.isPlaying,
                          isFirst: ts.currentIndex == 0,
                          isLast: ts.isLastToken,
                          onPrev: notifier.previous,
                          onPlay: notifier.play,
                          onPause: notifier.pause,
                          onNext: notifier.next,
                        ).animate().fadeIn(duration: 200.ms),
                        const SizedBox(height: 12),
                      ],

                      // Metin giriş satırı
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              onChanged: _onTextChanged,
                              onSubmitted: (_) => _translateNow(),
                              decoration: InputDecoration(
                                hintText: 'Metni girin, otomatik çevrilir…',
                                filled: true,
                                fillColor: isDark
                                    ? AppTheme.darkBg.withValues(alpha: 0.5)
                                    : Colors.black.withValues(alpha: 0.04),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                suffixIcon: ts.hasTokens
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
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              textInputAction: TextInputAction.done,
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
                                    ? AppTheme.primaryBlue.withValues(alpha: 0.2)
                                    : (sttEnabled && _sttReady)
                                        ? AppTheme.primaryBlue
                                              .withValues(alpha: 0.12)
                                        : Colors.grey.withValues(alpha: 0.1),
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
                                    : Colors.grey.withValues(alpha: 0.5),
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Video Sahnesi — büyük, tam ekran benzeri video oynatıcı
// ─────────────────────────────────────────────────────────────────────────────

class _VideoStage extends StatefulWidget {
  const _VideoStage({
    required this.token,
    required this.isPlaying,
    required this.isDark,
    required this.error,
    required this.isLoading,
    required this.onRetry,
    required this.onVideoEnd,
  });

  final SignToken? token;
  final bool isPlaying;
  final bool isDark;
  final String? error;
  final bool isLoading;
  final VoidCallback onRetry;
  final VoidCallback onVideoEnd;

  @override
  State<_VideoStage> createState() => _VideoStageState();
}

class _VideoStageState extends State<_VideoStage> {
  VideoPlayerController? _ctrl;
  bool _initialized = false;
  bool _ended = false;
  String? _currentUrl;

  @override
  void didUpdateWidget(_VideoStage old) {
    super.didUpdateWidget(old);
    final token = widget.token;
    final newUrl = token is SignFound ? token.videoUrl : null;

    if (newUrl != _currentUrl) {
      _disposeCtrl();
      _currentUrl = newUrl;
      if (newUrl != null) _initCtrl(newUrl);
      return;
    }

    if (_initialized && widget.isPlaying != old.isPlaying) {
      if (widget.isPlaying) {
        _ctrl?.play();
      } else {
        _ctrl?.pause();
      }
    }
  }

  Future<void> _initCtrl(String url) async {
    _ended = false;
    final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
    _ctrl = ctrl;
    await ctrl.initialize();
    if (!mounted || _ctrl != ctrl) {
      ctrl.dispose();
      return;
    }
    ctrl.addListener(_onProgress);
    if (widget.isPlaying) ctrl.play();
    setState(() => _initialized = true);
  }

  void _onProgress() {
    if (_ctrl == null || _ended) return;
    final pos = _ctrl!.value.position;
    final dur = _ctrl!.value.duration;
    if (dur.inMilliseconds > 0 &&
        pos >= dur - const Duration(milliseconds: 200)) {
      _ended = true;
      widget.onVideoEnd();
    }
  }

  void _disposeCtrl() {
    _ctrl?.removeListener(_onProgress);
    _ctrl?.dispose();
    _ctrl = null;
    _currentUrl = null;
    _ended = false;
    if (mounted) setState(() => _initialized = false);
  }

  @override
  void dispose() {
    _disposeCtrl();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final token = widget.token;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── İçerik ────────────────────────────────────────────────────
            if (widget.error != null)
              _StageError(onRetry: widget.onRetry)
            else if (widget.isLoading)
              const _StageLoading()
            else if (token == null)
              const _StageEmpty()
            else if (token is SignNotFound)
              _StageNotFound(word: token.originalWord)
            else if (_initialized && _ctrl != null)
              FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: _ctrl!.value.size.width,
                  height: _ctrl!.value.size.height,
                  child: VideoPlayer(_ctrl!),
                ),
              )
            else
              _StageBuffering(
                word: token is SignFound ? token.matchedWord : null,
              ),

            // ── Kelime etiketi overlay ─────────────────────────────────────
            if (token != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.65),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        switch (token) {
                          SignFound() => token.originalWord,
                          SignNotFound() => token.originalWord,
                        },
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (token is SignFound &&
                          token.originalWord != token.matchedWord)
                        Text(
                          '→ ${token.matchedWord}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Sahne yardımcı widget'ları ────────────────────────────────────────────────

class _StageEmpty extends StatelessWidget {
  const _StageEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sign_language_outlined, size: 64, color: Colors.white24),
          SizedBox(height: 16),
          Text(
            'Metni girin, işaret dili\notomatik çevrilir',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 15,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StageLoading extends StatelessWidget {
  const _StageLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white38,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Hazırlanıyor…',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _StageBuffering extends StatelessWidget {
  const _StageBuffering({this.word});
  final String? word;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white54,
            ),
          ),
          if (word != null) ...[
            const SizedBox(height: 12),
            Text(
              word!,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}

class _StageNotFound extends StatelessWidget {
  const _StageNotFound({required this.word});
  final String word;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.help_outline_rounded,
            size: 48,
            color: Colors.white38,
          ),
          const SizedBox(height: 12),
          Text(
            '"$word"',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'için video bulunamadı',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _StageError extends StatelessWidget {
  const _StageError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.white38),
          const SizedBox(height: 12),
          const Text(
            'Kelime haritası yüklenemedi',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Tekrar Dene'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Token şeridi — yatay kaydırılabilir kelime chip'leri
// ─────────────────────────────────────────────────────────────────────────────

class _TokenStrip extends StatelessWidget {
  const _TokenStrip({
    required this.tokens,
    required this.currentIndex,
    required this.isDark,
    required this.onTap,
  });

  final List<SignToken> tokens;
  final int currentIndex;
  final bool isDark;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: tokens.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final token = tokens[i];
          final isActive = i == currentIndex;
          final hasVideo = token is SignFound;
          final word = switch (token) {
            SignFound() => token.originalWord,
            SignNotFound() => token.originalWord,
          };

          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.primaryBlue
                    : hasVideo
                        ? (isDark
                              ? Colors.white12
                              : Colors.black.withValues(alpha: 0.07))
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.black.withValues(alpha: 0.03)),
                borderRadius: BorderRadius.circular(20),
                border: isActive
                    ? null
                    : Border.all(
                        color: isDark
                            ? Colors.white12
                            : Colors.black.withValues(alpha: 0.1),
                      ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!hasVideo) ...[
                    Icon(
                      Icons.help_outline_rounded,
                      size: 12,
                      color: isActive
                          ? Colors.white70
                          : (isDark ? Colors.white38 : Colors.black38),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    word,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? Colors.white
                          : (hasVideo
                                ? (isDark ? Colors.white70 : Colors.black87)
                                : (isDark ? Colors.white38 : Colors.black45)),
                    ),
                  ),
                ],
              ),
            ),
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
