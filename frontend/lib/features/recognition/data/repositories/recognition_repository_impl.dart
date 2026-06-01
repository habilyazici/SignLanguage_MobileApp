import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../../../../../core/constants/recognition_constants.dart';
import '../../domain/entities/inference_result.dart';
import '../../domain/entities/recognition_state.dart';
import '../../domain/repositories/recognition_repository.dart';
import '../datasources/camera_datasource.dart';
import '../datasources/inference_datasource.dart';
import '../datasources/ml_pipeline_datasource.dart';
import '../../domain/entities/ml_frame_result.dart';

/// Recognition pipeline'ını orkestre eden veri katmanı implementasyonu.
///
/// Sorumluluklar:
///   - Datasource'ları başlatır ve birbirine bağlar
///   - Kayan zaman penceresini (timedBuffer) yönetir
///   - Hareket tespitini hesaplar
///   - Uygun koşullarda inference tetikler
///   - Sonuçları stream'ler üzerinden sunar
class RecognitionRepositoryImpl implements RecognitionRepository {
  RecognitionRepositoryImpl({
    required CameraDataSource cameraDataSource,
    required MlPipelineDatasource mlPipelineDataSource,
    required InferenceDatasource inferenceDataSource,
  }) : _camera = cameraDataSource,
       _ml = mlPipelineDataSource,
       _inference = inferenceDataSource;

  final CameraDataSource _camera;
  final MlPipelineDatasource _ml;
  final InferenceDatasource _inference;

  // ── Streams ─────────────────────────────────────────────────────────────────
  final _cameraCtrl = StreamController<CameraController?>.broadcast();
  final _inferenceCtrl = StreamController<InferenceResult>.broadcast();
  final _landmarkCtrl = StreamController<LandmarkDevData>.broadcast();

  @override
  Stream<CameraController?> get cameraControllerStream => _cameraCtrl.stream;
  @override
  Stream<InferenceResult> get inferenceStream => _inferenceCtrl.stream;
  @override
  Stream<LandmarkDevData> get landmarkStream => _landmarkCtrl.stream;

  // ── Çalışma zamanı durumu ────────────────────────────────────────────────────
  final List<(int, List<double>)> _timedBuffer = [];
  int _frameCounter = 0;
  int _resultCounter = 0;
  bool _isInferring = false;
  bool _isInitializing = false;
  bool _isPausing = false;
  // pauseCamera initialize() devam ederken çağrılırsa stream'i iptal etmek için.
  bool _cancelInit = false;
  List<double>? _prevFrame;
  int _lastMotionMs = 0;
  bool _leftHandMode = false;
  bool _isStreaming = false;
  int _targetFps = 30;
  double _motionThreshold = RecognitionConstants.motionThreshold;
  int _lastFrameTimeMs = 0;
  int _lastInferenceMs = 0;
  Timer? _noDetectionTimer;
  StreamSubscription<CameraController?>? _cameraSub;
  StreamSubscription<MlFrameResult>? _mlSub;

  // ── Başlatma ───────────────────────────────────────────────────────────────

  @override
  Future<void> initialize() async {
    if (_isInitializing || _isStreaming) return;
    _isInitializing = true;
    try {
      if (!_ml.isReady) await _ml.initialize();
      if (!_inference.isReady) await _inference.initialize();

      _mlSub ??= _ml.resultStream.listen(_onMlResult);

      _cameraSub ??= _camera.controllerStream.listen((ctrl) {
        _cameraCtrl.add(ctrl);
        if (ctrl != null) _resetBuffer();
      });

      await _camera.initialize();
      if (_cancelInit) {
        _cancelInit = false;
        return;
      }
      _isStreaming = true;
      _camera.startStream(_onFrame);
    } finally {
      _isInitializing = false;
    }
  }

  // ── Kamera kontrolü ───────────────────────────────────────────────────────

