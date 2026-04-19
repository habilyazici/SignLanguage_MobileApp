import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/recognition_constants.dart';
import '../../../../../core/providers/camera_lifecycle_provider.dart';
import '../../../../../core/providers/label_provider.dart';
import '../../../../../core/providers/tts_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/datasources/camera_datasource.dart';
import '../../data/datasources/inference_datasource.dart';
import '../../data/datasources/ml_pipeline_datasource.dart';
import '../../data/repositories/recognition_repository_impl.dart';
import '../../domain/entities/inference_result.dart';
import '../../domain/entities/recognition_state.dart';
import '../../domain/repositories/recognition_repository.dart';

export '../../domain/entities/recognition_state.dart'
    show RecognitionState, LandmarkDevData;

// ─────────────────────────────────────────────────────────────────────────────
// Repository provider
// ─────────────────────────────────────────────────────────────────────────────

final _recognitionRepositoryProvider = Provider<RecognitionRepository>(
  (_) => RecognitionRepositoryImpl(
    cameraDataSource: CameraDataSource(),
    mlPipelineDataSource: MlPipelineDatasource(),
    inferenceDataSource: InferenceDatasource(),
  ),
);

// ─────────────────────────────────────────────────────────────────────────────
// Notifier provider
// ─────────────────────────────────────────────────────────────────────────────

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

  // ─────────────────────────────────────────────────────────────────────────
  // build()
  // ─────────────────────────────────────────────────────────────────────────

  @override
  RecognitionState build() {
    ref.keepAlive();
    _repo = ref.read(_recognitionRepositoryProvider);

    // Kamera controller → state (kamera hazır / kamera geçişi)
    final cameraSub = _repo.cameraControllerStream.listen((ctrl) {
      state = state.copyWith(
        isReady: ctrl != null,
        cameraController: ctrl,
        isError: false,
        predictedWord: '',
        confidenceScore: 0.0,
      );
    });

    // Inference sonuçları → smoothing + state güncellemesi
    final inferenceSub = _repo.inferenceStream.listen(_onInferenceResult);

    // Landmark verisi → devNotifier (Riverpod rebuild yok)
    final landmarkSub = _repo.landmarkStream.listen((data) {
      devNotifier.value = data;
    });

    // Sol el modu değişince repository'ye bildir
    ref.listen<AppSettings>(settingsProvider, (_, next) {
      _repo.updateLeftHandMode(next.leftHandMode);
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
      devNotifier.dispose();
    });

    _repo.initialize().catchError((e) {
      state = state.copyWith(isError: true);
    });

    return const RecognitionState();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Inference sonucu işleme — smoothing + TTS + haptic
  // ─────────────────────────────────────────────────────────────────────────

  void _onInferenceResult(InferenceResult result) {
    // Sentinel: tespit yok / buffer temizlendi → ekranı sıfırla
    if (result.classIndex == -1) {
      state = state.copyWith(predictedWord: '', confidenceScore: 0.0);
      _streak = 0;
      _lastIdx = -1;
      _lastShownWord = '';
      return;
    }

    final settings = ref.read(settingsProvider);
    final smoothingOn = settings.temporalSmoothingEnabled;
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

      final threshold = smoothingOn ? RecognitionConstants.stableFrames : 1;
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
          if (maxScore >= 0.90) HapticFeedback.mediumImpact();

          _clearTimer?.cancel();
          _clearTimer = Timer(const Duration(seconds: 4), () {
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

  // ─────────────────────────────────────────────────────────────────────────
  // Public API — ekran ve navigasyon katmanına açık
  // ─────────────────────────────────────────────────────────────────────────

  void pauseCamera() => _repo.pauseCamera();
  void resumeCamera() => _repo.resumeCamera();
  Future<void> switchCamera() => _repo.switchCamera();
}
