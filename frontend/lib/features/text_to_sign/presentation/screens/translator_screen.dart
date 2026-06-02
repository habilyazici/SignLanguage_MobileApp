import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:video_player/video_player.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/providers/camera_lifecycle_provider.dart';
import '../../../../../core/providers/translation_tab_provider.dart';
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
  bool _sttInitializing = false;
  bool _listening = false;
  bool _continuous = true; // sürekli dinleme modu
  int _sttFailCount = 0; // sonsuz retry döngüsünü önler
  static const _maxSttFails = 5;
  Timer? _debounce;
  Timer? _restartDelay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initStt());
  }

  Future<void> _initStt() async {
    if (_sttInitializing || _sttReady) return;

    // TabBarView her iki çocuğu önceden inşa eder; tab 0 aktifken
    // STT init edilmemeli.
    if (ref.read(translationTabProvider) != 1) return;

    _sttInitializing = true;
    try {
      // iOS: kamera ve mikrofon aynı AVAudioSession'ı kullanır.
      // Kamera donanımı tamamen serbest kalana kadar STT init edilmemeli.
      // waitForRelease(), pauseCamera() + _camera.release() tamamlandığında
      // döner — sabit delay yerine kesin sinyal.
      if (Platform.isIOS) {
        await ref.read(cameraActiveProvider.notifier).waitForRelease();
        // Hızlı tab geçişinde (0→1→0) kamera yeniden aktif olmuş olabilir.
        if (!mounted || ref.read(translationTabProvider) != 1) return;
      }
      final ready = await _stt.initialize(
        onError: (error) {
          if (!mounted) return;
          setState(() => _listening = false);
          _sttFailCount++;
          if (_continuous && ref.read(settingsProvider).sttEnabled &&
              _sttFailCount < _maxSttFails) {
            _restartDelay?.cancel();
            _restartDelay = Timer(const Duration(milliseconds: 800), _startListening);
          }
        },
      );
      if (!mounted) return;
      setState(() => _sttReady = ready);
      if (ready && ref.read(settingsProvider).sttEnabled) {
        _startListening();
      }
    } finally {
      _sttInitializing = false;
    }
  }

  Future<void> _startListening() async {
    if (!_sttReady || _listening || !mounted) return;
    setState(() => _listening = true);

    final started = await _stt.listen(
      onResult: (result) {
        if (!result.finalResult) return;
        final text = result.recognizedWords.trim();
        if (text.isNotEmpty) {
          _controller.text = text;
          // Yeni konuşma → eski çeviriyi tamamen değiştir
          ref.read(textToSignProvider.notifier).translate(text);
        }
        if (!mounted) return;
        setState(() => _listening = false);
        _sttFailCount = 0; // başarılı tanıma — hata sayacını sıfırla
        // Sürekli modda: 600ms bekle, yeniden dinle
        if (_continuous && ref.read(settingsProvider).sttEnabled) {
          _restartDelay?.cancel();
          _restartDelay = Timer(const Duration(milliseconds: 600), _startListening);
        }
      },
      localeId: 'tr_TR',
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(cancelOnError: false),
    );

    // listen() false döndüyse (başlatılamadı) durumu düzelt
    if (!started && mounted) {
      setState(() => _listening = false);
      _sttFailCount++;
      if (_continuous && ref.read(settingsProvider).sttEnabled &&
          _sttFailCount < _maxSttFails) {
        _restartDelay?.cancel();
        _restartDelay = Timer(const Duration(seconds: 1), _startListening);
      }
    }
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      _continuous = false;
      _restartDelay?.cancel();
      await _stt.stop();
      if (mounted) setState(() => _listening = false);
    } else {
      // İlk basışta lazy init — STT henüz başlatılmadıysa başlat
      if (!_sttReady) {
        await _initStt();
        if (!_sttReady || !mounted) return;
      }
      _continuous = true;
      _sttFailCount = 0;
      _startListening();
    }
  }

  void _onTextChanged(String text) {
    final ts = ref.read(textToSignProvider);
    // Hata durumunda kullanıcı yeniden denemeli; yükleme sırasında timer kurulsun.
    if (ts.error != null) return;

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
    _restartDelay?.cancel();
    _continuous = false;
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

    // Tab 1'e geçildiğinde STT'yi otomatik başlat.
    ref.listen(translationTabProvider, (_, next) {
      if (next == 1 && !_sttReady) _initStt();
    });

    // Tüm cümle oynatıldığında ses + titreşim — konuşan kişi ekrana bakamıyor.
    ref.listen<TextToSignState>(textToSignProvider, (prev, next) {
      if (prev != null &&
          prev.isPlaying &&
          !next.isPlaying &&
          next.hasTokens &&
          next.isLastToken) {
        HapticFeedback.mediumImpact();
        SystemSound.play(SystemSoundType.alert);
      }
    });

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
              const SizedBox(height: 8),

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

              const SizedBox(height: 12),

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
                        const SizedBox(height: 4),
                        _PlaybackBar(
                          isPlaying: ts.isPlaying,
                          isFirst: ts.currentIndex == 0,
                          isLast: ts.isLastToken,
                          onPrev: notifier.previous,
                          onPlay: notifier.play,
                          onPause: notifier.pause,
                          onNext: notifier.next,
                          onRestart: notifier.restart,
                        ).animate().fadeIn(duration: 200.ms),
                        const SizedBox(height: 6),
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
                            // !_sttReady olsa da tıklanabilir: _toggleListening
                            // içinde _initStt() yeniden denenir (lazy retry).
                            onTap: sttEnabled ? _toggleListening : null,
                            child: _MicButton(
                              listening: _listening,
                              enabled: sttEnabled && _sttReady,
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
  Timer? _notFoundTimer;
  Object? _currentTokenRef;

  @override
  void didUpdateWidget(_VideoStage old) {
    super.didUpdateWidget(old);
    final token = widget.token;
    final newUrl = token is SignFound ? token.videoUrl : null;

    // Token nesnesi (referans) veya URL değiştiyse yeni kelimeye geç.
    if (!identical(token, _currentTokenRef) || newUrl != _currentUrl) {
      _disposeCtrl();
      _currentUrl = newUrl;
      _currentTokenRef = token;
      if (newUrl != null) {
        _initCtrl(newUrl);
      } else if (token is SignNotFound && widget.isPlaying) {
        // Bilinmeyen kelime — 1.5s göster, sonra sonraki kelimeye geç.
        _startNotFoundTimer();
      }
      return;
    }

    if (widget.isPlaying != old.isPlaying) {
      if (token is SignNotFound) {
        if (widget.isPlaying) {
          _startNotFoundTimer();
        } else {
          _notFoundTimer?.cancel();
          _notFoundTimer = null;
        }
      } else if (_initialized) {
        if (widget.isPlaying) {
          if (_ended) {
            _ended = false;
            _ctrl?.seekTo(Duration.zero).then((_) {
              if (mounted && widget.isPlaying) _ctrl?.play();
            });
          } else {
            _ctrl?.play();
          }
        } else {
          _ctrl?.pause();
        }
      }
    }
  }

  void _startNotFoundTimer() {
    _notFoundTimer?.cancel();
    _notFoundTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted && widget.isPlaying) widget.onVideoEnd();
    });
  }

  Future<void> _initCtrl(String url) async {
    _ended = false;
    final ctrl = VideoPlayerController.networkUrl(
      Uri.parse(url),
      httpHeaders: kNgrokHeaders,
    );
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
    _notFoundTimer?.cancel();
    _notFoundTimer = null;
    _ctrl?.removeListener(_onProgress);
    _ctrl?.dispose();
    _ctrl = null;
    _currentUrl = null;
    _currentTokenRef = null;
    _ended = false;
    if (mounted) setState(() => _initialized = false);
  }

  @override
  void dispose() {
    _notFoundTimer?.cancel();
    _ctrl?.removeListener(_onProgress);
    _ctrl?.dispose();
    _ctrl = null;
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          word,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
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

class _TokenStrip extends StatefulWidget {
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
  State<_TokenStrip> createState() => _TokenStripState();
}

class _TokenStripState extends State<_TokenStrip> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_TokenStrip old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive());
    }
  }

  void _scrollToActive() {
    if (!_scrollController.hasClients) return;
    // Her chip ortalama 80px genişliğinde + 6px separator
    const itemWidth = 86.0;
    final targetOffset = widget.currentIndex * itemWidth;
    final viewWidth = _scrollController.position.viewportDimension;
    final offset = (targetOffset - viewWidth / 2 + itemWidth / 2).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: widget.tokens.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final tokens = widget.tokens;
          final currentIndex = widget.currentIndex;
          final isDark = widget.isDark;
          final token = tokens[i];
          final isActive = i == currentIndex;
          final hasVideo = token is SignFound;
          final word = switch (token) {
            SignFound() => token.originalWord,
            SignNotFound() => token.originalWord,
          };

          return GestureDetector(
            onTap: () => widget.onTap(i),
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
    required this.onRestart,
  });

  final bool isPlaying;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onPrev;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onNext;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.replay_rounded),
          onPressed: onRestart,
          iconSize: 24,
          tooltip: 'Baştan Oynat',
        ),
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded),
          onPressed: isFirst ? null : onPrev,
          iconSize: 28,
        ),
        const SizedBox(width: 4),
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
        const SizedBox(width: 4),
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
// Mikrofon butonu — dinlerken pulse animasyonu
// ─────────────────────────────────────────────────────────────────────────────

class _MicButton extends StatefulWidget {
  const _MicButton({required this.listening, required this.enabled});
  final bool listening;
  final bool enabled;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.4, end: 0.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeOut),
    );
    if (widget.listening) _pulse.repeat();
  }

  @override
  void didUpdateWidget(_MicButton old) {
    super.didUpdateWidget(old);
    if (widget.listening && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.listening && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.listening)
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, _) => Transform.scale(
                scale: _scale.value,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryBlue.withValues(alpha: _opacity.value),
                  ),
                ),
              ),
            ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.listening
                  ? AppTheme.primaryBlue
                  : widget.enabled
                      ? AppTheme.primaryBlue.withValues(alpha: 0.12)
                      : Colors.grey.withValues(alpha: 0.1),
            ),
            child: Icon(
              widget.listening
                  ? Icons.mic_rounded
                  : widget.enabled
                      ? Icons.mic_none_rounded
                      : Icons.mic_off_rounded,
              color: widget.listening
                  ? Colors.white
                  : widget.enabled
                      ? AppTheme.primaryBlue
                      : Colors.grey.withValues(alpha: 0.5),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
