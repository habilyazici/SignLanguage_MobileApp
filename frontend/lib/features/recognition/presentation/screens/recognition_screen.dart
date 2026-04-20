import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/providers/tts_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/recognition_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class RecognitionScreen extends ConsumerWidget {
  const RecognitionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recognitionProvider);
    final notifier = ref.read(recognitionProvider.notifier);
    final devMode = ref.watch(settingsProvider).devMode;
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

              // ── Kamera Kartı ─────────────────────────────────────────────
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Stack(
                    children: [
                      Container(
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
                          // ValueListenableBuilder: kamera geçişinde sadece
                          // kamera bölümü rebuild olur, tüm ekran değil.
                          child: ValueListenableBuilder<CameraController?>(
                            valueListenable: notifier.cameraNotifier,
                            builder: (context, cameraCtrl, _) => Stack(
                              fit: StackFit.expand,
                              children: [
                                _CameraLayer(
                                  isReady: state.isReady,
                                  cameraController: cameraCtrl,
                                  onDoubleTap: () => notifier.switchCamera(),
                                ),
                                if (devMode &&
                                    state.isReady &&
                                    cameraCtrl != null)
                                  _LandmarkOverlay(
                                    notifier: notifier.devNotifier,
                                    cameraController: cameraCtrl,
                                  ),
                                if (devMode)
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: _DevStatsPanel(
                                      devNotifier: notifier.devNotifier,
                                    ),
                                  ),
                                if (ref.watch(settingsProvider).showDevButton)
                                  Positioned(
                                    top: 12,
                                    left: 12,
                                    child: GestureDetector(
                                      onTap: settingsNotifier.toggleDevMode,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: devMode
                                              ? Colors.cyanAccent.withValues(
                                                  alpha: 0.1,
                                                )
                                              : Colors.black45,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: devMode
                                                ? Colors.cyanAccent
                                                : Colors.white24,
                                          ),
                                        ),
                                        child: Text(
                                          'DEV',
                                          style: TextStyle(
                                            color: devMode
                                                ? Colors.cyanAccent
                                                : Colors.white60,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (state.isError) _ErrorOverlay(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Sonuç Paneli ─────────────────────────────────────────────
              Expanded(
                flex: 3,
                child: _ResultPanel(
                  state: state,
                  isDark: isDark,
                  onTtsReplay:
                      state.sentence.isNotEmpty &&
                          ref.watch(settingsProvider).ttsEnabled
                      ? () => ref
                            .read(ttsProvider.notifier)
                            .speak(state.sentence.join(' '))
                      : null,
                  onCopy: state.sentence.isNotEmpty
                      ? () {
                          Clipboard.setData(
                            ClipboardData(text: state.sentence.join(' ')),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cümle panoya kopyalandı'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      : null,
                  onShare: state.sentence.isNotEmpty
                      ? () => Share.share(state.sentence.join(' '))
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Top Header kaldırıldı.

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.state,
    required this.isDark,
    this.onTtsReplay,
    this.onCopy,
    this.onShare,
  });
  final RecognitionState state;
  final bool isDark;
  final VoidCallback? onTtsReplay;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final hasWords = state.sentence.isNotEmpty;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white70,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: hasWords
                  ? _SentenceRow(sentence: state.sentence, isDark: isDark)
                  : Text(
                      'Kameraya ellerinizi gösterin',
                      style: TextStyle(
                        color: isDark ? Colors.white24 : Colors.black26,
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          _ConfidenceBar(score: state.confidenceScore, active: hasWords),
          const SizedBox(height: 16),
          _ActionBar(
            isDark: isDark,
            onTtsReplay: onTtsReplay,
            onCopy: onCopy,
            onShare: onShare,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }
}

class _ErrorOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off, color: Colors.white54, size: 48),
            SizedBox(height: 12),
            Text('Kamera açılamadı', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _CameraLayer extends StatelessWidget {
  const _CameraLayer({
    required this.isReady,
    required this.cameraController,
    required this.onDoubleTap,
  });
  final bool isReady;
  final CameraController? cameraController;
  final VoidCallback onDoubleTap;

  @override
  Widget build(BuildContext context) {
    if (!isReady || cameraController == null) {
      return Shimmer.fromColors(
        baseColor: const Color(0xFF1A1A1A),
        highlightColor: const Color(0xFF2E2E2E),
        child: Container(color: const Color(0xFF1A1A1A)),
      );
    }
    final controller = cameraController!;
    return GestureDetector(
      onDoubleTap: onDoubleTap,
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: controller.value.previewSize!.height,
            height: controller.value.previewSize!.width,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}

class _LandmarkOverlay extends StatelessWidget {
  const _LandmarkOverlay({
    required this.notifier,
    required this.cameraController,
  });
  final ValueNotifier<LandmarkDevData> notifier;
  final CameraController cameraController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: notifier,
      builder: (context, _) {
        final data = notifier.value;
        final previewSize = cameraController.value.previewSize;
        if (previewSize == null) return const SizedBox.shrink();
        return CustomPaint(
          painter: _LandmarkPainter(
            data: data,
            cameraAspect: previewSize.height / previewSize.width,
            screenSize: MediaQuery.of(context).size,
          ),
        );
      },
    );
  }
}

class _LandmarkPainter extends CustomPainter {
  const _LandmarkPainter({
    required this.data,
    required this.cameraAspect,
    required this.screenSize,
  });
  final LandmarkDevData data;
  final double cameraAspect;
  final Size screenSize;

  @override
  void paint(Canvas canvas, Size size) {
    final double screenAspect = size.width / size.height;
    double camW, camH, offsetX, offsetY;

    if (cameraAspect > screenAspect) {
      camW = size.width;
      camH = size.width / cameraAspect;
      offsetX = 0;
      offsetY = (size.height - camH) / 2;
    } else {
      camH = size.height;
      camW = size.height * cameraAspect;
      offsetX = (size.width - camW) / 2;
      offsetY = 0;
    }

    Offset toScreen(Offset n) =>
        Offset(offsetX + n.dx * camW, offsetY + n.dy * camH);

    final posePaint = Paint()
      ..color = Colors.yellowAccent
      ..style = PaintingStyle.fill;
    final rightPaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;
    final leftPaint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.fill;

    for (final p in data.posePoints) {
      canvas.drawCircle(toScreen(p), 4, posePaint);
    }
    for (final p in data.rightHand) {
      canvas.drawCircle(toScreen(p), 4, rightPaint);
    }
    for (final p in data.leftHand) {
      canvas.drawCircle(toScreen(p), 4, leftPaint);
    }
  }

  @override
  bool shouldRepaint(_LandmarkPainter old) =>
      data != old.data ||
      cameraAspect != old.cameraAspect ||
      screenSize != old.screenSize;
}

class _DevStatsPanel extends StatelessWidget {
  const _DevStatsPanel({required this.devNotifier});
  final ValueNotifier<LandmarkDevData> devNotifier;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ListenableBuilder(
        listenable: devNotifier,
        builder: (ctx, child) {
          final d = devNotifier.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statRow('BUF', '${d.bufferFill}/60', Colors.white70),
                _statRow('POSE', '${d.poseCount}', Colors.yellowAccent),
                _statRow('HAND', '${d.handCount}', Colors.white70),
                _statRow('R', '${d.rightHand.length}pt', Colors.redAccent),
                _statRow('L', '${d.leftHand.length}pt', Colors.blueAccent),
                if (d.topPredictions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(height: 1, color: Colors.white12),
                  const SizedBox(height: 4),
                  for (int i = 0; i < d.topPredictions.length; i++)
                    _predRow(
                      i + 1,
                      d.topPredictions[i].word,
                      d.topPredictions[i].confidence,
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _predRow(int rank, String word, double confidence) {
    final color = rank == 1
        ? Colors.greenAccent
        : rank == 2
        ? Colors.yellowAccent
        : Colors.white38;
    final pct = '${(confidence * 100).toStringAsFixed(0)}%';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$rank ',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 72),
            child: Text(
              word,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Text(
            ' $pct',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.isDark,
    this.onTtsReplay,
    this.onCopy,
    this.onShare,
  });
  final bool isDark;
  final VoidCallback? onTtsReplay;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionBtn(
          icon: Icons.volume_up_rounded,
          label: 'Seslendir',
          color: isDark ? Colors.cyanAccent : Colors.cyan[700]!,
          onTap: onTtsReplay,
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _ActionBtn(
          icon: Icons.copy_rounded,
          label: 'Kopyala',
          color: isDark ? Colors.white70 : Colors.black54,
          onTap: onCopy,
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _ActionBtn(
          icon: Icons.share_rounded,
          label: 'Paylaş',
          color: isDark ? AppTheme.secondaryBlue : AppTheme.primaryBlue,
          onTap: onShare,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.isDark,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: enabled
                  ? color.withValues(alpha: 0.15)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05)),
              shape: BoxShape.circle,
              border: Border.all(
                color: enabled
                    ? color.withValues(alpha: 0.4)
                    : (isDark ? Colors.white12 : Colors.black12),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: enabled
                  ? color
                  : (isDark ? Colors.white24 : Colors.black26),
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: enabled
                  ? color.withValues(alpha: 0.8)
                  : (isDark ? Colors.white24 : Colors.black26),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SentenceRow extends StatelessWidget {
  const _SentenceRow({required this.sentence, required this.isDark});
  final List<String> sentence;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      color: isDark ? Colors.white : AppTheme.primaryBlue,
      fontSize: 26,
      fontWeight: FontWeight.w600,
      height: 1.3,
    );

    return SingleChildScrollView(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: sentence.map((word) {
          return Text(
            word,
            style: textStyle,
          ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0);
        }).toList(),
      ),
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  const _ConfidenceBar({required this.score, required this.active});
  final double score;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = score >= 0.90
        ? AppTheme.primaryStatusGreen
        : (score >= 0.80
              ? AppTheme.primaryStatusYellow
              : AppTheme.primaryStatusRed);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: LinearProgressIndicator(
              value: active ? score : 0.0,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ),
        if (active) ...[
          const SizedBox(height: 4),
          Text(
            '%${(score * 100).toStringAsFixed(0)} güven',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
