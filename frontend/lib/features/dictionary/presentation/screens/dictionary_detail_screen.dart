import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../bookmarks/presentation/providers/bookmarks_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class _WordDetail {
  final int id;
  final String word;
  final String letter;
  final String? meaningEn;
  final String videoUrl;
  final List<String> allVideos;

  const _WordDetail({
    required this.id,
    required this.word,
    required this.letter,
    required this.meaningEn,
    required this.videoUrl,
    required this.allVideos,
  });

  factory _WordDetail.fromJson(Map<String, dynamic> j) => _WordDetail(
        id: j['id'] as int,
        word: j['word'] as String,
        letter: j['letter'] as String,
        meaningEn: j['meaningEn'] as String?,
        videoUrl: j['videoUrl'] as String,
        allVideos: (j['allVideos'] as List?)?.cast<String>() ?? [],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final _wordDetailProvider =
    FutureProvider.family<_WordDetail, int>((ref, id) async {
  final res = await ref.apiGet('/api/words/$id');
  if (res.statusCode != 200) throw Exception('Kelime yuklenemedi.');
  return _WordDetail.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
});

// ─────────────────────────────────────────────────────────────────────────────
// Ekran
// ─────────────────────────────────────────────────────────────────────────────

class DictionaryDetailScreen extends ConsumerWidget {
  final int wordId;
  const DictionaryDetailScreen({super.key, required this.wordId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_wordDetailProvider(wordId));

    return async.when(
      loading: () => Scaffold(
        backgroundColor: AppTheme.softGrey,
        appBar: AppBar(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        backgroundColor: AppTheme.softGrey,
        appBar: AppBar(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.textMuted),
              const SizedBox(height: 12),
              const Text('Kelime yuklenemedi.', style: TextStyle(color: AppTheme.midGrey)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(_wordDetailProvider(wordId)),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
      data: (word) => _DetailBody(word: word),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ana gövde
// ─────────────────────────────────────────────────────────────────────────────

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.word});
  final _WordDetail word;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final isBookmarked = ref.watch(
      bookmarksProvider.select((s) => s.contains(word.id)),
    );

    return Scaffold(
      backgroundColor: AppTheme.softGrey,
      body: CustomScrollView(
        slivers: [
          // ── Video Header ────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: _VideoHeader(videoUrl: word.videoUrl),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Kelime + harf + bookmark ──────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              word.word,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _LetterBadge(letter: word.letter),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: isBookmarked
                              ? AppTheme.primaryBlueTint
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isBookmarked
                                ? AppTheme.primaryBlue
                                : AppTheme.borderColor,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            isBookmarked
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                          ),
                          color: AppTheme.primaryBlue,
                          onPressed: auth.isAuthenticated
                              ? () => ref
                                  .read(bookmarksProvider.notifier)
                                  .toggle(word.id)
                              : () => _showLoginPrompt(context),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 100.ms, duration: 350.ms),

                  // ── İngilizce anlam ──────────────────────────────────
                  if (word.meaningEn != null) ...[
                    const SizedBox(height: 20),
                    _InfoCard(
                      icon: Icons.translate_rounded,
                      iconColor: AppTheme.secondaryBlue,
                      title: 'İngilizce Karşılık',
                      body: word.meaningEn!,
                    ).animate().fadeIn(delay: 160.ms, duration: 350.ms),
                  ],

                  // ── Alternatif videolar ──────────────────────────────
                  if (word.allVideos.length > 1) ...[
                    const SizedBox(height: 20),
                    _SectionTitle('Alternatif Kullanımlar'),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 140,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: word.allVideos.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (_, i) => _AltVideoCard(
                          url: word.allVideos[i],
                          index: i + 1,
                        ),
                      ),
                    ),
                  ].animate().fadeIn(delay: 220.ms, duration: 350.ms),

                  // ── İpucu kartı ──────────────────────────────────────
                  const SizedBox(height: 20),
                  _InfoCard(
                    icon: Icons.tips_and_updates_rounded,
                    iconColor: AppTheme.primaryStatusYellow,
                    title: 'İpucu',
                    body:
                        'İşareti yaparken yüz ifadeniz ve vücut diliniz de anlamı güçlendirir.',
                  ).animate().fadeIn(delay: 260.ms, duration: 350.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLoginPrompt(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kaydetmek için giriş yapmanız gerekiyor.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Video header
// ─────────────────────────────────────────────────────────────────────────────

class _VideoHeader extends ConsumerStatefulWidget {
  const _VideoHeader({required this.videoUrl});
  final String videoUrl;

  @override
  ConsumerState<_VideoHeader> createState() => _VideoHeaderState();
}

class _VideoHeaderState extends ConsumerState<_VideoHeader> {
  VideoPlayerController? _ctrl;
  bool _ready = false;
  bool _showPlayIcon = false;
  double _speed = 1.0;
  bool _isPlaying = false;
  bool _blockedByCellular = false;

  static const _speeds = [1.0, 1.5, 2.0, 0.5];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final settings = ref.read(settingsProvider);

    if (settings.cellularVideoDisabled) {
      final result = await Connectivity().checkConnectivity();
      final onCellular = result.contains(ConnectivityResult.mobile) &&
          !result.contains(ConnectivityResult.wifi);
      if (onCellular) {
        if (mounted) setState(() => _blockedByCellular = true);
        return;
      }
    }

    // DEBUG: Video oynatılmadan hemen önce linke bakalım
    debugPrint('DEBUG: DictionaryDetail videoUrl -> ${widget.videoUrl}');

    _ctrl = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
      httpHeaders: const {'ngrok-skip-browser-warning': 'true'},
    );
    await _ctrl!.initialize();
    _ctrl!.addListener(_onControllerUpdate);
    _ctrl!.setLooping(true);

    final autoplay = settings.videoQuality != VideoQuality.dataSaver;
    if (autoplay) _ctrl!.play();
    if (mounted) setState(() { _ready = true; _isPlaying = autoplay; });
  }

  // isPlaying değişince rebuild; diğer frame güncellemelerini yoksay.
  void _onControllerUpdate() {
    if (!mounted) return;
    final playing = _ctrl?.value.isPlaying ?? false;
    if (playing != _isPlaying) {
      setState(() => _isPlaying = playing);
    }
  }

  void _togglePlayPause() {
    final ctrl = _ctrl;
    if (ctrl == null) return;
    if (_isPlaying) {
      ctrl.pause();
    } else {
      ctrl.play();
    }
    setState(() => _showPlayIcon = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _showPlayIcon = false);
    });
  }

  void _cycleSpeed() {
    final ctrl = _ctrl;
    if (ctrl == null) return;
    final next = _speeds[(_speeds.indexOf(_speed) + 1) % _speeds.length];
    ctrl.setPlaybackSpeed(next);
    setState(() => _speed = next);
  }

  @override
  void dispose() {
    _ctrl?.removeListener(_onControllerUpdate);
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _ctrl;

    return Container(
      color: AppTheme.primaryBlue,
      child: _ready && ctrl != null
          ? GestureDetector(
              onTap: _togglePlayPause,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: ctrl.value.size.width,
                      height: ctrl.value.size.height,
                      child: VideoPlayer(ctrl),
                    ),
                  ),

                  // tap feedback overlay
                  if (_showPlayIcon)
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),

                  // bottom controls
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VideoProgressIndicator(
                            ctrl,
                            allowScrubbing: true,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            colors: VideoProgressColors(
                              playedColor: Colors.white,
                              bufferedColor: Colors.white38,
                              backgroundColor: Colors.white24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                onPressed: _togglePlayPause,
                                visualDensity: VisualDensity.compact,
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: _cycleSpeed,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.white38),
                                  ),
                                  child: Text(
                                    '${_speed == _speed.truncateToDouble() ? _speed.toInt() : _speed}x',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : _blockedByCellular
              ? const _CellularBlockPlaceholder()
              : const Center(
                  child: CircularProgressIndicator(color: Colors.white54),
                ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Alternatif video kartı (CDN URL'leri)
// ─────────────────────────────────────────────────────────────────────────────

class _AltVideoCard extends ConsumerStatefulWidget {
  const _AltVideoCard({required this.url, required this.index});
  final String url;
  final int index;

  @override
  ConsumerState<_AltVideoCard> createState() => _AltVideoCardState();
}

class _AltVideoCardState extends ConsumerState<_AltVideoCard> {
  VideoPlayerController? _ctrl;
  bool _ready = false;
  bool _playing = false;

  Future<void> _toggle() async {
    if (_ctrl == null) {
      final settings = ref.read(settingsProvider);
      if (settings.cellularVideoDisabled) {
        final result = await Connectivity().checkConnectivity();
        final onCellular = result.contains(ConnectivityResult.mobile) &&
            !result.contains(ConnectivityResult.wifi);
        if (onCellular && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video yüklemek için Wi-Fi bağlantısı gerekli.'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }
      }
      _ctrl = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
        httpHeaders: const {'ngrok-skip-browser-warning': 'true'},
      );
      await _ctrl!.initialize();
      _ctrl!.play();
      setState(() { _ready = true; _playing = true; });
      return;
    }
    if (_playing) {
      await _ctrl!.pause();
    } else {
      await _ctrl!.play();
    }
    setState(() => _playing = !_playing);
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        width: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _playing ? AppTheme.primaryBlue : AppTheme.borderColor,
            width: _playing ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_ready && _ctrl != null)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _ctrl!.value.size.width,
                    height: _ctrl!.value.size.height,
                    child: VideoPlayer(_ctrl!),
                  ),
                )
              else
                Container(
                  color: AppTheme.primaryBlueTint,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_circle_outline_rounded,
                        size: 28,
                        color: AppTheme.primaryBlue.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Anlam ${widget.index}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_playing)
                Positioned(
                  top: 6, right: 6,
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Küçük yardımcı widget'lar
// ─────────────────────────────────────────────────────────────────────────────

class _CellularBlockPlaceholder extends StatelessWidget {
  const _CellularBlockPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryBlue,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.white54, size: 40),
          SizedBox(height: 8),
          Text(
            'Wi-Fi bağlantısı gerekli',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          SizedBox(height: 4),
          Text(
            'Mobil veride video devre dışı (Ayarlar)',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _LetterBadge extends StatelessWidget {
  const _LetterBadge({required this.letter});
  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlueTint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryBlue,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
