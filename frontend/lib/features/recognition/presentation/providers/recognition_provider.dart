import 'dart:async';
import 'dart:io';
import 'dart:math' show min;
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart'
    as mlkit;
import 'package:hand_detection/hand_detection.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:tflite_flutter/tflite_flutter.dart' as tflite;

import '../../../../../core/providers/camera_lifecycle_provider.dart';
import '../../../../../core/providers/tts_provider.dart';
import '../../../../../core/utils/landmark_normalizer.dart';
import '../../../../../core/utils/label_mapper.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Developer modu için landmark verisi (ValueNotifier ile taşınır)
// ─────────────────────────────────────────────────────────────────────────────

class LandmarkDevData {
  final List<Offset> posePoints;  // 11 nokta [0,1] normalize
  final List<Offset> rightHand;   // ≤21 nokta
  final List<Offset> leftHand;    // ≤21 nokta
  final int bufferFill;
  final int poseCount;
  final int handCount;

  const LandmarkDevData({
    this.posePoints = const [],
    this.rightHand  = const [],
    this.leftHand   = const [],
    this.bufferFill = 0,
    this.poseCount  = 0,
    this.handCount  = 0,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Durum sınıfı
// ─────────────────────────────────────────────────────────────────────────────

class RecognitionState {
  final bool isReady;
  final bool isError;
  final CameraController? cameraController;
  // Anlık tahmin (smoothing sonrası)
  final String predictedWord;
  final double confidenceScore;
  // Altyazı biriktirme listesi
  final List<String> sentence;

  const RecognitionState({
    this.isReady = false,
    this.isError = false,
    this.cameraController,
    this.predictedWord = '',
    this.confidenceScore = 0.0,
    this.sentence = const [],
  });

  RecognitionState copyWith({
    bool? isReady,
    bool? isError,
    CameraController? cameraController,
    String? predictedWord,
    double? confidenceScore,
    List<String>? sentence,
  }) {
    return RecognitionState(
      isReady: isReady ?? this.isReady,
      isError: isError ?? this.isError,
      cameraController: cameraController ?? this.cameraController,
      predictedWord: predictedWord ?? this.predictedWord,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      sentence: sentence ?? this.sentence,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider  (Riverpod 3.x — NotifierProvider)
// ─────────────────────────────────────────────────────────────────────────────

final recognitionProvider =
    NotifierProvider<RecognitionNotifier, RecognitionState>(
  RecognitionNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class RecognitionNotifier extends Notifier<RecognitionState> {
  // ── Algılayıcılar ──────────────────────────────────────────────────────────
  mlkit.PoseDetector? _poseDetector;
  HandDetector? _handDetector;
  tflite.Interpreter? _interpreter;
  CameraController? _camera;
  List<CameraDescription> _allCameras = [];
  CameraLensDirection _currentLens = CameraLensDirection.back;

  // ── Sliding-window tamponu ─────────────────────────────────────────────────
  // [0..41] Sağ el · [42..83] Sol el · [84..105] Pose (11 nokta)
  static const int _windowSize  = 60;
  static const int _featureSize = 106;
  static const int _numClasses  = 226;
  static const List<int> _poseIndices = [0, 2, 5, 7, 8, 11, 12, 13, 14, 15, 16];

  // Canlı çeviri için parametreler:
  // stride=2 → 30fps'de 15 kare/sn buffer'a girer
  // İlk inference: 15 kare (~1 sn), sonra her 3 karede bir
  static const int _stride       = 2;
  static const int _inferEvery   = 3;   // inference adımı (kare sayısı)
  static const int _minBuffer    = 15;  // ilk inference için minimum kare

  final List<List<double>> _buffer = [];
  int  _frameCounter = 0;
  bool _isProcessing = false;

  // ── Temporal smoothing ────────────────────────────────────────────────────
  // Aynı sınıf 3 ardışık inference → göster (canlı çeviri için düşürüldü)
  static const int _stableFrames = 3;
  int _lastIdx = -1;
  int _streak  = 0;

  // ── Altyazı / cümle biriktirme ────────────────────────────────────────────
  String _lastShownWord = '';
  Timer? _clearTimer;

  // ── Buffer temizleme grace period ─────────────────────────────────────────
  // El bir kare kaybolunca buffer hemen silinmez; 1 sn boyunca hiç tespit
  // yoksa silinir. Bu sayede kısa okluzyonlarda tanıma sıfırlanmaz.
  Timer? _noDetectionTimer;

  // ── Developer modu — per-frame Riverpod rebuild tetiklememek için ─────────
  final devNotifier = ValueNotifier<LandmarkDevData>(const LandmarkDevData());

  // ── Riverpod 3.x: build() başlangıç durumunu döndürür ────────────────────

  @override
  RecognitionState build() {
    ref.keepAlive();
    ref.onDispose(_cleanup);

    // Kamera aktif provider'ını dinle — navigasyon katmanından gelen sinyal
    ref.listen<bool>(cameraActiveProvider, (_, isActive) {
      if (isActive) {
        resumeCamera();
      } else {
        pauseCamera();
      }
    });

    _init();
    return const RecognitionState();
  }

  // ── Başlatma ───────────────────────────────────────────────────────────────

  Future<void> _init() async {
    try {
      _poseDetector = mlkit.PoseDetector(
        options: mlkit.PoseDetectorOptions(
          mode: mlkit.PoseDetectionMode.stream,
          model: mlkit.PoseDetectionModel.base,
        ),
      );

      _handDetector = HandDetector();
      await _handDetector!.initialize();

      final opts = tflite.InterpreterOptions()..threads = 4;
      _interpreter = await tflite.Interpreter.fromAsset(
        'assets/models/sign_language_model.tflite',
        options: opts,
      );

      await _startCamera();
    } catch (e) {
      debugPrint('❌ Başlatma hatası: $e');
      state = state.copyWith(isError: true);
    }
  }

  Future<void> _startCamera({CameraLensDirection? lens}) async {
    // Kamera değişince önceki tespit durumunu sıfırla
    _noDetectionTimer?.cancel();
    _noDetectionTimer = null;
    _clearTimer?.cancel();
    _clearTimer = null;
    _lastIdx = -1;
    _streak = 0;
    _lastShownWord = '';

    _allCameras = await availableCameras();
    if (_allCameras.isEmpty) {
      state = state.copyWith(isError: true);
      return;
    }

    final direction = lens ?? _currentLens;
    final selected = _allCameras.firstWhere(
      (c) => c.lensDirection == direction,
      orElse: () => _allCameras.first,
    );
    _currentLens = selected.lensDirection;

    final format = Platform.isIOS
        ? ImageFormatGroup.bgra8888
        : ImageFormatGroup.nv21;

    await _camera?.stopImageStream();
    await _camera?.dispose();

    _camera = CameraController(
      selected,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: format,
    );
    await _camera!.initialize();
    _buffer.clear();

    state = state.copyWith(
      isReady: true,
      cameraController: _camera,
      predictedWord: '',
      confidenceScore: 0.0,
    );

    // Stream'i yalnızca kamera ekranı aktifse başlat
    if (ref.read(cameraActiveProvider)) {
      _camera!.startImageStream(_onFrame);
    }
  }

  // ── Kare işleme ────────────────────────────────────────────────────────────

  void _onFrame(CameraImage image) async {
    _frameCounter++;
    if (_frameCounter % _stride != 0) return;
    if (_isProcessing) return;
    if (_poseDetector == null || _handDetector == null) return;
    _isProcessing = true;

    final bool doLog = (_frameCounter % 150 == 0); // ~15 sn'de bir log

    // ── Merkezi kare kırpma bölgesi ────────────────────────────────────────
    // AUTSL eğitim videoları 512×512 (kare). Kamera görüntüsü dikdörtgen
    // (örn. 480×640). Normalize koordinatlar eğitimde 1:1 uzayda hesaplandı;
    // biz de aynı oranı sağlamak için merkezlenmiş min-kenar kareye kırpıyoruz.
    final int cropSide = min(image.width, image.height);
    final int cropXOff = (image.width  - cropSide) ~/ 2;
    final int cropYOff = (image.height - cropSide) ~/ 2;

    if (doLog) {
      debugPrint('📷 Kare=$_frameCounter '
          'sensör=${image.width}x${image.height} '
          'crop=${cropSide}x$cropSide off=($cropXOff,$cropYOff) '
          'buf=${_buffer.length}/$_windowSize');
    }

    try {
      final frame = List<double>.filled(_featureSize, 0.0);
      bool anyDetected = false;

      final inputImage = _buildInputImage(image);

      // 1. Pose (ML Kit) — indeksler 84..105
      var poseRaw = const <Offset>[];
      int poseCount = 0;
      if (inputImage != null) {
        final poses = await _poseDetector!.processImage(inputImage);
        poseCount = poses.length;
        if (poses.isNotEmpty) {
          anyDetected = true;
          poseRaw = _fillPose(poses.first, frame,
              cropSide: cropSide, cropXOff: cropXOff);
        }
        if (doLog) debugPrint('🧍 Pose: $poseCount tespit');
      }

      // 2. Eller (hand_detection) — indeksler 0..83
      var rightRaw = const <Offset>[];
      var leftRaw  = const <Offset>[];
      int handCount = 0;
      final mat = _toMat(image);
      if (mat != null) {
        try {
          final hands = await _handDetector!.detectOnMat(mat);
          handCount = hands.length;
          if (hands.isNotEmpty) {
            anyDetected = true;
            final filled = _fillHands(hands, frame,
                cropSide: cropSide, cropXOff: cropXOff);
            rightRaw = filled.right;
            leftRaw  = filled.left;
          }
          if (doLog) debugPrint('🖐 El: $handCount tespit');
        } catch (e) {
          // El tespiti başarısız olsa bile pose verisiyle devam et
          debugPrint('⚠️ El tespiti hatası (pose devam ediyor): $e');
        } finally {
          mat.dispose();
        }
      }

      // Dev notifier güncelle (Riverpod rebuild olmaz)
      if (ref.read(settingsProvider).devMode) {
        devNotifier.value = LandmarkDevData(
          posePoints: poseRaw,
          rightHand:  rightRaw,
          leftHand:   leftRaw,
          bufferFill: _buffer.length,
          poseCount:  poseCount,
          handCount:  handCount,
        );
      }

      if (anyDetected) {
        // Tespit geldi → grace period timer'ı iptal et, buffer'a ekle
        _noDetectionTimer?.cancel();
        _noDetectionTimer = null;
        _buffer.add(frame);
        if (_buffer.length > _windowSize) _buffer.removeAt(0);
        // İlk inference: _minBuffer kare yeterli (~1 sn).
        // Sonrasında her _inferEvery karede bir inference.
        // Buffer her zaman 60 kareye resampling ile normalize edilir
        // (son kare padding yerine uniform interpolasyon → eğitimle uyumlu).
        if (_buffer.length >= _minBuffer &&
            _buffer.length % _inferEvery == 0) {
          _runInference();
        }
      } else {
        // Tespit yok → hemen silme, 1 saniyelik grace period başlat
        _noDetectionTimer ??= Timer(const Duration(seconds: 1), () {
          _buffer.clear();
          _noDetectionTimer = null;
          state = state.copyWith(predictedWord: '', confidenceScore: 0.0);
        });
      }
    } catch (e, st) {
      debugPrint('❌ Frame hatası: $e\n$st');
    } finally {
      _isProcessing = false;
    }
  }

  // ── Landmark doldurma ──────────────────────────────────────────────────────

  // Ön kamera (selfie) kullanırken ham CameraImage X ekseni mirror'lıdır.
  // Model AUTSL verisiyle (kamera karşısındaki kişi, mirror'sız) eğitildiği için
  // ön kamerada X koordinatları 1.0 - nx şeklinde çevrilmelidir.
  double _maybeFlipX(double nx) =>
      _currentLens == CameraLensDirection.front ? 1.0 - nx : nx;

  // ── Sensör → model koordinat dönüşümü ────────────────────────────────────
  //
  // Kamera sensörü landscape görüntü üretir (örn. 720×480).
  // Model AUTSL portré 512×512 videolarıyla eğitildi; koordinatlar portré uzayında.
  // sensorOrientation=90° → 90° saat yönünde döndürerek portré elde edilir:
  //
  //   model_x (portre yatay, 0=sol 1=sağ) = 1.0 - sensor_y / cropSide
  //   model_y (portre dikey, 0=üst 1=alt) = (sensor_x - cropXOff) / cropSide
  //
  // cropSide = min(sensorW, sensorH) = sensörün kısa kenarı (480 için 720×480)
  // cropXOff = (sensorW - cropSide) / 2  → sensör_x yönünde ortalanmış kırpma
  //            bu portrede üst/alt kırpmaya karşılık gelir

  double _sensorToModelX(double sy, int cropSide) =>
      (1.0 - sy / cropSide).clamp(0.0, 1.0).toDouble();

  double _sensorToModelY(double sx, int cropXOff, int cropSide) =>
      ((sx - cropXOff) / cropSide).clamp(0.0, 1.0).toDouble();

  List<Offset> _fillPose(
      mlkit.Pose pose, List<double> frame, {
      required int cropSide, required int cropXOff}) {
    final raw = <Offset>[];
    for (int i = 0; i < _poseIndices.length; i++) {
      final lm = pose.landmarks[mlkit.PoseLandmarkType.values[_poseIndices[i]]];
      if (lm == null) continue;
      // ML Kit, InputImage.fromBytes ile sensör uzayında koordinat döndürür.
      final mx = _maybeFlipX(_sensorToModelX(lm.y, cropSide));
      final my = _sensorToModelY(lm.x, cropXOff, cropSide);
      frame[84 + i * 2]     = mx;
      frame[84 + i * 2 + 1] = my;
      raw.add(Offset(mx, my));
    }
    return raw;
  }

  ({List<Offset> right, List<Offset> left}) _fillHands(
      List<dynamic> hands, List<double> frame, {
      required int cropSide, required int cropXOff}) {
    final right = <Offset>[];
    final left  = <Offset>[];
    for (final hand in hands) {
      final detectedRight = hand.handedness == Handedness.right;
      // Ön kamerada ham görüntü mirror'lı → hand detector sağ/solu ters görür.
      // Fiziksel sağ eli doğru buffer'a koymak için handedness da terslenmelidir.
      final isRight = _currentLens == CameraLensDirection.front
          ? !detectedRight
          : detectedRight;
      final offset  = isRight ? 0 : 42;
      final target  = isRight ? right : left;
      final landmarksRaw = hand.landmarks;
      if (landmarksRaw == null) continue;
      final landmarks = landmarksRaw as List;
      for (int i = 0; i < landmarks.length && i < 21; i++) {
        final lm = landmarks[i];
        final sx = (lm.x as num).toDouble(); // sensör x (landscape yatay)
        final sy = (lm.y as num).toDouble(); // sensör y (landscape dikey)
        final mx = _maybeFlipX(_sensorToModelX(sy, cropSide));
        final my = _sensorToModelY(sx, cropXOff, cropSide);
        frame[offset + i * 2]     = mx;
        frame[offset + i * 2 + 1] = my;
        target.add(Offset(mx, my));
      }
    }
    return (right: right, left: left);
  }

  // ── Buffer resampling ──────────────────────────────────────────────────────
  // Buffer'daki N kareyi uniform interpolasyonla _windowSize kareye dönüştürür.
  // AUTSL eğitiminde her video klip 60 kareye yeniden örneklendi; biz de aynısını
  // yaparak buffer uzunluğundan bağımsız doğru temporal dağılımı sağlıyoruz.
  List<List<double>> _resampleBuffer(List<List<double>> buffer) {
    if (buffer.isEmpty) {
      return List.generate(
        _windowSize, (_) => List<double>.filled(_featureSize, 0.0));
    }
    if (buffer.length == _windowSize) return buffer;
    return List.generate(_windowSize, (i) {
      final src = (i * (buffer.length - 1) / (_windowSize - 1))
          .round()
          .clamp(0, buffer.length - 1);
      return buffer[src];
    });
  }

  // ── TFLite çıkarımı ────────────────────────────────────────────────────────

  void _runInference() {
    if (_interpreter == null || _buffer.isEmpty) return;

    try {
      // Buffer'ı her zaman _windowSize kareye uniform resampling ile normalize et.
      // Son kare padding yerine interpolasyon → eğitimle aynı temporal dağılım.
      final window = _resampleBuffer(_buffer);
      final normalized = LandmarkNormalizer.normalizeWindow(window);

      final input = [
        List.generate(_windowSize, (j) => List<double>.from(normalized[j])),
      ];
      final output =
          List<double>.filled(_numClasses, 0.0).reshape([1, _numClasses]);

      _interpreter!.run(input, output);

      final scores = List<double>.from(output[0] as List);
      var maxScore = 0.0;
      var maxIdx   = -1;

      for (int i = 0; i < scores.length; i++) {
        if (scores[i] > maxScore) {
          maxScore = scores[i];
          maxIdx   = i;
        }
      }

      final topWord = maxIdx >= 0 ? LabelMapper.getTrWord(maxIdx) : '?';
      debugPrint('🧠 Inference → idx:$maxIdx  skor:${(maxScore * 100).toStringAsFixed(1)}%  kelime:$topWord');

      // ── Threshold settings'ten okunur (Düşük=%70 / Orta=%80 / Yüksek=%90) ──
      final currentSettings   = ref.read(settingsProvider);
      final smoothingOn       = currentSettings.temporalSmoothingEnabled;
      final scoreThreshold    = currentSettings.confidenceThreshold;

      if (maxIdx >= 0 && maxScore >= scoreThreshold) {
        if (maxIdx == _lastIdx) {
          _streak++;
        } else {
          // Yeni sınıf → streak'i sıfırla AMA sadece belirgin fark varsa
          // (önceki sınıftan çok düşük skorla ayrılıyorsa geçiş sayılmaz)
          _lastIdx = maxIdx;
          _streak  = 1;
        }

        // Smoothing kapalıysa ilk inference'da anında göster (streak=1 yeterli)
        final threshold = smoothingOn ? _stableFrames : 1;
        if (_streak >= threshold) {
          final word = LabelMapper.getTrWord(maxIdx);

          if (word != _lastShownWord) {
            _lastShownWord = word;
            final updated = [...state.sentence, word];
            final trimmed = updated.length > 6
                ? updated.sublist(updated.length - 6)
                : updated;

            state = state.copyWith(
              predictedWord:   word,
              confidenceScore: maxScore,
              sentence:        trimmed,
            );

            // TTS: ttsEnabled ise yeni kelimeyi seslendir
            if (ref.read(settingsProvider).ttsEnabled) {
              ref.read(ttsProvider.notifier).speak(word);
            }

            // Haptic: ≥90% güven → orta titreşim (spec)
            if (maxScore >= 0.90) {
              HapticFeedback.mediumImpact();
            }

            _clearTimer?.cancel();
            _clearTimer = Timer(const Duration(seconds: 4), () {
              state = state.copyWith(
                predictedWord:   '',
                confidenceScore: 0.0,
                sentence:        [],
              );
              _lastShownWord = '';
            });
          } else {
            state = state.copyWith(confidenceScore: maxScore);
          }
        }
      } else {
        // Skor düşük — streak ve sınıfı sıfırla (stale lastIdx'den streak devam etmesin)
        _streak = 0;
        _lastIdx = -1;
      }
    } catch (e, st) {
      debugPrint('❌ Çıkarım hatası: $e\n$st');
    }
  }

  // ── Yardımcılar ────────────────────────────────────────────────────────────

  mlkit.InputImage? _buildInputImage(CameraImage image) {
    try {
      final rotation =
          mlkit.InputImageRotationValue.fromRawValue(
            _camera!.description.sensorOrientation,
          ) ??
          mlkit.InputImageRotation.rotation90deg;

      if (Platform.isIOS) {
        return mlkit.InputImage.fromBytes(
          bytes: image.planes[0].bytes,
          metadata: mlkit.InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation,
            format: mlkit.InputImageFormat.bgra8888,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );
      } else {
        final bytes = _buildNV21(image);
        return mlkit.InputImage.fromBytes(
          bytes: bytes,
          metadata: mlkit.InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation,
            format: mlkit.InputImageFormat.nv21,
            bytesPerRow: image.width,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ _buildInputImage hatası: $e');
      return null;
    }
  }

  Uint8List _buildNV21(CameraImage image) {
    final int w = image.width;
    final int h = image.height;

    if (image.planes.length == 1) {
      final int stride = image.planes[0].bytesPerRow;
      if (stride == w) return image.planes[0].bytes;
      final out = Uint8List(w * h * 3 ~/ 2);
      final src = image.planes[0].bytes;
      for (int r = 0; r < h; r++) {
        out.setRange(r * w, (r + 1) * w, src, r * stride);
      }
      for (int r = 0; r < h ~/ 2; r++) {
        out.setRange(
          h * w + r * w, h * w + (r + 1) * w,
          src, h * stride + r * stride,
        );
      }
      return out;
    }

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final out = Uint8List(w * h * 3 ~/ 2);
    for (int r = 0; r < h; r++) {
      out.setRange(r * w, (r + 1) * w, yPlane.bytes, r * yPlane.bytesPerRow);
    }
    int uvOffset = w * h;
    final int uvRows = h ~/ 2;
    final int uvCols = w ~/ 2;
    for (int r = 0; r < uvRows; r++) {
      for (int c = 0; c < uvCols; c++) {
        final srcU = r * uPlane.bytesPerRow + c * (uPlane.bytesPerPixel ?? 1);
        final srcV = r * vPlane.bytesPerRow + c * (vPlane.bytesPerPixel ?? 1);
        out[uvOffset++] = vPlane.bytes[srcV];
        out[uvOffset++] = uPlane.bytes[srcU];
      }
    }
    return out;
  }

  cv.Mat? _toMat(CameraImage image) {
    try {
      if (Platform.isIOS) {
        final bgra = cv.Mat.fromList(
          image.height, image.width,
          cv.MatType.CV_8UC4,
          image.planes[0].bytes,
        );
        final bgr = cv.cvtColor(bgra, cv.COLOR_BGRA2BGR);
        bgra.dispose();
        return bgr;
      } else {
        final nv21 = _buildNV21(image);
        final yuv  = cv.Mat.fromList(
          image.height + image.height ~/ 2, image.width,
          cv.MatType.CV_8UC1,
          nv21,
        );
        final bgr = cv.cvtColor(yuv, cv.COLOR_YUV2BGR_NV21);
        yuv.dispose();
        return bgr;
      }
    } catch (_) {
      return null;
    }
  }

  // ── Temizlik ───────────────────────────────────────────────────────────────

  void _cleanup() {
    try { _clearTimer?.cancel(); } catch (_) {}
    try { _noDetectionTimer?.cancel(); } catch (_) {}
    try { _poseDetector?.close(); } catch (_) {}
    try { _handDetector?.dispose(); } catch (_) {}
    try { _interpreter?.close(); } catch (_) {}
    try { _camera?.stopImageStream(); } catch (_) {}
    try { _camera?.dispose(); } catch (_) {}
    try { devNotifier.dispose(); } catch (_) {}
  }

  // ── Kamera kontrolü ───────────────────────────────────────────────────────

  void pauseCamera() {
    try { _camera?.stopImageStream(); } catch (_) {}
  }

  void resumeCamera() {
    try {
      if (_camera != null &&
          _camera!.value.isInitialized &&
          !_camera!.value.isStreamingImages) {
        _camera!.startImageStream(_onFrame);
      }
    } catch (_) {}
  }

  /// Çift tıkla ön/arka kamera geçişi
  Future<void> switchCamera() async {
    final next = _currentLens == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    await _startCamera(lens: next);
  }
}
