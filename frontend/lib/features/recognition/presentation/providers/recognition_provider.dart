import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/camera_lifecycle_provider.dart';
import '../../../../../core/providers/label_provider.dart';
import '../../../../../core/providers/tts_provider.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/entities/inference_result.dart';
import '../../domain/entities/recognition_state.dart';
import '../../domain/repositories/recognition_repository.dart';

export '../../domain/entities/recognition_state.dart'
    show RecognitionState, LandmarkDevData;

import 'recognition_repository_provider.dart';

// Notifier provider
final recognitionProvider =
    NotifierProvider<RecognitionNotifier, RecognitionState>(
      RecognitionNotifier.new,
    );

class RecognitionNotifier extends Notifier<RecognitionState> {
  late final RecognitionRepository _repo;

  // ── Temporal smoothing (presentation sorumluluğu) ────────────────────────
  int _lastIdx = -1;
  int _streak = 0;
  String _lastShownWord = '';
  Timer? _clearTimer;
  static const _clearDuration = Duration(seconds: 4);

  // ── Dev modu top-3 (per-inference güncellenir) ────────────────────────────
  List<({String word, double confidence})> _topPredictions = [];

  // ── Kamera controller — presentation katmanında tutuluyor, domain'e girmez ─
  /// CameraController değiştiğinde (kamera geçişi dahil) listener'lar tetiklenir.
  final cameraNotifier = ValueNotifier<CameraController?>(null);

  // ── Developer modu — per-frame Riverpod rebuild tetiklemez ───────────────
  final devNotifier = ValueNotifier<LandmarkDevData>(
    LandmarkDevData(
      posePoints: [],
      rightHand: [],
      leftHand: [],
      bufferFill: 0,
      poseCount: 0,
      handCount: 0,
    ),
  );

  @override
  RecognitionState build() {
    ref.keepAlive();
    _repo = ref.read(recognitionRepositoryProvider);

    // Kamera controller → cameraNotifier (platform nesnesi domain'e girmez)
    final cameraSub = _repo.cameraControllerStream.listen((ctrl) {
      cameraNotifier.value = ctrl;
      state = state.copyWith(
        isReady: ctrl != null,
        isError: false,
        predictedWord: '',
        confidenceScore: 0.0,
      );
    });

    // Inference sonuçları → smoothing + state güncellemesi
    final inferenceSub = _repo.inferenceStream.listen(_onInferenceResult);

    // Landmark verisi → devNotifier (Riverpod rebuild yok)
    // _topPredictions her inference'ta güncellenir, burada devNotifier'a eklenir.
    final landmarkSub = _repo.landmarkStream.listen((data) {
      devNotifier.value = LandmarkDevData(
        posePoints: data.posePoints,
        rightHand: data.rightHand,
        leftHand: data.leftHand,
        bufferFill: data.bufferFill,
        poseCount: data.poseCount,
        handCount: data.handCount,
        topPredictions: _topPredictions,
      );
    });

    // Ayarlar değişince repository'ye bildir
    ref.listen<AppSettings>(settingsProvider, (_, next) {
      _repo.updateLeftHandMode(next.leftHandMode);
      _repo.updateFpsLimit(next.targetFps);
      _repo.updateMotionThreshold(next.motionThreshold);
    });

    // Kamera aktif sinyali (navigasyon katmanından)
    ref.listen<bool>(cameraActiveProvider, (_, isActive) {
      if (isActive) {
        _repo.resumeCamera();
      } else {
        _repo.pauseCamera();
      }
    });

    ref.onDispose(() {
      cameraSub.cancel();
      inferenceSub.cancel();
      landmarkSub.cancel();
      _clearTimer?.cancel();
      _repo.dispose();
      cameraNotifier.dispose();
      devNotifier.dispose();
    });

    _repo
        .initialize()
        .then((_) {
          final s = ref.read(settingsProvider);
          _repo.updateLeftHandMode(s.leftHandMode);
          _repo.updateFpsLimit(s.targetFps);
          _repo.updateMotionThreshold(s.motionThreshold);
        })
        .catchError((e) {
          state = state.copyWith(isError: true);
        });

    return const RecognitionState();
  }

  // Inference sonucu işleme — smoothing + TTS

  void _onInferenceResult(InferenceResult result) {
    // Sentinel: tespit yok / buffer temizlendi → ekranı sıfırla
    if (result.classIndex == -1) {
      state = state.copyWith(predictedWord: '', confidenceScore: 0.0);
      _streak = 0;
      _lastIdx = -1;
      _lastShownWord = '';
      return;
    }

    // Top-3'ü Türkçe etikete çevir ve devNotifier için sakla
    if (result.topPredictions.isNotEmpty) {
      final labelRepo = ref.read(labelRepositoryProvider);
      _topPredictions = result.topPredictions
          .map(
            (p) => (
              word: labelRepo.getTrWord(p.classIndex),
              confidence: p.confidence,
            ),
          )
          .toList();
    }

    final settings = ref.read(settingsProvider);
    final scoreThreshold = settings.confidenceThreshold;
    final maxIdx = result.classIndex;
    final maxScore = result.confidence;

    if (maxScore >= scoreThreshold) {
      if (maxIdx == _lastIdx) {
        _streak++;
      } else {
        _lastIdx = maxIdx;
        _streak = 1;
      }

      final threshold = settings.stableFramesThreshold;
      if (_streak >= threshold) {
        final word = ref.read(labelRepositoryProvider).getTrWord(maxIdx);

        if (word != _lastShownWord) {
          _lastShownWord = word;
          final updated = [...state.sentence, word];
          final trimmed = updated.length > 6
              ? updated.sublist(updated.length - 6)
              : updated;

          state = state.copyWith(
            predictedWord: word,
            confidenceScore: maxScore,
            sentence: trimmed,
          );

          if (settings.ttsEnabled) {
            ref.read(ttsProvider.notifier).speak(word);
          }
          if (!settings.zeroDataMode) {
            ref.read(historyProvider.notifier).add(word);
          }
          _clearTimer?.cancel();
          _clearTimer = Timer(_clearDuration, () {
            _lastShownWord = '';
            _streak = 0;
            _lastIdx = -1;
            state = state.copyWith(
              predictedWord: '',
              confidenceScore: 0.0,
              sentence: [],
            );
          });
        } else {
          state = state.copyWith(confidenceScore: maxScore);
        }
      }
    } else {
      // Skor eşiğin altında — streak ve son sınıfı sıfırla
      _streak = 0;
      _lastIdx = -1;
      _lastShownWord = '';
    }
  }

  // Public API — ekran ve navigasyon katmanına açık

  void pauseCamera() => _repo.pauseCamera();
  void resumeCamera() => _repo.resumeCamera();
  Future<void> switchCamera() => _repo.switchCamera();
}