  @override
  Future<void> pauseCamera({bool releaseHardware = false}) async {
    if (_isInitializing) _cancelInit = true;
    if (!_isStreaming) return;
    _isStreaming = false;
    _isPausing = true;

    _cameraCtrl.add(null);
    await _camera.stopStream();

    if (releaseHardware) {
      // Donanımı tamamen serbest bırak — iOS STT / AVAudioSession için gerekli.
      await _camera.release();
    }
    // releaseHardware=false: controller canlı kalır, resume anında olur.

    _resetBuffer();
    _isPausing = false;
  }

  @override
  Future<void> resumeCamera() async {
    if (_isStreaming || _isInitializing || _isPausing) return;
    _cancelInit = false;

    _resetBuffer();

    if (_camera.currentCamera == null) {
      // Donanım tamamen serbest bırakılmış (releaseHardware=true sonrası) — yeniden başlat.
      await initialize();
    } else {
      // Controller hâlâ canlı (sadece stream durdurulmuştu) — anında yeniden başlat.
      _isStreaming = true;
      _cameraCtrl.add(_camera.currentCamera);
      _camera.startStream(_onFrame);
    }
  }

  @override
  Future<void> switchCamera() async {
    final wasStreaming = _isStreaming;
    await _camera.stopStream();
    _resetBuffer();
    try {
      await _camera.switchCamera();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Kamera geçişi başarısız: $e');
      // Eski kamerayı geri aç
      try {
        await _camera.initialize();
      } catch (_) {}
      if (wasStreaming && _camera.currentCamera != null) {
        _isStreaming = true;
        _camera.startStream(_onFrame);
      }
      return;
    }
    if (wasStreaming) {
      _isStreaming = true;
      _camera.startStream(_onFrame);
    }
  }

  @override
  void updateLeftHandMode(bool leftHand) => _leftHandMode = leftHand;

  @override
  void updateFpsLimit(int targetFps) => _targetFps = targetFps;

  @override
  void updateMotionThreshold(double threshold) => _motionThreshold = threshold;

  // ── Frame işleme ──────────────────────────────────────────────────────────

  void _onFrame(CameraImage image) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    if (_targetFps > 0) {
      final int frameIntervalMs = 1000 ~/ _targetFps;
      if (now - _lastFrameTimeMs < frameIntervalMs) return;
    }

    _frameCounter++;
    
    // ML pipeline meşgulse veya henüz hazır değilse kareyi düşür.
    // iOS'ta kaynak yönetimi için _isInferring (TFLite) durumunda da düşür.
    if (_ml.isBusy || (Platform.isIOS && _isInferring) || !_ml.isReady) return;

    _lastFrameTimeMs = now;

