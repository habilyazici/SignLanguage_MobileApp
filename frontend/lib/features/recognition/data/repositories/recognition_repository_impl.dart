import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../../../../../core/constants/recognition_constants.dart';
import '../../domain/entities/inference_result.dart';
import '../../domain/entities/recognition_state.dart';
import '../../domain/repositories/recognition_repository.dart';
import '../datasources/camera_datasource.dart';
import '../datasources/inference_datasource.dart';
import '../datasources/ml_pipeline_datasource.dart';

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
  })  : _camera = cameraDataSource,
        _ml = mlPipelineDataSource,
        _inference = inferenceDataSource;

  final CameraDataSource _camera;
  final MlPipelineDatasource _ml;
  final InferenceDatasource _inference;

  // ── Streams ────────────────────────────────────────────────────────────────

  final _cameraCtrl = StreamController<CameraController?>.broadcast();
  final _inferenceCtrl = StreamController<InferenceResult>.broadcast();
  final _landmarkCtrl = StreamController<LandmarkDevData>.broadcast();

  @override
  Stream<CameraController?> get cameraControllerStream => _cameraCtrl.stream;
  @override
  Stream<InferenceResult> get inferenceStream => _inferenceCtrl.stream;
  @override
  Stream<LandmarkDevData> get landmarkStream => _landmarkCtrl.stream;

  // ── Çalışma zamanı durumu ─────────────────────────────────────────────────

  final List<(int, List<double>)> _timedBuffer = [];
  int _frameCounter = 0;
  bool _isProcessing = false;
  bool _isInferring = false;
  List<double>? _prevFrame;
  int _lastMotionMs = 0;
  bool _leftHandMode = false;
  bool _isStreaming = false;
  Timer? _noDetectionTimer;
  StreamSubscription<CameraController?>? _cameraSub;

  // ── Başlatma ───────────────────────────────────────────────────────────────

  @override
  Future<void> initialize() async {
    await _ml.initialize();
    await _inference.initialize();

    // Kamera controller değişince stream'e ilet; buffer'ı sıfırla.
    _cameraSub = _camera.controllerStream.listen((ctrl) {
      _cameraCtrl.add(ctrl);
      if (ctrl != null) _resetBuffer();
    });

    await _camera.initialize();
    _isStreaming = true;
    _camera.startStream(_onFrame);
  }

  // ── Kamera kontrolü ───────────────────────────────────────────────────────

  @override
  Future<void> pauseCamera() async {
    _isStreaming = false;
    _camera.stopStream();
  }

  @override
  Future<void> resumeCamera() async {
    if (!_isStreaming && _camera.currentCamera != null) {
      _isStreaming = true;
      _camera.startStream(_onFrame);
    }
  }

  @override
  Future<void> switchCamera() async {
    final wasStreaming = _isStreaming;
    _camera.stopStream();
    _resetBuffer();
    await _camera.switchCamera();
    if (wasStreaming) {
      _isStreaming = true;
      _camera.startStream(_onFrame);
    }
  }

  @override
  void updateLeftHandMode(bool leftHand) => _leftHandMode = leftHand;

  // ── Frame işleme ──────────────────────────────────────────────────────────

  void _onFrame(CameraImage image) async {
    _frameCounter++;
    if (_isProcessing || !_ml.isReady) return;
    _isProcessing = true;

    final bool doLog = (_frameCounter % 150 == 0);
    bool shouldInfer = false;

    try {
      final result = await _ml.process(
        image,
        sensorOrientation: _camera.sensorOrientation,
        isFlipped: _camera.isFlipped,
        leftHandMode: _leftHandMode,
      );

      if (doLog) {
        debugPrint(
          '📷 Kare=$_frameCounter buf=${_timedBuffer.length} '
          '(~${RecognitionConstants.windowMs}ms pencere)',
        );
      }

      // Developer modu landmark stream'i
      _landmarkCtrl.add(LandmarkDevData(
        posePoints: result.posePoints,
        rightHand: result.rightHandPoints,
        leftHand: result.leftHandPoints,
        bufferFill: _timedBuffer.length,
        poseCount: result.poseCount,
        handCount: result.handCount,
      ));

      if (result.anyDetected) {
        _noDetectionTimer?.cancel();
        _noDetectionTimer = null;

        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final motion = _computeMotion(result.features);
        _prevFrame = List<double>.from(result.features);

        if (motion >= RecognitionConstants.motionThreshold) {
          _lastMotionMs = nowMs;
        }

        _timedBuffer.add((nowMs, result.features));
        _timedBuffer.removeWhere(
          (e) => nowMs - e.$1 > RecognitionConstants.windowMs,
        );

        final timeSinceMotion = nowMs - _lastMotionMs;
        final windowAge = _timedBuffer.length >= 2
            ? nowMs - _timedBuffer.first.$1
            : 0;

        if (timeSinceMotion <= RecognitionConstants.motionWindowMs &&
            (windowAge >= RecognitionConstants.minWindowMs ||
                _timedBuffer.length >= 3) &&
            _frameCounter % RecognitionConstants.inferEvery == 0) {
          shouldInfer = true;
        }
      } else {
        // Tespit yok → 1 saniyelik grace period, sonra buffer temizle
        _noDetectionTimer ??= Timer(const Duration(seconds: 1), () {
          _timedBuffer.clear();
          _noDetectionTimer = null;
          _inferenceCtrl.add(InferenceResult.empty);
        });
      }
    } catch (e, st) {
      debugPrint('❌ Frame hatası: $e\n$st');
    } finally {
      _isProcessing = false;
    }

    if (shouldInfer) _runInference();
  }

  // ── Hareket skoru ─────────────────────────────────────────────────────────
  // El landmark koordinatları (0..83) üzerinden hesaplanır.
  // Pose (84..105) kasıtlı hariç tutulur — vücut az hareket eder.
  double _computeMotion(List<double> current) {
    if (_prevFrame == null) return double.infinity;
    double sum = 0.0;
    for (int i = 0; i < 84; i++) {
      sum += (current[i] - _prevFrame![i]).abs();
    }
    return sum / 84.0;
  }

  // ── TFLite inference ──────────────────────────────────────────────────────

  Future<void> _runInference() async {
    if (_isInferring || _timedBuffer.isEmpty) return;
    // Kararlılık guard: ~8 gerçek kare yeterli (resampling ile 60'a tamamlanır)
    if (_timedBuffer.length < 8) return;

    _isInferring = true;
    try {
      final frames = _timedBuffer.map((e) => e.$2).toList();
      final result = await _inference.run(frames);
      if (result != null) {
        debugPrint(
          '🧠 Inference → idx:${result.classIndex} '
          'skor:${(result.confidence * 100).toStringAsFixed(1)}%',
        );
        _inferenceCtrl.add(result);
      }
    } catch (e, st) {
      debugPrint('❌ Çıkarım hatası: $e\n$st');
    } finally {
      _isInferring = false;
    }
  }

  // ── Yardımcılar ───────────────────────────────────────────────────────────

  void _resetBuffer() {
    _timedBuffer.clear();
    _prevFrame = null;
    _lastMotionMs = 0;
    _frameCounter = 0;
  }

  // ── Temizlik ──────────────────────────────────────────────────────────────

  @override
  Future<void> dispose() async {
    _noDetectionTimer?.cancel();
    await _cameraSub?.cancel();
    _camera.stopStream();
    await _camera.dispose();
    _ml.dispose();
    _inference.dispose();
    if (!_cameraCtrl.isClosed) _cameraCtrl.close();
    if (!_inferenceCtrl.isClosed) _inferenceCtrl.close();
    if (!_landmarkCtrl.isClosed) _landmarkCtrl.close();
  }
}
