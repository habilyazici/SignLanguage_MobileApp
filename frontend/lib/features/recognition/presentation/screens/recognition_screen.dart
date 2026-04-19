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

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _CameraLayer(
            state: state,
            onDoubleTap: () =>
                ref.read(recognitionProvider.notifier).switchCamera(),
          ),
          if (devMode && state.isReady && state.cameraController != null)
            _LandmarkOverlay(
              notifier: notifier.devNotifier,
              cameraController: state.cameraController!,
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopOverlay(
              devMode: devMode,
              onDevToggle: settingsNotifier.toggleDevMode,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _SubtitlePanel(
              state: state,
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
          if (devMode)
            Positioned(
              top: 0,
              bottom: 0,
              right: 12,
              child: _DevStatsPanel(devNotifier: notifier.devNotifier),
            ),
          if (state.isError)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam_off, color: Colors.white54, size: 56),
                    SizedBox(height: 16),
                    Text(
                      'Kamera başlatılamadı.\nLütfen izinleri kontrol edin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CameraLayer extends StatelessWidget {
  const _CameraLayer({required this.state, required this.onDoubleTap});
  final RecognitionState state;
  final VoidCallback onDoubleTap;

  @override
  Widget build(BuildContext context) {
    if (!state.isReady || state.cameraController == null) {
      return Shimmer.fromColors(
        baseColor: const Color(0xFF1A1A1A),
        highlightColor: const Color(0xFF2E2E2E),
        child: Container(color: const Color(0xFF1A1A1A)),
      );
    }
    final controller = state.cameraController!;
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

    for (final p in data.posePoints)
      canvas.drawCircle(toScreen(p), 4, posePaint);
    for (final p in data.rightHand)
      canvas.drawCircle(toScreen(p), 4, rightPaint);
    for (final p in data.leftHand) canvas.drawCircle(toScreen(p), 4, leftPaint);
  }

  @override
  bool shouldRepaint(_LandmarkPainter old) =>
      data != old.data ||
      cameraAspect != old.cameraAspect ||
      screenSize != old.screenSize;
}

class _TopOverlay extends StatelessWidget {
  const _TopOverlay({required this.devMode, required this.onDevToggle});
  final bool devMode;
  final VoidCallback onDevToggle;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 12, 12, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xCC000000), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Canlı Çeviri',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          const Text(
            'Kamera değiştir: 2×',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDevToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: devMode
                    ? Colors.cyanAccent.withValues(alpha: 0.2)
                    : Colors.transparent,
                border: Border.all(
                  color: devMode ? Colors.cyanAccent : Colors.white24,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'DEV',
                style: TextStyle(
                  color: devMode ? Colors.cyanAccent : Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
}

class _SubtitlePanel extends StatelessWidget {
  const _SubtitlePanel({
    required this.state,
    this.onTtsReplay,
    this.onCopy,
    this.onShare,
  });
  final RecognitionState state;
  final VoidCallback? onTtsReplay;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final hasWords = state.sentence.isNotEmpty;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 60, 20, bottom + 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xE6000000), Color(0x80000000), Colors.transparent],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (hasWords) ...[
            _SentenceRow(sentence: state.sentence),
            const SizedBox(height: 14),
          ],
          _ConfidenceBar(score: state.confidenceScore, active: hasWords),
          const SizedBox(height: 10),
          if (hasWords)
            _ActionBar(
              onTtsReplay: onTtsReplay,
              onCopy: onCopy,
              onShare: onShare,
            )
          else
            const Text(
              'Kameranın önünde işaret yapın',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({this.onTtsReplay, this.onCopy, this.onShare});
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
          color: Colors.cyanAccent,
          onTap: onTtsReplay,
        ),
        const SizedBox(width: 12),
        _ActionBtn(
          icon: Icons.copy_rounded,
          label: 'Kopyala',
          color: Colors.white70,
          onTap: onCopy,
        ),
        const SizedBox(width: 12),
        _ActionBtn(
          icon: Icons.share_rounded,
          label: 'Paylaş',
          color: AppTheme.secondaryBlue,
          onTap: onShare,
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
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

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
                  : Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: enabled ? color.withValues(alpha: 0.4) : Colors.white12,
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: enabled ? color : Colors.white24,
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: enabled ? color.withValues(alpha: 0.8) : Colors.white24,
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
  const _SentenceRow({required this.sentence});
  final List<String> sentence;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: sentence.asMap().entries.map((entry) {
        final isLast = entry.key == sentence.length - 1;
        return AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isLast ? Colors.white : Colors.white60,
                fontSize: isLast ? 30 : 22,
                fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                height: 1.2,
              ),
              child: Text(entry.value),
            )
            .animate(key: ValueKey(entry.key))
            .fadeIn(duration: 250.ms)
            .scale(
              begin: const Offset(0.75, 0.75),
              end: const Offset(1, 1),
              duration: 300.ms,
              curve: Curves.easeOutBack,
            );
      }).toList(),
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
