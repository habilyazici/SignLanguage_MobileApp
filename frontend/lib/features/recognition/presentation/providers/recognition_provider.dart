import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/recognition_constants.dart';
import '../../../../../core/providers/camera_lifecycle_provider.dart';
import '../../../../../core/providers/label_provider.dart';
import '../../../../../core/providers/tts_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../history/domain/entities/history_item.dart' show HistoryItemType;
import '../../../history/presentation/providers/history_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/entities/inference_result.dart';
import '../../domain/entities/recognition_state.dart';
import '../../domain/repositories/recognition_repository.dart';

export '../../domain/entities/recognition_state.dart'
    show RecognitionState, LandmarkDevData;

import 'recognition_repository_provider.dart';

// keepAlive: recognition pipeline navigasyon boyunca sürekli çalışmalı.
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
  Timer? _sameWordTimer;
  static const _clearDuration = Duration(milliseconds: RecognitionConstants.sentenceClearMs);
  static const _sameWordCooldown = Duration(milliseconds: RecognitionConstants.sameWordCooldownMs);

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

    final cameraSub = _repo.cameraControllerStream.listen((ctrl) {
      cameraNotifier.value = ctrl;
      state = state.copyWith(
        isReady: ctrl != null,
        isError: false,
        predictedWord: '',
        confidenceScore: 0.0,
      );
    });

    final inferenceSub = _repo.inferenceStream.listen(_onInferenceResult);

    final landmarkSub = _repo.landmarkStream.listen((data) {
      devNotifier.value = LandmarkDevData(
        posePoints: data.posePoints,
        rightHand: data.rightHand,
        leftHand: data.leftHand,
        bufferFill: data.bufferFill,
        poseCount: data.poseCount,
        handCount: data.handCount,
        latencyMs: data.latencyMs,
        topPredictions: _topPredictions,
      );
    });

    ref.listen<AppSettings>(settingsProvider, (_, next) {
      _repo.updateLeftHandMode(next.leftHandMode);
      _repo.updateFpsLimit(next.targetFps);
      _repo.updateMotionThreshold(next.motionThreshold);
    });

    // Kamera aktif sinyali (navigasyon katmanından)
    ref.listen<bool>(cameraActiveProvider, (_, isActive) async {
      if (isActive) {
        _repo.resumeCamera();
      } else {
        final releaseHardware =
            ref.read(cameraActiveProvider.notifier).releaseHardware;
        await _repo.pauseCamera(releaseHardware: releaseHardware);
        ref.read(cameraActiveProvider.notifier).markReleased();
        if (ref.read(cameraActiveProvider)) {
          _repo.resumeCamera();
        }
      }
    });

    ref.onDispose(() {
      cameraSub.cancel();
      inferenceSub.cancel();
      landmarkSub.cancel();
      _clearTimer?.cancel();
      _sameWordTimer?.cancel();
      _repo.dispose();
      cameraNotifier.dispose();
      devNotifier.dispose();
    });

    // Settings'i initialize başlamadan önce uygula — ilk kameradan gelen
    // frame'ler doğru FPS/el modu/eşik değerleriyle işlensin.
    final initialSettings = ref.read(settingsProvider);
    _repo.updateLeftHandMode(initialSettings.leftHandMode);
    _repo.updateFpsLimit(initialSettings.targetFps);
    _repo.updateMotionThreshold(initialSettings.motionThreshold);

    _repo.initialize().catchError((e) {
      state = state.copyWith(isError: true);
    });

    return const RecognitionState();
  }

  // ── Inference sonucu işleme — smoothing + TTS ─────────────────────────────

  void _onInferenceResult(InferenceResult result) {
    if (result.classIndex == -1) {
      state = state.copyWith(predictedWord: '', confidenceScore: 0.0);
      _streak = 0;
      _lastIdx = -1;
      _lastShownWord = '';
      _sameWordTimer?.cancel();
      _sameWordTimer = null;
      return;
    }

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
          final trimmed = updated.length > RecognitionConstants.sentenceMaxWords
              ? updated.sublist(updated.length - RecognitionConstants.sentenceMaxWords)
              : updated;

          state = state.copyWith(
            predictedWord: word,
            confidenceScore: maxScore,
            sentence: trimmed,
          );

          if (settings.ttsEnabled) {
            ref.read(ttsProvider.notifier).speak(word);
          }
          if (!settings.zeroDataMode &&
              ref.read(authProvider).isAuthenticated) {
            ref.read(historyProvider.notifier).add(word, type: HistoryItemType.recognition);
          }
          _streak = 0;
          _lastIdx = -1;
          _sameWordTimer?.cancel();
          _sameWordTimer = Timer(_sameWordCooldown, () {
            _lastShownWord = '';
            _sameWordTimer = null;
          });
          _scheduleClear();
        } else {
          // Cooldown'da aynı kelime: streak sıfırla, yoksa cooldown bitince
          // birikmiş streak anında yeniden tetikler.
          _streak = 0;
          _lastIdx = -1;
          state = state.copyWith(confidenceScore: maxScore);
        }
      }
    } else if (maxScore < RecognitionConstants.streakNoiseFloor) {
      if (_streak > 0) _streak--;
    }
  }

  void _scheduleClear() {
    _clearTimer?.cancel();
    _clearTimer = Timer(_clearDuration, () {
      _clearTimer = null;
      _lastShownWord = '';
      _streak = 0;
      _lastIdx = -1;
      state = state.copyWith(predictedWord: '', confidenceScore: 0.0, sentence: []);
    });
  }

  // Public API — ekran ve navigasyon katmanına açık

  Future<void> switchCamera() => _repo.switchCamera();

  void clearSentence() {
    _clearTimer?.cancel();
    _sameWordTimer?.cancel();
    _sameWordTimer = null;
    _lastShownWord = '';
    _streak = 0;
    _lastIdx = -1;
    state = state.copyWith(
      sentence: [],
      predictedWord: '',
      confidenceScore: 0.0,
    );
  }
}
