import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math' show min;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Offset, Size;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart'
    as mlkit;
import 'package:hand_detection/hand_detection.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

import '../../../../../core/constants/recognition_constants.dart';
import '../../domain/entities/ml_frame_result.dart';

/// Bir sonraki işleme için bekleyen kare verisi.
class _PendingData {
  const _PendingData({
    required this.planes,
    required this.width,
    required this.height,
    required this.sensorOrientation,
    required this.isFlipped,
    required this.leftHandMode,
  });

  /// Android'de [Y, U, V] plane'lerini, iOS'ta tek [BGRA] plane'ini tutar.
  final List<({Uint8List bytes, int bytesPerRow, int? bytesPerPixel})> planes;
  final int width;
  final int height;
  final int sensorOrientation;
  final bool isFlipped;
  final bool leftHandMode;
}

/// Sıkı Bağlı ML Pipeline: Pose ve El tespiti her zaman aynı kareden gelir.
///
/// Mimari:
///   submit() → Meşgulse sadece kopyala; Boşsa _execute() başlat.
///   _execute() → Pose (Sync) + Mat (Sync) → Hand Isolate (Async)
///   Finish → resultStream'e bas → Varsa bekleyen kareyi başlat.
class MlPipelineDatasource {
  mlkit.PoseDetector? _poseDetector;
  HandDetectorIsolate? _handDetectorIsolate;
  Uint8List? _nv21Buffer;

  static const List<int> _poseIndices = [0, 2, 5, 7, 8, 11, 12, 13, 14, 15, 16];
  final List<double> _lastPoseFeatures = List<double>.filled(22, 0.0);

  // Pose her N karede bir çalışır. Yavaş cihazlarda (latency > eşik) otomatik artar.
  // Hand detection her frame çalışmaya devam eder — asıl darboğaz o.
  int _poseFrameCount = 0;
  int _currentPoseEvery = RecognitionConstants.poseEvery;

  // Son 8 frame latency ortalaması — adaptif pose frekansı için.
  final _recentLatencies = Queue<int>();
  static const int _latencyWindow = 8;

  bool _handBusy = false;
  _PendingData? _pendingData;

  final _resultCtrl = StreamController<MlFrameResult>.broadcast();
  Stream<MlFrameResult> get resultStream => _resultCtrl.stream;