    try {
      await _ml.submit(
        image,
        sensorOrientation: _camera.sensorOrientation,
        isFlipped: _camera.isFlipped,
        leftHandMode: _leftHandMode,
      );
    } catch (e, st) {
      if (kDebugMode) debugPrint('❌ Frame submit hatası: $e\n$st');
    }
  }

  /// ML Isolate'ten gelen sonuçları işler (non-blocking flow).
  void _onMlResult(MlFrameResult result) {
    _resultCounter++;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // 1. Zamana göre temizlik: El olsa da olmasa da eskimiş kareleri at.
    // Bu sayede el çekildiğinde buffer 2sn içinde kendiliğinden boşalır.
    _timedBuffer.removeWhere(
      (e) => nowMs - e.$1 > RecognitionConstants.windowMs,
    );

    bool shouldInfer = false;

    _landmarkCtrl.add(
      LandmarkDevData(
        posePoints: result.posePoints,
        rightHand: result.rightHandPoints,
        leftHand: result.leftHandPoints,
        bufferFill: _timedBuffer.length,
        poseCount: result.poseCount,
        handCount: result.handCount,
        latencyMs: result.latencyMs,
      ),
    );

    if (result.anyDetected) {
      if (_noDetectionTimer != null) {
        _noDetectionTimer!.cancel();
        _noDetectionTimer = null;
      }

      if (kDebugMode && _resultCounter % 300 == 0) {
        debugPrint(
          '📊 [Durum] Kare=$_frameCounter | Buf=${_timedBuffer.length}',
        );
      }

      final motion = _computeMotion(result.features);
      _prevFrame = List<double>.from(result.features);

      if (motion >= _motionThreshold) {
        _lastMotionMs = nowMs;
      }

      _timedBuffer.add((nowMs, result.features));

      final timeSinceMotion = nowMs - _lastMotionMs;
      final windowAge = _timedBuffer.length >= 2
          ? nowMs - _timedBuffer.first.$1
          : 0;

      if (timeSinceMotion <= RecognitionConstants.motionWindowMs &&
          (windowAge >= RecognitionConstants.minWindowMs ||
              _timedBuffer.length >= 3) &&
          nowMs - _lastInferenceMs >= RecognitionConstants.inferIntervalMs) {
        shouldInfer = true;
      }
    } else {
      _noDetectionTimer ??= Timer(const Duration(milliseconds: RecognitionConstants.noDetectionGracePeriodMs), () {
        _timedBuffer.clear();
        _noDetectionTimer = null;
        _inferenceCtrl.add(InferenceResult.empty);
      });
    }

    if (shouldInfer) _runInference();
  }

  // ── Hareket skoru ─────────────────────────────────────────────────────────
  // El landmark koordinatları (0..83) üzerinden hesaplanır.
  // Pose (84..105) kasıtlı hariç tutulur — vücut az hareket eder.
  double _computeMotion(List<double> current) {
    if (_prevFrame == null) return 0.0; // İlk kare — hareket yok
    double sum = 0.0;
    for (int i = 0; i < 84; i++) {
      sum += (current[i] - _prevFrame![i]).abs();
    }
    return sum / 84.0;
  }

  // ── TFLite inference ──────────────────────────────────────────────────────

  Future<void> _runInference() async {
    if (_isInferring || _timedBuffer.isEmpty) return;
    // Minimum 4 gerçek frame: yavaş cihazlarda (A32) 8-frame guard
    // inference fırsatlarını bloke ediyordu. 4 frame ≈ 600ms sinyal.
    if (_timedBuffer.length < RecognitionConstants.minInferenceFrames) return;

    _isInferring = true;
    _lastInferenceMs = DateTime.now().millisecondsSinceEpoch;
    try {
      final frames = _timedBuffer.map((e) => e.$2).toList();
      final result = await _inference.run(frames);
      if (result != null) {
        if (kDebugMode && _frameCounter % 500 == 0) {
          debugPrint(
            '🧠 Zeka → [${result.classIndex}] %${(result.confidence * 100).toStringAsFixed(0)}',
          );
        }
        _inferenceCtrl.add(result);
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('❌ Çıkarım hatası: $e\n$st');
    } finally {
      _isInferring = false;
    }
  }

  // ── Yardımcılar ───────────────────────────────────────────────────────────

  void _resetBuffer() {
    _timedBuffer.clear();
    _prevFrame = null;
    _lastMotionMs = 0;
    _lastInferenceMs = 0;
    _frameCounter = 0;
    _resultCounter = 0;
  }

  // ── Temizlik ──────────────────────────────────────────────────────────────

  @override
  Future<void> dispose() async {
    _noDetectionTimer?.cancel();
    await _cameraSub?.cancel();
    await _mlSub?.cancel();
    _camera.stopStream();
    await _camera.dispose();
    _ml.dispose();
    _inference.dispose();
    if (!_cameraCtrl.isClosed) _cameraCtrl.close();
    if (!_inferenceCtrl.isClosed) _inferenceCtrl.close();
    if (!_landmarkCtrl.isClosed) _landmarkCtrl.close();
  }
}
