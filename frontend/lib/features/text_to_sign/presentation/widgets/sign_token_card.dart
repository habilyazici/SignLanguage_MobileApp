import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../domain/entities/sign_token.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Bulunan kelime — video oynatıcı
// ─────────────────────────────────────────────────────────────────────────────

class SignFoundCard extends StatefulWidget {
  const SignFoundCard({
    super.key,
    required this.token,
    required this.isActive,
    required this.onVideoEnd,
  });

  final SignFound token;
  final bool isActive;
  final VoidCallback onVideoEnd;

  @override
  State<SignFoundCard> createState() => _SignFoundCardState();
}

class _SignFoundCardState extends State<SignFoundCard> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _initVideo();
  }

  @override
  void didUpdateWidget(SignFoundCard old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) _initVideo();
    if (!widget.isActive && old.isActive) _disposeVideo();
  }

  Future<void> _initVideo() async {
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.token.videoUrl),
    );
    await _controller!.initialize();
    _controller!.addListener(_onVideoProgress);
    _controller!.play();
    if (mounted) setState(() => _initialized = true);
  }

  void _onVideoProgress() {
    if (_controller == null) return;
    final pos = _controller!.value.position;
    final dur = _controller!.value.duration;
    if (dur.inMilliseconds > 0 && pos >= dur - const Duration(milliseconds: 200)) {
      widget.onVideoEnd();
    }
  }

  void _disposeVideo() {
    _controller?.removeListener(_onVideoProgress);
    _controller?.dispose();
    _controller = null;
    if (mounted) setState(() => _initialized = false);
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isActive
              ? AppTheme.primaryBlue
              : (isDark ? Colors.white12 : Colors.black12),
          width: widget.isActive ? 2 : 1,
        ),
        boxShadow: widget.isActive
            ? [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          children: [
            // Video alanı
            Expanded(
              child: _initialized && _controller != null
                  ? AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    )
                  : _VideoPlaceholder(
                      word: widget.token.matchedWord,
                      isActive: widget.isActive,
                    ),
            ),
            // Kelime etiketi
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              color: widget.isActive
                  ? AppTheme.primaryBlue.withValues(alpha: 0.08)
                  : Colors.transparent,
              child: Column(
                children: [
                  Text(
                    widget.token.originalWord,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.isActive
                          ? AppTheme.primaryBlue
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.token.originalWord != widget.token.matchedWord)
                    Text(
                      '→ ${widget.token.matchedWord}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white38 : AppTheme.midGrey,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder({required this.word, required this.isActive});
  final String word;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isActive
          ? AppTheme.primaryBlue.withValues(alpha: 0.06)
          : Colors.transparent,
      child: Center(
        child: isActive
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.play_circle_outline_rounded,
                size: 32,
                color: isActive ? AppTheme.primaryBlue : Colors.grey,
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bulunamayan kelime — metin kartı
// ─────────────────────────────────────────────────────────────────────────────

class SignNotFoundCard extends StatelessWidget {
  const SignNotFoundCard({super.key, required this.token});
  final SignNotFound token;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.help_outline_rounded,
            size: 28,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              token.originalWord,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white38 : Colors.black45,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'video yok',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ),
        ],
      ),
    );
  }
}