  // ── Başlatma ────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    _poseDetector = mlkit.PoseDetector(
      options: mlkit.PoseDetectorOptions(
        mode: mlkit.PoseDetectionMode.stream,
        model: mlkit.PoseDetectionModel.base,
      ),
    );
    _handDetectorIsolate = await HandDetectorIsolate.spawn();
    if (kDebugMode) debugPrint('✅ HandDetectorIsolate başlatıldı');
  }

  bool get isReady => _poseDetector != null && _handDetectorIsolate != null;

  // ── Giriş Noktası ──────────────────────────────────────────────────────────

  /// Kamera karesini kabul eder. Isolate meşgulse işlem yapmadan saklar.
  Future<void> submit(
    CameraImage image, {
    required int sensorOrientation,
    required bool isFlipped,
    required bool leftHandMode,
  }) async {
    // Sorumluluk: Kamera resim verisini HIZLI kopyala (Main thread'i yormadan).
    // Loop (NV21 assembly) burada yapılmaz, _execute() içine ertelenir.
    final List<({Uint8List bytes, int bytesPerRow, int? bytesPerPixel})> planes = [];
    
    try {
      for (final plane in image.planes) {
        planes.add((
          bytes: Uint8List.fromList(plane.bytes),
          bytesPerRow: plane.bytesPerRow,
          bytesPerPixel: plane.bytesPerPixel,
        ));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Plane kopyalama hatası: $e');
      return;
    }

    if (planes.isEmpty) return;

    final data = _PendingData(
      planes: planes,
      width: image.width,
      height: image.height,
      sensorOrientation: sensorOrientation,
      isFlipped: isFlipped,
      leftHandMode: leftHandMode,
    );

    if (_handBusy) {
      _pendingData = data;
      return;
    }

    _handBusy = true;
    final sw = Stopwatch()..start();
    _execute(data, sw);
  }

  // ── Çekirdek İşlem ────────────────────────────────────────────────────────

  /// Pose ve El tespitini aynı kare üzerinde PARALEL olarak gerçekleştirir.
  Future<void> _execute(_PendingData data, Stopwatch sw) async {
    final frame = List<double>.filled(106, 0.0);

    // NV21'i bir kez üret — hem InputImage hem Mat için kullanılır.
    final Uint8List? nv21 = Platform.isAndroid
        ? _buildNV21FromPlanes(data.planes, data.width, data.height)
        : null;

    final inputImage = _buildInputImageFromBytes(data, nv21);
    final mat = _toMatFromBytes(data, nv21);

    if (inputImage == null || mat == null) {
      mat?.dispose();
      _finishCycle();
      return;
    }

    try {
      // ── Adaptif pose frekansı: latency yüksekse pose daha seyrek çalışır ──
      _recentLatencies.add(sw.elapsedMilliseconds);
      if (_recentLatencies.length > _latencyWindow) {
        _recentLatencies.removeFirst(); // Queue: O(1) — List.removeAt(0)'dan daha doğru
      }
      if (_recentLatencies.length == _latencyWindow) {
        final avg = _recentLatencies.reduce((a, b) => a + b) ~/ _latencyWindow;
        if (avg > RecognitionConstants.kLatencySlowMs &&
            _currentPoseEvery < RecognitionConstants.poseEveryMax) {
          _currentPoseEvery++;
        } else if (avg <= RecognitionConstants.kLatencySlowMs &&
            _currentPoseEvery > RecognitionConstants.poseEvery) {
          _currentPoseEvery--;
        }
      }

      // ── Pose ve El tespitini PARALEL başlat ──
      _poseFrameCount++;
      final bool runPose = _poseFrameCount % _currentPoseEvery == 0;

      final results = await Future.wait([
        runPose
            ? _poseDetector!.processImage(inputImage)
            : Future.value(<mlkit.Pose>[]),
        _handDetectorIsolate!.detectHandsFromMat(mat),
      ]);

      final List<mlkit.Pose> poses = results[0] as List<mlkit.Pose>;
      final List<Hand> hands = results[1] as List<Hand>;

      // ── 1. Pose Verilerini İşle ──
      int poseCount = poses.length;
      List<Offset> posePoints = [];

      // Sensör döndürmesi (90/270°) ekran boyutlarını tersine çevirir.
      final bool rotated = data.sensorOrientation == 90 || data.sensorOrientation == 270;
      final double displayW = rotated ? data.height.toDouble() : data.width.toDouble();
      final double displayH = rotated ? data.width.toDouble() : data.height.toDouble();

      if (poses.isNotEmpty) {
        // _lastPoseFeatures per-landmark olarak _fillPose içinde güncellenir.
        posePoints = _fillPose(
          poses.first,
          frame,
          cropSide: _calcCropSide(data.width, data.height, data.sensorOrientation),
          cropXOff: _calcCropXOff(data.width, data.height, data.sensorOrientation),
          cropYOff: _calcCropYOff(data.width, data.height, data.sensorOrientation),
          isFlipped: data.isFlipped,
          displayWidth: displayW,
          displayHeight: displayH,
        );
      } else {
        // Pose atlandı veya tespit edilemedi — son bilinen değerleri taşı
        for (int i = 0; i < 22; i++) {
          frame[84 + i] = _lastPoseFeatures[i];
        }
      }

      // ── 2. El Verilerini İşle ──
      final handsData = _fillHands(
        hands,
        frame,
        imageWidth: data.width.toDouble(),
        imageHeight: data.height.toDouble(),
        cropSide: min(data.width, data.height),
        cropXOff: (data.width - min(data.width, data.height)) ~/ 2,
        sensorOrientation: data.sensorOrientation,
        isFlipped: data.isFlipped,
        leftHandMode: data.leftHandMode,
      );

      // ── 3. Sonuçları Yay ──
      _resultCtrl.add(MlFrameResult(
        features: frame,
        posePoints: posePoints,
        rightHandPoints: handsData.right,
        leftHandPoints: handsData.left,
        anyDetected: hands.isNotEmpty,
        poseCount: poseCount,
        handCount: hands.length,
        latencyMs: sw.elapsedMilliseconds,
      ));
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Paralel ML Hatası: $e');
    } finally {
      mat.dispose();
      sw.stop();
      _finishCycle();
    }
  }

  void _finishCycle() {
    final next = _pendingData;
    _pendingData = null;

    if (next != null) {
      final sw = Stopwatch()..start();
      _execute(next, sw);
    } else {
      _handBusy = false;
    }
  }

  // ── Dönüşüm Yardımcıları ──────────────────────────────────────────────────

  mlkit.InputImage? _buildInputImageFromBytes(_PendingData d, Uint8List? nv21) {
    final rotation = mlkit.InputImageRotationValue.fromRawValue(d.sensorOrientation) ??
        mlkit.InputImageRotation.rotation90deg;

    final Uint8List bytes = Platform.isAndroid
        ? (nv21 ?? Uint8List(0))
        : d.planes[0].bytes;

    if (bytes.isEmpty) return null;

    return mlkit.InputImage.fromBytes(
      bytes: bytes,
      metadata: mlkit.InputImageMetadata(
        size: Size(d.width.toDouble(), d.height.toDouble()),
        rotation: rotation,
        format: Platform.isAndroid ? mlkit.InputImageFormat.nv21 : mlkit.InputImageFormat.bgra8888,
        bytesPerRow: Platform.isAndroid ? d.width : d.width * 4,
      ),
    );
  }

  cv.Mat? _toMatFromBytes(_PendingData d, Uint8List? nv21) {
    try {
      if (Platform.isAndroid) {
        if (nv21 == null) return null;
        final yuv = cv.Mat.fromList(d.height + d.height ~/ 2, d.width, cv.MatType.CV_8UC1, nv21);
        final bgr = cv.cvtColor(yuv, cv.COLOR_YUV2BGR_NV21);
        yuv.dispose();
        return bgr;
      } else {
        final bgra = cv.Mat.fromList(d.height, d.width, cv.MatType.CV_8UC4, d.planes[0].bytes);
        final bgr = cv.cvtColor(bgra, cv.COLOR_BGRA2BGR);
        bgra.dispose();
        return bgr;
      }
    } catch (_) {
      return null;
    }
  }

  // ── Crop Hesaplamaları ────────────────────────────────────────────────────

  int _calcCropSide(int w, int h, int rot) {
    final bool r = rot == 90 || rot == 270;
    return min(r ? h : w, r ? w : h);
  }

  int _calcCropXOff(int w, int h, int rot) {
    final bool r = rot == 90 || rot == 270;
    final int rw = r ? h : w;
    return (rw - _calcCropSide(w, h, rot)) ~/ 2;
  }

  int _calcCropYOff(int w, int h, int rot) {
    final bool r = rot == 90 || rot == 270;
    final int rh = r ? w : h;
    return (rh - _calcCropSide(w, h, rot)) ~/ 2;
  }

  // ── Veri Doldurma ─────────────────────────────────────────────────────────

  List<Offset> _fillPose(mlkit.Pose pose, List<double> frame,
      {required int cropSide, required int cropXOff, required int cropYOff,
      required bool isFlipped, required double displayWidth, required double displayHeight}) {
    final pts = <Offset>[];
    for (int i = 0; i < _poseIndices.length; i++) {
      final lm = pose.landmarks[mlkit.PoseLandmarkType.values[_poseIndices[i]]];
      if (lm == null) continue;
      double mx = ((lm.x - cropXOff) / cropSide).clamp(0.0, 1.0);
      double my = ((lm.y - cropYOff) / cropSide).clamp(0.0, 1.0);
      if (isFlipped) mx = 1.0 - mx;
      frame[84 + i * 2] = mx;
      frame[84 + i * 2 + 1] = my;
      // Sadece tespit edilen landmark'lar güncellenir — null olanlar önceki değeri korur.
      _lastPoseFeatures[i * 2] = mx;
      _lastPoseFeatures[i * 2 + 1] = my;
      pts.add(Offset(lm.x / displayWidth, lm.y / displayHeight));
    }
    return pts;
  }

  ({List<Offset> right, List<Offset> left}) _fillHands(List<dynamic> hands, List<double> frame,
      {required double imageWidth,
      required double imageHeight,
      required int cropSide,
      required int cropXOff,
      required int sensorOrientation,
      required bool isFlipped,
      required bool leftHandMode}) {
    final rPts = <Offset>[];
    final lPts = <Offset>[];
    for (final hand in hands) {
      final bool isRight = hand.handedness == Handedness.right;
      final bool useRight = leftHandMode ? !isRight : isRight;
      final offset = useRight ? 0 : 42;
      final target = useRight ? rPts : lPts;
      final lms = hand.landmarks;
      if (lms is! List) continue;
      for (int i = 0; i < lms.length && i < 21; i++) {
        final lm = lms[i] as dynamic;
        double sx = (lm.x as num).toDouble();
        double sy = (lm.y as num).toDouble();
        // hand_detection koordinatları normalize [0,1] döner; piksel aralığına çevir.
        // Eşik (handCoordNormThreshold): tracking artifact'larında ufak taşma (1.01 gibi)
        // normalize kabul edilir; bu eşiğin üzerindekilerin piksel koordinatı olarak geldiği kabul edilir.
        if (sx <= RecognitionConstants.handCoordNormThreshold) {
          sx *= imageWidth;
          sy *= imageHeight;
        }
        double mx = _sXToMX(sx, sy, cropSide, cropXOff, sensorOrientation);
        double my = _sYToMY(sx, sy, cropSide, cropXOff, sensorOrientation);
        if (isFlipped) mx = 1.0 - mx;
        frame[offset + i * 2] = mx;
        frame[offset + i * 2 + 1] = my;
        // Dev overlay: gerçek çözünürlük kullanılır (Android 320×240, iOS 480×360).
        // 90° sensör dönüşü: kamera-Y → ekran-X, kamera-X → ekran-Y.
        target.add(Offset((imageHeight - sy) / imageHeight, sx / imageWidth));
      }
    }
    return (right: rPts, left: lPts);
  }

  double _sXToMX(double sx, double sy, int cs, int cx, int rot) {
    switch (rot) {
      case 90: return (1.0 - sy / cs).clamp(0.0, 1.0);
      case 270: return (sy / cs).clamp(0.0, 1.0);
      case 180: return (1.0 - (sx - cx) / cs).clamp(0.0, 1.0);
      default: return ((sx - cx) / cs).clamp(0.0, 1.0);
    }
  }

  double _sYToMY(double sx, double sy, int cs, int cx, int rot) {
    switch (rot) {
      case 90: return ((sx - cx) / cs).clamp(0.0, 1.0);
      case 270: return (1.0 - (sx - cx) / cs).clamp(0.0, 1.0);
      case 180: return (1.0 - sy / cs).clamp(0.0, 1.0);
      default: return (sy / cs).clamp(0.0, 1.0);
    }
  }

  Uint8List? _buildNV21FromPlanes(
    List<({Uint8List bytes, int bytesPerRow, int? bytesPerPixel})> planes,
    int w,
    int h,
  ) {
    if (planes.length < 3) return null;
    final int size = w * h * 3 ~/ 2;
    if (_nv21Buffer == null || _nv21Buffer!.length != size) {
      _nv21Buffer = Uint8List(size);
    }
    
    final yPlane = planes[0];
    final uPlane = planes[1];
    final vPlane = planes[2];
    final int uPS = uPlane.bytesPerPixel ?? 2;
    final int vPS = vPlane.bytesPerPixel ?? 2;
    final out = _nv21Buffer!;

    // 1. Y Plane (O(N) row-by-row setRange)
    for (int r = 0; r < h; r++) {
      out.setRange(r * w, (r + 1) * w, yPlane.bytes, r * yPlane.bytesPerRow);
    }

    // 2. UV Birleştirme (üretilen veriyi işleme aşamasına ertele)
    int uvOff = w * h;
    for (int r = 0; r < h ~/ 2; r++) {
      final int vRowBase = r * vPlane.bytesPerRow;
      final int uRowBase = r * uPlane.bytesPerRow;
      for (int c = 0; c < w ~/ 2; c++) {
        out[uvOff++] = vPlane.bytes[vRowBase + c * vPS];
        out[uvOff++] = uPlane.bytes[uRowBase + c * uPS];
      }
    }
    return out;
  }

  void dispose() {
    _resultCtrl.close();
    _pendingData = null;
    try { _poseDetector?.close(); } catch (_) {}
    try { _handDetectorIsolate?.dispose(); } catch (_) {}
  }
}
