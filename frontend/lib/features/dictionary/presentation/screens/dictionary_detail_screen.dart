import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';

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
  final res = await http
      .get(Uri.parse('$kApiBaseUrl/api/words/$id'))
      .timeout(const Duration(seconds: 10));
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

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.word});
  final _WordDetail word;

  @override
  Widget build(BuildContext context) {
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
                      // Bookmark butonu — ileride bağlanacak
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.bookmark_border_rounded),
                          color: AppTheme.primaryBlue,
                          onPressed: () {},
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Video header
// ─────────────────────────────────────────────────────────────────────────────

class _VideoHeader extends StatefulWidget {
  const _VideoHeader({required this.videoUrl});
  final String videoUrl;

  @override
  State<_VideoHeader> createState() => _VideoHeaderState();
}

class _VideoHeaderState extends State<_VideoHeader> {
  VideoPlayerController? _ctrl;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    await _ctrl!.initialize();
    _ctrl!.setLooping(true);
    _ctrl!.play();
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryBlue,
      child: _ready && _ctrl != null
          ? Stack(
              fit: StackFit.expand,
              children: [
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _ctrl!.value.size.width,
                    height: _ctrl!.value.size.height,
                    child: VideoPlayer(_ctrl!),
                  ),
                ),
                // Alt gradient
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Alternatif video kartı (CDN URL'leri)
// ─────────────────────────────────────────────────────────────────────────────

class _AltVideoCard extends StatefulWidget {
  const _AltVideoCard({required this.url, required this.index});
  final String url;
  final int index;

  @override
  State<_AltVideoCard> createState() => _AltVideoCardState();
}

class _AltVideoCardState extends State<_AltVideoCard> {
  VideoPlayerController? _ctrl;
  bool _ready = false;
  bool _playing = false;

  Future<void> _toggle() async {
    if (_ctrl == null) {
      _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url));
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
